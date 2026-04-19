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
import '../translate/translate_screen.dart';
import '../models/model_list_screen.dart';

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

  // 滚动到底部按钮
  bool _showScrollToBottom = false;
  // 用户是否手动上滑（流式输出时用）
  bool _userScrolledUp = false;

  // 性能指标
  int _totalTokens = 0;
  double _tokensPerSecond = 0.0;
  DateTime? _inferenceStartTime;
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
  bool _showTimestamp = true;

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
    if (!mounted) return;
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

      final displaySettings = SettingsService.instance.loadDisplaySettings();
      _showMetrics = displaySettings['showMetrics'];
      _showTimestamp = displaySettings['showTimestamp'];
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    final distFromBottom = maxScroll - current;

    // 显示/隐藏滚到底部按钮
    final shouldShow = distFromBottom > 150;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }

    // 用户手动上滑时停止自动跟随
    if (_isSending) {
      _userScrolledUp = distFromBottom > 80;
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _textController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _flutterTts.stop();
    _messages.clear();
    _pendingImage = null;
    super.dispose();
  }

  void _addWelcomeMessage() {
    _messages.add(Message.text(
      text: '👋 你好！我是 **DG AI** 助手\n\n'
          '✨ 完全运行在你手机上的端侧 AI\n'
          '🔒 无需联网，保护隐私\n\n'
          '**我可以帮你：**\n'
          '- 💬 智能对话\n'
          '- 🖼️ 图片分析\n'
          '- 🌐 翻译功能\n'
          '- 🎤 语音交互\n\n'
          '开始对话吧！',
      isUser: false,
    ));
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage(_ttsLanguage);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _flutterTts.setCompletionHandler(() {});
      _flutterTts.setErrorHandler((msg) => debugPrint('TTS 错误: $msg'));
    } catch (e) {
      debugPrint('TTS 初始化失败: $e');
    }
  }

  Future<void> _playTts(String text) async {
    if (!_enableTts || text.isEmpty) return;
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS 播放失败: $e');
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
      _totalTokens = 0;
      _totalCharacters = 0;
      _tokensPerSecond = 0.0;
      _averageLatency = 0.0;
      _streamingText = '';
      _userScrolledUp = false;
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
      _messages.add(Message.text(text: '', isUser: false));
    });

    _scrollToBottom(force: true);

    try {
      await _streamSubscription?.cancel();
      _streamSubscription = null;

      final stream = AIService.instance.sendMessageStream(
        msgText,
        imageBytes: finalImage,
        systemPrompt: _systemPrompt,
        temperature: _temperature,
        topK: _topK,
        topP: _topP,
        maxTokens: _maxTokens,
      );

      _streamSubscription = stream.listen(
        (chunk) {
          if (!mounted) return;
          _streamingText += chunk;
          _totalTokens++;
          _totalCharacters = _streamingText.length;
          if (_inferenceStartTime != null) {
            final elapsed = DateTime.now().difference(_inferenceStartTime!);
            if (elapsed.inMilliseconds > 0) {
              _tokensPerSecond =
                  _totalTokens / elapsed.inMilliseconds * 1000;
              _averageLatency = elapsed.inMilliseconds / _totalTokens;
            }
          }
          // 更新消息内容（不触发完整rebuild，只更新对应消息）
          setState(() {
            if (_streamingMessageIndex != null &&
                _streamingMessageIndex! < _messages.length) {
              _messages[_streamingMessageIndex!] =
                  Message.text(text: _streamingText, isUser: false);
            }
          });
          // 流式输出时自动跟随（用户未上滑时）
          if (!_userScrolledUp) {
            _scrollToBottom(force: false);
          }
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _isSending = false;
            _streamingMessageIndex = null;
            _userScrolledUp = false;
          });
          _streamSubscription = null;
          _scrollToBottom(force: true);
          if (_enableTts && _autoPlayTts && _streamingText.isNotEmpty) {
            _playTts(_streamingText);
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            if (_streamingMessageIndex != null &&
                _streamingMessageIndex! < _messages.length) {
              _messages[_streamingMessageIndex!] =
                  Message.text(text: '抱歉，发生了错误：$e', isUser: false);
            }
            _isSending = false;
            _streamingMessageIndex = null;
          });
          _streamSubscription = null;
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_streamingMessageIndex != null &&
            _streamingMessageIndex! < _messages.length) {
          _messages[_streamingMessageIndex!] =
              Message.text(text: '抱歉，发生了错误：$e', isUser: false);
        }
        _isSending = false;
        _streamingMessageIndex = null;
      });
    }
  }

  Future<void> _cancelSending() async {
    // 先取消流订阅
    await _streamSubscription?.cancel();
    _streamSubscription = null;

    final partialText = _streamingText;
    final idx = _streamingMessageIndex;

    setState(() {
      _isSending = false;
      _streamingText = '';
      _streamingMessageIndex = null;
      _userScrolledUp = false;

      if (idx != null && idx < _messages.length) {
        if (partialText.isNotEmpty) {
          _messages[idx] = Message.text(
            text: '$partialText\n\n[已取消生成]',
            isUser: false,
          );
        } else {
          _messages.removeAt(idx);
        }
      }
    });

    // 立即重置会话，确保旧的生成器完全停止
    await AIService.instance.resetSession();
  }

  Future<void> _resendMessage(Message userMsg) async {
    if (_isSending) return;

    final idx = _messages.indexOf(userMsg);
    if (idx < 0) return;

    setState(() {
      _messages.removeRange(idx, _messages.length);
    });

    // 重发前清除历史，确保全新上下文
    await AIService.instance.clearHistory();

    await _sendMessage(
      text: userMsg.text,
      imageBytes: userMsg.mediaBytes,
    );
  }

  Future<void> _handleVoiceRecorded(String voicePath, int duration) async {
    setState(() {
      _messages.add(Message.withAudio(
        text: '语音消息',
        audioPath: voicePath,
        isUser: true,
        duration: duration,
      ));
      _messages.add(Message.text(
        text: '我已收到你的语音消息。你可以点击播放按钮回放录音。\n\n当前 flutter_gemma 包暂不支持音频识别功能（该功能正在开发中）。请使用文字或图片输入与我交流。',
        isUser: false,
      ));
    });
    _scrollToBottom(force: true);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          _pendingImage = bytes;
          _showImagePreview = true;
        });
        _scrollToBottom(force: true);
      }
    } catch (e) {
      _showError('选择图片失败：$e');
    }
  }

  void _clearMessages() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('清除对话'),
        content: const Text('确定要清除所有对话记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _streamingText = '';
                _streamingMessageIndex = null;
              });
              _addWelcomeMessage();
              setState(() {});
              await AIService.instance.clearHistory();
            },
            child: const Text('清除',
                style: TextStyle(color: Color(0xFFF56565))),
          ),
        ],
      ),
    );
  }

  /// 滚动到底部
  /// force=true：强制滚动（发送/完成时）
  /// force=false：仅在用户未上滑时跟随
  void _scrollToBottom({required bool force}) {
    if (!_scrollController.hasClients) return;
    if (!force && _userScrolledUp) return;

    // 使用多次 postFrameCallback 确保布局完成后滚动到真正的底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      if (force) {
        // 强制滚动：先 jumpTo 再 animateTo，确保到达真正底部
        final maxExtent = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(maxExtent);

        // 再次检查并动画滚动（处理布局延迟）
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted || !_scrollController.hasClients) return;
          final newMax = _scrollController.position.maxScrollExtent;
          if (newMax > maxExtent) {
            _scrollController.animateTo(
              newMax,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        // 流式输出时用 jumpTo 避免动画堆积导致卡顿
        final maxExtent = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(maxExtent);
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    await _initSettings();
    await _initTts();
    await AIService.instance.clearHistory();
  }

  void _openTranslate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TranslateScreen()),
    );
  }

  void _openModelManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ModelListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Column(
            children: [
              if (_showMetrics && _isSending) _buildMetricsBar(),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        // 关键：physics 使用 ClampingScrollPhysics 避免弹性滚动干扰
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isStreaming = _isSending &&
                              index == _streamingMessageIndex;
                          return MessageBubble(
                            key: ValueKey(message.id),
                            message: message,
                            isThinking: isStreaming,
                            showTimestamp: _showTimestamp,
                            onTtsPlay:
                                (!message.isUser && message.text.isNotEmpty)
                                    ? () => _playTts(message.text)
                                    : null,
                            onResend: message.isUser
                                ? () => _resendMessage(message)
                                : null,
                          );
                        },
                      ),
              ),
              if (_showImagePreview && _pendingImage != null)
                _buildImagePreview(),
              InputBar(
                controller: _textController,
                onSend: () => _sendMessage(),
                onCancel: _cancelSending,
                onVoiceRecorded: _handleVoiceRecorded,
                onCameraPick: () => _pickImage(ImageSource.camera),
                onImagePick: () => _pickImage(ImageSource.gallery),
                isSending: _isSending,
              ),
            ],
          ),

          // 滚动到底部按钮（居中显示，位置更高）
          if (_showScrollToBottom)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(child: _buildScrollToBottomButton()),
            ),
        ],
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    return GestureDetector(
      onTap: () {
        _userScrolledUp = false;
        _scrollToBottom(force: true);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF0EA5E9),
          size: 28,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF64748B)),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'DG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DG AI',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '智能助手',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_messages.length > 1)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFF94A3B8)),
            onPressed: _clearMessages,
          ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Color(0xFF94A3B8)),
          onPressed: _openSettings,
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'DG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'DG AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '端侧智能助手',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 导航项
            _buildDrawerItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: '智能对话',
              isActive: true,
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              icon: Icons.translate_rounded,
              label: '翻译',
              onTap: () {
                Navigator.pop(context);
                _openTranslate();
              },
            ),
            _buildDrawerItem(
              icon: Icons.memory_rounded,
              label: '模型管理',
              onTap: () {
                Navigator.pop(context);
                _openModelManagement();
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings_outlined,
              label: '设置',
              onTap: () {
                Navigator.pop(context);
                _openSettings();
              },
            ),

            const Divider(indent: 16, endIndent: 16),

            // 清除对话
            _buildDrawerItem(
              icon: Icons.delete_outline_rounded,
              label: '清除对话',
              iconColor: const Color(0xFFEF4444),
              onTap: () {
                Navigator.pop(context);
                _clearMessages();
              },
            ),

            const Spacer(),

            // 版本信息
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'DG AI v1.1.2 · Gemma 4 E2B',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive
            ? const Color(0xFF0EA5E9)
            : (iconColor ?? const Color(0xFF64748B)),
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive
              ? const Color(0xFF0EA5E9)
              : (iconColor ?? const Color(0xFF1E293B)),
        ),
      ),
      tileColor: isActive
          ? const Color(0xFF0EA5E9).withValues(alpha: 0.08)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
    );
  }

  Widget _buildMetricsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0EA5E9).withValues(alpha: 0.07),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(Icons.speed_rounded, '速度',
              '${_tokensPerSecond.toStringAsFixed(1)} t/s'),
          _buildMetricItem(
              Icons.token_rounded, 'Tokens', _totalTokens.toString()),
          _buildMetricItem(
              Icons.text_fields_rounded, '字符', _totalCharacters.toString()),
          _buildMetricItem(
              Icons.timer_outlined,
              '时长',
              _inferenceStartTime != null
                  ? '${DateTime.now().difference(_inferenceStartTime!).inSeconds}s'
                  : '0s'),
          _buildMetricItem(Icons.access_time_rounded, '延迟',
              '${_averageLatency.toStringAsFixed(0)}ms'),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF0EA5E9)),
        const SizedBox(width: 3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: Color(0xFF94A3B8))),
            Text(value,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0EA5E9))),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(_pendingImage!,
                    width: 56, height: 56, fit: BoxFit.cover),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _pendingImage = null;
                    _showImagePreview = false;
                  }),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 13, color: Colors.white),
                  ),
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
                const Text('图片已选择',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _isSending ? null : () => _sendMessage(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('直接发送',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() {
                        _pendingImage = null;
                        _showImagePreview = false;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('取消',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF64748B))),
                      ),
                    ),
                  ],
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: Text('DG',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('开始对话',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          const Text('发送消息开始',
              style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
