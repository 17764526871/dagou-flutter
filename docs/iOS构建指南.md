# iOS 构建和安装指南

## 方式一：使用 GitHub Actions（推荐）

### 1. 手动触发构建

1. 访问 GitHub 仓库页面
2. 点击 **Actions** 标签
3. 选择 **Manual Build** 工作流
4. 点击 **Run workflow** 按钮
5. 选择平台：
   - `android` - 只构建 Android APK
   - `ios` - 只构建 iOS IPA
   - `both` - 同时构建两个平台
6. 点击 **Run workflow** 开始构建

### 2. 下载构建产物

构建完成后：
1. 进入该次运行的详情页
2. 滚动到底部的 **Artifacts** 区域
3. 下载对应的文件：
   - `android-apk-xxx` - Android APK 文件
   - `ios-ipa-xxx` - iOS IPA 文件

### 3. 发布版本（自动构建）

推送版本标签会自动触发构建和发布：

```bash
# 创建版本标签
git tag v1.0.0

# 推送标签到 GitHub
git push origin v1.0.0
```

构建完成后会自动创建 GitHub Release，包含 APK 和 IPA 文件。

## 方式二：本地构建（需要 macOS）

### 前置要求

1. **macOS 系统**（iOS 只能在 macOS 上构建）
2. **Xcode**（从 App Store 安装）
3. **Flutter SDK**
4. **CocoaPods**

```bash
# 安装 CocoaPods
sudo gem install cocoapods
```

### 构建步骤

#### 1. 使用 Makefile（推荐）

```bash
make build-ios
```

#### 2. 使用 Flutter 命令

```bash
# 构建 iOS（不签名）
flutter build ios --release --no-codesign

# 构建完成后，IPA 位于：
# build/ios/iphoneos/Runner.app
```

#### 3. 创建 IPA 文件

```bash
# 创建 Payload 目录
mkdir Payload

# 复制 .app 文件
cp -r build/ios/iphoneos/Runner.app Payload/

# 打包成 IPA
zip -r DagouAI.ipa Payload

# 清理
rm -rf Payload
```

## iOS 安装方法

### 方法一：使用 AltStore（推荐，无需越狱）

1. **安装 AltStore**
   - 下载：https://altstore.io/
   - 在 Windows/Mac 上安装 AltServer
   - 在 iPhone 上安装 AltStore 应用

2. **安装 IPA**
   - 将 IPA 文件传输到 iPhone（通过 AirDrop、iCloud 等）
   - 在 iPhone 上打开 AltStore
   - 点击 "+" 按钮
   - 选择 DagouAI.ipa 文件
   - 等待安装完成

3. **信任开发者**
   - 设置 → 通用 → VPN与设备管理
   - 找到开发者证书
   - 点击"信任"

**注意：** AltStore 安装的应用每 7 天需要重新签名一次。

### 方法二：使用 Sideloadly

1. **下载 Sideloadly**
   - 官网：https://sideloadly.io/
   - 支持 Windows 和 macOS

2. **安装步骤**
   - 连接 iPhone 到电脑
   - 打开 Sideloadly
   - 拖入 IPA 文件
   - 输入 Apple ID（用于签名）
   - 点击 Start 开始安装

3. **信任证书**
   - 设置 → 通用 → VPN与设备管理
   - 信任开发者证书

### 方法三：使用 TestFlight（需要开发者账号）

如果你有 Apple Developer 账号：

1. **上传到 App Store Connect**
   ```bash
   # 使用 Xcode 或 Transporter 上传
   ```

2. **配置 TestFlight**
   - 在 App Store Connect 中配置测试信息
   - 添加内部或外部测试员

3. **分发测试**
   - 测试员通过 TestFlight 应用安装

### 方法四：使用 Xcode（需要 Mac）

1. **打开项目**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **连接 iPhone**
   - 使用数据线连接 iPhone 到 Mac
   - 在 iPhone 上信任该电脑

3. **选择设备**
   - 在 Xcode 顶部选择你的 iPhone

4. **运行**
   - 点击运行按钮（▶️）
   - 首次运行需要在 iPhone 上信任开发者

## 常见问题

### Q1: 为什么 iOS 构建需要 macOS？

**A:** Apple 的限制，iOS 应用只能在 macOS 上使用 Xcode 构建。

### Q2: 没有 Mac 怎么办？

**A:** 使用 GitHub Actions！它提供免费的 macOS 虚拟机，可以自动构建 iOS 应用。

### Q3: 无签名的 IPA 能直接安装吗？

**A:** 不能。需要使用 AltStore、Sideloadly 等工具重新签名后才能安装。

### Q4: AltStore 每 7 天重新签名很麻烦？

**A:** 
- 使用 AltStore 的自动刷新功能（需要电脑和手机在同一网络）
- 或者购买 Apple Developer 账号（$99/年），签名有效期 1 年

### Q5: 能上架 App Store 吗？

**A:** 可以，但需要：
1. Apple Developer 账号（$99/年）
2. 完善应用信息和截图
3. 通过 App Store 审核

### Q6: GitHub Actions 构建失败？

**A:** 检查：
- Flutter 版本是否正确
- 依赖是否都能正常获取
- 查看 Actions 日志中的错误信息

### Q7: 模型文件太大，GitHub Actions 超时？

**A:** 
- 模型文件不要打包进 IPA
- 使用应用内下载功能
- 或者使用 Git LFS 存储大文件

## 构建配置

### 修改应用信息

编辑 `ios/Runner/Info.plist`：

```xml
<key>CFBundleDisplayName</key>
<string>Dagou AI</string>

<key>CFBundleIdentifier</key>
<string>com.example.dagouFlutter</string>

<key>CFBundleVersion</key>
<string>1.0.0</string>
```

### 修改应用图标

替换 `ios/Runner/Assets.xcassets/AppIcon.appiconset/` 中的图标文件。

### 修改启动页

编辑 `ios/Runner/Assets.xcassets/LaunchImage.imageset/` 中的启动图。

## GitHub Actions 配置说明

### 工作流文件

- `.github/workflows/build.yml` - 标签触发的自动构建
- `.github/workflows/manual-build.yml` - 手动触发的构建

### 触发条件

**自动构建：**
```bash
git tag v1.0.0
git push origin v1.0.0
```

**手动构建：**
- GitHub 网页 → Actions → Manual Build → Run workflow

### 构建产物

- **Android APK**: 支持 arm64-v8a、armeabi-v7a、x86_64
- **iOS IPA**: 未签名，需要使用工具重新签名

### 保留时间

- 手动构建：30 天
- 标签构建：永久（作为 Release）

## 最佳实践

1. **开发阶段**
   - 使用 GitHub Actions 手动构建
   - 通过 AltStore 安装测试

2. **测试阶段**
   - 使用 TestFlight 分发给测试员
   - 收集反馈并修复问题

3. **发布阶段**
   - 创建版本标签触发自动构建
   - 发布到 GitHub Release
   - 可选：上架 App Store

## 相关链接

- [Flutter iOS 部署文档](https://docs.flutter.dev/deployment/ios)
- [AltStore 官网](https://altstore.io/)
- [Sideloadly 官网](https://sideloadly.io/)
- [Apple Developer](https://developer.apple.com/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
