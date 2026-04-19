# 快速参考

## 构建命令

### Android
```bash
# 本地构建
flutter build apk --release

# 或使用 Makefile
make build

# 构建多架构
flutter build apk --release --split-per-abi
```

### iOS
```bash
# 本地构建（需要 macOS）
flutter build ios --release --no-codesign

# 或使用 Makefile
make build-ios
```

## GitHub Actions

### 手动构建
1. 访问 GitHub 仓库
2. Actions → Manual Build
3. Run workflow → 选择平台
4. 下载 Artifacts

### 自动发布
```bash
git tag v1.0.0
git push origin v1.0.0
```

## 模型服务器

### 启动服务器
```bash
# Windows
双击 启动服务器.bat

# 命令行
node model_server.js
```

### 下载模型
```bash
node download_models.js
```

## 常用命令

```bash
# 运行应用
flutter run --release

# 安装依赖
flutter pub get

# 代码分析
flutter analyze

# 格式化代码
flutter format .

# 清理缓存
flutter clean
```

## 目录结构

```
dagou-flutter/
├── .github/workflows/     # GitHub Actions
├── docs/                  # 文档
├── lib/                   # 源代码
├── assets/models/         # AI模型文件
├── model_server.js        # 模型服务器
├── download_models.js     # 模型下载脚本
├── 启动服务器.bat         # 服务器启动脚本
└── Makefile              # 构建命令
```

## 重要文档

- [CLAUDE.md](CLAUDE.md) - 开发指南
- [iOS构建指南.md](docs/iOS构建指南.md) - iOS编译和安装
- [GitHub_Actions使用指南.md](docs/GitHub_Actions使用指南.md) - CI/CD教程
- [模型管理完整指南.md](docs/模型管理完整指南.md) - 模型下载和管理
- [SERVER_README.md](SERVER_README.md) - 服务器快速开始

## 版本发布流程

1. 更新版本号（pubspec.yaml）
2. 提交代码
3. 创建标签：`git tag v1.0.0`
4. 推送标签：`git push origin v1.0.0`
5. GitHub Actions 自动构建
6. 在 Releases 页面下载

## 故障排查

### 构建失败
- 检查 Flutter 版本
- 运行 `flutter clean`
- 删除 `pubspec.lock` 重新获取依赖

### 模型加载失败
- 确认模型文件存在
- 检查文件大小（约2.4GB）
- 查看应用日志

### iOS 安装失败
- 使用 AltStore 重新签名
- 检查设备是否信任证书
- 查看 iOS构建指南.md

## 联系方式

- Issues: https://github.com/你的用户名/dagou-flutter/issues
- Discussions: https://github.com/你的用户名/dagou-flutter/discussions
