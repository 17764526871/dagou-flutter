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

  // 支持的模型列表（扩展更多模型）
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
      id: 'gemma-3n-e2b',
      name: 'Gemma 3n E2B',
      size: '2.0GB',
      capabilities: ['text', 'image', 'audio'],
      url:
          'https://huggingface.co/litert-community/Gemma-3n-E2B-it-litert-lm/resolve/main/gemma-3n-E2B-it.litertlm',
      description: '多模态轻量模型（文本+图片+音频）',
    ),
    AIModelInfo(
      id: 'gemma-3-1b',
      name: 'Gemma 3 1B',
      size: '0.8GB',
      capabilities: ['text'],
      url:
          'https://huggingface.co/litert-community/Gemma-3-1B-IT-int4/resolve/main/gemma3-1b-it-int4.task',
      description: '超轻量纯文本模型，速度最快',
    ),
    AIModelInfo(
      id: 'gemma-3-4b',
      name: 'Gemma 3 4B',
      size: '2.6GB',
      capabilities: ['text', 'image'],
      url:
          'https://huggingface.co/litert-community/Gemma-3-4B-IT-int4/resolve/main/gemma3-4b-it-int4.task',
      description: '中等规模视觉语言模型',
    ),
    AIModelInfo(
      id: 'gemma-2-2b',
      name: 'Gemma 2 2B',
      size: '1.5GB',
      capabilities: ['text'],
      url:
          'https://huggingface.co/litert-community/gemma-2b-it-gpu-int4/resolve/main/gemma-2b-it-gpu-int4.bin',
      description: '轻量级纯文本模型',
    ),
    AIModelInfo(
      id: 'gemma-2-9b',
      name: 'Gemma 2 9B',
      size: '5.4GB',
      capabilities: ['text'],
      url:
          'https://huggingface.co/litert-community/gemma-2-9b-it-gpu-int4/resolve/main/gemma-2-9b-it-gpu-int4.bin',
      description: '高性能文本模型（需要高端设备）',
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
