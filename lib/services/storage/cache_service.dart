import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static CacheService get instance => _instance;

  /// 获取缓存大小（字节）
  Future<int> getCacheSize() async {
    try {
      int totalSize = 0;

      // 临时目录
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        totalSize += await _getDirectorySize(tempDir);
      }

      // 应用缓存目录
      final cacheDir = await getApplicationCacheDirectory();
      if (await cacheDir.exists()) {
        totalSize += await _getDirectorySize(cacheDir);
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// 清除所有缓存
  Future<bool> clearAllCache() async {
    try {
      // 清除临时目录
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await _clearDirectory(tempDir);
      }

      // 清除应用缓存目录
      final cacheDir = await getApplicationCacheDirectory();
      if (await cacheDir.exists()) {
        await _clearDirectory(cacheDir);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 清除音频文件
  Future<bool> clearAudioCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final audioFiles = tempDir
          .listSync()
          .where((file) =>
              file.path.endsWith('.m4a') ||
              file.path.endsWith('.mp3') ||
              file.path.endsWith('.wav'))
          .toList();

      for (final file in audioFiles) {
        if (file is File) {
          await file.delete();
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 清除图片缓存
  Future<bool> clearImageCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final imageFiles = tempDir
          .listSync()
          .where((file) =>
              file.path.endsWith('.jpg') ||
              file.path.endsWith('.jpeg') ||
              file.path.endsWith('.png') ||
              file.path.endsWith('.gif'))
          .toList();

      for (final file in imageFiles) {
        if (file is File) {
          await file.delete();
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取目录大小
  Future<int> _getDirectorySize(Directory directory) async {
    int size = 0;
    try {
      if (await directory.exists()) {
        await for (final entity in directory.list(recursive: true)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      // 忽略错误
    }
    return size;
  }

  /// 清除目录内容（保留目录本身）
  Future<void> _clearDirectory(Directory directory) async {
    try {
      if (await directory.exists()) {
        await for (final entity in directory.list()) {
          if (entity is File) {
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        }
      }
    } catch (e) {
      // 忽略错误
    }
  }

  /// 格式化文件大小
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
