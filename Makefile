# Dagou AI - Flutter 快捷命令
# 使用方法: make <command>
# Windows 用户: 需要安装 GNU Make (https://gnuwin32.sourceforge.net/packages/make.htm)
#              或直接运行 scripts/ 下的 bat 脚本

DEVICE_ID ?= 6150eeda
APK_RELEASE = build/app/outputs/flutter-apk/app-release.apk
APK_DEBUG   = build/app/outputs/flutter-apk/app-debug.apk

.PHONY: help run run-release build build-debug build-ios install install-debug \
        analyze format clean pub upgrade download-model

help:
	@echo ""
	@echo "  Dagou AI - 快捷命令"
	@echo "  ─────────────────────────────────────────"
	@echo "  make run            Debug 模式运行"
	@echo "  make run-release    Release 模式运行（推荐，性能更好）"
	@echo "  make build          构建 Release APK"
	@echo "  make build-debug    构建 Debug APK"
	@echo "  make build-ios      构建 iOS IPA（需要 macOS）"
	@echo "  make install        构建 Release APK 并安装到设备"
	@echo "  make install-debug  构建 Debug APK 并安装到设备"
	@echo "  make analyze        代码静态分析"
	@echo "  make format         格式化代码"
	@echo "  make clean          清理构建缓存"
	@echo "  make pub            获取依赖"
	@echo "  make upgrade        升级依赖"
	@echo "  make download-model 下载 Gemma 4 E2B 模型文件"
	@echo "  ─────────────────────────────────────────"
	@echo "  DEVICE_ID=$(DEVICE_ID) (可通过 make install DEVICE_ID=<id> 覆盖)"
	@echo ""

# ── 运行 ──────────────────────────────────────────────────────────────────────

run:
	flutter run -d $(DEVICE_ID)

run-release:
	flutter run --release -d $(DEVICE_ID)

# ── 构建 ──────────────────────────────────────────────────────────────────────

build:
	flutter build apk --release

build-debug:
	flutter build apk --debug

build-ios:
	flutter build ios --release --no-codesign

# ── 安装 ──────────────────────────────────────────────────────────────────────

install: build
	adb -s $(DEVICE_ID) install -r $(APK_RELEASE)
	@echo "✅ Release APK 已安装到设备 $(DEVICE_ID)"

install-debug: build-debug
	adb -s $(DEVICE_ID) install -r $(APK_DEBUG)
	@echo "✅ Debug APK 已安装到设备 $(DEVICE_ID)"

# ── 代码质量 ──────────────────────────────────────────────────────────────────

analyze:
	flutter analyze --no-fatal-infos

format:
	flutter format .

# ── 依赖管理 ──────────────────────────────────────────────────────────────────

clean:
	flutter clean

pub:
	flutter pub get

upgrade:
	flutter pub upgrade

# ── 模型下载 ──────────────────────────────────────────────────────────────────

download-model:
	@echo "📥 开始下载 Gemma 4 E2B 模型（约 2.4GB）..."
	@mkdir -p assets/models
	curl -L --progress-bar \
	  "https://hf-mirror.com/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm" \
	  -o assets/models/gemma-4-E2B-it.litertlm
	@echo "✅ 模型下载完成: assets/models/gemma-4-E2B-it.litertlm"
