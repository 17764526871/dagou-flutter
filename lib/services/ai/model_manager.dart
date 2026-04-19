import 'package:flutter_gemma/flutter_gemma.dart';
import '../../data/models/ai_model_info.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class ModelManager {
  static final ModelManager _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  static ModelManager get instance => _instance;

  InferenceModel? _currentModel;
  String? _currentModelId;
  PreferredBackend _currentBackend = PreferredBackend.gpu;

  // 支持的模型列表（扩展更多模型，真实HuggingFace地址）
  static const List<AIModelInfo> availableModels = [
    AIModelInfo(
      id: 'gemma-4-e2b',
      name: 'Gemma 4 E2B',
      size: '2.4GB',
      capabilities: ['text', 'image', 'audio', 'function_calling', 'thinking'],
      description: 'Next-gen multimodal chat — text, image, audio',
      isBuiltIn: true,
      localPath: 'assets/models/gemma-4-E2B-it.litertlm',
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm,
    ),
    AIModelInfo(
      id: 'gemma-4-e4b',
      name: 'Gemma 4 E4B',
      size: '4.3GB',
      capabilities: ['text', 'image', 'audio', 'function_calling', 'thinking'],
      url: 'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm',
      description: 'Next-gen multimodal chat (Larger) — text, image, audio',
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm,
    ),
    // AIModelInfo(
    //   id: 'gemma-3-1b',
    //   name: 'Gemma 3 1B',
    //   size: '0.5GB',
    //   capabilities: ['text'],
    //   url: 'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT.task',
    //   description: 'Balanced and efficient text generation',
    //   modelType: ModelType.gemmaIt,
    //   fileType: ModelFileType.task,
    // ), // 暂时不可用：.task文件未上传到HuggingFace
    // AIModelInfo(
    //   id: 'function-gemma-270m',
    //   name: 'FunctionGemma 270M',
    //   size: '284MB',
    //   capabilities: ['text', 'function_calling'],
    //   url: 'https://huggingface.co/sasha-denisov/function-gemma-270M-it/resolve/main/function-gemma-270M-it.task',
    //   description: 'Specialized for function calling on-device',
    //   modelType: ModelType.functionGemma,
    //   fileType: ModelFileType.task,
    // ), // 暂时不可用：.task文件未上传到HuggingFace
    AIModelInfo(
      id: 'fastvlm-0.5b',
      name: 'FastVLM 0.5B',
      size: '0.5GB',
      capabilities: ['text', 'image'],
      url: 'https://huggingface.co/litert-community/FastVLM-0.5B/resolve/main/FastVLM-0.5B.litertlm',
      description: 'Fast vision-language inference',
      modelType: ModelType.general,
      fileType: ModelFileType.litertlm,
    ),
    // AIModelInfo(
    //   id: 'deepseek-r1',
    //   name: 'DeepSeek R1',
    //   size: '1.7GB',
    //   capabilities: ['text', 'function_calling', 'thinking'],
    //   url: 'https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B.task',
    //   description: 'High-performance reasoning and code generation',
    //   modelType: ModelType.deepSeek,
    //   fileType: ModelFileType.task,
    // ), // 暂时不可用：.task文件未上传到HuggingFace
    // AIModelInfo(
    //   id: 'qwen2.5-0.5b',
    //   name: 'Qwen2.5 0.5B',
    //   size: '586MB',
    //   capabilities: ['text', 'function_calling', 'thinking'],
    //   url: 'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct.task',
    //   description: 'Compact multilingual chat with function calling',
    //   modelType: ModelType.qwen,
    //   fileType: ModelFileType.task,
    // ), // 暂时不可用：.task文件未上传到HuggingFace
    // AIModelInfo(
    //   id: 'phi-4-mini',
    //   name: 'Phi-4 Mini',
    //   size: '3.9GB',
    //   capabilities: ['text', 'function_calling'],
    //   url: 'https://huggingface.co/litert-community/Phi-4-mini-instruct/resolve/main/Phi-4-mini-instruct.task',
    //   description: 'Advanced reasoning and instruction following',
    //   modelType: ModelType.general,
    //   fileType: ModelFileType.task,
    // ), // 暂时不可用：.task文件未上传到HuggingFace
    // AIModelInfo(
    //   id: 'smollm-135m',
    //   name: 'SmolLM 135M',
    //   size: '135MB',
    //   capabilities: ['text'],
    //   url: 'https://huggingface.co/litert-community/SmolLM-135M-Instruct/resolve/main/SmolLM-135M-Instruct.task',
    //   description: 'Ultra-compact, resource-constrained devices',
    //   modelType: ModelType.general,
    //   fileType: ModelFileType.task,
    // ), // 暂时不可用：.task文件未上传到HuggingFace
  ];

  final Map<String, CancelToken> _cancelTokens = {};

  /// 下载模型（真实下载，使用 FlutterGemma 原生支持后台下载）
  Stream<double> downloadModel(String modelId, String url) async* {
    final controller = StreamController<double>();
    final cancelToken = CancelToken();
    _cancelTokens[modelId] = cancelToken;

    try {
      debugPrint('📥 开始下载模型: $modelId from $url');

      final modelInfo = availableModels.firstWhere((m) => m.id == modelId);

      await FlutterGemma.installModel(
        modelType: modelInfo.modelType,
        fileType: modelInfo.fileType,
      )
      .fromNetwork(url)
      .withCancelToken(cancelToken)
      .withProgress((progress) {
        // progress is 0-100 int or double
        controller.add(progress / 100.0);
        debugPrint('📥 下载进度: $progress%');
      })
      .install();

      debugPrint('✅ 模型下载完成: $modelId');

      controller.add(1.0);
      await controller.close();

      yield* controller.stream;
    } catch (e) {
      if (CancelToken.isCancel(e)) {
        debugPrint('⚠️ 模型下载已取消: $modelId');
      } else {
        debugPrint('❌ 模型下载失败: $e');
      }
      await controller.close();
      rethrow;
    } finally {
      _cancelTokens.remove(modelId);
    }
  }

  /// 取消下载
  void cancelDownload(String modelId) {
    _cancelTokens[modelId]?.cancel('User cancelled download');
    _cancelTokens.remove(modelId);
  }

  // 从本地文件加载模型
  Future<void> switchLocalModel(
    String filePath, {
    required ModelType modelType,
    required ModelFileType fileType,
    PreferredBackend? backend,
    int? maxTokens,
  }) async {
    _currentModel = null;
    _currentModelId = 'local_${filePath.split('/').last}';

    await FlutterGemma.installModel(
      modelType: modelType,
      fileType: fileType,
    )
    .fromFile(filePath)
    .install();

    _currentModel = await FlutterGemma.getActiveModel(
      preferredBackend: backend ?? _currentBackend,
      maxTokens: maxTokens ?? 4096,
      supportImage: true, // 本地模型默认开启以防是多模态
      supportAudio: true,
    );

    if (backend != null) {
      _currentBackend = backend;
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

    // 设置为当前激活模型（如果已安装会跳过下载）
    if (modelInfo.isBuiltIn && modelInfo.localPath != null) {
      await FlutterGemma.installModel(
        modelType: modelInfo.modelType,
        fileType: modelInfo.fileType,
      )
      .fromAsset(modelInfo.localPath!)
      .install();
    } else if (modelInfo.url != null) {
      await FlutterGemma.installModel(
        modelType: modelInfo.modelType,
        fileType: modelInfo.fileType,
      )
      .fromNetwork(modelInfo.url!)
      .install();
    }

    // 创建新模型
    _currentModel = await FlutterGemma.getActiveModel(
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
    if (_currentModelId!.startsWith('local_')) {
      return AIModelInfo(
        id: _currentModelId!,
        name: _currentModelId!.replaceFirst('local_', ''),
        size: '未知',
        capabilities: ['text', 'image', 'audio', 'function_calling'],
        description: '从本地文件夹加载的模型',
      );
    }
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
