# Dagou AI - Gemma 4 端侧多模态智能助手

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.41.7-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11.5-0175C2?logo=dart)
![Gemma 4](https://img.shields.io/badge/Gemma_4-E2B-4285F4?logo=google)
![License](https://img.shields.io/badge/License-Apache_2.0-green)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)

**完全运行在手机上的 AI 助手 | 无需联网 | 保护隐私**

[功能特性](#功能特性) • [快速开始](#快速开始) • [技术架构](#技术架构) • [文档](#文档)

</div>

---

## 📱 项目简介

Dagou AI 是一个完全运行在移动设备上的端侧 AI 助手应用，基于 Google 最新的 **Gemma 4 E2B** 多模态模型构建。应用内置 AI 模型，无需网络连接即可使用，充分保护用户隐私。

### ✨ 核心亮点

- 🔒 **完全离线** - 模型内置在应用中，无需联网即可使用
- 🚀 **端侧运行** - AI 推理完全在设备上进行，响应快速
- 🎨 **多模态支持** - 支持文本、图片、语音多种输入方式
- 🛡️ **隐私保护** - 所有数据都在本地处理，不上传到云端
- 💎 **现代化 UI** - Material Design 3 设计，流畅美观

---

## 🎯 功能特性

### 💬 智能对话
- 自然语言理解和生成
- 上下文记忆和连续对话
- 多轮对话支持

### 🖼️ 图片分析
- 图片内容识别和理解
- 物体检测和场景分析
- 支持相册选择和实时拍照

### 🎤 语音交互
- 语音转文字输入
- 文字转语音输出
- 实时语音识别

### 🎨 用户体验
- 渐变色现代化设计
- 流畅的动画效果
- 直观的操作界面
- 实时加载进度显示

---

## 🚀 快速开始

### 环境要求

- Flutter SDK: 3.41.7+
- Dart SDK: 3.11.5+
- Android Studio / VS Code
- Android 设备（API 24+）

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/your-username/dagou-flutter.git
cd dagou-flutter
```

2. **下载模型文件**

由于模型文件较大（约2.5GB），需要单独下载：

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
flutter run
```

### 首次启动

首次启动时，应用会显示加载界面，将内置的 Gemma 4 E2B 模型加载到内存中。这个过程需要几秒钟时间。

---

## 🏗️ 技术架构

### 核心技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Flutter | 3.41.7 | 跨平台 UI 框架 |
| Dart | 3.11.5 | 编程语言 |
| flutter_gemma | 0.13.5 | Gemma 模型集成 |
| Gemma 4 E2B | Latest | 端侧多模态 AI 模型 |

### 项目结构

```
dagou-flutter/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── models/                   # 数据模型
│   │   └── message.dart          # 消息模型
│   ├── screens/                  # 界面页面
│   │   ├── loading_screen.dart   # 加载界面
│   │   └── chat_screen.dart      # 聊天界面
│   ├── services/                 # 业务服务
│   │   └── ai_service.dart       # AI 服务
│   └── widgets/                  # UI 组件
│       ├── message_bubble.dart   # 消息气泡
│       └── input_bar.dart        # 输入栏
├── assets/
│   └── models/                   # 内置模型文件
│       └── gemma-4-E2B-it-web.task
├── android/                      # Android 平台配置
├── docs/                         # 项目文档
└── pubspec.yaml                  # 项目配置
```

### 架构设计

```
┌─────────────────────────────────────┐
│         用户界面层 (UI Layer)        │
│  ┌──────────┐      ┌──────────┐    │
│  │ 加载界面  │      │ 聊天界面  │    │
│  └──────────┘      └──────────┘    │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│       业务逻辑层 (Service Layer)     │
│         ┌──────────────┐            │
│         │  AI Service  │            │
│         └──────────────┘            │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│        模型层 (Model Layer)          │
│    ┌────────────────────────┐       │
│    │  Gemma 4 E2B (2B 参数)  │       │
│    │  - 文本理解与生成        │       │
│    │  - 图片识别与分析        │       │
│    │  - 多模态融合推理        │       │
│    └────────────────────────┘       │
└─────────────────────────────────────┘
```

---

## 📚 文档

详细文档请查看 [docs](docs/) 目录：

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

# Release 版本
flutter build apk --release
```

### 代码规范

项目遵循 Flutter 官方代码规范：

```bash
# 代码格式化
flutter format .

# 代码分析
flutter analyze
```

---

## 🎨 UI 设计

### 设计理念

- **简洁现代** - Material Design 3 设计语言
- **渐变配色** - 紫蓝渐变主题色
- **流畅动画** - 自然的过渡效果
- **直观操作** - 符合用户习惯的交互设计

### 主题色

| 颜色 | 色值 | 用途 |
|------|------|------|
| 主色调 | `#667EEA` | 按钮、强调元素 |
| 辅助色 | `#764BA2` | 渐变、装饰 |
| 背景色 | `#F5F7FA` | 页面背景 |
| 文字色 | `#2D3748` | 主要文字 |

---

## 📊 性能指标

- **模型大小**: ~2.5GB (内置)
- **启动时间**: ~3-5 秒
- **推理速度**: ~50-100 tokens/秒 (取决于设备)
- **内存占用**: ~1.5-2GB
- **支持设备**: Android 7.0+ (API 24+)

---

## 🤝 贡献指南

欢迎贡献代码、报告问题或提出建议！

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📄 许可证

本项目采用 Apache 2.0 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 🙏 致谢

- [Google Gemma](https://ai.google.dev/gemma) - 提供强大的端侧 AI 模型
- [Flutter](https://flutter.dev/) - 优秀的跨平台框架
- [flutter_gemma](https://pub.dev/packages/flutter_gemma) - Gemma 模型集成包

---

## 📞 联系方式

- 项目主页: [GitHub](https://github.com/your-username/dagou-flutter)
- 问题反馈: [Issues](https://github.com/your-username/dagou-flutter/issues)

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给个 Star！⭐**

Made with ❤️ by Dagou AI Team

</div>
