import 'package:flutter_gemma/flutter_gemma.dart';
import '../../data/models/ai_model_info.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class ModelManager {
  static final ModelManager _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  static ModelManager get instance => _instance;

  final _plugin = FlutterGemmaPlugin.instance;
  InferenceModel? _currentModel;
  String? _currentModelId;
  PreferredBackend _currentBackend = PreferredBackend.gpu;

  // 支持的模型列表（扩展更多模型，真实HuggingFace地址）
  static const List<AIModelInfo> availableModels = [
    AIModelInfo(
      id: 'gemma-4-e2b',
      name: 'Gemma 4 E2B',
      size: '2.4GB',
      capabilities: ['text', 'image', 'audio'],
      description: '端侧多模态模型（内置）',
      isBuiltIn: true,
      localPath: 'assets/models/gemma-4-E2B-it.litertlm',
    ),
    AIModelInfo(
      id: 'gemma-2-2b-it-cpu',
      name: 'Gemma 2 2B IT (CPU)',
      size: '1.4GB',
      capabilities: ['text'],
      url: 'https://huggingface.co/bensonruan/gemma-2-2b-it-cpu-int4/resolve/main/gemma-2-2b-it-cpu-int4.bin?download=true',
      description: '适合CPU运行的纯文本模型，速度较快，兼容性强',
    ),
    AIModelInfo(
      id: 'gemma-2-2b-it-gpu',
      name: 'Gemma 2 2B IT (GPU)',
      size: '1.4GB',
      capabilities: ['text'],
      url: 'https://huggingface.co/bensonruan/gemma-2-2b-it-gpu-int4/resolve/main/gemma-2-2b-it-gpu-int4.bin?download=true',
      description: '适合高端设备GPU运行的纯文本模型，速度最快',
    ),
    AIModelInfo(
      id: 'gemma-2b-it-cpu',
      name: 'Gemma 1.1 2B IT (CPU)',
      size: '1.3GB',
      capabilities: ['text'],
      url: 'https://huggingface.co/bensonruan/gemma-2b-it-cpu-int4/resolve/main/gemma-2b-it-cpu-int4.bin?download=true',
      description: '第一代轻量级文本模型，资源占用极小',
    ),
    AIModelInfo(
      id: 'gemma-2b-it-gpu',
      name: 'Gemma 1.1 2B IT (GPU)',
      size: '1.3GB',
      capabilities: ['text'],
      url: 'https://huggingface.co/bensonruan/gemma-2b-it-gpu-int4/resolve/main/gemma-2b-it-gpu-int4.bin?download=true',
      description: '第一代GPU加速文本模型，适合老旧设备',
    ),
  ];

  /// 下载模型（真实下载）
  Stream<double> downloadModel(String modelId, String url) async* {
    final controller = StreamController<double>();

    try {
      debugPrint('📥 开始下载模型: $modelId from $url');

      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/models');
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      // 确定文件名
      final fileName = url.split('/').last;
      final filePath = '${modelsDir.path}/$fileName';

      // 如果文件已存在，先删除
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 使用 Dio 下载文件
      final dio = Dio();

      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            controller.add(progress);
            debugPrint('📥 下载进度: ${(progress * 100).toStringAsFixed(1)}%');
          } else {
            // 如果服务端不返回总大小，我们用2GB(2147483648 bytes)作为估算
            const estimatedTotal = 2147483648.0;
            final progress = (received / estimatedTotal).clamp(0.0, 0.99);
            controller.add(progress);
            debugPrint('📥 下载已接收: ${(received / 1024 / 1024).toStringAsFixed(1)} MB');
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(minutes: 30),
        ),
      );

      debugPrint('✅ 模型下载完成: $modelId');
      debugPrint('📁 文件路径: $filePath');

      controller.add(1.0);
      await controller.close();

      yield* controller.stream;
    } catch (e) {
      debugPrint('❌ 模型下载失败: $e');
      await controller.close();
      rethrow;
    }
  }

  // 初始化并切换模型
  Future<void> switchModel(
    String modelId, {
    PreferredBackend? backend,
    int? maxTokens,
  }) async {
    final modelInfo = availableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => availableModels.first,
    );

    // 释放当前模型（如果存在）
    _currentModel = null;

    // 创建新模型
    _currentModel = await _plugin.createModel(
      modelType: ModelType.gemmaIt,
      preferredBackend: backend ?? _currentBackend,
      maxTokens: maxTokens ?? 4096,
      supportImage: modelInfo.supportsImage,
      supportAudio: modelInfo.supportsAudio,
    );

    _currentModelId = modelId;
    if (backend != null) {
      _currentBackend = backend;
    }
  }

  // 获取当前模型
  InferenceModel? get currentModel => _currentModel;
  String? get currentModelId => _currentModelId;
  PreferredBackend get currentBackend => _currentBackend;

  // 获取模型信息
  AIModelInfo? getModelInfo(String modelId) {
    try {
      return availableModels.firstWhere((m) => m.id == modelId);
    } catch (e) {
      return null;
    }
  }

  // 获取当前模型信息
  AIModelInfo? get currentModelInfo {
    if (_currentModelId == null) return null;
    return getModelInfo(_currentModelId!);
  }

  // 获取模型能力
  List<String> getModelCapabilities(String modelId) {
    final model = getModelInfo(modelId);
    return model?.capabilities ?? [];
  }

  // 释放资源
  Future<void> dispose() async {
    _currentModel = null;
    _currentModelId = null;
  }
}
