import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ModelDownloadService {
  static final ModelDownloadService _instance = ModelDownloadService._internal();
  factory ModelDownloadService() => _instance;
  ModelDownloadService._internal();

  static ModelDownloadService get instance => _instance;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 30),
  ));

  final Map<String, CancelToken> _cancelTokens = {};

  /// 获取服务器上的模型列表
  Future<List<Map<String, dynamic>>> fetchServerModels(String serverUrl) async {
    try {
      // 确保URL格式正确
      String url = serverUrl.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'http://$url';
      }
      if (!url.endsWith('/')) {
        url = '$url/';
      }

      final response = await _dio.get(
        '${url}api/models',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final models = data['models'] as List<dynamic>;
        return models.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      debugPrint('❌ 获取服务器模型列表失败: $e');
      rethrow;
    }
  }

  /// 从局域网下载模型
  Stream<double> downloadFromLAN({
    required String modelId,
    required String lanUrl,
    required String fileName,
  }) async* {
    final controller = StreamController<double>();
    final cancelToken = CancelToken();
    _cancelTokens[modelId] = cancelToken;

    try {
      // 获取应用外部存储目录
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception('无法访问外部存储');

      final modelsDir = Directory(path.join(dir.path, 'models'));
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      final savePath = path.join(modelsDir.path, fileName);
      debugPrint('📥 开始从局域网下载: $lanUrl -> $savePath');

      await _dio.download(
        lanUrl,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            controller.add(progress);
            debugPrint('📥 下载进度: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
      );

      debugPrint('✅ 模型下载完成: $savePath');
      controller.add(1.0);
      await controller.close();

      yield* controller.stream;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('⚠️ 下载已取消: $modelId');
      } else {
        debugPrint('❌ 下载失败: $e');
      }
      await controller.close();
      rethrow;
    } finally {
      _cancelTokens.remove(modelId);
    }
  }

  /// 取消下载
  void cancelDownload(String modelId) {
    _cancelTokens[modelId]?.cancel('User cancelled download');
    _cancelTokens.remove(modelId);
  }

  /// 获取已下载的模型路径
  Future<String?> getDownloadedModelPath(String fileName) async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return null;

      final modelPath = path.join(dir.path, 'models', fileName);
      final file = File(modelPath);

      if (await file.exists()) {
        return modelPath;
      }
      return null;
    } catch (e) {
      debugPrint('❌ 获取模型路径失败: $e');
      return null;
    }
  }
}
