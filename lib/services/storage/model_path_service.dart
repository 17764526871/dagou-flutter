import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// 模型路径管理服务
/// 负责查找和管理模型文件的位置
class ModelPathService {
  static final ModelPathService _instance = ModelPathService._internal();
  factory ModelPathService() => _instance;
  ModelPathService._internal();

  static ModelPathService get instance => _instance;

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 获取所有可能的模型路径（按优先级排序）
  Future<List<String>> getPossibleModelPaths(String modelFileName) async {
    final paths = <String>[];

    // 1. 用户自定义路径（最高优先级）
    final customPath = getCustomModelPath();
    if (customPath != null) {
      paths.add(customPath);
    }

    // 2. 应用外部存储目录（推荐位置）
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        paths.add(path.join(externalDir.path, 'models', modelFileName));
      }
    } catch (e) {
      debugPrint('获取外部存储失败: $e');
    }

    // 3. 应用文档目录
    try {
      final docDir = await getApplicationDocumentsDirectory();
      paths.add(path.join(docDir.path, 'models', modelFileName));
    } catch (e) {
      debugPrint('获取文档目录失败: $e');
    }

    // 4. 应用支持目录
    try {
      final supportDir = await getApplicationSupportDirectory();
      paths.add(path.join(supportDir.path, 'models', modelFileName));
    } catch (e) {
      debugPrint('获取支持目录失败: $e');
    }

    // 5. 内置资源（最低优先级）
    paths.add('assets/models/$modelFileName');

    return paths;
  }

  /// 查找模型文件
  /// 返回第一个存在的模型文件路径
  Future<String?> findModelFile(String modelFileName) async {
    final possiblePaths = await getPossibleModelPaths(modelFileName);

    for (final filePath in possiblePaths) {
      // 检查是否是资源文件
      if (filePath.startsWith('assets/')) {
        // 资源文件无法直接检查，假设存在
        debugPrint('检查内置模型: $filePath');
        return filePath;
      }

      // 检查文件是否存在
      final file = File(filePath);
      if (await file.exists()) {
        final size = await file.length();
        debugPrint('找到模型文件: $filePath (${(size / 1024 / 1024).toStringAsFixed(1)}MB)');
        return filePath;
      }
    }

    debugPrint('未找到模型文件: $modelFileName');
    return null;
  }

  /// 验证模型文件
  /// 检查文件大小是否合理
  Future<bool> validateModelFile(String filePath) async {
    try {
      // 资源文件跳过验证
      if (filePath.startsWith('assets/')) {
        return true;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('模型文件不存在: $filePath');
        return false;
      }

      final size = await file.length();

      // 检查文件大小（至少10MB，最多10GB）
      if (size < 10 * 1024 * 1024) {
        debugPrint('模型文件太小: ${(size / 1024 / 1024).toStringAsFixed(1)}MB');
        return false;
      }

      if (size > 10 * 1024 * 1024 * 1024) {
        debugPrint('模型文件太大: ${(size / 1024 / 1024 / 1024).toStringAsFixed(1)}GB');
        return false;
      }

      debugPrint('模型文件验证通过: ${(size / 1024 / 1024).toStringAsFixed(1)}MB');
      return true;
    } catch (e) {
      debugPrint('验证模型文件失败: $e');
      return false;
    }
  }

  /// 保存自定义模型路径
  Future<void> saveCustomModelPath(String filePath) async {
    await _prefs?.setString('custom_model_path', filePath);
    debugPrint('已保存自定义模型路径: $filePath');
  }

  /// 获取自定义模型路径
  String? getCustomModelPath() {
    return _prefs?.getString('custom_model_path');
  }

  /// 清除自定义模型路径
  Future<void> clearCustomModelPath() async {
    await _prefs?.remove('custom_model_path');
    debugPrint('已清除自定义模型路径');
  }

  /// 获取推荐的模型存放目录
  Future<String> getRecommendedModelDirectory() async {
    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      final modelDir = Directory(path.join(externalDir.path, 'models'));
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }
      return modelDir.path;
    }

    final docDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory(path.join(docDir.path, 'models'));
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }

  /// 获取模型文件信息
  Future<Map<String, dynamic>?> getModelFileInfo(String filePath) async {
    try {
      if (filePath.startsWith('assets/')) {
        return {
          'path': filePath,
          'type': 'builtin',
          'size': 0,
          'exists': true,
        };
      }

      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final size = await file.length();
      final stat = await file.stat();

      return {
        'path': filePath,
        'type': 'external',
        'size': size,
        'sizeFormatted': _formatFileSize(size),
        'exists': true,
        'modified': stat.modified,
      };
    } catch (e) {
      debugPrint('获取模型文件信息失败: $e');
      return null;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
    }
  }

  /// 列出所有可能的模型文件位置
  Future<List<Map<String, dynamic>>> listAllModelLocations(String modelFileName) async {
    final locations = <Map<String, dynamic>>[];
    final possiblePaths = await getPossibleModelPaths(modelFileName);

    for (final filePath in possiblePaths) {
      final info = await getModelFileInfo(filePath);
      if (info != null) {
        locations.add(info);
      } else {
        locations.add({
          'path': filePath,
          'type': filePath.startsWith('assets/') ? 'builtin' : 'external',
          'exists': false,
        });
      }
    }

    return locations;
  }
}
