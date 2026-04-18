import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static SettingsService get instance => _instance;

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 系统提示词
  Future<void> saveSystemPrompt(String prompt) async {
    await _prefs?.setString('system_prompt', prompt);
  }

  String loadSystemPrompt() {
    return _prefs?.getString('system_prompt') ?? '你是一个有帮助的AI助手。';
  }

  // 模型参数
  Future<void> saveModelParams({
    required double temperature,
    required int topK,
    required double topP,
    required int maxTokens,
  }) async {
    await _prefs?.setDouble('temperature', temperature);
    await _prefs?.setInt('top_k', topK);
    await _prefs?.setDouble('top_p', topP);
    await _prefs?.setInt('max_tokens', maxTokens);
  }

  Map<String, dynamic> loadModelParams() {
    return {
      'temperature': _prefs?.getDouble('temperature') ?? 1.0,
      'topK': _prefs?.getInt('top_k') ?? 64,
      'topP': _prefs?.getDouble('top_p') ?? 0.95,
      'maxTokens': _prefs?.getInt('max_tokens') ?? 8192,
    };
  }

  // TTS 设置
  Future<void> saveTtsSettings({
    required bool enableTts,
    required bool autoPlay,
    required String language,
  }) async {
    await _prefs?.setBool('enable_tts', enableTts);
    await _prefs?.setBool('auto_play_tts', autoPlay);
    await _prefs?.setString('tts_language', language);
  }

  Map<String, dynamic> loadTtsSettings() {
    return {
      'enableTts': _prefs?.getBool('enable_tts') ?? true,
      'autoPlay': _prefs?.getBool('auto_play_tts') ?? false,
      'language': _prefs?.getString('tts_language') ?? 'zh-CN',
    };
  }

  // 翻译设置
  Future<void> saveTranslationSettings({
    required bool enable,
    required String mode,
  }) async {
    await _prefs?.setBool('enable_translation', enable);
    await _prefs?.setString('translation_mode', mode);
  }

  Map<String, dynamic> loadTranslationSettings() {
    return {
      'enable': _prefs?.getBool('enable_translation') ?? false,
      'mode': _prefs?.getString('translation_mode') ?? 'auto',
    };
  }

  // 显示设置
  Future<void> saveDisplaySettings({
    required bool showMetrics,
    required bool showTimestamp,
  }) async {
    await _prefs?.setBool('show_metrics', showMetrics);
    await _prefs?.setBool('show_timestamp', showTimestamp);
  }

  Map<String, dynamic> loadDisplaySettings() {
    return {
      'showMetrics': _prefs?.getBool('show_metrics') ?? true,
      'showTimestamp': _prefs?.getBool('show_timestamp') ?? true,
    };
  }

  // 清除所有设置
  Future<void> clearAllSettings() async {
    await _prefs?.clear();
  }

  // 重置为默认值
  Future<void> resetToDefaults() async {
    await saveSystemPrompt('你是一个有帮助的AI助手。');
    await saveModelParams(
      temperature: 1.0,
      topK: 64,
      topP: 0.95,
      maxTokens: 8192,
    );
    await saveTtsSettings(
      enableTts: true,
      autoPlay: false,
      language: 'zh-CN',
    );
    await saveTranslationSettings(
      enable: false,
      mode: 'auto',
    );
    await saveDisplaySettings(
      showMetrics: true,
      showTimestamp: true,
    );
  }
}
