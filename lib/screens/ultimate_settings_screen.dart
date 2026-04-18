import 'package:flutter/material.dart';

class UltimateSettingsScreen extends StatefulWidget {
  const UltimateSettingsScreen({super.key});

  @override
  State<UltimateSettingsScreen> createState() => _UltimateSettingsScreenState();
}

class _UltimateSettingsScreenState extends State<UltimateSettingsScreen> {
  final TextEditingController _systemPromptController = TextEditingController();

  // 模型参数
  double _temperature = 1.0;
  int _topK = 64;
  double _topP = 0.95;
  int _maxTokens = 8192;

  // 语音设置
  bool _enableTts = true;
  bool _autoPlayTts = false;
  String _ttsLanguage = 'zh-CN';

  // 翻译设置
  bool _enableTranslation = false;
  String _translationMode = 'zh-en'; // zh-en, en-zh, auto

  // 显示设置
  bool _showMetrics = true;
  bool _showTimestamp = true;

  @override
  void initState() {
    super.initState();
    _systemPromptController.text = '你是一个有帮助的AI助手。';
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
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
            title: '语音设置',
            children: [
              _buildSwitch(
                label: '启用语音播报',
                value: _enableTts,
                onChanged: (value) => setState(() => _enableTts = value),
                description: '允许 AI 回复语音播报',
              ),
              _buildSwitch(
                label: '自动播报',
                value: _autoPlayTts,
                onChanged: (value) => setState(() => _autoPlayTts = value),
                description: 'AI 回复后自动播报',
              ),
              _buildDropdown(
                label: '播报语言',
                value: _ttsLanguage,
                items: const [
                  {'value': 'zh-CN', 'label': '中文'},
                  {'value': 'en-US', 'label': 'English'},
                ],
                onChanged: (value) => setState(() => _ttsLanguage = value!),
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
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'systemPrompt': _systemPromptController.text,
                'temperature': _temperature,
                'topK': _topK,
                'topP': _topP,
                'maxTokens': _maxTokens,
                'enableTts': _enableTts,
                'autoPlayTts': _autoPlayTts,
                'ttsLanguage': _ttsLanguage,
                'enableTranslation': _enableTranslation,
                'translationMode': _translationMode,
                'showMetrics': _showMetrics,
                'showTimestamp': _showTimestamp,
              });
            },
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
