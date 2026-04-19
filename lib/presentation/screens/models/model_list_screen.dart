import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'dart:async';
import '../../../services/ai/model_manager.dart';
import '../../../data/models/ai_model_info.dart';

class ModelListScreen extends StatefulWidget {
  const ModelListScreen({super.key});

  @override
  State<ModelListScreen> createState() => _ModelListScreenState();
}

class _ModelListScreenState extends State<ModelListScreen> {
  final ModelManager _modelManager = ModelManager.instance;

  // 下载进度追踪 modelId -> progress(0.0~1.0)
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};
  final Map<String, StreamSubscription<double>> _downloadSubs = {};

  @override
  void dispose() {
    for (final sub in _downloadSubs.values) {
      sub.cancel();
    }
    super.dispose();
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
          const Text(
            '全部模型',
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
                    '下载模型需要稳定的网络连接，文件较大（1~3GB），建议在 WiFi 环境下下载。下载完成后可离线使用。',
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
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: current.capabilities.map((cap) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_capIcon(cap), color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      _capLabel(cap),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(AIModelInfo model) {
    final isCurrent = _modelManager.currentModelId == model.id;
    final isDownloading = _isDownloading[model.id] == true;
    final progress = _downloadProgress[model.id] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isCurrent
            ? Border.all(color: const Color(0xFF0EA5E9), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：图标 + 名称 + 状态
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF0EA5E9).withValues(alpha: 0.1)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    model.isBuiltIn
                        ? Icons.phone_android_rounded
                        : Icons.cloud_download_rounded,
                    color: isCurrent
                        ? const Color(0xFF0EA5E9)
                        : const Color(0xFF94A3B8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              model.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('使用中',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            )
                          else if (model.isBuiltIn)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('已安装',
                                  style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('可下载',
                                  style: TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        model.description,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 大小 + 能力标签
            Row(
              children: [
                _buildTag(Icons.storage_rounded, model.size,
                    const Color(0xFF64748B)),
                const SizedBox(width: 8),
                ...model.capabilities.map((cap) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildCapTag(cap),
                    )),
              ],
            ),

            // 下载进度条
            if (isDownloading) ...[
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '下载中 ${(progress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF0EA5E9)),
                      ),
                      GestureDetector(
                        onTap: () => _cancelDownload(model.id),
                        child: const Text('取消',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFFEF4444))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0EA5E9)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],

            // 操作按钮
            if (!isCurrent && !isDownloading) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: model.isBuiltIn
                    ? ElevatedButton(
                        onPressed: () => _switchModel(model),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('切换使用',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      )
                    : OutlinedButton.icon(
                        onPressed: model.url != null
                            ? () => _startDownload(model)
                            : null,
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('下载模型',
                            style: TextStyle(fontSize: 14)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0EA5E9),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(
                              color: Color(0xFF0EA5E9)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCapTag(String cap) {
    final color = _capColor(cap);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_capIcon(cap), size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            _capLabel(cap),
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _capColor(String cap) {
    switch (cap) {
      case 'text':
        return const Color(0xFF0EA5E9);
      case 'image':
        return const Color(0xFF8B5CF6);
      case 'audio':
        return const Color(0xFF10B981);
      case 'function_calling':
        return const Color(0xFFF59E0B);
      case 'thinking':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _capIcon(String cap) {
    switch (cap) {
      case 'text':
        return Icons.text_fields_rounded;
      case 'image':
        return Icons.image_rounded;
      case 'audio':
        return Icons.mic_rounded;
      case 'function_calling':
        return Icons.functions_rounded;
      case 'thinking':
        return Icons.psychology_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  String _capLabel(String cap) {
    switch (cap) {
      case 'text':
        return '文本';
      case 'image':
        return '图片';
      case 'audio':
        return '音频';
      case 'function_calling':
        return '函数调用';
      case 'thinking':
        return '深度思考';
      default:
        return cap;
    }
  }

  Future<void> _switchModel(AIModelInfo model) async {
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
                Text('正在切换模型...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await _modelManager.switchModel(model.id);
      if (mounted) {
        Navigator.pop(context);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已切换到 ${model.name}'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('切换失败：$e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _startDownload(AIModelInfo model) {
    if (model.url == null) return;

    setState(() {
      _isDownloading[model.id] = true;
      _downloadProgress[model.id] = 0.0;
    });

    final stream = _modelManager.downloadModel(model.id, model.url!);
    final sub = stream.listen(
      (progress) {
        if (mounted) {
          setState(() => _downloadProgress[model.id] = progress);
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isDownloading[model.id] = false;
            _downloadProgress.remove(model.id);
          });
          _downloadSubs.remove(model.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${model.name} 下载完成'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _isDownloading[model.id] = false;
            _downloadProgress.remove(model.id);
          });
          _downloadSubs.remove(model.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('下载失败：$e'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
    );
    _downloadSubs[model.id] = sub;
  }

  void _cancelDownload(String modelId) {
    _downloadSubs[modelId]?.cancel();
    _downloadSubs.remove(modelId);
    setState(() {
      _isDownloading[modelId] = false;
      _downloadProgress.remove(modelId);
    });
  }
}
