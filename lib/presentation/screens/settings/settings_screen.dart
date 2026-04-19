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

  double _temperature = 1.0;
  int _topK = 64;
  double _topP = 0.95;
  int _maxTokens = 8192;
  bool _showMetrics = true;
  bool _showTimestamp = true;

  // 预设系统提示词
  static const List<Map<String, String>> _presets = [
    {
      'label': '🤖 智能助手',
      'prompt':
          '你是 DG AI，一个聪明、友善、有温度的 AI 助手。你说话自然流畅，偶尔会用 emoji 增加亲切感。你会认真理解用户的问题，给出清晰、实用的回答。遇到不确定的事情会坦诚说明，不会胡编乱造。',
    },
    {
      'label': '💻 代码专家',
      'prompt':
          '你是一位经验丰富的全栈工程师，精通多种编程语言和框架。你擅长代码审查、调试、架构设计和性能优化。回答时会给出具体的代码示例，并解释关键思路。说话简洁专业，直击要点。',
    },
    {
      'label': '📚 学习导师',
      'prompt':
          '你是一位耐心的学习导师，善于把复杂的概念用简单易懂的方式解释清楚。你会用类比、举例和循序渐进的方式帮助用户理解知识。鼓励用户提问，营造轻松的学习氛围。',
    },
    {
      'label': '✍️ 写作助手',
      'prompt':
          '你是一位专业的写作助手，擅长各类文体的写作和润色。你能帮助用户改善文章结构、优化措辞、提升表达效果。对于创意写作，你会发挥想象力；对于正式文书，你会保持严谨规范。',
    },
    {
      'label': '🧠 深度思考',
      'prompt':
          '你是一个善于深度思考的 AI。面对问题时，你会从多个角度分析，考虑不同观点，权衡利弊，给出有深度的见解。你不会给出简单的答案，而是帮助用户建立更全面的认知。',
    },
    {
      'label': '😄 轻松聊天',
      'prompt':
          '你是一个幽默风趣的聊天伙伴！你喜欢用轻松愉快的方式交流，偶尔开个小玩笑，让对话充满乐趣。你关心用户的感受，善于倾听，是个很好的聊天朋友。',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await SettingsService.instance.initialize();
    if (!mounted) return;
    setState(() {
      _systemPromptController.text = SettingsService.instance.loadSystemPrompt();
      final modelParams = SettingsService.instance.loadModelParams();
      _temperature = modelParams['temperature'];
      _topK = modelParams['topK'];
      _topP = modelParams['topP'];
      _maxTokens = modelParams['maxTokens'];
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

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    await SettingsService.instance.saveDisplaySettings(
      showMetrics: _showMetrics,
      showTimestamp: _showTimestamp,
    );
    if (mounted) {
      _showSnack('设置已保存');
      Navigator.pop(context);
    }
  }

  Future<void> _resetSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('重置设置'),
        content: const Text('确定要重置所有设置为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SettingsService.instance.resetToDefaults();
      await _loadSettings();
      if (mounted) _showSnack('设置已重置');
    }
  }

  Future<void> _clearCache() async {
    final cacheSize = await CacheService.instance.getCacheSize();
    final sizeStr = CacheService.formatBytes(cacheSize);
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('清除缓存'),
        content: Text('当前缓存：$sizeStr\n\n确定要清除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清除',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await CacheService.instance.clearAllCache();
      if (mounted) {
        _showSnack(success ? '缓存已清除' : '清除失败', isError: !success);
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
          '设置',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              '保存',
              style: TextStyle(
                color: Color(0xFF0EA5E9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // 模型管理
          _buildSection(
            title: '模型管理',
            icon: Icons.memory_rounded,
            children: [
              _buildNavTile(
                icon: Icons.layers_rounded,
                label: '模型列表',
                subtitle: '查看和切换 AI 模型',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ModelListScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 系统提示词
          _buildSection(
            title: '系统提示词',
            icon: Icons.psychology_rounded,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 4, 14, 0),
                child: Text(
                  '定义 AI 的角色和行为风格',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),
              // 预设快捷选择
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((preset) {
                    final isActive =
                        _systemPromptController.text == preset['prompt'];
                    return GestureDetector(
                      onTap: () => setState(() {
                        _systemPromptController.text = preset['prompt']!;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF0EA5E9)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: isActive
                              ? null
                              : Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          preset['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: TextField(
                  controller: _systemPromptController,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '输入自定义系统提示词...',
                    hintStyle: const TextStyle(
                        color: Color(0xFFCBD5E1), fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF0EA5E9), width: 1.5),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF1E293B), height: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 模型参数
          _buildSection(
            title: '模型参数',
            icon: Icons.tune_rounded,
            children: [
              _buildSlider(
                label: 'Temperature',
                value: _temperature,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                onChanged: (v) => setState(() => _temperature = v),
                description: '值越高输出越随机，越低越保守',
              ),
              _buildSlider(
                label: 'Top K',
                value: _topK.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                onChanged: (v) => setState(() => _topK = v.toInt()),
                description: '每步采样的候选词数量',
              ),
              _buildSlider(
                label: 'Top P',
                value: _topP,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                onChanged: (v) => setState(() => _topP = v),
                description: '核采样概率阈值',
              ),
              _buildSlider(
                label: 'Max Tokens',
                value: _maxTokens.toDouble(),
                min: 512,
                max: 8192,
                divisions: 15,
                onChanged: (v) => setState(() => _maxTokens = v.toInt()),
                description: '最大生成 Token 数',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 高级设置
          _buildSection(
            title: '高级设置',
            icon: Icons.settings_rounded,
            children: [
              _buildDropdown(
                label: '推理后端',
                value: ModelManager.instance.currentBackend ==
                        PreferredBackend.gpu
                    ? 'gpu'
                    : 'cpu',
                items: const [
                  {'value': 'gpu', 'label': 'GPU（推荐）'},
                  {'value': 'cpu', 'label': 'CPU'},
                ],
                onChanged: (value) async {
                  final backend = value == 'gpu'
                      ? PreferredBackend.gpu
                      : PreferredBackend.cpu;
                  final id = ModelManager.instance.currentModelId;
                  if (id != null) {
                    await ModelManager.instance
                        .switchModel(id, backend: backend);
                    if (mounted) setState(() {});
                    if (mounted) {
                      _showSnack(
                          '已切换到 ${value == 'gpu' ? 'GPU' : 'CPU'} 后端');
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 显示设置
          _buildSection(
            title: '显示设置',
            icon: Icons.visibility_rounded,
            children: [
              _buildSwitch(
                label: '显示性能指标',
                value: _showMetrics,
                onChanged: (v) => setState(() => _showMetrics = v),
                description: '推理速度、Token 数等',
              ),
              _buildSwitch(
                label: '显示时间戳',
                value: _showTimestamp,
                onChanged: (v) => setState(() => _showTimestamp = v),
                description: '消息发送时间',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 关于
          _buildSection(
            title: '关于',
            icon: Icons.info_outline_rounded,
            children: [
              _buildInfoRow('版本', 'v1.1.1'),
              _buildInfoRow('模型', 'Gemma 4 E2B (2B)'),
              _buildInfoRow('运行模式', '端侧离线'),
            ],
          ),
          const SizedBox(height: 20),

          // 操作按钮
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('保存设置',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _resetSettings,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('重置为默认',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _clearCache,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFEF4444)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('清除缓存',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF0EA5E9)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 14, endIndent: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF0EA5E9)),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Color(0xFFCBD5E1)),
      onTap: onTap,
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value.toStringAsFixed(value < 10 ? 2 : 0),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0EA5E9)),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: const Color(0xFF0EA5E9),
              inactiveColor: const Color(0xFFE2E8F0),
              onChanged: onChanged,
            ),
          ),
          Text(description,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          DropdownButton<String>(
            value: value,
            items: items
                .map((item) => DropdownMenuItem<String>(
                      value: item['value'],
                      child: Text(item['label']!),
                    ))
                .toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0EA5E9),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF64748B))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
