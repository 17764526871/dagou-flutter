import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/common/top_notification.dart';
import 'dart:async';
import '../../../services/ai/ai_service.dart';

/// 翻译页面 —— 独立功能，不影响聊天上下文
/// 每次翻译都使用独立的临时会话，完全隔离
class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _outputScrollController = ScrollController();

  // 语言列表
  static const List<Map<String, String>> _languages = [
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇧🇷'},
  ];

  String _sourceLang = 'zh';
  String _targetLang = 'en';

  String _outputText = '';
  bool _isTranslating = false;
  StreamSubscription<String>? _streamSub;

  // 历史记录
  final List<_TranslateRecord> _history = [];

  @override
  void dispose() {
    _streamSub?.cancel();
    _inputController.dispose();
    _outputScrollController.dispose();
    super.dispose();
  }

  String _getLangName(String code) {
    return _languages.firstWhere((l) => l['code'] == code,
        orElse: () => {'name': code})['name']!;
  }

  String _getLangFlag(String code) {
    return _languages.firstWhere((l) => l['code'] == code,
        orElse: () => {'flag': '🌐'})['flag']!;
  }

  String _buildTranslatePrompt() {
    final srcName = _getLangName(_sourceLang);
    final tgtName = _getLangName(_targetLang);
    if (_sourceLang == 'auto') {
      return '你是专业翻译。请将以下文本翻译成$tgtName，只返回翻译结果，不要解释，不要添加任何额外内容：';
    }
    return '你是专业翻译。请将以下$srcName文本翻译成$tgtName，只返回翻译结果，不要解释，不要添加任何额外内容：';
  }

  Future<void> _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    await _streamSub?.cancel();
    _streamSub = null;

    setState(() {
      _isTranslating = true;
      _outputText = '';
    });

    try {
      final prompt = _buildTranslatePrompt();
      final fullPrompt = '$prompt\n\n$text';

      // 使用独立的翻译提示词，每次都强制新会话
      final stream = AIService.instance.sendMessageStream(
        fullPrompt,
        // 翻译用固定系统提示词，与聊天完全隔离
        systemPrompt: '你是一个专业翻译引擎，只输出翻译结果，绝不输出其他内容。',
        temperature: 0.3,
        topK: 40,
        topP: 0.9,
        maxTokens: 2048,
      );

      _streamSub = stream.listen(
        (chunk) {
          if (!mounted) return;
          setState(() => _outputText += chunk);
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _isTranslating = false);
          _streamSub = null;
          // 保存到历史
          if (_outputText.isNotEmpty) {
            setState(() {
              _history.insert(
                0,
                _TranslateRecord(
                  sourceText: text,
                  targetText: _outputText,
                  sourceLang: _sourceLang,
                  targetLang: _targetLang,
                  time: DateTime.now(),
                ),
              );
              if (_history.length > 20) _history.removeLast();
            });
          }
          // 翻译完成后重置AI会话，避免污染聊天上下文
          AIService.instance.markNeedsReset();
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _outputText = '翻译失败：$e';
            _isTranslating = false;
          });
          _streamSub = null;
          AIService.instance.markNeedsReset();
        },
        cancelOnError: true,
      );
    } catch (e) {
      setState(() {
        _outputText = '翻译失败：$e';
        _isTranslating = false;
      });
    }
  }

  void _swapLanguages() {
    if (_sourceLang == 'auto') return;
    setState(() {
      final tmp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = tmp;
      // 互换文本
      final tmpText = _inputController.text;
      _inputController.text = _outputText;
      _outputText = tmpText;
    });
  }

  void _copyOutput() {
    if (_outputText.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _outputText));
    TopNotification.show(
      context,
      '已复制翻译结果',
      type: NotificationType.success,
    );
  }

  void _clearAll() {
    _streamSub?.cancel();
    _streamSub = null;
    setState(() {
      _inputController.clear();
      _outputText = '';
      _isTranslating = false;
    });
    AIService.instance.markNeedsReset();
  }

  Future<void> _showLangPicker({required bool isSource}) async {
    final langs = isSource
        ? [
            {'code': 'auto', 'name': '自动检测', 'flag': '🌐'},
            ..._languages,
          ]
        : _languages;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LangPickerSheet(
        languages: langs,
        selected: isSource ? _sourceLang : _targetLang,
      ),
    );

    if (selected != null) {
      setState(() {
        if (isSource) {
          _sourceLang = selected;
        } else {
          _targetLang = selected;
        }
      });
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
          onPressed: () {
            // 离开翻译页时重置AI会话，确保聊天不受影响
            AIService.instance.markNeedsReset();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '翻译',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFF64748B)),
            onPressed: _showHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // 语言选择栏
          _buildLangBar(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // 输入区
                  _buildInputCard(),
                  const SizedBox(height: 10),
                  // 翻译按钮
                  _buildTranslateButton(),
                  const SizedBox(height: 10),
                  // 输出区
                  if (_outputText.isNotEmpty || _isTranslating)
                    _buildOutputCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EDF2))),
      ),
      child: Row(
        children: [
          // 源语言
          Expanded(
            child: GestureDetector(
              onTap: () => _showLangPicker(isSource: true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_getLangFlag(_sourceLang),
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      _sourceLang == 'auto'
                          ? '自动检测'
                          : _getLangName(_sourceLang),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more_rounded,
                        size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          ),

          // 互换按钮
          GestureDetector(
            onTap: _swapLanguages,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.swap_horiz_rounded,
                  color: Color(0xFF0EA5E9), size: 20),
            ),
          ),

          // 目标语言
          Expanded(
            child: GestureDetector(
              onTap: () => _showLangPicker(isSource: false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_getLangFlag(_targetLang),
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      _getLangName(_targetLang),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0EA5E9),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more_rounded,
                        size: 16, color: Color(0xFF0EA5E9)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                Text(
                  _sourceLang == 'auto'
                      ? '输入文本'
                      : _getLangName(_sourceLang),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_inputController.text.isNotEmpty)
                  GestureDetector(
                    onTap: _clearAll,
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
          TextField(
            controller: _inputController,
            maxLines: 5,
            minLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: '输入要翻译的文本...',
              hintStyle: TextStyle(color: Color(0xFFCBD5E1), fontSize: 15),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1E293B),
              height: 1.5,
            ),
          ),
          // 字数统计
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                Text(
                  '${_inputController.text.length} 字',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFFCBD5E1)),
                ),
                const Spacer(),
                // 粘贴按钮
                GestureDetector(
                  onTap: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _inputController.text = data!.text!;
                      setState(() {});
                    }
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.content_paste_rounded,
                          size: 14, color: Color(0xFF94A3B8)),
                      SizedBox(width: 3),
                      Text('粘贴',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isTranslating ? null : _translate,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0EA5E9),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isTranslating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('翻译中...', style: TextStyle(fontSize: 15)),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.translate_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('翻译',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }

  Widget _buildOutputCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                Text(
                  _getLangName(_targetLang),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0EA5E9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (!_isTranslating && _outputText.isNotEmpty) ...[
                  GestureDetector(
                    onTap: _copyOutput,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded,
                            size: 14, color: Color(0xFF94A3B8)),
                        SizedBox(width: 3),
                        Text('复制',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: _isTranslating && _outputText.isEmpty
                ? const _TranslatingDots()
                : SelectableText(
                    _outputText,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                      height: 1.6,
                    ),
                  ),
          ),
          // 流式输出时的光标
          if (_isTranslating && _outputText.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 14, bottom: 10),
              child: _BlinkingCursor(),
            ),
          if (!_isTranslating && _outputText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                '${_outputText.length} 字',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFFCBD5E1)),
              ),
            ),
        ],
      ),
    );
  }

  void _showHistory() {
    if (_history.isEmpty) {
      TopNotification.show(
        context,
        '暂无翻译历史',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('翻译历史',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = _history[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        r.sourceText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        r.targetText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF0EA5E9)),
                      ),
                      trailing: Text(
                        '${r.sourceLang}→${r.targetLang}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _inputController.text = r.sourceText;
                        setState(() {
                          _outputText = r.targetText;
                          _sourceLang = r.sourceLang;
                          _targetLang = r.targetLang;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 语言选择底部弹窗 ──────────────────────────────────────────────────
class _LangPickerSheet extends StatelessWidget {
  final List<Map<String, String>> languages;
  final String selected;

  const _LangPickerSheet({
    required this.languages,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text('选择语言',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...languages.map((lang) {
            final isSelected = lang['code'] == selected;
            return ListTile(
              leading: Text(lang['flag']!,
                  style: const TextStyle(fontSize: 22)),
              title: Text(lang['name']!,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? const Color(0xFF0EA5E9)
                        : const Color(0xFF1E293B),
                  )),
              trailing: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Color(0xFF0EA5E9))
                  : null,
              onTap: () => Navigator.pop(context, lang['code']),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── 翻译中动画 ────────────────────────────────────────────────────────
class _TranslatingDots extends StatefulWidget {
  const _TranslatingDots();

  @override
  State<_TranslatingDots> createState() => _TranslatingDotsState();
}

class _TranslatingDotsState extends State<_TranslatingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      );
    });
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -6).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _animations[i].value),
            child: Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: const BoxDecoration(
                color: Color(0xFF0EA5E9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── 闪烁光标 ─────────────────────────────────────────────────────────
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: _controller.value,
        child: Container(
          width: 2,
          height: 16,
          color: const Color(0xFF0EA5E9),
        ),
      ),
    );
  }
}

// ── 翻译记录数据类 ────────────────────────────────────────────────────
class _TranslateRecord {
  final String sourceText;
  final String targetText;
  final String sourceLang;
  final String targetLang;
  final DateTime time;

  const _TranslateRecord({
    required this.sourceText,
    required this.targetText,
    required this.sourceLang,
    required this.targetLang,
    required this.time,
  });
}
