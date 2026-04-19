import 'package:flutter_gemma/flutter_gemma.dart';

class AIModelInfo {
  final String id;
  final String name;
  final String size;
  final List<String> capabilities;
  final String? url;
  final String description;
  final bool isBuiltIn;
  final String? localPath;
  final ModelType modelType;
  final ModelFileType fileType;

  const AIModelInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.capabilities,
    this.url,
    required this.description,
    this.isBuiltIn = false,
    this.localPath,
    this.modelType = ModelType.gemmaIt,
    this.fileType = ModelFileType.task,
  });

  bool get supportsText => capabilities.contains('text');
  bool get supportsImage => capabilities.contains('image');
  bool get supportsAudio => capabilities.contains('audio');
  bool get supportsFunctionCalling => capabilities.contains('function_calling');
  bool get supportsThinking => capabilities.contains('thinking');

  AIModelInfo copyWith({
    String? id,
    String? name,
    String? size,
    List<String>? capabilities,
    String? url,
    String? description,
    bool? isBuiltIn,
    String? localPath,
  }) {
    return AIModelInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      capabilities: capabilities ?? this.capabilities,
      url: url ?? this.url,
      description: description ?? this.description,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      localPath: localPath ?? this.localPath,
    );
  }
}
