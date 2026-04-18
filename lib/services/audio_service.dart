import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static AudioService get instance => _instance;

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;

  /// 开始录音
  Future<bool> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _currentRecordingPath = '${directory.path}/audio_$timestamp.m4a';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _currentRecordingPath!,
        );

        _isRecording = true;
        return true;
      }
      return false;
    } catch (e) {
      print('开始录音失败: $e');
      return false;
    }
  }

  /// 停止录音并返回文件路径
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      print('停止录音失败: $e');
      _isRecording = false;
      return null;
    }
  }

  /// 取消录音
  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      _isRecording = false;

      // 删除录音文件
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentRecordingPath = null;
      }
    } catch (e) {
      print('取消录音失败: $e');
    }
  }

  /// 获取当前录音音量（0.0 - 1.0）
  Future<double> getAmplitude() async {
    try {
      final amplitude = await _recorder.getAmplitude();
      // 将分贝值转换为 0-1 范围
      // 通常分贝范围是 -160 到 0
      final normalized = (amplitude.current + 160) / 160;
      return normalized.clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    await _recorder.dispose();
  }

  /// 获取音频文件时长（秒）
  static Future<int> getAudioDuration(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return 0;

      // 简单估算：文件大小 / 比特率
      // 对于 128kbps 的 AAC，大约是 16KB/s
      final bytes = await file.length();
      final seconds = (bytes / 16000).round();
      return seconds;
    } catch (e) {
      print('获取音频时长失败: $e');
      return 0;
    }
  }
}
