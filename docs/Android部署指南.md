# Android 部署指南

## 方法一：直接运行到设备（推荐）

### 前提条件
- Android 设备已连接并开启 USB 调试
- 已安装 Android SDK 和驱动

### 步骤

1. **检查设备连接**
```bash
flutter devices
# 应该能看到你的设备：23113RKC6C
```

2. **等待 Gradle 下载完成**

首次构建时，Gradle 需要下载依赖包（约 100-200MB），这可能需要 5-10 分钟。

你可以手动触发下载：
```bash
cd android
./gradlew --version
# 等待下载完成
```

3. **运行应用**
```bash
flutter run -d 23113RKC6C
```

## 方法二：构建 APK 并手动安装

### 构建 Debug APK

```bash
# 确保 Gradle 已下载完成
cd android
./gradlew clean

# 返回项目根目录
cd ..

# 构建 APK
flutter build apk --debug
```

APK 文件位置：
```
build/app/outputs/flutter-apk/app-debug.apk
```

### 安装到设备

```bash
# 方法1：使用 adb
adb install build/app/outputs/flutter-apk/app-debug.apk

# 方法2：使用 flutter
flutter install -d 23113RKC6C
```

### 手动安装

1. 将 APK 文件复制到手机
2. 在手机上打开文件管理器
3. 点击 APK 文件安装
4. 允许安装未知来源应用

## 方法三：构建 Release APK（生产版本）

### 构建命令

```bash
flutter build apk --release
```

生成的 APK：
```
build/app/outputs/flutter-apk/app-release.apk
```

### Release 版本优势
- 体积更小（约为 Debug 版本的 1/3）
- 性能更好
- 适合分发给其他用户

## 常见问题

### 1. Gradle 下载超时

**问题**：`Timeout of 120000 reached waiting for exclusive access`

**解决方案**：
```bash
# 删除损坏的 Gradle 缓存
rm -rf C:/Users/jack/.gradle/wrapper/dists/gradle-8.14-all

# 重新下载
cd android
./gradlew --version
```

### 2. 设备未授权

**问题**：`device unauthorized`

**解决方案**：
1. 在手机上允许 USB 调试授权
2. 重新连接设备
3. 运行 `adb devices` 确认

### 3. 安装失败

**问题**：`INSTALL_FAILED_UPDATE_INCOMPATIBLE`

**解决方案**：
```bash
# 卸载旧版本
adb uninstall com.example.dagou_flutter

# 重新安装
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### 4. 权限问题

首次运行时，应用会请求以下权限：
- 相机权限
- 麦克风权限
- 存储权限

请在手机上点击"允许"。

## 性能优化建议

### 1. 启用 R8 代码压缩

编辑 `android/app/build.gradle.kts`：
```kotlin
buildTypes {
    release {
        minifyEnabled = true
        shrinkResources = true
    }
}
```

### 2. 启用 ProGuard

创建 `android/app/proguard-rules.pro`：
```
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
```

### 3. 分包构建

```bash
# 构建 ARM64 版本（推荐，适用于大多数现代设备）
flutter build apk --target-platform android-arm64 --release

# 构建通用版本（兼容所有设备，但体积较大）
flutter build apk --release
```

## 应用签名（发布到应用商店）

### 1. 生成签名密钥

```bash
keytool -genkey -v -keystore dagou-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias dagou
```

### 2. 配置签名

创建 `android/key.properties`：
```properties
storePassword=你的密码
keyPassword=你的密码
keyAlias=dagou
storeFile=../dagou-release-key.jks
```

### 3. 构建签名版本

```bash
flutter build apk --release
```

## 测试清单

安装后请测试以下功能：

- [ ] 应用正常启动
- [ ] 显示欢迎消息
- [ ] 文本输入和发送
- [ ] 图片选择功能
- [ ] 相机拍照功能
- [ ] 视频选择功能
- [ ] 语音输入功能
- [ ] 语音播报功能
- [ ] 权限请求正常
- [ ] AI 响应正常（需配置 API Key）

## 下一步

1. 配置 API Key（见 [USAGE.md](USAGE.md)）
2. 测试所有功能
3. 根据需要调整 UI 和配置
4. 准备发布到应用商店

---

**提示**：首次构建可能需要较长时间，请耐心等待 Gradle 下载完成。
