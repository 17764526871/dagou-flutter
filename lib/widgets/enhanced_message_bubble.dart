import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:typed_data';
import '../models/message.dart';

class EnhancedMessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onTtsPlay;
  final bool isThinking;

  const EnhancedMessageBubble({
    super.key,
    required this.message,
    this.onTtsPlay,
    this.isThinking = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
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
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.hasMedia && message.mediaBytes != null)
                            _buildImage(message.mediaBytes!),
                          if (message.text.isNotEmpty)
                            isUser
                                ? Text(
                                    message.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  )
                                : MarkdownBody(
                                    data: message.text,
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(
                                        color: Color(0xFF2D3748),
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                      code: TextStyle(
                                        backgroundColor:
                                            const Color(0xFFF7FAFC),
                                        color: const Color(0xFF0EA5E9),
                                        fontSize: 14,
                                      ),
                                      codeblockDecoration: BoxDecoration(
                                        color: const Color(0xFFF7FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      blockquote: const TextStyle(
                                        color: Color(0xFF718096),
                                        fontStyle: FontStyle.italic,
                                      ),
                                      h1: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3748),
                                      ),
                                      h2: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3748),
                                      ),
                                      h3: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3748),
                                      ),
                                      listBullet: const TextStyle(
                                        color: Color(0xFF0EA5E9),
                                      ),
                                    ),
                                  ),
                          if (isThinking) _buildThinkingAnimation(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 时间和TTS按钮
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: const TextStyle(
                            color: Color(0xFFA0AEC0),
                            fontSize: 11,
                          ),
                        ),
                        if (!isUser && onTtsPlay != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onTtsPlay,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.volume_up_rounded,
                                size: 16,
                                color: Color(0xFF0EA5E9),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 12),
                _buildAvatar(isUser),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
              )
            : const LinearGradient(
                colors: [Color(0xFF48BB78), Color(0xFF38A169)],
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isUser ? const Color(0xFF0EA5E9) : const Color(0xFF48BB78))
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
        size: 22,
        color: Colors.white,
      ),
    );
  }

  Widget _buildImage(Uint8List imageBytes) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: 220,
        ),
      ),
    );
  }

  Widget _buildThinkingAnimation() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              final delay = index * 0.2;
              final animValue = (value - delay).clamp(0.0, 1.0);
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFFE2E8F0),
                    const Color(0xFF0EA5E9),
                    animValue,
                  ),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
