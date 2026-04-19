import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../data/models/message.dart';
import 'audio_player_widget.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onTtsPlay;
  final bool isThinking;
  final bool showTimestamp;
  final VoidCallback? onResend;

  const MessageBubble({
    super.key,
    required this.message,
    this.onTtsPlay,
    this.isThinking = false,
    this.showTimestamp = true,
    this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _buildAvatar(isUser),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    _buildBubble(context, isUser),
                    if (showTimestamp) ...[
                      const SizedBox(height: 4),
                      _buildMetaRow(context, isUser),
                    ],
                  ],
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 10),
                _buildAvatar(isUser),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, bool isUser) {
    return GestureDetector(
      onLongPress: () => _showCopyMenu(context),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 音频消息
            if (message.type == MessageType.audio &&
                message.mediaPath != null)
              AudioPlayerWidget(
                audioPath: message.mediaPath!,
                duration: message.audioDuration,
              ),
            // 图片消息
            if (message.hasMedia && message.mediaBytes != null)
              _buildImage(message.mediaBytes!),
            // 文本内容
            if (message.type != MessageType.audio) ...[
              if (message.text.isEmpty && !isUser && isThinking)
                // 空内容 + 正在推理 → 显示加载动画
                _buildLoadingDots()
              else if (message.text.isNotEmpty)
                isUser
                    ? SelectableText(
                        message.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      )
                    : _buildMarkdown(context, message.text),
              // 推理中且已有内容 → 在末尾显示小动画
              if (!isUser && isThinking && message.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _buildLoadingDots(),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarkdown(BuildContext context, String text) {
    return MarkdownBody(
      data: text,
      selectable: true,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 15,
          height: 1.55,
        ),
        code: const TextStyle(
          backgroundColor: Color(0xFFF1F5F9),
          color: Color(0xFF0EA5E9),
          fontSize: 13.5,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquote: const TextStyle(
          color: Color(0xFF64748B),
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
        blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
        blockquoteDecoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(0xFF0EA5E9), width: 3),
          ),
        ),
        h1: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
          height: 1.4,
        ),
        h2: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
          height: 1.4,
        ),
        h3: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
          height: 1.4,
        ),
        listBullet: const TextStyle(color: Color(0xFF0EA5E9), fontSize: 15),
        listIndent: 20,
        a: const TextStyle(
          color: Color(0xFF0EA5E9),
          decoration: TextDecoration.underline,
        ),
        strong: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
        em: const TextStyle(fontStyle: FontStyle.italic),
        tableHead: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
        tableBody: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
        tableBorder: TableBorder.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        horizontalRuleDecoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
      ),
    );
  }

  /// 三点跳动加载动画
  Widget _buildLoadingDots() {
    return _ThinkingDotsWidget();
  }

  Widget _buildMetaRow(BuildContext context, bool isUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.timestamp),
          style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 11),
        ),
        // 复制按钮
        if (message.text.isNotEmpty) ...[
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _copyText(context),
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(
                Icons.copy_rounded,
                size: 14,
                color: Color(0xFFB0BEC5),
              ),
            ),
          ),
        ],
        // 重发按钮（仅用户消息，且非音频消息）
        if (isUser && onResend != null && message.type != MessageType.audio) ...[
          const SizedBox(width: 6),
          InkWell(
            onTap: onResend,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(
                Icons.refresh_rounded,
                size: 15,
                color: Color(0xFF0EA5E9),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _copyText(BuildContext context) {
    if (message.text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已复制到剪贴板'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.fixed,
        margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _showCopyMenu(BuildContext context) {
    if (message.text.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Color(0xFF0EA5E9)),
              title: const Text('复制文本'),
              onTap: () {
                Navigator.pop(context);
                _copyText(context);
              },
            ),
            if (onResend != null && message.isUser)
              ListTile(
                leading: const Icon(Icons.refresh_rounded,
                    color: Color(0xFF0EA5E9)),
                title: const Text('重新发送'),
                onTap: () {
                  Navigator.pop(context);
                  onResend?.call();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
              )
            : const LinearGradient(
                colors: [Color(0xFF48BB78), Color(0xFF38A169)],
              ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: (isUser
                    ? const Color(0xFF0EA5E9)
                    : const Color(0xFF48BB78))
                .withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
        size: 20,
        color: Colors.white,
      ),
    );
  }

  Widget _buildImage(Uint8List imageBytes) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: 200,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// 三点跳动动画组件（StatefulWidget 保证动画循环）
class _ThinkingDotsWidget extends StatefulWidget {
  @override
  State<_ThinkingDotsWidget> createState() => _ThinkingDotsWidgetState();
}

class _ThinkingDotsWidgetState extends State<_ThinkingDotsWidget>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
    });
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    // 错开启动
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) {
            return Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFF94A3B8),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
