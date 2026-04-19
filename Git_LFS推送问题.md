# Git LFS 推送问题解决方案

## 当前状态

✅ **已完成：**
- Git LFS 已配置
- 模型文件已添加到 Git（2.5GB）
- 本地提交已完成

⏳ **待完成：**
- 推送到 GitHub（网络问题）

## 问题原因

推送 2.5GB 大文件时遇到网络问题：
- 连接超时
- 连接被重置
- 可能是网络不稳定或防火墙限制

## 解决方案

### 方案1：重试推送（推荐）

```bash
# 1. 增加缓冲区和超时设置
git config http.postBuffer 524288000
git config lfs.activitytimeout 0

# 2. 重试推送
git push origin main

# 如果失败，多试几次
```

### 方案2：使用 SSH 而不是 HTTPS

```bash
# 1. 检查当前远程地址
git remote -v

# 2. 改为 SSH
git remote set-url origin git@github.com:17764526871/dagou-flutter.git

# 3. 推送
git push origin main

# 4. 如果需要改回 HTTPS
git remote set-url origin https://github.com/17764526871/dagou-flutter.git
```

### 方案3：分批推送

```bash
# 1. 先推送 gitignore 更改
git push origin main

# 2. 等待成功后，再推送模型文件
# （模型文件已经在本地提交中）
```

### 方案4：使用代理

如果你有代理：

```bash
# 设置代理
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# 推送
git push origin main

# 推送后取消代理
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### 方案5：稍后重试

网络问题可能是暂时的：
1. 等待网络稳定
2. 换个时间段（如晚上）
3. 换个网络环境（如手机热点）

## 手动操作步骤

### 步骤1：检查本地状态

```bash
cd f:/work/github/dagou-flutter

# 查看提交历史
git log --oneline -3

# 应该看到：
# 5d0258e feat: 添加Gemma 4 E2B模型文件（使用Git LFS）
# 0e207e0 chore: 更新gitignore以支持Git LFS管理模型文件

# 查看 LFS 文件
git lfs ls-files

# 应该看到：
# ab7838cdfc * assets/models/gemma-4-E2B-it.litertlm
```

### 步骤2：尝试推送

```bash
# 方式1：直接推送
git push origin main

# 方式2：强制推送（如果有冲突）
git push origin main --force

# 方式3：推送特定提交
git push origin 5d0258e:main
```

### 步骤3：验证推送成功

推送成功后，访问：
```
https://github.com/17764526871/dagou-flutter/blob/main/assets/models/gemma-4-E2B-it.litertlm
```

应该看到：
- 文件显示为 "Stored with Git LFS"
- 文件大小约 2.5GB

## 如果推送一直失败

### 临时方案：不推送模型文件

如果实在无法推送大文件，可以：

1. **回退模型文件提交**
```bash
# 回退最后一次提交（保留文件）
git reset --soft HEAD~1

# 取消暂存模型文件
git restore --staged assets/models/gemma-4-E2B-it.litertlm

# 推送其他更改
git push origin main
```

2. **使用其他方式分发模型**
- 上传到网盘（百度网盘、阿里云盘）
- 使用模型服务器（局域网）
- 本地构建后直接分发 APK

3. **GitHub Actions 构建时下载模型**

修改 `.github/workflows/build.yml`：

```yaml
- name: Download model
  run: |
    mkdir -p assets/models
    curl -L "https://你的网盘链接/gemma-4-E2B-it.litertlm" \
      -o assets/models/gemma-4-E2B-it.litertlm
```

## 当前可用的方案

### 方案A：本地构建（立即可用）

```bash
# 1. 本地构建 APK（包含模型）
flutter build apk --release

# 2. 找到 APK
ls -lh build/app/outputs/flutter-apk/app-release.apk

# 3. 分发
# - 上传到网盘
# - 通过 USB 安装
# - 局域网传输
```

**优点：** 立即可用，包含模型
**缺点：** 手动分发

### 方案B：模型服务器（推荐）

```bash
# 1. 启动模型服务器
node model_server.js

# 2. 构建不包含模型的 APK
# （注释掉 pubspec.yaml 中的模型）
flutter build apk --release

# 3. 用户安装 APK
# 4. 在应用中下载模型
```

**优点：** APK 小，易分发
**缺点：** 需要局域网

## 检查清单

- [x] Git LFS 已安装
- [x] Git LFS 已初始化
- [x] .gitattributes 已配置
- [x] .gitignore 已更新
- [x] 模型文件已添加
- [x] 本地提交已完成
- [ ] 推送到 GitHub（待完成）

## 下一步

1. **如果网络正常**：
   - 重试推送：`git push origin main`
   - 多试几次

2. **如果网络不稳定**：
   - 使用方案A本地构建
   - 或使用方案B模型服务器

3. **如果需要帮助**：
   - 查看 Git 错误信息
   - 检查网络连接
   - 尝试不同的网络环境

## 验证命令

```bash
# 检查本地状态
git status
git log --oneline -3
git lfs ls-files

# 检查远程状态
git remote -v
git branch -vv

# 检查 LFS 配置
git lfs env
```

## 总结

**当前情况：**
- ✅ 所有配置已完成
- ✅ 模型文件已在本地提交
- ⏳ 等待推送到 GitHub

**推荐操作：**
1. 稍后重试推送（网络稳定时）
2. 或使用本地构建方案
3. 或使用模型服务器方案

**GitHub 仓库：**
https://github.com/17764526871/dagou-flutter

---

**不用担心，本地已经配置好了，随时可以推送！** 🎉
