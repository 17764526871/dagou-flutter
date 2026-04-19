# iOS 和模型管理问题解决方案

## ⚠️ 重要问题说明

### 1. iOS 平台支持情况

**flutter_gemma 插件支持情况：**
- ✅ **Android**: 完全支持
- ❌ **iOS**: 目前 flutter_gemma 0.13.5 **不支持 iOS**

**原因：**
- flutter_gemma 基于 Google 的 MediaPipe 和 LiteRT
- 这些底层库目前只支持 Android 平台
- iOS 支持正在开发中，但尚未发布

**结论：**
- 当前版本**无法在 iOS 上运行**
- 即使编译成功，运行时会崩溃或无法加载模型
- 需要等待 flutter_gemma 官方支持 iOS

### 2. Windows 连接 iPhone 安装

**可以使用以下工具：**

#### Sideloadly（推荐）
- ✅ 支持 Windows
- ✅ 免费使用
- ✅ 操作简单

**步骤：**
1. 下载 Sideloadly: https://sideloadly.io/
2. 连接 iPhone 到电脑
3. 拖入 IPA 文件
4. 输入 Apple ID
5. 点击 Start 安装

#### AltStore
- ⚠️ Windows 版本功能有限
- 需要安装 iTunes 和 iCloud
- 相对复杂

**但是：由于应用目前不支持 iOS，安装后无法正常运行！**

### 3. iOS 限制

即使将来支持 iOS，也会有以下限制：

#### 签名限制
- **免费 Apple ID**: 每 7 天需要重新签名
- **付费开发者账号** ($99/年): 1 年有效期

#### 性能限制
- iOS 对后台进程限制更严格
- 内存使用受限
- 可能影响大模型运行

#### 安装限制
- 无法直接安装 IPA
- 必须通过工具重新签名
- 或者上架 App Store（需要审核）

### 4. GitHub Actions 构建的模型问题

**关键问题：模型文件太大！**

- 模型文件: **2.5GB**
- GitHub 文件限制: **100MB**
- Git 仓库限制: **1GB**

**当前状态：**
- ❌ 模型文件**无法**推送到 GitHub
- ❌ GitHub Actions 构建的 APK **不包含模型**
- ❌ 下载的 APK 安装后**无法使用**（缺少模型）

**问题表现：**
1. 安装 APK 后打开应用
2. 显示"加载模型"界面
3. 加载失败或卡住
4. 应用无法正常使用

### 5. 解决方案

## 方案一：使用 Git LFS（推荐）

### 什么是 Git LFS？
Git Large File Storage - 专门用于存储大文件

### 设置步骤

#### 1. 安装 Git LFS
```bash
# Windows (使用 Git for Windows 自带)
git lfs install

# 或下载安装
# https://git-lfs.github.com/
```

#### 2. 配置 LFS 跟踪模型文件
```bash
cd f:/work/github/dagou-flutter

# 跟踪 .litertlm 文件
git lfs track "*.litertlm"
git lfs track "*.task"

# 添加 .gitattributes
git add .gitattributes
git commit -m "chore: 添加 Git LFS 支持"
```

#### 3. 添加模型文件
```bash
# 添加模型文件
git add assets/models/gemma-4-E2B-it.litertlm
git commit -m "feat: 添加 Gemma 4 E2B 模型文件"
git push
```

#### 4. 更新 GitHub Actions
```yaml
# .github/workflows/build.yml
steps:
  - name: Checkout code
    uses: actions/checkout@v4
    with:
      lfs: true  # 启用 LFS

  - name: Checkout LFS objects
    run: git lfs checkout
```

**优点：**
- ✅ 模型文件正常推送
- ✅ GitHub Actions 可以下载
- ✅ 构建的 APK 包含模型
- ✅ 用户下载即可使用

**缺点：**
- ⚠️ GitHub LFS 免费额度有限（1GB 存储，1GB/月 带宽）
- ⚠️ 超出需要付费

## 方案二：应用内下载模型（推荐用于生产）

### 实现思路
1. APK 不包含模型文件
2. 首次启动时提示下载模型
3. 从服务器下载到手机

### 优点
- ✅ APK 体积小（约 50MB）
- ✅ 不占用 GitHub 空间
- ✅ 用户可以选择下载时机
- ✅ 可以更新模型而不更新应用

### 缺点
- ⚠️ 需要网络连接
- ⚠️ 首次使用需要等待下载

### 实现步骤

#### 1. 修改 pubspec.yaml
```yaml
flutter:
  uses-material-design: true
  
  # 不打包模型文件
  # assets:
  #   - assets/models/gemma-4-E2B-it.litertlm
```

#### 2. 添加模型下载逻辑
在 LoadingScreen 中添加：
```dart
Future<void> _downloadModelIfNeeded() async {
  final modelPath = await _getModelPath();
  final file = File(modelPath);
  
  if (!await file.exists()) {
    // 显示下载对话框
    await _showDownloadDialog();
    // 下载模型
    await _downloadModel(modelPath);
  }
  
  // 加载模型
  await _loadModel(modelPath);
}
```

#### 3. 托管模型文件
- 上传到云存储（阿里云 OSS、腾讯云 COS）
- 或使用 GitHub Release 附件
- 或使用自己的服务器

## 方案三：混合方案（最佳）

### 策略
1. **开发版本**: 使用 Git LFS，包含模型
2. **发布版本**: 不包含模型，应用内下载
3. **局域网版本**: 使用模型服务器

### 实现
```yaml
# pubspec.yaml
flutter:
  assets:
    # 开发时启用
    - assets/models/gemma-4-E2B-it.litertlm  # 注释掉用于发布
```

构建时：
```bash
# 开发版本（包含模型）
flutter build apk --release

# 发布版本（不包含模型）
# 先注释掉 pubspec.yaml 中的模型
flutter build apk --release
```

## 当前推荐方案

### 短期方案（立即可用）

**1. 本地构建（包含模型）**
```bash
# 确保模型文件存在
ls assets/models/gemma-4-E2B-it.litertlm

# 构建 APK
flutter build apk --release

# 手动分发
# 通过网盘、局域网等方式分发
```

**2. 使用模型服务器**
- 启动 `model_server.js`
- 用户通过局域网下载模型
- 应用从外部存储加载

### 长期方案（生产环境）

**1. 实现应用内下载**
- 首次启动检测模型
- 提示用户下载
- 从云存储下载

**2. 使用 CDN 加速**
- 将模型上传到 CDN
- 国内外分别加速
- 提供断点续传

## 模型文件位置说明

### Android

#### 内置模型（打包在 APK 中）
```
应用内部: assets/models/gemma-4-E2B-it.litertlm
运行时路径: 由 Flutter 自动处理
```

#### 外部下载的模型
```
外部存储: /storage/emulated/0/Android/data/com.example.dagou_flutter/files/models/
特点: 卸载应用不会删除
```

#### 用户选择的模型
```
任意位置: 用户通过文件选择器指定
应用记录路径: SharedPreferences
```

### iOS（将来支持时）

#### 内置模型
```
应用包内: Runner.app/Frameworks/App.framework/flutter_assets/assets/models/
```

#### 下载的模型
```
应用文档目录: /var/mobile/Containers/Data/Application/[UUID]/Documents/models/
```

## 检查清单

### 使用 GitHub Actions 构建前

- [ ] 确认是否需要包含模型
- [ ] 如果包含，配置 Git LFS
- [ ] 如果不包含，实现应用内下载
- [ ] 测试构建产物是否可用

### 发布前检查

- [ ] 测试 APK 是否包含模型
- [ ] 测试首次启动是否正常
- [ ] 测试模型加载是否成功
- [ ] 测试 AI 功能是否正常

### 用户安装后

- [ ] 检查应用是否正常启动
- [ ] 检查模型是否加载成功
- [ ] 检查 AI 对话是否正常
- [ ] 检查图片分析是否正常

## 常见问题

### Q1: 为什么下载的 APK 无法使用？
**A:** 可能是因为 APK 不包含模型文件。检查：
1. APK 大小（应该 > 2.5GB）
2. 首次启动是否提示下载模型
3. 查看应用日志

### Q2: 如何确认 APK 是否包含模型？
**A:** 
```bash
# 解压 APK
unzip app-release.apk -d apk_contents

# 检查模型文件
ls -lh apk_contents/assets/models/
```

### Q3: GitHub Actions 构建失败？
**A:** 可能原因：
- 模型文件太大，未配置 LFS
- 构建超时（免费版有时间限制）
- 内存不足

### Q4: iOS 什么时候能支持？
**A:** 
- 关注 flutter_gemma 官方更新
- 查看 GitHub Issues
- 可能需要等待几个月

### Q5: 可以用其他 AI 模型吗？
**A:** 
- 可以，但需要修改代码
- 支持 TensorFlow Lite 格式的模型
- 需要适配不同的输入输出格式

## 立即行动方案

### 方案 A: 本地构建 + 手动分发（最快）

```bash
# 1. 确保模型文件存在
ls assets/models/gemma-4-E2B-it.litertlm

# 2. 构建 APK
flutter build apk --release

# 3. 找到 APK
ls -lh build/app/outputs/flutter-apk/app-release.apk

# 4. 分发
# - 上传到网盘（百度网盘、阿里云盘）
# - 或通过局域网传输
# - 或使用 USB 直接安装
```

**优点：** 立即可用，包含模型
**缺点：** 文件大（2.5GB+），分发不便

### 方案 B: 配置 Git LFS（推荐）

```bash
# 1. 安装 Git LFS
git lfs install

# 2. 跟踪模型文件
git lfs track "*.litertlm"
git add .gitattributes

# 3. 添加模型
git add assets/models/gemma-4-E2B-it.litertlm
git commit -m "feat: 添加模型文件（使用 LFS）"
git push

# 4. 更新 GitHub Actions（见下文）
```

**优点：** 自动化构建，用户直接下载
**缺点：** 需要配置，有存储限制

## 下一步建议

1. **立即**: 使用方案 A 本地构建测试
2. **短期**: 配置 Git LFS 实现自动构建
3. **长期**: 实现应用内下载功能
4. **iOS**: 等待 flutter_gemma 官方支持

---

**总结：当前 iOS 不可用，Android 需要解决模型打包问题！**
