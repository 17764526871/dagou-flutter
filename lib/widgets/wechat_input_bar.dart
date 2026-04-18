import 'package:flutter/material.dart';
import 'dart:async';

class WeChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String) onVoiceRecorded;
  final VoidCallback onCameraPick;
  final VoidCallback onImagePick;
  final VoidCallback onFilePick;

  const WeChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onVoiceRecorded,
    required this.onCameraPick,
    required this.onImagePick,
    required this.onFilePick,
  });

  @override
  State<WeChatInputBar> createState() => _WeChatInputBarState();
}

class _WeChatInputBarState extends State<WeChatInputBar>
    with TickerProviderStateMixin {
  bool _isVoiceMode = false;
  bool _isRecording = false;
  bool _isCancelZone = false;
  bool _showMoreMenu = false;
  double _recordingVolume = 0.0;
  Timer? _volumeTimer;
  late AnimationController _volumeController;

  @override
  void initState() {
    super.initState();
    _volumeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _volumeTimer?.cancel();
    _volumeController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isCancelZone = false;
    });

    // 模拟音量变化
    _volumeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _recordingVolume = 0.3 + (DateTime.now().millisecond % 100) / 100 * 0.7;
        });
      }
    });
  }

  void _stopRecording() {
    _volumeTimer?.cancel();

    if (!_isCancelZone) {
      // 发送语音
      widget.onVoiceRecorded('voice_message_${DateTime.now().millisecondsSinceEpoch}');
    }

    setState(() {
      _isRecording = false;
      _isCancelZone = false;
      _recordingVolume = 0.0;
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isRecording) {
      setState(() {
        _isCancelZone = details.localPosition.dy < -50;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 主输入区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 左侧相机按钮
                  _buildIconButton(
                    icon: Icons.camera_alt_rounded,
                    onTap: widget.onCameraPick,
                  ),
                  const SizedBox(width: 8),

                  // 中间输入区域
                  Expanded(
                    child: _isVoiceMode
                        ? _buildVoiceButton()
                        : _buildTextInput(),
                  ),

                  const SizedBox(width: 8),

                  // 右侧语音/更多按钮
                  _buildIconButton(
                    icon: _isVoiceMode ? Icons.keyboard : Icons.mic,
                    onTap: () {
                      setState(() {
                        _isVoiceMode = !_isVoiceMode;
                        _showMoreMenu = false;
                      });
                    },
                  ),

                  const SizedBox(width: 8),

                  // 更多功能按钮
                  _buildIconButton(
                    icon: Icons.add_circle_outline,
                    onTap: () {
                      setState(() {
                        _showMoreMenu = !_showMoreMenu;
                      });
                    },
                  ),
                ],
              ),
            ),

            // 更多功能菜单
            if (_showMoreMenu) _buildMoreMenu(),

            // 录音提示
            if (_isRecording) _buildRecordingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 22,
          color: const Color(0xFF0EA5E9),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        decoration: const InputDecoration(
          hintText: '输入消息...',
          hintStyle: TextStyle(
            color: Color(0xFFA0AEC0),
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
        maxLines: null,
        style: const TextStyle(fontSize: 15),
        textInputAction: TextInputAction.send,
        onSubmitted: (_) {
          if (widget.controller.text.trim().isNotEmpty) {
            widget.onSend();
          }
        },
      ),
    );
  }

  Widget _buildVoiceButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      onVerticalDragUpdate: _onVerticalDragUpdate,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _isRecording
              ? (_isCancelZone ? const Color(0xFFF56565) : const Color(0xFF0EA5E9))
              : const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isRecording
                ? (_isCancelZone ? const Color(0xFFF56565) : const Color(0xFF0EA5E9))
                : const Color(0xFFE2E8F0),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          _isRecording
              ? (_isCancelZone ? '松开取消' : '松开发送')
              : '按住说话',
          style: TextStyle(
            fontSize: 15,
            color: _isRecording ? Colors.white : const Color(0xFF0EA5E9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingOverlay() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 音频可视化
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final height = 20.0 + _recordingVolume * 40 * (index % 2 == 0 ? 1 : 0.7);
              return Container(
                width: 4,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _isCancelZone ? const Color(0xFFF56565) : const Color(0xFF0EA5E9),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _isCancelZone ? '松开手指，取消发送' : '上滑取消',
            style: TextStyle(
              fontSize: 13,
              color: _isCancelZone ? const Color(0xFFF56565) : const Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildMenuButton(
            icon: Icons.image_rounded,
            label: '相册',
            color: const Color(0xFF0EA5E9),
            onTap: widget.onImagePick,
          ),
          _buildMenuButton(
            icon: Icons.insert_drive_file_rounded,
            label: '文件',
            color: const Color(0xFF48BB78),
            onTap: widget.onFilePick,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }
}
