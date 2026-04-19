import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'model_manager.dart';

class AIService {
  static final AIService instance = AIService._internal();
  AIService._internal();

  final ModelManager _modelManager = ModelManager.instance;
  InferenceChat? _chat;
  bool _isInitialized = false;

  // 当前模型参数
  double _temperature = 1.0;
  int _topK = 64;
  double _topP = 0.95;
  int _maxTokens = 8192;
  String? _currentSystemPrompt;

  // 标记：是否需要在下次发送前强制重建会话
  bool _needsReset = false;

  bool get isInitialized => _isInitialized;

  /// 初始化 Gemma 4 E2B 端侧多模态模型
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 开始初始化 Gemma 4 E2B 端侧多模态模型...');

      final installer = FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.task,
      );

      await installer
          .fromAsset('assets/models/gemma-4-E2B-it.litertlm')
          .install();

      debugPrint('✅ 模型安装完成');

      await _modelManager.switchModel(
        'gemma-4-e2b',
        backend: PreferredBackend.gpu,
        maxTokens: 8192,
      );

      debugPrint('✅ 模型实例创建完成');

      final model = _modelManager.currentModel;
      if (model != null) {
        _chat = await model.createChat(
          temperature: 1.0,
          topK: 64,
          topP: 0.95,
          randomSeed: 42,
          tokenBuffer: 512,
          supportImage: true,
          supportAudio: true,
        );
      }

      _isInitialized = true;
      _needsReset = false;
      debugPrint('✅ Gemma 4 E2B 端侧多模态模型初始化成功！');
    } catch (e) {
      debugPrint('❌ 模型初始化失败: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// 流式生成响应（实时显示）
  Stream<String> sendMessageStream(
    String text, {
    Uint8List? imageBytes,
    String? systemPrompt,
    double? temperature,
    int? topK,
    double? topP,
    int? maxTokens,
  }) async* {
    if (!_isInitialized || _chat == null) {
      yield '模型未初始化';
      return;
    }

    try {
      final tempChanged = temperature != null && temperature != _temperature;
      final topKChanged = topK != null && topK != _topK;
      final topPChanged = topP != null && topP != _topP;
      final maxTokensChanged = maxTokens != null && maxTokens != _maxTokens;
      final systemPromptChanged = systemPrompt != _currentSystemPrompt;

      // 需要重建会话的条件：参数变化 OR 被标记为需要重置
      final needRecreate = tempChanged ||
          topKChanged ||
          topPChanged ||
          maxTokensChanged ||
          systemPromptChanged ||
          _needsReset;

      if (needRecreate) {
        _temperature = temperature ?? _temperature;
        _topK = topK ?? _topK;
        _topP = topP ?? _topP;
        _maxTokens = maxTokens ?? _maxTokens;
        _currentSystemPrompt = systemPrompt;
        _needsReset = false;

        final model = await FlutterGemma.getActiveModel(
          maxTokens: _maxTokens,
          supportImage: true,
          maxNumImages: 1,
          supportAudio: true,
          preferredBackend: PreferredBackend.gpu,
        );

        _chat = await model.createChat(
          temperature: _temperature,
          topK: _topK,
          topP: _topP,
          randomSeed: 42,
          tokenBuffer: 512,
          supportImage: true,
          supportAudio: true,
        );

        // 系统提示词作为第一条AI消息注入
        if (systemPrompt != null && systemPrompt.isNotEmpty) {
          await _chat!.addQuery(
            Message(text: systemPrompt, isUser: false),
          );
        }
      }

      // 添加用户消息
      final message = imageBytes != null
          ? Message(text: text, imageBytes: imageBytes, isUser: true)
          : Message(text: text, isUser: true);

      await _chat!.addQuery(message);

      // 流式获取响应
      await for (final response in _chat!.generateChatResponseAsync()) {
        if (response is TextResponse) {
          yield response.token;
        }
      }
    } catch (e) {
      yield '生成响应时出错：$e';
    }
  }

  /// 标记需要重置（取消时调用）—— 不立即重建，下次发送时重建
  /// 这样避免取消后立即重建会话的耗时，同时保证下次发送是全新上下文
  void markNeedsReset() {
    _needsReset = true;
    _currentSystemPrompt = null;
    debugPrint('🔄 已标记会话需要重置，下次发送时生效');
  }

  /// 清除聊天历史（立即重建会话）
  Future<void> clearHistory() async {
    debugPrint('💬 清除聊天历史，重新创建会话');
    _currentSystemPrompt = null;
    _needsReset = false;

    final model = await FlutterGemma.getActiveModel(
      maxTokens: _maxTokens,
      supportImage: true,
      maxNumImages: 1,
      supportAudio: true,
      preferredBackend: PreferredBackend.gpu,
    );

    _chat = await model.createChat(
      temperature: _temperature,
      topK: _topK,
      topP: _topP,
      randomSeed: 42,
      tokenBuffer: 512,
      supportImage: true,
      supportAudio: true,
    );
  }

  /// 获取当前模型信息
  String getCurrentModel() {
    final modelInfo = _modelManager.currentModelInfo;
    return modelInfo?.name ?? 'Gemma 4 E2B (2B 参数，多模态：文本+图片+音频)';
  }

  /// 获取当前模型能力
  List<String> getCurrentModelCapabilities() {
    final modelInfo = _modelManager.currentModelInfo;
    return modelInfo?.capabilities ?? ['text', 'image', 'audio'];
  }

  /// 切换模型
  Future<void> switchModel(String modelId, {PreferredBackend? backend}) async {
    await _modelManager.switchModel(modelId, backend: backend);
    _needsReset = true;
    _currentSystemPrompt = null;

    final model = _modelManager.currentModel;
    if (model != null) {
      _chat = await model.createChat(
        temperature: _temperature,
        topK: _topK,
        topP: _topP,
        randomSeed: 42,
        tokenBuffer: 512,
        supportImage: _modelManager.currentModelInfo?.supportsImage ?? false,
        supportAudio: _modelManager.currentModelInfo?.supportsAudio ?? false,
      );
      _needsReset = false;
    }
  }
}
