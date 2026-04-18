import 'package:flutter_gemma/flutter_gemma.dart';
import '../../data/models/ai_model_info.dart';

class ModelManager {
  static final ModelManager _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  static ModelManager get instance => _instance;

  final _plugin = FlutterGemmaPlugin.instance;
  InferenceModel? _currentModel;
  String? _currentModelId;
  PreferredBackend _currentBackend = PreferredBackend.gpu;

  // 支持的模型列表
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
      id: 'gemma-3-nano-2b',
      name: 'Gemma 3 Nano 2B',
      size: '1.2GB',
      capabilities: ['text', 'image'],
      url: 'https://example.com/gemma-3-nano-2b.bin',
      description: '轻量级视觉模型',
    ),
    AIModelInfo(
      id: 'gemma-2-2b',
      name: 'Gemma 2 2B',
      size: '1.5GB',
      capabilities: ['text'],
      url: 'https://example.com/gemma-2-2b.bin',
      description: '纯文本模型',
    ),
  ];

  // 下载模型（带进度）- 预留接口
  Stream<double> downloadModel(String url) async* {
    // TODO: 实现实际的下载逻辑
    // 当前版本暂时使用内置模型
    yield 0.0;
    await Future.delayed(const Duration(milliseconds: 100));
    yield 0.5;
    await Future.delayed(const Duration(milliseconds: 100));
    yield 1.0;
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
