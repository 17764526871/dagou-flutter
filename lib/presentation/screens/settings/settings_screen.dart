import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../../../services/storage/settings_service.dart';
import '../../../services/storage/cache_service.dart';
import '../../../services/ai/model_manager.dart';
import '../models/model_list_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _systemPromptController = TextEditingController();

  // 模型参数
  double _temperature = 1.0;
  int _topK = 64;
  double _topP = 0.95;
  int _maxTokens = 8192;

  // 翻译设置
  bool _enableTranslation = false;
  String _translationMode = 'zh-en'; // zh-en, en-zh, auto

  // 显示设置
  bool _showMetrics = true;
  bool _showTimestamp = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await SettingsService.instance.initialize();
    setState(() {
      _systemPromptController.text = SettingsService.instance.loadSystemPrompt();

      final modelParams = SettingsService.instance.loadModelParams();
      _temperature = modelParams['temperature'];
      _topK = modelParams['topK'];
      _topP = modelParams['topP'];
      _maxTokens = modelParams['maxTokens'];

      final translationSettings = SettingsService.instance.loadTranslationSettings();
      _enableTranslation = translationSettings['enable'];
      _translationMode = translationSettings['mode'];

      final displaySettings = SettingsService.instance.loadDisplaySettings();
      _showMetrics = displaySettings['showMetrics'];
      _showTimestamp = displaySettings['showTimestamp'];
    });
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    super.dispose();
  }

  void _showTopSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? const Color(0xFF48BB78),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).size.height - 100,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    await SettingsService.instance.saveSystemPrompt(_systemPromptController.text);
    await SettingsService.instance.saveModelParams(
      temperature: _temperature,
      topK: _topK,
      topP: _topP,
      maxTokens: _maxTokens,
    );
    await SettingsService.instance.saveTranslationSettings(
      enable: _enableTranslation,
      mode: _translationMode,
    );
    await SettingsService.instance.saveDisplaySettings(
      showMetrics: _showMetrics,
      showTimestamp: _showTimestamp,
    );

    if (mounted) {
      _showTopSnackBar('设置已保存');
      Navigator.pop(context);
    }
  }

  Future<void> _resetSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要重置所有设置为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(color: Color(0xFFF56565))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SettingsService.instance.resetToDefaults();
      await _loadSettings();
      if (mounted) {
        _showTopSnackBar('设置已重置');
      }
    }
  }

  Future<void> _clearCache() async {
    final cacheSize = await CacheService.instance.getCacheSize();
    final sizeStr = CacheService.formatBytes(cacheSize);

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: Text('当前缓存大小：$sizeStr\n\n确定要清除所有缓存吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(color: Color(0xFFF56565))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await CacheService.instance.clearAllCache();
      if (mounted) {
        _showTopSnackBar(
          success ? '缓存已清除' : '清除缓存失败',
          backgroundColor: success ? const Color(0xFF48BB78) : const Color(0xFFF56565),
        );
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '设置',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: '模型管理',
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.memory,
                    color: Color(0xFF0EA5E9),
                  ),
                ),
                title: const Text(
                  '模型列表',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  '查看和切换 AI 模型',
                  style: TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ModelListScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: '系统提示词',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '自定义 AI 的行为和角色',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF718096),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _systemPromptController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: '输入系统提示词...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0EA5E9),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7FAFC),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildPresetChip('默认助手', '你是一个有帮助的AI助手。'),
                        _buildPresetChip('翻译专家', '你是一个专业的翻译专家，擅长中英互译。'),
                        _buildPresetChip('代码助手', '你是一个编程专家，擅长解释代码和提供编程建议。'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: '模型参数',
            children: [
              _buildSlider(
                label: 'Temperature',
                value: _temperature,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                onChanged: (value) => setState(() => _temperature = value),
                description: '控制输出的随机性，值越高越随机',
              ),
              _buildSlider(
                label: 'Top K',
                value: _topK.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                onChanged: (value) => setState(() => _topK = value.toInt()),
                description: '限制每步采样的词汇数量',
              ),
              _buildSlider(
                label: 'Top P',
                value: _topP,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                onChanged: (value) => setState(() => _topP = value),
                description: '核采样概率阈值',
              ),
              _buildSlider(
                label: 'Max Tokens',
                value: _maxTokens.toDouble(),
                min: 512,
                max: 8192,
                divisions: 15,
                onChanged: (value) => setState(() => _maxTokens = value.toInt()),
                description: '最大生成长度',
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: '高级设置',
            children: [
              _buildDropdown(
                label: '推理后端',
                value: ModelManager.instance.currentBackend == PreferredBackend.gpu ? 'gpu' : 'cpu',
                items: const [
                  {'value': 'gpu', 'label': 'GPU（推荐）'},
                  {'value': 'cpu', 'label': 'CPU'},
                ],
                onChanged: (value) async {
                  final backend = value == 'gpu' ? PreferredBackend.gpu : PreferredBackend.cpu;
                  final currentModelId = ModelManager.instance.currentModelId;
                  if (currentModelId != null) {
                    await ModelManager.instance.switchModel(currentModelId, backend: backend);
                    setState(() {});
                    if (mounted) {
                      _showTopSnackBar('已切换到 ${value == 'gpu' ? 'GPU' : 'CPU'} 后端');
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: '翻译功能',
            children: [
              _buildSwitch(
                label: '启用翻译模式',
                value: _enableTranslation,
                onChanged: (value) => setState(() => _enableTranslation = value),
                description: '自动识别并翻译输入内容',
              ),
              if (_enableTranslation)
                _buildDropdown(
                  label: '翻译方向',
                  value: _translationMode,
                  items: const [
                    {'value': 'zh-en', 'label': '中文 → English'},
                    {'value': 'en-zh', 'label': 'English → 中文'},
                    {'value': 'auto', 'label': '自动检测'},
                  ],
                  onChanged: (value) => setState(() => _translationMode = value!),
                ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: '显示设置',
            children: [
              _buildSwitch(
                label: '显示性能指标',
                value: _showMetrics,
                onChanged: (value) => setState(() => _showMetrics = value),
                description: '显示推理速度、Token 数等信息',
              ),
              _buildSwitch(
                label: '显示时间戳',
                value: _showTimestamp,
                onChanged: (value) => setState(() => _showTimestamp = value),
                description: '在消息下方显示时间',
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: '关于',
            children: [
              _buildInfoItem('版本', '2.0.0'),
              _buildInfoItem('模型', 'Gemma 4 E2B (2B)'),
              _buildInfoItem('运行模式', '端侧离线'),
            ],
          ),
          const SizedBox(height: 24),

          // 保存按钮
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '保存设置',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),

          // 重置按钮
          OutlinedButton(
            onPressed: _resetSettings,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF718096),
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '重置为默认设置',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),

          // 清除缓存按钮
          OutlinedButton(
            onPressed: _clearCache,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF56565),
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFFF56565)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '清除缓存',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, String prompt) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _systemPromptController.text = prompt;
        });
      },
      backgroundColor: const Color(0xFFF7FAFC),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: Color(0xFF0EA5E9),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                value.toStringAsFixed(value < 10 ? 2 : 0),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0EA5E9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: const Color(0xFF0EA5E9),
            onChanged: onChanged,
          ),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: const Color(0xFF0EA5E9),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3748),
            ),
          ),
          DropdownButton<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item['value'],
                child: Text(item['label']!),
              );
            }).toList(),
            onChanged: onChanged,
            underline: Container(),
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF0EA5E9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF718096),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }
}
