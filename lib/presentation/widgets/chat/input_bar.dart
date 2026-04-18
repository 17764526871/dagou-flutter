import 'package:flutter/material.dart';
import 'dart:async';
import '../../../services/audio/audio_service.dart';

class InputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String, int) onVoiceRecorded;
  final VoidCallback onCameraPick;
  final VoidCallback onImagePick;
  final bool isSending;

  const InputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onVoiceRecorded,
    required this.onCameraPick,
    required this.onImagePick,
    required this.isSending,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar>
    with TickerProviderStateMixin {
  bool _isVoiceMode = false;
  bool _isRecording = false;
  bool _isCancelZone = false;
  bool _showMoreMenu = false;

  // 音频可视化数据
  final List<double> _audioLevels = List.filled(15, 0.0);
  Timer? _audioTimer;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  @override
  void dispose() {
    _audioTimer?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _startRecording() async {
    final success = await AudioService.instance.startRecording();
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('录音权限未授予')),
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _isCancelZone = false;
      _recordingSeconds = 0;
    });

    // 开始录音计时
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingSeconds++;
        });
      }
    });

    // 音频可视化（使用真实音量数据）
    _audioTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (mounted && _isRecording) {
        final amplitude = await AudioService.instance.getAmplitude();
        setState(() {
          // 更新波形，从右向左移动
          for (int i = 0; i < _audioLevels.length - 1; i++) {
            _audioLevels[i] = _audioLevels[i + 1];
          }
          _audioLevels[_audioLevels.length - 1] = amplitude;
        });
      }
    });
  }

  void _stopRecording() async {
    _audioTimer?.cancel();
    _recordingTimer?.cancel();

    if (!_isCancelZone && _recordingSeconds > 0) {
      final path = await AudioService.instance.stopRecording();
      if (path != null) {
        widget.onVoiceRecorded(path, _recordingSeconds);
      }
    } else {
      await AudioService.instance.cancelRecording();
    }

    setState(() {
      _isRecording = false;
      _isCancelZone = false;
      _recordingSeconds = 0;
      _audioLevels.fillRange(0, _audioLevels.length, 0.0);
    });
  }

  void _onVerticalDragUpdate(LongPressMoveUpdateDetails details) {
    if (_isRecording) {
      setState(() {
        _isCancelZone = details.localPosition.dy < -80;
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
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 录音提示覆盖层
            if (_isRecording) _buildRecordingOverlay(),

            // 主输入区域
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 语音/键盘切换按钮
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

                  // 中间输入区域
                  Expanded(
                    child: _isVoiceMode
                        ? _buildVoiceButton()
                        : _buildTextInput(),
                  ),

                  const SizedBox(width: 8),

                  // 右侧功能按钮
                  if (!_isVoiceMode && widget.controller.text.trim().isEmpty)
                    _buildIconButton(
                      icon: Icons.add_circle_outline,
                      onTap: () {
                        setState(() {
                          _showMoreMenu = !_showMoreMenu;
                        });
                      },
                    )
                  else if (!_isVoiceMode)
                    _buildSendButton(),
                ],
              ),
            ),

            // 更多功能菜单
            if (_showMoreMenu) _buildMoreMenu(),
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
      constraints: const BoxConstraints(
        minHeight: 36,
        maxHeight: 120,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(18),
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
            vertical: 8,
          ),
        ),
        maxLines: null,
        style: const TextStyle(fontSize: 15),
        textInputAction: TextInputAction.send,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (widget.controller.text.trim().isNotEmpty && !widget.isSending) {
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
      onLongPressMoveUpdate: _onVerticalDragUpdate,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: _isRecording
              ? (_isCancelZone ? const Color(0xFFF56565) : const Color(0xFF0EA5E9))
              : const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isRecording
                ? (_isCancelZone ? const Color(0xFFF56565) : const Color(0xFF0EA5E9))
                : const Color(0xFFE2E8F0),
            width: _isRecording ? 2 : 1,
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
            fontWeight: _isRecording ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return InkWell(
      onTap: widget.isSending ? null : widget.onSend,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: widget.isSending
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                ),
          color: widget.isSending ? const Color(0xFFE2E8F0) : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          widget.isSending ? Icons.hourglass_empty : Icons.send_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRecordingOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 音频波形可视化
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_audioLevels.length, (index) {
              final height = 12.0 + _audioLevels[index] * 36;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                width: 4,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  gradient: _isCancelZone
                      ? const LinearGradient(
                          colors: [Color(0xFFF56565), Color(0xFFFC8181)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // 录音时长
          Text(
            _formatDuration(_recordingSeconds),
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // 提示文字
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isCancelZone ? Icons.cancel_outlined : Icons.arrow_upward_rounded,
                size: 16,
                color: _isCancelZone
                    ? const Color(0xFFF56565)
                    : const Color(0xFF718096),
              ),
              const SizedBox(width: 6),
              Text(
                _isCancelZone ? '松开取消发送' : '上滑取消',
                style: TextStyle(
                  fontSize: 14,
                  color: _isCancelZone
                      ? const Color(0xFFF56565)
                      : const Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildMenuButton(
            icon: Icons.image_rounded,
            label: '相册',
            color: const Color(0xFF0EA5E9),
            onTap: widget.onImagePick,
          ),
          const SizedBox(width: 24),
          _buildMenuButton(
            icon: Icons.camera_alt_rounded,
            label: '拍照',
            color: const Color(0xFF48BB78),
            onTap: widget.onCameraPick,
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
          const SizedBox(height: 6),
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
