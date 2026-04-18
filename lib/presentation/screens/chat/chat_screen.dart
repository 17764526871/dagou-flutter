import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:typed_data';
import 'dart:async';
import '../../../data/models/message.dart';
import '../../../services/ai/ai_service.dart';
import '../../../services/storage/settings_service.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/input_bar.dart';
import '../settings/settings_screen.dart';

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
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSending = false;
  int? _streamingMessageIndex;
  String _streamingText = '';
  Uint8List? _pendingImage;
  bool _showImagePreview = false;
  StreamSubscription<String>? _streamSubscription;

  // 性能指标
  int _totalTokens = 0;
  double _tokensPerSecond = 0.0;
  DateTime? _inferenceStartTime;
  DateTime? _inferenceEndTime;
  int _totalCharacters = 0;
  double _averageLatency = 0.0;
  bool _showMetrics = true;

  // 设置参数
  String _systemPrompt = '你是一个有帮助的AI助手。';
  double _temperature = 1.0;
  int _topK = 64;
  double _topP = 0.95;
  int _maxTokens = 8192;
  bool _enableTts = true;
  bool _autoPlayTts = false;
  String _ttsLanguage = 'zh-CN';
  bool _enableTranslation = false;
  String _translationMode = 'auto';
  bool _showTimestamp = true;
  bool _userScrolling = false;

  @override
  void initState() {
    super.initState();
    _initSettings();
    _initTts();
    _addWelcomeMessage();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initSettings() async {
    await SettingsService.instance.initialize();
    setState(() {
      _systemPrompt = SettingsService.instance.loadSystemPrompt();
      final modelParams = SettingsService.instance.loadModelParams();
      _temperature = modelParams['temperature'];
      _topK = modelParams['topK'];
      _topP = modelParams['topP'];
      _maxTokens = modelParams['maxTokens'];

      final ttsSettings = SettingsService.instance.loadTtsSettings();
      _enableTts = ttsSettings['enableTts'];
      _autoPlayTts = ttsSettings['autoPlay'];
      _ttsLanguage = ttsSettings['language'];

      final translationSettings = SettingsService.instance.loadTranslationSettings();
      _enableTranslation = translationSettings['enable'];
      _translationMode = translationSettings['mode'];

      final displaySettings = SettingsService.instance.loadDisplaySettings();
      _showMetrics = displaySettings['showMetrics'];
      _showTimestamp = displaySettings['showTimestamp'];
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      setState(() {
        _userScrolling = currentScroll < maxScroll - 100;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _streamSubscription?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(Message.text(
        text: '👋 你好！我是 **DG AI** 助手\n\n'
            '✨ 完全运行在你手机上的端侧 AI\n'
            '🔒 无需联网，保护隐私\n\n'
            '**我可以帮你：**\n'
            '- 💬 智能对话\n'
            '- 🖼️ 图片分析\n'
            '- 🌐 中英互译\n'
            '- 🎤 语音交互\n\n'
            '开始对话吧！',
        isUser: false,
      ));
    });
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage(_ttsLanguage);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // 设置完成回调
      _flutterTts.setCompletionHandler(() {
        // TTS 播放完成
      });

      _flutterTts.setErrorHandler((msg) {
        print('TTS 错误: $msg');
      });
    } catch (e) {
      print('TTS 初始化失败: $e');
    }
  }

  Future<void> _playTts(String text) async {
    if (!_enableTts || text.isEmpty) return;

    try {
      // 停止当前播放
      await _flutterTts.stop();
      // 开始新的播放
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS 播放失败: $e');
    }
  }

  Future<void> _sendMessage({String? text, Uint8List? imageBytes}) async {
    final msgText = text ?? _textController.text.trim();
    if (msgText.isEmpty && imageBytes == null && _pendingImage == null) return;

    final finalImage = imageBytes ?? _pendingImage;

    _textController.clear();
    setState(() {
      _isSending = true;
      _pendingImage = null;
      _showImagePreview = false;
      _inferenceStartTime = DateTime.now();
      _inferenceEndTime = null;
      _totalTokens = 0;
      _totalCharacters = 0;
      _tokensPerSecond = 0.0;
      _averageLatency = 0.0;
    });

    Message userMsg;
    if (finalImage != null) {
      userMsg = Message.withImage(
        text: msgText.isEmpty ? '请分析这张图片' : msgText,
        imageBytes: finalImage,
        isUser: true,
      );
    } else {
      userMsg = Message.text(text: msgText, isUser: true);
    }

    setState(() {
      _messages.add(userMsg);
      _streamingMessageIndex = _messages.length;
      _streamingText = '';
      _messages.add(Message.text(text: '', isUser: false));
    });

    _scrollToBottom();

    try {
      // 构建最终的系统提示词（包含翻译功能）
      String? finalSystemPrompt = _systemPrompt;
      if (_enableTranslation) {
        switch (_translationMode) {
          case 'zh-en':
            finalSystemPrompt = '你是专业翻译，将中文翻译成英文。只返回翻译结果，不要解释。';
            break;
          case 'en-zh':
            finalSystemPrompt = '你是专业翻译，将英文翻译成中文。只返回翻译结果，不要解释。';
            break;
          case 'auto':
            finalSystemPrompt = '你是专业翻译，自动识别语言并翻译（中文→英文，英文→中文）。只返回翻译结果，不要解释。';
            break;
        }
      }

      // 使用流式输出，传递所有参数
      await for (final chunk in AIService.instance.sendMessageStream(
        msgText,
        imageBytes: finalImage,
        systemPrompt: finalSystemPrompt,
        temperature: _temperature,
        topK: _topK,
        topP: _topP,
        maxTokens: _maxTokens,
      )) {
        if (mounted) {
          setState(() {
            _streamingText += chunk;
            if (_streamingMessageIndex != null) {
              _messages[_streamingMessageIndex!] =
                  Message.text(text: _streamingText, isUser: false);
            }

            // 更新性能指标
            _totalTokens++;
            _totalCharacters = _streamingText.length;
            if (_inferenceStartTime != null) {
              final elapsed = DateTime.now().difference(_inferenceStartTime!);
              _tokensPerSecond = _totalTokens / elapsed.inMilliseconds * 1000;
              _averageLatency = elapsed.inMilliseconds / _totalTokens;
            }
          });
          if (!_userScrolling) {
            _scrollToBottom();
          }
        }
      }

      setState(() {
        _isSending = false;
        _streamingMessageIndex = null;
        _inferenceEndTime = DateTime.now();
      });

      // 自动播报
      if (_enableTts && _autoPlayTts && _streamingText.isNotEmpty) {
        await _playTts(_streamingText);
      }
    } catch (e) {
      setState(() {
        if (_streamingMessageIndex != null) {
          _messages[_streamingMessageIndex!] =
              Message.text(text: '抱歉，发生了错误：$e', isUser: false);
        }
        _isSending = false;
        _streamingMessageIndex = null;
      });
    }
  }

  Future<void> _handleVoiceRecorded(String voicePath, int duration) async {
    setState(() {
      _messages.add(Message.withAudio(
        text: '语音消息',
        audioPath: voicePath,
        isUser: true,
        duration: duration,
      ));
    });
    _scrollToBottom();

    // 直接回复语音消息（暂不支持语音识别）
    setState(() {
      _messages.add(Message.text(
        text: '抱歉，当前版本暂不支持语音识别。请使用文字或图片输入。',
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pendingImage = bytes;
          _showImagePreview = true;
        });
      }
    } catch (e) {
      _showError('选择图片失败：$e');
    }
  }

  void _cancelSending() {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    setState(() {
      _isSending = false;
      if (_streamingMessageIndex != null && _streamingText.isNotEmpty) {
        // 保留已生成的部分内容
        _messages[_streamingMessageIndex!] =
            Message.text(text: '$_streamingText\n\n[已停止生成]', isUser: false);
      } else if (_streamingMessageIndex != null) {
        // 如果没有内容，删除消息
        _messages.removeAt(_streamingMessageIndex!);
      }
      _streamingMessageIndex = null;
      _streamingText = '';
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
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
    await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );

    // 设置界面返回后重新加载所有设置
    await _initSettings();

    // 重新初始化 TTS（语言可能已更改）
    await _initTts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 性能指标栏
          if (_showMetrics && _isSending) _buildMetricsBar(),

          // 消息列表
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return MessageBubble(message: message);
                    },
                  ),
          ),

          // 图片预览
          if (_showImagePreview && _pendingImage != null)
            _buildImagePreview(),

          // 输入栏
          InputBar(
            controller: _textController,
            onSend: _isSending ? () {} : () => _sendMessage(),
            onVoiceRecorded: _handleVoiceRecorded,
            onCameraPick: () => _pickImage(ImageSource.camera),
            onImagePick: () => _pickImage(ImageSource.gallery),
            isSending: _isSending,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'DG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DG AI',
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
        if (_isSending)
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFFF56565)),
            onPressed: _cancelSending,
            tooltip: '取消',
          ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Color(0xFF718096)),
          onPressed: _openSettings,
        ),
      ],
    );
  }

  Widget _buildMetricsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            icon: Icons.speed,
            label: '速度',
            value: '${_tokensPerSecond.toStringAsFixed(1)} t/s',
          ),
          _buildMetricItem(
            icon: Icons.token,
            label: 'Tokens',
            value: _totalTokens.toString(),
          ),
          _buildMetricItem(
            icon: Icons.text_fields,
            label: '字符',
            value: _totalCharacters.toString(),
          ),
          _buildMetricItem(
            icon: Icons.timer,
            label: '时长',
            value: _inferenceStartTime != null
                ? '${DateTime.now().difference(_inferenceStartTime!).inSeconds}s'
                : '0s',
          ),
          _buildMetricItem(
            icon: Icons.access_time,
            label: '延迟',
            value: '${_averageLatency.toStringAsFixed(0)}ms',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0EA5E9)),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF718096),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _pendingImage!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() {
                      _pendingImage = null;
                      _showImagePreview = false;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '图片已选择',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _isSending ? null : () => _sendMessage(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '直接发送',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
            child: const Center(
              child: Text(
                'DG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
