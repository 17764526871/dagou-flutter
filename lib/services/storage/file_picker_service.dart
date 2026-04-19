import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class FilePickerService {
  static final FilePickerService _instance = FilePickerService._internal();
  factory FilePickerService() => _instance;
  FilePickerService._internal();

  static FilePickerService get instance => _instance;

  /// 选择模型文件（.task 或 .litertlm）
  Future<String?> pickModelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['task', 'litertlm'],
        dialogTitle: '选择模型文件',
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        debugPrint('📁 选择的模型文件: $path');

        // 验证文件存在
        final file = File(path);
        if (!await file.exists()) {
          throw Exception('文件不存在');
        }

        return path;
      }
      return null;
    } catch (e) {
      debugPrint('❌ 文件选择失败: $e');
      rethrow;
    }
  }

  /// 选择文件夹
  Future<String?> pickDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择模型存储目录',
      );

      if (result != null) {
        debugPrint('📁 选择的目录: $result');
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('❌ 目录选择失败: $e');
      rethrow;
    }
  }
}
