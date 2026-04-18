import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _temperature = 1.0;
  int _topK = 64;
  double _topP = 0.95;
  int _maxTokens = 8192;
  bool _enableTts = true;
  bool _autoPlayTts = false;

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
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '关于',
            children: [
              _buildInfoItem('版本', '1.0.0'),
              _buildInfoItem('模型', 'Gemma 4 E2B (2B)'),
              _buildInfoItem('运行模式', '端侧离线'),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // 保存设置
              Navigator.pop(context, {
                'temperature': _temperature,
                'topK': _topK,
                'topP': _topP,
                'maxTokens': _maxTokens,
                'enableTts': _enableTts,
                'autoPlayTts': _autoPlayTts,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
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
                  color: Color(0xFF667EEA),
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
            activeColor: const Color(0xFF667EEA),
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
            activeTrackColor: const Color(0xFF667EEA),
            onChanged: onChanged,
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
