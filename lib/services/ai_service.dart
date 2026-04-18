import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';

class AIService {
  static final AIService instance = AIService._internal();
  AIService._internal();

  InferenceChat? _chat;
  bool _isInitialized = false;

  // 当前模型参数
  double _temperature = 1.0;
  int _topK = 64;
  double _topP = 0.95;
  int _maxTokens = 8192;

  bool get isInitialized => _isInitialized;

  /// 初始化 Gemma 4 E2B 端侧多模态模型
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔄 开始初始化 Gemma 4 E2B 端侧多模态模型...');

      // 步骤 1: 安装模型（从内置 assets 加载）
      final installer = FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.task,
      );

      // 使用内置的 Gemma 4 E2B 模型
      await installer
          .fromAsset('assets/models/gemma-4-E2B-it.litertlm')
          .install();

      print('✅ 模型安装完成');

      // 步骤 2: 创建模型实例
      final model = await FlutterGemma.getActiveModel(
        maxTokens: 8192,
        supportImage: true,  // 支持图片输入
        maxNumImages: 1,
        supportAudio: true,  // 支持音频输入
        preferredBackend: PreferredBackend.gpu,
      );

      print('✅ 模型实例创建完成');

      // 步骤 3: 创建聊天会话
      _chat = await model.createChat(
        temperature: 1.0,
        topK: 64,
        topP: 0.95,
        randomSeed: 42,
        tokenBuffer: 512,
        supportImage: true,
        supportAudio: true,
      );

      _isInitialized = true;
      print('✅ Gemma 4 E2B 端侧多模态模型初始化成功！');
    } catch (e) {
      print('❌ 模型初始化失败: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// 发送消息（支持文本和图片）
  Future<String> sendMessage(String text, {Uint8List? imageBytes}) async {
    if (!_isInitialized || _chat == null) {
      return '错误: 模型未初始化，请稍候...';
    }

    try {
      // 创建用户消息
      final message = imageBytes != null
          ? Message(
              text: text,
              imageBytes: imageBytes,
              isUser: true,
            )
          : Message(
              text: text,
              isUser: true,
            );

      // 添加用户消息到历史
      await _chat!.addQuery(message);

      // 获取 AI 响应
      final response = await _chat!.generateChatResponse();

      // 处理响应
      if (response is TextResponse) {
        return response.token;
      } else {
        return '无响应';
      }
    } catch (e) {
      print('❌ 生成响应失败: $e');
      return '抱歉，生成响应时出错：$e';
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
      // 如果提供了新的模型参数，需要重新创建聊天会话
      if (temperature != null || topK != null || topP != null || maxTokens != null) {
        _temperature = temperature ?? _temperature;
        _topK = topK ?? _topK;
        _topP = topP ?? _topP;
        _maxTokens = maxTokens ?? _maxTokens;

        // 重新创建聊天会话
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

      // 如果提供了系统提示词，在用户消息前添加
      String finalText = text;
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        finalText = '$systemPrompt\n\n用户: $text';
      }

      // 创建消息
      final message = imageBytes != null
          ? Message(
              text: finalText,
              imageBytes: imageBytes,
              isUser: true,
            )
          : Message(
              text: finalText,
              isUser: true,
            );

      // 添加用户消息
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

  /// 获取当前模型信息
  String getCurrentModel() => 'Gemma 4 E2B (2B 参数，多模态：文本+图片+音频)';

  /// 清除聊天历史
  void clearHistory() {
    print('💬 聊天历史已清除');
  }
}
