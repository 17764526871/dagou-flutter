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

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.mediaBytes,
    this.mediaPath,
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

  bool get hasMedia => mediaBytes != null || mediaPath != null;
}
