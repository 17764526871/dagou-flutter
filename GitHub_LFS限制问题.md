# ⚠️ 重要发现：GitHub LFS 文件大小限制

## 问题

GitHub LFS 单个文件大小限制：**2GB**
我们的模型文件大小：**2.5GB**

**错误信息：**
```
Size must be less than or equal to 2147483648 (2GB)
```

## 这意味着什么？

**无法将 2.5GB 的模型文件推送到 GitHub！**

即使使用 Git LFS，GitHub 也有 2GB 的单文件限制。

## 解决方案

### 方案1：使用 GitHub Releases（推荐）

GitHub Releases 支持更大的文件（最大 2GB 每个文件，但可以多个文件）。

**步骤：**

1. **分割模型文件**
```bash
# 将 2.5GB 文件分割成 2 个文件
cd assets/models
split -b 2000M gemma-4-E2B-it.litertlm gemma-4-E2B-it.litertlm.part

# 会生成：
# gemma-4-E2B-it.litertlm.partaa (2GB)
# gemma-4-E2B-it.litertlm.partab (0.5GB)
```

2. **手动上传到 Release**
- 创建一个 Release（如 v1.0.0-models）
- 上传分割后的文件
- 在 README 中说明如何合并

3. **GitHub Actions 下载并合并**
```yaml
- name: Download and merge model
  run: |
    mkdir -p assets/models
    cd assets/models
    
    # 下载分割的文件
    curl -L "https://github.com/17764526871/dagou-flutter/releases/download/v1.0.0-models/gemma-4-E2B-it.litertlm.partaa" -o partaa
    curl -L "https://github.com/17764526871/dagou-flutter/releases/download/v1.0.0-models/gemma-4-E2B-it.litertlm.partab" -o partab
    
    # 合并文件
    cat partaa partab > gemma-4-E2B-it.litertlm
    rm partaa partab
```

### 方案2：使用外部存储（推荐）

**不将模型文件放在 GitHub，而是使用外部存储。**

#### 选项A：云存储
- 阿里云 OSS
- 腾讯云 COS
- AWS S3
- Google Cloud Storage

#### 选项B：网盘
- 百度网盘
- 阿里云盘
- OneDrive
- Google Drive

#### 选项C：自建服务器
- 使用你的 NAS
- 或租用服务器

**GitHub Actions 配置：**
```yaml
- name: Download model from external storage
  run: |
    mkdir -p assets/models
    curl -L "https://你的存储地址/gemma-4-E2B-it.litertlm" \
      -o assets/models/gemma-4-E2B-it.litertlm
```

### 方案3：应用内下载（最佳）

**不在 APK 中包含模型，首次启动时下载。**

**优点：**
- APK 体积小（约 50MB）
- 不占用 GitHub 空间
- 用户可以选择下载时机
- 可以更新模型而不更新应用

**实现：**
1. 修改 `pubspec.yaml`，不包含模型
2. 在 `LoadingScreen` 添加下载逻辑
3. 从云存储下载模型到手机

### 方案4：本地构建 + 手动分发

**不使用 GitHub Actions，本地构建后手动分发。**

```bash
# 1. 本地构建（包含模型）
flutter build apk --release

# 2. 上传到网盘
# 百度网盘、阿里云盘等

# 3. 分享链接给用户
```

## 推荐方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| GitHub Releases 分割 | 免费，自动化 | 需要分割合并 | ⭐⭐⭐ |
| 外部存储 | 简单，稳定 | 需要付费存储 | ⭐⭐⭐⭐ |
| 应用内下载 | APK小，灵活 | 需要网络 | ⭐⭐⭐⭐⭐ |
| 本地构建 | 立即可用 | 手动分发 | ⭐⭐⭐ |

## 立即可用的方案

### 当前最佳方案：本地构建 + 模型服务器

**步骤：**

1. **回退 Git LFS 提交**
```bash
cd f:/work/github/dagou-flutter

# 回退模型文件提交
git reset --soft HEAD~1
git restore --staged assets/models/gemma-4-E2B-it.litertlm

# 推送其他更改
git remote set-url origin https://github.com/17764526871/dagou-flutter.git
git push origin main
```

2. **本地构建 APK**
```bash
# 构建包含模型的 APK
flutter build apk --release

# APK 位置
build/app/outputs/flutter-apk/app-release.apk
```

3. **分发方式**
- **方式A**：上传到网盘分享
- **方式B**：使用模型服务器（局域网）
- **方式C**：USB 直接安装

## 更新 README 说明

需要在 README 中说明：

```markdown
## 下载安装

### 预编译版本

由于模型文件较大（2.5GB），超过 GitHub 限制，请通过以下方式获取：

**方式1：网盘下载**
- 链接：[百度网盘/阿里云盘链接]
- 包含完整模型，下载后直接安装

**方式2：局域网下载**
1. 在电脑上运行 `node model_server.js`
2. 安装 APK（不包含模型）
3. 在应用中设置服务器地址
4. 下载模型到手机

**方式3：本地构建**
```bash
flutter build apk --release
```
```

## 下一步操作

### 选项1：回退并推送（推荐）

```bash
# 1. 回退模型文件提交
git reset --soft HEAD~1
git restore --staged assets/models/gemma-4-E2B-it.litertlm

# 2. 切换回 HTTPS
git remote set-url origin https://github.com/17764526871/dagou-flutter.git

# 3. 推送其他更改
git push origin main

# 4. 添加说明文档
git add Git_LFS推送问题.md
git commit -m "docs: 说明GitHub LFS文件大小限制"
git push
```

### 选项2：实现应用内下载

这是长期最佳方案，需要：
1. 修改代码实现下载功能
2. 将模型上传到云存储
3. 更新 GitHub Actions

### 选项3：使用 GitHub Releases

1. 分割模型文件
2. 创建 Release
3. 上传分割文件
4. 更新 GitHub Actions

## 总结

**关键发现：**
- ❌ GitHub LFS 限制单文件 2GB
- ❌ 我们的模型 2.5GB 超过限制
- ✅ 需要使用其他方案

**推荐方案：**
1. **短期**：本地构建 + 网盘分发
2. **长期**：实现应用内下载

**立即行动：**
```bash
# 回退模型提交
git reset --soft HEAD~1
git restore --staged assets/models/gemma-4-E2B-it.litertlm

# 推送其他更改
git remote set-url origin https://github.com/17764526871/dagou-flutter.git
git push origin main
```

---

**不用担心，我们有多种解决方案！** 💪
