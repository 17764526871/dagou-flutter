import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import '../../../services/ai/model_manager.dart';
import '../../../services/network/model_download_service.dart';
import '../../../services/storage/settings_service.dart';
import '../../../data/models/ai_model_info.dart';
import '../../widgets/common/top_notification.dart';

class ModelListScreen extends StatefulWidget {
  const ModelListScreen({super.key});

  @override
  State<ModelListScreen> createState() => _ModelListScreenState();
}

class _ModelListScreenState extends State<ModelListScreen> {
  final ModelManager _modelManager = ModelManager.instance;
  final ModelDownloadService _downloadService = ModelDownloadService.instance;
  final SettingsService _settingsService = SettingsService.instance;
  final TextEditingController _serverUrlController = TextEditingController();

  // 服务器模型列表
  List<Map<String, dynamic>> _serverModels = [];
  bool _loadingServerModels = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _serverUrlController.text = _settingsService.loadModelServerUrl();
    if (_serverUrlController.text.isNotEmpty) {
      _fetchServerModels();
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchServerModels() async {
    if (_serverUrlController.text.trim().isEmpty) {
      setState(() {
        _serverError = '请输入服务器地址';
      });
      return;
    }

    setState(() {
      _loadingServerModels = true;
      _serverError = null;
    });

    try {
      final models = await _downloadService.fetchServerModels(_serverUrlController.text);
      setState(() {
        _serverModels = models;
        _loadingServerModels = false;
      });

      // 保存服务器地址
      await _settingsService.saveModelServerUrl(_serverUrlController.text);

      if (mounted) {
        TopNotification.show(context, '已连接到服务器，找到 ${models.length} 个模型',
          type: NotificationType.success);
      }
    } catch (e) {
      setState(() {
        _loadingServerModels = false;
        _serverError = '连接失败：$e';
      });

      if (mounted) {
        TopNotification.show(context, '连接服务器失败：$e',
          type: NotificationType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '模型管理',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildCurrentModelCard(),
          const SizedBox(height: 16),

          // 服务器设置
          _buildServerSettingsCard(),
          const SizedBox(height: 16),

          // 服务器模型列表
          if (_serverModels.isNotEmpty) ...[
            const Text(
              '局域网可下载模型',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            ..._serverModels.map((m) => _buildServerModelCard(m)),
            const SizedBox(height: 16),
          ],

          // 本地文件选择
          _buildLocalFileCard(),
          const SizedBox(height: 16),

          // 内置模型列表
          const Text(
            '内置模型',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          ...ModelManager.availableModels.map((m) => _buildModelCard(m)),

          const SizedBox(height: 20),
          // 说明
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Color(0xFFF97316), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '• 局域网下载：在电脑上运行 model_server.js，手机连接同一WiFi即可下载\n• 本地文件：从手机存储选择已下载的模型文件\n• 模型保存在外部存储，卸载应用不会丢失',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cloud_download_rounded,
                  color: Color(0xFF0EA5E9), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                '局域网服务器',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _serverUrlController,
            decoration: InputDecoration(
              hintText: '例如: 192.168.1.100:8080',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loadingServerModels ? null : _fetchServerModels,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _loadingServerModels
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('连接服务器',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
          if (_serverError != null) ...[
            const SizedBox(height: 8),
            Text(
              _serverError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServerModelCard(Map<String, dynamic> model) {
    final String name = model['name'] ?? '';
    final String size = model['size'] ?? '';
    final String url = model['url'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cloud_outlined, color: Color(0xFF0EA5E9), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    size,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _downloadFromServer(name, url),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('下载', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFromServer(String fileName, String url) async {
    try {
      // 构建完整URL
      String serverUrl = _serverUrlController.text.trim();
      if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
        serverUrl = 'http://$serverUrl';
      }
      if (!serverUrl.endsWith('/')) {
        serverUrl = '$serverUrl/';
      }

      final fullUrl = '$serverUrl${url.startsWith('/') ? url.substring(1) : url}';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('正在下载 $fileName...'),
            ],
          ),
        ),
      );

      final stream = _downloadService.downloadFromLAN(
        modelId: fileName,
        lanUrl: fullUrl,
        fileName: fileName,
      );

      await for (final progress in stream) {
        // 更新进度
        debugPrint('下载进度: ${(progress * 100).toStringAsFixed(1)}%');
      }

      if (mounted) {
        Navigator.pop(context);
        TopNotification.show(context, '模型下载完成：$fileName',
          type: NotificationType.success);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        TopNotification.show(context, '下载失败：$e',
          type: NotificationType.error);
      }
    }
  }

  Widget _buildLocalFileCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.folder_open_rounded, color: Color(0xFF64748B), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '从本地文件夹选择模型',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '支持 .task, .litertlm, .bin 格式文件',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _pickLocalModel,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('选择', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocalModel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['task', 'litertlm', 'bin'],
      );

      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;
        String fileName = result.files.single.name;

        // 猜测模型类型
        ModelType guessModelType = ModelType.general;
        ModelFileType guessFileType = ModelFileType.task;

        if (fileName.toLowerCase().contains('gemma')) guessModelType = ModelType.gemmaIt;
        if (fileName.toLowerCase().contains('qwen')) guessModelType = ModelType.qwen;
        if (fileName.toLowerCase().contains('deepseek')) guessModelType = ModelType.deepSeek;

        if (fileName.endsWith('.bin')) guessFileType = ModelFileType.binary;
        if (fileName.endsWith('.litertlm')) guessFileType = ModelFileType.litertlm;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在加载本地模型...'),
                  ],
                ),
              ),
            ),
          ),
        );

        // 使用本地路径加载
        await _modelManager.switchLocalModel(
          path,
          modelType: guessModelType,
          fileType: guessFileType
        );

        if (mounted) {
          Navigator.pop(context);
          setState(() {});
          TopNotification.show(context, '已切换到本地模型 $fileName', type: NotificationType.success);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        TopNotification.show(context, '加载本地模型失败：$e', type: NotificationType.error);
      }
    }
  }

  Widget _buildCurrentModelCard() {
    final current = _modelManager.currentModelInfo;
    if (current == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.memory_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('当前使用',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      current.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _modelManager.currentBackend == PreferredBackend.gpu
                      ? 'GPU'
                      : 'CPU',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: current.capabilities
                .map((cap) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getCapabilityLabel(cap),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(AIModelInfo model) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: model.isBuiltIn
                        ? const Color(0xFFF0F9FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    model.isBuiltIn ? Icons.star_rounded : Icons.cloud_outlined,
                    color: model.isBuiltIn
                        ? const Color(0xFF0EA5E9)
                        : const Color(0xFF64748B),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        model.size,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              model.description,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: model.capabilities
                  .map((cap) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFFBAE6FD)),
                        ),
                        child: Text(
                          _getCapabilityLabel(cap),
                          style: const TextStyle(
                              color: Color(0xFF0369A1), fontSize: 11),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getCapabilityLabel(String cap) {
    const labels = {
      'text': '文本',
      'image': '图片',
      'audio': '音频',
      'function_calling': '函数调用',
      'thinking': '思维链',
    };
    return labels[cap] ?? cap;
  }
}
