import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'model_manager.dart';

class AIService {
  static final AIService instance = AIService._internal();
  AIService._internal();

  final ModelManager _modelManager = ModelManager.instance;
  InferenceChat? _chat;
  bool _isInitialized = false;

  // 当前模型参数（优化默认值以减少复读）
  double _temperature = 0.8;
  int _topK = 40;
  double _topP = 0.9;
  int _maxTokens = 8192;
  String? _currentSystemPrompt;

  // 标记：是否需要在下次发送前强制重建会话
  bool _needsReset = false;

  bool get isInitialized => _isInitialized;

  /// 初始化 Gemma 4 E2B 端侧多模态模型
  Future<void> initialize({String? modelPath}) async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 开始初始化 Gemma 4 E2B 端侧多模态模型...');

      if (modelPath != null) {
        debugPrint('📁 使用指定路径加载模型: $modelPath');
      }

      debugPrint('✅ 模型安装完成');

      await _modelManager.switchModel(
        'gemma-4-e2b',
        backend: PreferredBackend.gpu,
        maxTokens: 8192,
        customPath: modelPath,
      );

      debugPrint('✅ 模型实例创建完成');

      final model = _modelManager.currentModel;
      final currentInfo = _modelManager.currentModelInfo;
      if (model != null) {
        _chat = await model.createChat(
          temperature: 0.8,
          topK: 40,
          topP: 0.9,
          randomSeed: 42,
          tokenBuffer: 512,
          supportImage: currentInfo?.supportsImage ?? false,
          supportAudio: currentInfo?.supportsAudio ?? false,
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

        debugPrint('🔄 重建会话：参数变化或需要重置');

        final currentInfo = _modelManager.currentModelInfo;
        final model = await FlutterGemma.getActiveModel(
          maxTokens: _maxTokens,
          supportImage: currentInfo?.supportsImage ?? false,
          maxNumImages: 1,
          supportAudio: currentInfo?.supportsAudio ?? false,
          preferredBackend: PreferredBackend.gpu,
        );

        _chat = await model.createChat(
        temperature: _temperature,
        topK: _topK,
        topP: _topP,
        randomSeed: 42,
        tokenBuffer: 512,
        supportImage: currentInfo?.supportsImage ?? false,
        supportAudio: currentInfo?.supportsAudio ?? false,
      );

        debugPrint('✅ 新会话已创建');

        // 系统提示词作为第一条AI消息注入
        if (systemPrompt != null && systemPrompt.isNotEmpty) {
          await _chat!.addQuery(
            Message(text: systemPrompt, isUser: false),
          );
          debugPrint('✅ 系统提示词已注入');
        }
      }

      // 添加用户消息（必须在会话重建之后）
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

  /// 停止生成
  Future<void> stopGeneration() async {
    if (_chat != null) {
      try {
        await _chat!.stopGeneration();
        debugPrint('🛑 已停止模型生成');
      } catch (e) {
        debugPrint('⚠️ 停止生成时出错 (可能已停止): $e');
      }
    }
  }

  /// 标记需要重置并立即重建会话（取消时调用）
  /// 立即重建确保旧的生成器完全停止
  Future<void> resetSession() async {
    debugPrint('🔄 立即重置会话');
    _needsReset = false;
    _currentSystemPrompt = null;

    final currentInfo = _modelManager.currentModelInfo;
    final model = await FlutterGemma.getActiveModel(
      maxTokens: _maxTokens,
      supportImage: currentInfo?.supportsImage ?? false,
      maxNumImages: 1,
      supportAudio: currentInfo?.supportsAudio ?? false,
      preferredBackend: PreferredBackend.gpu,
    );

    _chat = await model.createChat(
      temperature: _temperature,
      topK: _topK,
      topP: _topP,
      randomSeed: 42,
      tokenBuffer: 512,
      supportImage: currentInfo?.supportsImage ?? false,
      supportAudio: currentInfo?.supportsAudio ?? false,
    );

    debugPrint('✅ 会话已重置');
  }

  /// 标记需要重置（翻译页面退出时调用）—— 延迟到下次发送时重建
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

    final currentInfo = _modelManager.currentModelInfo;
    final model = await FlutterGemma.getActiveModel(
      maxTokens: _maxTokens,
      supportImage: currentInfo?.supportsImage ?? false,
      maxNumImages: 1,
      supportAudio: currentInfo?.supportsAudio ?? false,
      preferredBackend: PreferredBackend.gpu,
    );

    _chat = await model.createChat(
      temperature: _temperature,
      topK: _topK,
      topP: _topP,
      randomSeed: 42,
      tokenBuffer: 512,
      supportImage: currentInfo?.supportsImage ?? false,
      supportAudio: currentInfo?.supportsAudio ?? false,
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
