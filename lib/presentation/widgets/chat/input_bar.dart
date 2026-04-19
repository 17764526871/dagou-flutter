import 'package:flutter/material.dart';
import 'dart:async';
import '../../../services/audio/audio_service.dart';

import '../common/top_notification.dart';

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

  // 录音动画控制器（3个跳动点）
  late final List<AnimationController> _dotControllers;
  late final List<Animation<double>> _dotAnimations;

  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _dotControllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
    });
    _dotAnimations = _dotControllers.map((c) {
      return Tween<double>(begin: 0, end: -8).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _dotControllers) {
      c.dispose();
    }
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _startDotAnimation() {
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 130), () {
        if (mounted && _isRecording) {
          _dotControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopDotAnimation() {
    for (final c in _dotControllers) {
      c.stop();
      c.reset();
    }
  }

  void _startRecording() async {
    final success = await AudioService.instance.startRecording();
    if (!success) {
      if (mounted) {
        TopNotification.show(context, '录音权限未授予', type: NotificationType.error);
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _isCancelZone = false;
      _recordingSeconds = 0;
    });

    _startDotAnimation();

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingSeconds++);
    });
  }

  void _stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _stopDotAnimation();

    if (!_isCancelZone && _recordingSeconds > 0) {
      final path = await AudioService.instance.stopRecording();
      if (path != null) {
        widget.onVoiceRecorded(path, _recordingSeconds);
      }
    } else {
      await AudioService.instance.cancelRecording();
      if (!_isCancelZone && mounted) {
        TopNotification.show(context, '录音太短，已取消', type: NotificationType.info);
      }
    }

    setState(() {
      _isRecording = false;
      _isCancelZone = false;
      _recordingSeconds = 0;
    });
  }

  void _onVerticalDragUpdate(LongPressMoveUpdateDetails details) {
    if (_isRecording) {
      setState(() => _isCancelZone = details.localPosition.dy < -60);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EDF2), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图片选择菜单（从上方弹出，在输入行上方）
            if (_showMoreMenu) _buildMoreMenu(),

            // 录音提示条（不遮挡输入框，在输入行上方）
            if (_isRecording) _buildRecordingBar(),

            // 主输入行
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!widget.isSending) ...[
                    _buildIconBtn(
                      icon: _isVoiceMode
                          ? Icons.keyboard_rounded
                          : Icons.mic_rounded,
                      onTap: () => setState(() {
                        _isVoiceMode = !_isVoiceMode;
                        _showMoreMenu = false;
                      }),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: widget.isSending
                        ? _buildSendingIndicator()
                        : (_isVoiceMode
                            ? _buildVoiceButton()
                            : _buildTextInput()),
                  ),
                  const SizedBox(width: 6),
                  if (widget.isSending)
                    _buildCancelButton()
                  else if (!_isVoiceMode &&
                      widget.controller.text.trim().isEmpty)
                    _buildIconBtn(
                      icon: Icons.add_circle_outline_rounded,
                      onTap: () =>
                          setState(() => _showMoreMenu = !_showMoreMenu),
                      active: _showMoreMenu,
                    )
                  else if (!_isVoiceMode)
                    _buildSendButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 录音提示条：简洁的跳动点动效 + 计时器，不遮挡输入框
  Widget _buildRecordingBar() {
    final color =
        _isCancelZone ? const Color(0xFFEF4444) : const Color(0xFF0EA5E9);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.15), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 三个跳动点
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _dotAnimations[i],
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _dotAnimations[i].value),
                  child: Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 10),
          Text(
            _isCancelZone ? '松开取消' : '上滑取消',
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // 计时器
          Text(
            '${_recordingSeconds ~/ 60}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.fiber_manual_record, size: 10, color: color),
        ],
      ),
    );
  }

  Widget _buildIconBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          icon,
          size: 24,
          color: active ? const Color(0xFF0EA5E9) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: widget.controller,
        decoration: const InputDecoration(
          hintText: '输入消息...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        maxLines: null,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
        textInputAction: TextInputAction.send,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (widget.controller.text.trim().isNotEmpty) widget.onSend();
        },
      ),
    );
  }

  Widget _buildSendingIndicator() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
            ),
          ),
          SizedBox(width: 10),
          Text(
            '生成中...',
            style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: widget.onCancel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(22),
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
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: widget.onSend,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.send_rounded, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildVoiceButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      onLongPressMoveUpdate: _onVerticalDragUpdate,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _isRecording
              ? (_isCancelZone
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFDCFCE7))
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(22),
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
                ? (_isCancelZone
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981))
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: Color(0xFFE8EDF2), width: 0.5),
          bottom: BorderSide(color: Color(0xFFE8EDF2), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _buildMenuBtn(
            icon: Icons.photo_library_outlined,
            label: '相册',
            onTap: () {
              setState(() => _showMoreMenu = false);
              widget.onImagePick();
            },
          ),
          const SizedBox(width: 16),
          _buildMenuBtn(
            icon: Icons.camera_alt_outlined,
            label: '拍照',
            onTap: () {
              setState(() => _showMoreMenu = false);
              widget.onCameraPick();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF0EA5E9)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
