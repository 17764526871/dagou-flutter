import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:typed_data';
import '../models/message.dart';
import '../services/ai_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/input_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  final ImagePicker _picker = ImagePicker();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isSending = false;

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
        text: '👋 你好！我是 Gemma 4 AI 助手\n\n'
            '✨ 我是完全运行在你手机上的端侧 AI 模型\n'
            '🔒 无需联网，保护你的隐私\n\n'
            '我可以帮你：\n'
            '💬 智能对话 - 回答各种问题\n'
            '🖼️ 图片分析 - 识别和理解图片内容\n'
            '🎤 语音交互 - 语音输入和输出\n\n'
            '点击下方按钮开始体验吧！',
        isUser: false,
      ));
    });
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onError: (error) => print('语音识别错误: $error'),
      onStatus: (status) => print('语音识别状态: $status'),
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

    setState(() => _messages.add(userMsg));
    _scrollToBottom();

    try {
      final response = await AIService.instance.sendMessage(
        msgText,
        imageBytes: imageBytes,
      );

      setState(() {
        _messages.add(Message.text(text: response, isUser: false));
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(Message.text(
          text: '抱歉，发生了错误：$e',
          isUser: false,
        ));
        _isSending = false;
      });
    }
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

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final thumbnail = await VideoThumbnail.thumbnailData(
          video: video.path,
          imageFormat: ImageFormat.JPEG,
          quality: 75,
        );
        if (thumbnail != null) {
          await _sendMessage(
            text: '请分析这个视频',
            imageBytes: thumbnail,
          );
        }
      }
    } catch (e) {
      _showError('选择视频失败：$e');
    }
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
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
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
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
            icon: const Icon(Icons.info_outline, color: Color(0xFF718096)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('关于'),
                  content: const Text('Gemma AI 多模态智能助手\n\n支持文字、图片、视频和语音交互'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
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
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(message: _messages[index]);
                    },
                  ),
          ),
          if (_isSending)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: const Color(0xFF667EEA),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '正在思考...',
                    style: TextStyle(color: Color(0xFF718096)),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: InputBar(
              controller: _textController,
              isListening: _isListening,
              onSend: () => _sendMessage(),
              onImagePick: () => _pickImage(ImageSource.gallery),
              onCameraPick: () => _pickImage(ImageSource.camera),
              onVideoPick: _pickVideo,
              onVoiceToggle: _startListening,
            ),
          ),
        ],
      ),
    );
  }
}
