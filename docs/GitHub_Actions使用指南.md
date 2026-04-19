# GitHub Actions 自动构建指南

## 概述

本项目配置了 GitHub Actions 自动构建，可以自动编译 Android APK 和 iOS IPA 文件，无需本地环境。

## 工作流说明

### 1. Manual Build（手动构建）

**文件：** `.github/workflows/manual-build.yml`

**用途：** 日常开发测试，手动触发构建

**触发方式：**
1. 访问 GitHub 仓库
2. 点击 **Actions** 标签
3. 选择 **Manual Build**
4. 点击 **Run workflow**
5. 选择平台（android/ios/both）
6. 点击绿色的 **Run workflow** 按钮

**构建产物：**
- Android: `DagouAI-arm64-v8a.apk`
- iOS: `DagouAI-xxx.ipa`
- 保留 30 天

### 2. Build and Release（自动发布）

**文件：** `.github/workflows/build.yml`

**用途：** 版本发布，自动构建并创建 GitHub Release

**触发方式：**
```bash
# 创建版本标签
git tag v1.0.0

# 推送到 GitHub
git push origin v1.0.0
```

**构建产物：**
- Android: 3个架构的 APK（arm64-v8a、armeabi-v7a、x86_64）
- iOS: IPA 文件
- 自动创建 GitHub Release，永久保存

## 使用步骤

### 方式一：手动构建（推荐用于测试）

#### 1. 触发构建

![GitHub Actions Manual Build](https://docs.github.com/assets/cb-33892/images/help/actions/workflow-dispatch-button.png)

1. 进入仓库的 **Actions** 页面
2. 左侧选择 **Manual Build**
3. 右侧点击 **Run workflow** 下拉菜单
4. 选择要构建的平台：
   - `android` - 只构建 Android（约 5-8 分钟）
   - `ios` - 只构建 iOS（约 10-15 分钟）
   - `both` - 同时构建（约 15-20 分钟）
5. 点击绿色按钮开始构建

#### 2. 查看构建进度

- 构建开始后会出现在列表中
- 点击进入可以查看实时日志
- 绿色 ✓ 表示成功，红色 ✗ 表示失败

#### 3. 下载构建产物

构建成功后：
1. 滚动到页面底部
2. 找到 **Artifacts** 区域
3. 点击下载：
   - `android-apk-xxx` - Android APK
   - `ios-ipa-xxx` - iOS IPA

### 方式二：版本发布（推荐用于正式版本）

#### 1. 准备发布

确保代码已提交并推送：
```bash
git add .
git commit -m "feat: 准备发布 v1.0.0"
git push
```

#### 2. 创建版本标签

```bash
# 创建标签（使用语义化版本号）
git tag v1.0.0

# 或者创建带注释的标签
git tag -a v1.0.0 -m "Release version 1.0.0"

# 推送标签到 GitHub
git push origin v1.0.0
```

#### 3. 自动构建和发布

- 推送标签后自动触发构建
- 构建完成后自动创建 GitHub Release
- Release 中包含所有构建产物

#### 4. 查看 Release

1. 进入仓库的 **Releases** 页面
2. 找到对应版本
3. 下载 APK 或 IPA 文件

## 构建环境

### Android 构建

- **运行环境：** Ubuntu Latest
- **Java 版本：** 17 (Zulu)
- **Flutter 版本：** 3.41.7
- **构建时间：** 约 5-8 分钟

### iOS 构建

- **运行环境：** macOS Latest
- **Flutter 版本：** 3.41.7
- **构建时间：** 约 10-15 分钟
- **签名：** 无签名（需要使用工具重新签名）

## 构建产物说明

### Android APK

**完整构建（标签触发）：**
- `app-arm64-v8a-release.apk` - 64位 ARM（推荐，现代设备）
- `app-armeabi-v7a-release.apk` - 32位 ARM（老旧设备）
- `app-x86_64-release.apk` - 64位 x86（模拟器）

**快速构建（手动触发）：**
- `DagouAI-arm64-v8a.apk` - 只构建 64位 ARM 版本

**安装方式：**
- 直接安装到 Android 设备
- 需要开启"允许安装未知来源应用"

### iOS IPA

**文件：** `DagouAI.ipa` 或 `DagouAI-xxx.ipa`

**特点：**
- 未签名，无法直接安装
- 需要使用工具重新签名

**安装方式：**
- AltStore（推荐）
- Sideloadly
- TestFlight（需要开发者账号）

详见：[iOS构建指南.md](iOS构建指南.md)

## 常见问题

### Q1: 构建失败怎么办？

**A:** 
1. 点击失败的构建查看日志
2. 查找错误信息（通常在红色 ✗ 的步骤中）
3. 常见问题：
   - 依赖下载失败 → 重新运行
   - 代码错误 → 修复后重新推送
   - 配置错误 → 检查 workflow 文件

### Q2: 为什么 iOS 构建比 Android 慢？

**A:** 
- macOS 虚拟机启动较慢
- iOS 编译过程更复杂
- 需要处理 CocoaPods 依赖

### Q3: 构建产物保留多久？

**A:** 
- 手动构建：30 天
- 标签构建（Release）：永久

### Q4: 可以构建 Debug 版本吗？

**A:** 
可以，修改 workflow 文件：
```yaml
- name: Build APK
  run: flutter build apk --debug
```

### Q5: 如何修改构建配置？

**A:** 
编辑 `.github/workflows/` 下的 YAML 文件：
- 修改 Flutter 版本
- 修改 Java 版本
- 添加构建参数
- 修改产物名称

### Q6: GitHub Actions 有使用限制吗？

**A:** 
- 公开仓库：免费无限制
- 私有仓库：每月 2000 分钟免费
- 超出后需要付费

### Q7: 可以在本地测试 workflow 吗？

**A:** 
可以使用 [act](https://github.com/nektos/act) 工具：
```bash
# 安装 act
brew install act  # macOS
choco install act  # Windows

# 运行 workflow
act -j build-android
```

### Q8: 如何添加构建通知？

**A:** 
可以添加 Slack、Discord、Email 等通知：
```yaml
- name: Notify on success
  if: success()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## 高级配置

### 1. 添加构建缓存

加速构建：
```yaml
- name: Cache Flutter dependencies
  uses: actions/cache@v3
  with:
    path: |
      ~/.pub-cache
      build
    key: ${{ runner.os }}-flutter-${{ hashFiles('**/pubspec.lock') }}
```

### 2. 矩阵构建

同时构建多个版本：
```yaml
strategy:
  matrix:
    flutter-version: ['3.41.7', '3.40.0']
    
steps:
  - uses: subosito/flutter-action@v2
    with:
      flutter-version: ${{ matrix.flutter-version }}
```

### 3. 条件构建

只在特定条件下构建：
```yaml
jobs:
  build-android:
    if: contains(github.event.head_commit.message, '[android]')
```

### 4. 自定义构建参数

通过输入参数控制：
```yaml
on:
  workflow_dispatch:
    inputs:
      build-mode:
        description: 'Build mode'
        required: true
        default: 'release'
        type: choice
        options:
          - release
          - debug
          - profile
```

## 最佳实践

1. **频繁提交，定期构建**
   - 每次重要更新后手动触发构建
   - 确保代码可以正常编译

2. **使用语义化版本号**
   - 主版本号：重大更新
   - 次版本号：新功能
   - 修订号：Bug 修复
   - 例如：v1.2.3

3. **编写清晰的 Release Notes**
   ```bash
   git tag -a v1.0.0 -m "
   ## 新功能
   - 添加模型管理功能
   - 支持局域网下载
   
   ## Bug 修复
   - 修复 UI 溢出问题
   
   ## 改进
   - 优化性能
   "
   ```

4. **保持 workflow 文件简洁**
   - 使用可复用的 actions
   - 避免重复代码
   - 添加注释说明

5. **监控构建状态**
   - 在 README 中添加构建徽章
   - 设置构建失败通知

## 构建徽章

在 README.md 中添加：

```markdown
![Build Status](https://github.com/你的用户名/dagou-flutter/workflows/Build%20and%20Release/badge.svg)
```

## 相关资源

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Flutter CI/CD 最佳实践](https://docs.flutter.dev/deployment/cd)
- [subosito/flutter-action](https://github.com/subosito/flutter-action)
- [actions/upload-artifact](https://github.com/actions/upload-artifact)
- [softprops/action-gh-release](https://github.com/softprops/action-gh-release)
