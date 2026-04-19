# Dagou AI - Gemma 4 端侧多模态智能助手

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.41.7-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11.5-0175C2?logo=dart)
![Gemma 4](https://img.shields.io/badge/Gemma_4-E2B-4285F4?logo=google)
![License](https://img.shields.io/badge/License-Apache_2.0-green)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?logo=android)
![Build](https://github.com/你的用户名/dagou-flutter/workflows/Build%20and%20Release/badge.svg)

**完全运行在手机上的 AI 助手 | 无需联网 | 保护隐私**

[功能特性](#功能特性) • [快速开始](#快速开始) • [下载安装](#下载安装) • [技术架构](#技术架构) • [文档](#文档)

</div>

---

## 📱 项目简介

Dagou AI 是一个完全运行在移动设备上的端侧 AI 助手应用，基于 Google 最新的 **Gemma 4 E2B** 多模态模型构建。应用内置 AI 模型，无需网络连接即可使用，充分保护用户隐私。

### ✨ 核心亮点

- 🔒 **完全离线** - 模型内置在应用中，无需联网即可使用
- 🚀 **端侧运行** - AI 推理完全在设备上进行，响应快速
- 🎨 **多模态支持** - 支持文本、图片输入方式
- 🛡️ **隐私保护** - 所有数据都在本地处理，不上传到云端
- 💎 **现代化 UI** - Material Design 3 设计，流畅美观
- 📊 **实时性能监控** - 显示推理速度、Token数、延迟等指标
- 🌐 **翻译功能** - 支持中英互译和自动检测
- ⚙️ **高度可配置** - 支持调整温度、Top-K、Top-P等模型参数

---

## 🎯 功能特性

### 💬 智能对话
- 自然语言理解和生成
- 流式输出，实时显示响应
- 支持停止生成功能
- 可配置系统提示词

### 🖼️ 图片分析
- 图片内容识别和理解
- 物体检测和场景分析
- 支持相册选择和实时拍照
- 支持图片直接发送（无需输入文字）

### 🌐 翻译功能
- 中文→英文翻译
- 英文→中文翻译
- 自动语言检测
- 可在设置中开启/关闭

### 📊 性能监控
- 实时推理速度（tokens/秒）
- Token 数量统计
- 字符数统计
- 推理时长
- 平均延迟

### 🎨 用户体验
- 蓝绿渐变现代化设计
- 流畅的动画效果
- 直观的操作界面
- 实时加载进度显示
- 微信风格输入栏
- 语音录制（按住说话）

## ⚠️ 重要说明

### 平台支持
- ✅ **Android**: 完全支持（API 26+，Android 8.0+）
- ⚠️ **iOS**: 暂不支持（flutter_gemma 插件尚未支持 iOS）
- 🔄 **其他平台**: 计划支持 Windows、macOS、Linux

### 模型文件说明

应用支持两种打包方式：

#### 1. 带模型打包（推荐自用）
- APK 大小: **约 2.5GB**
- 安装后即可使用，无需额外配置
- 适合个人使用或少量分发

#### 2. 不带模型打包（推荐分发）
- APK 大小: **约 50MB**
- 首次启动时需要选择模型文件位置
- 适合公开分发或团队使用

### 模型文件位置

应用会按以下优先级查找模型文件：

1. **用户自定义路径**（最高优先级）
   - 通过文件选择器指定的路径
   - 保存在应用设置中

2. **外部存储目录**
   ```
   /storage/emulated/0/Android/data/com.example.dagou_flutter/files/models/
   ```

3. **应用文档目录**
   ```
   /data/user/0/com.example.dagou_flutter/app_flutter/models/
   ```

4. **内置资源**（最低优先级）
   - 仅在带模型打包时可用
   - 路径: `assets/models/gemma-4-E2B-it.litertlm`

### 如何获取模型文件

**方式 1: 从 HuggingFace 下载**
```bash
# 下载 Gemma 4 E2B 模型（2.5GB）
curl -L "https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm" -o gemma-4-E2B-it.litertlm
```

**方式 2: 使用局域网下载**
1. 在电脑上运行模型服务器：
   ```bash
   node model_server.js
   ```
2. 在应用的"模型管理"中设置服务器地址
3. 选择模型并下载到手机

**方式 3: 从手机存储选择**
- 将模型文件复制到手机任意位置
- 首次启动时选择该文件
- 或在"模型管理"中选择本地文件

### 模型文件验证

应用会自动验证模型文件：
- 文件大小: 10MB - 10GB
- 文件格式: `.litertlm` 或 `.task`
- 文件完整性检查

详见：[模型管理使用指南](docs/模型管理使用指南.md)

---

## 📥 下载安装

### 方式一：下载预编译版本（推荐）

访问 [Releases](https://github.com/你的用户名/dagou-flutter/releases) 页面下载最新版本：

**Android:**
- `app-arm64-v8a-release.apk` - 64位设备（推荐）
- `app-armeabi-v7a-release.apk` - 32位设备
- 下载后直接安装即可

**iOS:**
- `DagouAI.ipa` - 需要使用 AltStore 或 Sideloadly 重新签名
- 详见 [iOS构建指南](docs/iOS构建指南.md)

### 方式二：使用 GitHub Actions 构建

1. Fork 本仓库
2. 进入 Actions 页面
3. 选择 "Manual Build" 工作流
4. 点击 "Run workflow" 选择平台
5. 等待构建完成后下载

详见 [GitHub Actions使用指南](docs/GitHub_Actions使用指南.md)

### 方式三：本地编译

---

## 🚀 快速开始

### 环境要求

- Flutter SDK: 3.41.7+
- Dart SDK: 3.11.5+
- Android Studio / VS Code
- Android 设备（API 26+，推荐 Android 8.0+）

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/your-username/dagou-flutter.git
cd dagou-flutter
```

2. **下载模型文件**

由于模型文件较大（约2.4GB），需要单独下载：

```bash
# 使用 curl 下载（推荐国内用户使用镜像）
cd assets/models
curl -L "https://hf-mirror.com/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm" -o gemma-4-E2B-it.litertlm
```

或访问 [HuggingFace](https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm) 手动下载，放置到 `assets/models/` 目录。

详细说明请查看 [assets/models/README.md](assets/models/README.md)

3. **安装依赖**
```bash
flutter pub get
```

4. **连接设备**
```bash
# 确保 Android 设备已连接并开启 USB 调试
flutter devices
```

5. **运行应用**
```bash
# Debug 模式
flutter run

# Release 模式（推荐）
flutter run --release
```

### 首次启动

首次启动时，应用会显示加载界面，将内置的 Gemma 4 E2B 模型加载到内存中。这个过程需要 10-15 秒时间，进度条会实时显示加载进度。

---

## 🏗️ 技术架构

### 核心技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Flutter | 3.41.7 | 跨平台 UI 框架 |
| Dart | 3.11.5 | 编程语言 |
| flutter_gemma | 0.13.5 | Gemma 模型集成 |
| Gemma 4 E2B | Latest | 端侧多模态 AI 模型（2B 参数）|
| shared_preferences | ^2.3.5 | 本地数据持久化 |
| image_picker | ^1.1.2 | 图片选择 |
| record | ^5.1.2 | 语音录制 |
| just_audio | ^0.9.42 | 音频播放 |

### 项目结构（Clean Architecture）

```
dagou-flutter/
├── lib/
│   ├── main.dart                          # 应用入口
│   ├── core/                              # 核心基础设施
│   │   ├── constants/                     # 常量定义
│   │   ├── theme/                         # 主题配置
│   │   └── utils/                         # 工具类
│   ├── data/                              # 数据层
│   │   ├── models/                        # 数据模型
│   │   │   ├── message.dart               # 消息模型
│   │   │   └── ai_model_info.dart         # AI模型信息
│   │   └── repositories/                  # 数据仓库
│   ├── domain/                            # 业务逻辑层
│   │   ├── entities/                      # 业务实体
│   │   └── usecases/                      # 用例
│   ├── presentation/                      # 表现层
│   │   ├── screens/                       # 界面页面
│   │   │   ├── loading/                   # 加载界面
│   │   │   │   └── loading_screen.dart
│   │   │   ├── chat/                      # 聊天界面
│   │   │   │   └── chat_screen.dart
│   │   │   ├── settings/                  # 设置界面
│   │   │   │   └── settings_screen.dart
│   │   │   └── models/                    # 模型管理
│   │   │       └── model_list_screen.dart
│   │   └── widgets/                       # UI 组件
│   │       ├── chat/                      # 聊天组件
│   │       │   ├── message_bubble.dart    # 消息气泡
│   │       │   ├── input_bar.dart         # 输入栏
│   │       │   └── audio_player_widget.dart # 音频播放器
│   │       └── common/                    # 通用组件
│   └── services/                          # 服务层
│       ├── ai/                            # AI 服务
│       │   ├── ai_service.dart            # AI 推理服务
│       │   ├── model_manager.dart         # 模型管理
│       │   └── lora_service.dart          # LoRA 微调服务
│       ├── audio/                         # 音频服务
│       │   └── audio_service.dart         # 录音服务
│       └── storage/                       # 存储服务
│           ├── settings_service.dart      # 设置持久化
│           └── cache_service.dart         # 缓存管理
├── assets/
│   └── models/                            # 内置模型文件
│       └── gemma-4-E2B-it.litertlm        # Gemma 4 E2B 模型
├── android/                               # Android 平台配置
│   └── app/
│       ├── build.gradle.kts               # Gradle 配置
│       └── proguard-rules.pro             # ProGuard 规则
├── docs/                                  # 项目文档
│   └── lora_finetuning_guide.md           # LoRA 微调指南
└── pubspec.yaml                           # 项目配置
```

### 架构设计

```
┌─────────────────────────────────────────────────────┐
│              用户界面层 (Presentation)               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │ 加载界面  │  │ 聊天界面  │  │ 设置界面  │         │
│  └──────────┘  └──────────┘  └──────────┘         │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│              业务逻辑层 (Domain)                     │
│         ┌──────────────────────────┐                │
│         │  Use Cases & Entities    │                │
│         └──────────────────────────┘                │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│              服务层 (Services)                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │ AI服务   │  │ 音频服务  │  │ 存储服务  │         │
│  └──────────┘  └──────────┘  └──────────┘         │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│              模型层 (Model)                          │
│    ┌────────────────────────────────────┐           │
│    │  Gemma 4 E2B (2B 参数)              │           │
│    │  - 文本理解与生成                    │           │
│    │  - 图片识别与分析                    │           │
│    │  - 多模态融合推理                    │           │
│    │  - 流式输出支持                      │           │
│    └────────────────────────────────────┘           │
└─────────────────────────────────────────────────────┘
```

---

## 📚 文档

详细文档请查看 [docs](docs/) 目录：

- [LoRA 微调完整指南](docs/lora_finetuning_guide.md) - 包含数据准备、训练脚本、权重导出
- [项目最终完成报告](docs/项目最终完成报告.md)
- [快速上手指南](docs/快速上手指南.md)
- [使用说明](docs/使用说明.md)
- [Android 部署指南](docs/Android部署指南.md)
- [项目技术总结](docs/项目技术总结.md)

---

## 🔧 开发指南

### 构建 APK

```bash
# Debug 版本
flutter build apk --debug

# Release 版本（推荐）
flutter build apk --release

# 安装到设备
flutter install -d <device-id>

# 或使用 adb 直接安装
adb -s <device-id> install -r build/app/outputs/flutter-apk/app-release.apk
```

### 代码规范

项目遵循 Flutter 官方代码规范：

```bash
# 代码格式化
flutter format .

# 代码分析
flutter analyze

# 运行测试
flutter test
```

### ProGuard 配置

Release 版本启用了代码混淆和优化，ProGuard 规则位于 `android/app/proguard-rules.pro`：

```proguard
# Flutter Gemma ProGuard Rules
-keep class com.google.mediapipe.** { *; }
-keep class org.tensorflow.** { *; }
-keep class dev.flutterberlin.flutter_gemma.** { *; }
```

---

## 🎨 UI 设计

### 设计理念

- **简洁现代** - Material Design 3 设计语言
- **蓝绿渐变** - 清新的蓝绿渐变主题色
- **流畅动画** - 自然的过渡效果
- **直观操作** - 符合用户习惯的交互设计
- **微信风格** - 熟悉的聊天界面布局

### 主题色

| 颜色 | 色值 | 用途 |
|------|------|------|
| 主色调 | `#0EA5E9` | 按钮、强调元素 |
| 辅助色 | `#06B6D4` | 渐变、装饰 |
| 背景色 | `#F5F7FA` | 页面背景 |
| 文字色 | `#2D3748` | 主要文字 |
| 次要文字 | `#718096` | 次要文字 |

---

## 📊 性能指标

- **模型大小**: ~2.4GB (内置)
- **APK 大小**: ~2.36GB (包含模型)
- **启动时间**: ~10-15 秒（首次加载模型）
- **推理速度**: ~30-80 tokens/秒 (取决于设备)
- **内存占用**: ~1.5-2.5GB
- **支持设备**: Android 8.0+ (API 26+)
- **最低要求**: 4GB RAM, 5GB 可用存储空间

### 性能优化

- ✅ 使用 GPU 加速推理
- ✅ 流式输出减少等待时间
- ✅ ProGuard 代码混淆和优化
- ✅ 图标树摇优化（减少 99.7% 大小）
- ✅ 懒加载和按需初始化

---

## ⚙️ 配置选项

### 模型参数

在设置界面可以调整以下参数：

- **Temperature** (0.1-2.0): 控制输出随机性，越高越随机
- **Top-K** (1-100): 采样时考虑的 token 数量
- **Top-P** (0.1-1.0): 核采样阈值
- **Max Tokens** (512-8192): 最大生成长度

### 系统提示词

支持自定义系统提示词，控制 AI 的行为和角色：

```
你是一个有帮助的AI助手。
```

### 翻译模式

- 中文 → English
- English → 中文
- 自动检测

---

## 🔬 高级功能

### LoRA 微调

项目支持 LoRA (Low-Rank Adaptation) 微调，可以用少量数据定制模型行为。

详细指南请查看：[docs/lora_finetuning_guide.md](docs/lora_finetuning_guide.md)

包含内容：
- 数据准备脚本
- 完整训练脚本（使用 Hugging Face PEFT）
- 权重导出和转换工具
- 应用集成示例

### 模型管理

支持多模型切换和管理：

- 查看已安装模型
- 切换不同模型
- 查看模型能力（文本/图片/音频）
- 后端切换（GPU/CPU）

---

## 🤝 贡献指南

欢迎贡献代码、报告问题或提出建议！

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 开发规范

- 遵循 Flutter 官方代码规范
- 使用有意义的提交信息
- 添加必要的注释和文档
- 确保代码通过 `flutter analyze`
- 测试新功能和修复

---

## 🐛 已知问题

- ⚠️ 语音识别功能暂未实现（发送语音会提示不支持）
- ⚠️ 首次加载模型时间较长（10-15秒）
- ⚠️ APK 文件较大（2.36GB，包含模型）
- ⚠️ 需要较大的设备存储空间（至少 5GB）

---

## 📄 许可证

本项目采用 Apache 2.0 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 🙏 致谢

- [Google Gemma](https://ai.google.dev/gemma) - 提供强大的端侧 AI 模型
- [Flutter](https://flutter.dev/) - 优秀的跨平台框架
- [flutter_gemma](https://pub.dev/packages/flutter_gemma) - Gemma 模型集成包
- [Hugging Face](https://huggingface.co/) - 模型托管和分享平台

---

## 📞 联系方式

- 项目主页: [GitHub](https://github.com/your-username/dagou-flutter)
- 问题反馈: [Issues](https://github.com/your-username/dagou-flutter/issues)

---

## 🗺️ 路线图

### v1.0 (当前版本)
- ✅ 基础聊天功能
- ✅ 图片分析
- ✅ 翻译功能
- ✅ 性能监控
- ✅ 设置持久化

### v1.1 (计划中)
- 🔲 语音识别集成
- 🔲 对话历史管理
- 🔲 多会话支持
- 🔲 导出对话记录

### v2.0 (未来)
- 🔲 模型在线下载
- 🔲 LoRA 权重管理
- 🔲 函数调用支持
- 🔲 思考模式显示

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给个 Star！⭐**

Made with ❤️ by Dagou AI Team

</div>
