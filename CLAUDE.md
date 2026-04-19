# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Dagou AI 是一个完全运行在移动设备上的端侧 AI 助手应用，基于 Google Gemma 4 E2B (2B 参数) 多模态模型。应用内置 AI 模型（约 2.4GB），无需网络连接即可使用，所有推理在设备本地进行。

**核心特性**：
- 端侧多模态 AI（文本、图片输入）
- 完全离线运行，保护隐私
- 流式输出，实时响应
- 支持翻译功能（中英互译）
- 实时性能监控（tokens/秒、延迟等）
- LoRA 微调支持
- **多种模型获取方式**：内置、网络下载、局域网下载、本地文件选择
- **外部存储支持**：模型保存在应用外部，卸载不丢失

## 开发环境

- **Flutter**: 3.41.7+
- **Dart**: 3.11.5+
- **Android**: API 26+ (Android 8.0+)
- **核心依赖**: flutter_gemma ^0.13.5

## 常用命令

### 运行和构建
```bash
# 运行应用（推荐 Release 模式以获得更好性能）
flutter run --release

# Debug 模式
flutter run

# 构建 APK
flutter build apk --release
flutter build apk --debug

# 安装到设备
flutter install -d <device-id>
adb -s <device-id> install -r build/app/outputs/flutter-apk/app-release.apk
```

### 代码质量
```bash
# 代码格式化
flutter format .

# 代码分析
flutter analyze

# 运行测试
flutter test
```

### 依赖管理
```bash
# 获取依赖
flutter pub get

# 清理构建缓存
flutter clean
```

## 架构设计

项目采用 **Clean Architecture** 分层架构：

### 目录结构
```
lib/
├── main.dart                    # 应用入口，初始化 FlutterGemma
├── core/                        # 核心基础设施
│   ├── constants/               # 常量定义
│   ├── theme/                   # 主题配置（Material Design 3）
│   └── utils/                   # 工具类
├── data/                        # 数据层
│   ├── models/                  # 数据模型
│   │   ├── message.dart         # 消息模型（文本/图片/音频）
│   │   └── ai_model_info.dart   # AI 模型信息
│   └── repositories/            # 数据仓库实现
├── domain/                      # 业务逻辑层
│   ├── entities/                # 业务实体
│   └── usecases/                # 用例
├── presentation/                # 表现层
│   ├── screens/                 # 界面页面
│   │   ├── loading/             # 加载界面（模型初始化）
│   │   ├── chat/                # 聊天界面（主界面）
│   │   ├── settings/            # 设置界面
│   │   └── models/              # 模型管理界面
│   └── widgets/                 # UI 组件
│       ├── chat/                # 聊天相关组件
│       │   ├── message_bubble.dart      # 消息气泡
│       │   ├── input_bar.dart           # 输入栏（微信风格）
│       │   └── audio_player_widget.dart # 音频播放器
│       └── common/              # 通用组件
└── services/                    # 服务层（核心业务逻辑）
    ├── ai/                      # AI 服务
    │   ├── ai_service.dart      # AI 推理服务（单例）
    │   ├── model_manager.dart   # 模型管理器
    │   └── lora_service.dart    # LoRA 微调服务
    ├── audio/                   # 音频服务
    │   └── audio_service.dart   # 录音服务
    └── storage/                 # 存储服务
        ├── settings_service.dart # 设置持久化（SharedPreferences）
        └── cache_service.dart    # 缓存管理
```

### 核心服务说明

#### AIService (lib/services/ai/ai_service.dart)
- **单例模式**，管理 Gemma 4 E2B 模型的生命周期
- 负责模型初始化、推理、流式输出
- 支持文本和图片输入（多模态）
- 可配置参数：temperature、topK、topP、maxTokens
- 支持系统提示词自定义

#### ModelManager (lib/services/ai/model_manager.dart)
- 管理多个 AI 模型的切换和配置
- 支持 GPU/CPU 后端切换
- 处理模型加载和卸载
- **支持外部存储路径**（用户选择的文件）
- 模型加载优先级：外部路径 > 内置模型 > 网络下载

#### FilePickerService (lib/services/storage/file_picker_service.dart)
- 文件选择服务，支持选择 .task 和 .litertlm 文件
- 用于从手机存储导入模型

#### ModelDownloadService (lib/services/network/model_download_service.dart)
- 局域网模型下载服务
- 支持从 NAS 或本地 HTTP 服务器下载
- 模型保存在应用外部存储，卸载不丢失

#### SettingsService (lib/services/storage/settings_service.dart)
- 使用 SharedPreferences 持久化用户设置
- 保存模型参数、系统提示词、翻译模式等配置

### 数据流
```
用户输入 → InputBar (Widget)
         ↓
    ChatScreen (State Management)
         ↓
    AIService.sendMessage() / sendMultimodalMessage()
         ↓
    FlutterGemma (Native Bridge)
         ↓
    Gemma 4 E2B Model (On-Device)
         ↓
    Stream<String> (流式输出)
         ↓
    MessageBubble (Widget) - 实时显示
```

## 关键技术点

### 1. 模型初始化流程
- 应用启动时在 `LoadingScreen` 显示加载进度
- `AIService.initialize()` 从 assets 加载内置模型（2.4GB）
- 首次加载需要 10-15 秒，进度条实时显示
- 初始化完成后跳转到 `ChatScreen`

### 2. 流式输出实现
- 使用 `Stream<String>` 接收模型输出
- `StreamBuilder` 实时更新 UI
- 支持停止生成功能（`stopGeneration()`）

### 3. 多模态输入
- 文本：直接通过 `sendMessage()`
- 图片：使用 `image_picker` 选择，通过 `sendMultimodalMessage()` 发送
- 图片会转换为 `Uint8List` 传递给模型

### 4. 性能监控
- 实时计算 tokens/秒
- 统计生成的 token 数量和字符数
- 显示推理时长和平均延迟

### 5. ProGuard 配置
Release 构建启用代码混淆，必须保留以下类：
```proguard
-keep class com.google.mediapipe.** { *; }
-keep class org.tensorflow.** { *; }
-keep class dev.flutterberlin.flutter_gemma.** { *; }
```

## 开发注意事项

### 修改 AI 相关代码
- AIService 是单例，修改时注意线程安全
- 模型参数变更需要调用 `updateModelParameters()`
- 系统提示词变更需要重新创建 chat 实例

### 修改 UI 组件
- 遵循 Material Design 3 设计规范
- 主题色：蓝绿渐变 (#0EA5E9 → #06B6D4)
- 使用 `const` 构造函数优化性能
- 避免在 build 方法中创建大对象

### 添加新功能
- 遵循 Clean Architecture 分层
- 新的业务逻辑放在 services/ 或 domain/usecases/
- UI 组件放在 presentation/widgets/
- 数据模型放在 data/models/

### 性能优化
- 使用 `--release` 模式测试性能
- 大图片需要压缩后再发送给模型
- 避免频繁重建 Widget，使用 `const` 和 `key`
- 长列表使用 `ListView.builder` 而非 `ListView`

### 测试
- 必须在真实 Android 设备上测试（模拟器不支持 MediaPipe）
- 推荐使用 Android 8.0+ 设备，至少 4GB RAM
- 测试时监控内存占用（约 1.5-2.5GB）

## 常见问题

### 模型加载失败
- 检查 `assets/models/gemma-4-E2B-it.litertlm` 是否存在
- 确认文件大小约 2.4GB
- 查看 `pubspec.yaml` 中 assets 配置是否正确

### 推理速度慢
- 确保使用 `--release` 模式
- 检查是否使用 GPU 后端（`PreferredBackend.gpu`）
- 降低 `maxTokens` 参数
- 检查设备性能和内存

### 依赖冲突
- `record_linux: 1.3.0` 在 `dependency_overrides` 中固定版本
- 如遇到其他冲突，先运行 `flutter pub upgrade`

## 相关文档

- [LoRA 微调指南](docs/lora_finetuning_guide.md) - 包含数据准备、训练、权重导出
- [Android 部署指南](docs/Android部署指南.md)
- [项目技术总结](docs/项目技术总结.md)
- [使用说明](docs/使用说明.md)
- [模型管理使用指南](docs/模型管理使用指南.md) - 局域网下载、文件选择等功能

## 模型文件

模型文件位于 `assets/models/gemma-4-E2B-it.litertlm`，由于文件较大（2.4GB），需要单独下载：

```bash
cd assets/models
curl -L "https://hf-mirror.com/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm" -o gemma-4-E2B-it.litertlm
```

或访问 [HuggingFace](https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm) 手动下载。
