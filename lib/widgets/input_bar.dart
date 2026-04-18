import 'package:flutter/material.dart';

class InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isListening;
  final VoidCallback onSend;
  final VoidCallback onVoiceToggle;
  final VoidCallback onImagePick;
  final VoidCallback onCameraPick;
  final VoidCallback onVideoPick;

  const InputBar({
    super.key,
    required this.controller,
    required this.isListening,
    required this.onSend,
    required this.onVoiceToggle,
    required this.onImagePick,
    required this.onCameraPick,
    required this.onVideoPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 功能按钮行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.image_rounded,
                label: '图片',
                color: const Color(0xFF667EEA),
                onPressed: onImagePick,
              ),
              _buildActionButton(
                icon: Icons.camera_alt_rounded,
                label: '拍照',
                color: const Color(0xFF48BB78),
                onPressed: onCameraPick,
              ),
              _buildActionButton(
                icon: Icons.videocam_rounded,
                label: '视频',
                color: const Color(0xFFED8936),
                onPressed: onVideoPick,
              ),
              _buildActionButton(
                icon: isListening ? Icons.mic : Icons.mic_none_rounded,
                label: '语音',
                color: isListening ? const Color(0xFFF56565) : const Color(0xFF9F7AEA),
                onPressed: onVoiceToggle,
                isActive: isListening,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 输入框和发送按钮
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isListening
                          ? const Color(0xFFF56565)
                          : const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: isListening ? '🎤 正在聆听...' : '输入消息...',
                      hintStyle: const TextStyle(
                        color: Color(0xFFA0AEC0),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    maxLines: null,
                    style: const TextStyle(fontSize: 15),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSend,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive ? color : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : color,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? color : const Color(0xFF718096),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
