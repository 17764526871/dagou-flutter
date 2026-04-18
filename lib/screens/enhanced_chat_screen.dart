import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:typed_data';
import '../models/message.dart';
import '../services/ai_service.dart';
import '../widgets/enhanced_message_bubble.dart';
import '../widgets/wechat_input_bar.dart';
import 'settings_screen.dart';

class EnhancedChatScreen extends StatefulWidget {
  const EnhancedChatScreen({super.key});

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  final ImagePicker _picker = ImagePicker();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSending = false;
  int? _thinkingMessageIndex;

  // 设置参数
  double _temperature = 1.0;
  int _topK = 64;
  double _topP = 0.95;
  int _maxTokens = 8192;
  bool _enableTts = true;
  bool _autoPlayTts = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(Message.text(
        text: '👋 你好！我是 **Gemma 4 AI** 助手\n\n'
            '✨ 我是完全运行在你手机上的端侧 AI 模型\n'
            '🔒 无需联网，保护你的隐私\n\n'
            '我可以帮你：\n'
            '- 💬 **智能对话** - 回答各种问题\n'
            '- 🖼️ **图片分析** - 识别和理解图片内容\n'
            '- 🎤 **语音交互** - 语音输入和输出\n\n'
            '点击下方按钮开始体验吧！',
        isUser: false,
      ));
    });
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onError: (error) => debugPrint('语音识别错误: $error'),
      onStatus: (status) => debugPrint('语音识别状态: $status'),
    );
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('zh-CN');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _sendMessage({String? text, Uint8List? imageBytes}) async {
    final msgText = text ?? _textController.text.trim();
    if (msgText.isEmpty && imageBytes == null) return;

    _textController.clear();
    setState(() => _isSending = true);

    Message userMsg;
    if (imageBytes != null) {
      userMsg = Message.withImage(
        text: msgText.isEmpty ? '请分析这张图片' : msgText,
        imageBytes: imageBytes,
        isUser: true,
      );
    } else {
      userMsg = Message.text(text: msgText, isUser: true);
    }

    setState(() {
      _messages.add(userMsg);
      // 添加思考中的占位消息
      _thinkingMessageIndex = _messages.length;
      _messages.add(Message.text(text: '', isUser: false));
    });
    _scrollToBottom();

    try {
      final response = await AIService.instance.sendMessage(
        msgText,
        imageBytes: imageBytes,
      );

      setState(() {
        if (_thinkingMessageIndex != null) {
          _messages[_thinkingMessageIndex!] =
              Message.text(text: response, isUser: false);
          _thinkingMessageIndex = null;
        }
        _isSending = false;
      });
      _scrollToBottom();

      // 自动播报
      if (_enableTts && _autoPlayTts && response.isNotEmpty) {
        await _playTts(response);
      }
    } catch (e) {
      setState(() {
        if (_thinkingMessageIndex != null) {
          _messages[_thinkingMessageIndex!] =
              Message.text(text: '抱歉，发生了错误：$e', isUser: false);
          _thinkingMessageIndex = null;
        }
        _isSending = false;
      });
    }
  }

  Future<void> _handleVoiceRecorded(String voicePath) async {
    // 实现语音识别
    // 暂时使用模拟文本
    await _sendMessage(text: '[语音消息]');
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        await _sendMessage(imageBytes: bytes);
      }
    } catch (e) {
      _showError('选择图片失败：$e');
    }
  }

  Future<void> _pickFile() async {
    _showError('文件功能开发中...');
  }

  Future<void> _playTts(String text) async {
    if (_enableTts) {
      await _flutterTts.speak(text);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );

    if (result != null) {
      setState(() {
        _temperature = result['temperature'] ?? _temperature;
        _topK = result['topK'] ?? _topK;
        _topP = result['topP'] ?? _topP;
        _maxTokens = result['maxTokens'] ?? _maxTokens;
        _enableTts = result['enableTts'] ?? _enableTts;
        _autoPlayTts = result['autoPlayTts'] ?? _autoPlayTts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gemma AI',
                  style: TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '智能助手',
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF718096)),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isThinking = index == _thinkingMessageIndex;
                      return EnhancedMessageBubble(
                        message: message,
                        isThinking: isThinking,
                        onTtsPlay: !message.isUser && message.text.isNotEmpty
                            ? () => _playTts(message.text)
                            : null,
                      );
                    },
                  ),
          ),
          WeChatInputBar(
            controller: _textController,
            onSend: () => _sendMessage(),
            onVoiceRecorded: _handleVoiceRecorded,
            onCameraPick: () => _pickImage(ImageSource.camera),
            onImagePick: () => _pickImage(ImageSource.gallery),
            onFilePick: _pickFile,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            '开始对话',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '发送消息或选择功能开始',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }
}
