# Gemma 4 E2B 模型文件

## 模型信息

- **模型名称**: Gemma 4 E2B (2B 参数)
- **文件名**: `gemma-4-E2B-it.litertlm`
- **文件大小**: 约 2.5 GB
- **模型类型**: 端侧多模态模型（文本 + 图片 + 音频）

## 下载模型

由于模型文件较大（2.5GB），未包含在 Git 仓库中。请从以下地址下载：

### 方法 1: HuggingFace 官方（推荐）

```bash
curl -L "https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm" -o gemma-4-E2B-it.litertlm
```

### 方法 2: HuggingFace 镜像（国内用户）

```bash
curl -L "https://hf-mirror.com/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm" -o gemma-4-E2B-it.litertlm
```

### 方法 3: 浏览器下载

访问以下链接直接下载：
- 官方: https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm
- 镜像: https://hf-mirror.com/litert-community/gemma-4-E2B-it-litert-lm

## 安装步骤

1. 下载模型文件到此目录（`assets/models/`）
2. 确保文件名为 `gemma-4-E2B-it.litertlm`
3. 运行 `flutter pub get` 更新依赖
4. 运行 `flutter run` 启动应用

## 验证

下载完成后，文件应该：
- 位于: `assets/models/gemma-4-E2B-it.litertlm`
- 大小: 约 2.5 GB
- MD5: (待补充)

## 注意事项

- 首次启动应用时，模型会被加载到内存中，需要几秒钟时间
- 确保设备有足够的存储空间（至少 3GB 可用空间）
- 运行时需要约 1.5-2GB 内存
