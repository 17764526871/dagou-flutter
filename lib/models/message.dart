import 'dart:typed_data';

enum MessageType {
  text,
  image,
  video,
  audio,
}

class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final Uint8List? mediaBytes;
  final String? mediaPath;
  final int? audioDuration; // 音频时长（秒）

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.mediaBytes,
    this.mediaPath,
    this.audioDuration,
  });

  factory Message.text({
    required String text,
    required bool isUser,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );
  }

  factory Message.withImage({
    required String text,
    required Uint8List imageBytes,
    required bool isUser,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
      type: MessageType.image,
      mediaBytes: imageBytes,
    );
  }

  factory Message.withVideo({
    required String text,
    required String videoPath,
    required bool isUser,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
      type: MessageType.video,
      mediaPath: videoPath,
    );
  }

  factory Message.withAudio({
    required String text,
    required String audioPath,
    required bool isUser,
    int? duration,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
      type: MessageType.audio,
      mediaPath: audioPath,
      audioDuration: duration,
    );
  }

  bool get hasMedia => mediaBytes != null || mediaPath != null;
}
