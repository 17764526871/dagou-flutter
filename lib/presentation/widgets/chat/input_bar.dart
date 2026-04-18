import 'package:flutter/material.dart';
import 'dart:async';
import '../../../services/audio/audio_service.dart';

class InputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onCancel;
  final Function(String, int) onVoiceRecorded;
  final VoidCallback onCameraPick;
  final VoidCallback onImagePick;
  final bool isSending;

  const InputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onCancel,
    required this.onVoiceRecorded,
    required this.onCameraPick,
    required this.onImagePick,
    required this.isSending,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> with TickerProviderStateMixin {
  bool _isVoiceMode = false;
  bool _isRecording = false;
  bool _isCancelZone = false;
  bool _showMoreMenu = false;

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

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingSeconds++;
        });
      }
    });

    _audioTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (mounted && _isRecording) {
        final amplitude = await AudioService.instance.getAmplitude();
        setState(() {
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
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRecording) _buildRecordingOverlay(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!widget.isSending) ...[
                    _buildActionButton(
                      icon: _isVoiceMode ? Icons.keyboard : Icons.mic,
                      onTap: () {
                        setState(() {
                          _isVoiceMode = !_isVoiceMode;
                          _showMoreMenu = false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: widget.isSending
                        ? _buildSendingIndicator()
                        : (_isVoiceMode ? _buildVoiceButton() : _buildTextInput()),
                  ),
                  const SizedBox(width: 8),
                  if (widget.isSending)
                    _buildCancelButton()
                  else if (!_isVoiceMode && widget.controller.text.trim().isEmpty)
                    _buildActionButton(
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
            if (_showMoreMenu) _buildMoreMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 24,
            color: const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 40,
        maxHeight: 120,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: widget.controller,
        decoration: const InputDecoration(
          hintText: '输入消息...',
          hintStyle: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        maxLines: null,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
        textInputAction: TextInputAction.send,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (widget.controller.text.trim().isNotEmpty) {
            widget.onSend();
          }
        },
      ),
    );
  }

  Widget _buildSendingIndicator() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF0EA5E9),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '生成中...',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onCancel,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '取消',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFFEF4444),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onSend,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.send_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      onLongPressMoveUpdate: _onVerticalDragUpdate,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _isRecording
              ? (_isCancelZone ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7))
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          _isRecording
              ? (_isCancelZone ? '松开取消' : '松开发送')
              : '按住说话',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _isRecording
                ? (_isCancelZone ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isCancelZone ? Icons.cancel_outlined : Icons.mic,
            size: 32,
            color: _isCancelZone ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          ),
          const SizedBox(height: 8),
          Text(
            _isCancelZone ? '松开取消发送' : '上滑取消',
            style: TextStyle(
              fontSize: 13,
              color: _isCancelZone ? const Color(0xFFEF4444) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _audioLevels.length,
              (index) => Container(
                width: 3,
                height: 20 + (_audioLevels[index] * 30),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _isCancelZone
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_recordingSeconds ~/ 60}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildMenuButton(
            icon: Icons.photo_library_outlined,
            label: '相册',
            onTap: widget.onImagePick,
          ),
          const SizedBox(width: 24),
          _buildMenuButton(
            icon: Icons.camera_alt_outlined,
            label: '拍照',
            onTap: widget.onCameraPick,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
