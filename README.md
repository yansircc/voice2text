# Voice2Text v1.0 - 全局语音转文字工具

一个 macOS 原生应用，通过全局热键快速将语音转换为文字，并自动输入到当前光标位置。

## ✨ 特性

- 🎤 **全局热键录音**：按住 Fn 键或 F5 开始录音，松开自动转录
- 📝 **自动文本插入**：转录结果自动输入到当前光标位置
- 🔄 **后台运行**：作为菜单栏应用常驻后台，不显示 Dock 图标
- 🚀 **快速响应**：使用 Whisper API 实时转录
- 🎯 **中文优化**：针对中文语音识别优化配置
- 🌐 **API 兼容**：支持 OpenAI、Azure、第三方兼容服务

## 📦 快速安装

### 一键安装（推荐）

```bash
# 1. 配置 API（首次使用）
cp .env.example .env
# 编辑 .env 文件，填入你的 WHISPER_API_KEY

# 2. 安装
./install.sh
```

### 手动安装

```bash
# 1. 构建
./build.sh

# 2. 安装到系统
cp -r build/Voice2Text.app /Applications/
open /Applications/Voice2Text.app
```

## 🔑 权限设置

首次运行时需要授予以下权限：

1. **辅助功能权限**（必需）
   - 系统设置 > 隐私与安全性 > 辅助功能
   - 添加并勾选 Voice2Text

2. **麦克风权限**（必需）
   - 系统设置 > 隐私与安全性 > 麦克风
   - 允许 Voice2Text 访问

## 🎮 使用方法

1. **启动应用**：应用会在菜单栏显示麦克风图标
2. **录音转文字**：
   - 方法 1：按住 **Fn** 键开始录音，松开键自动转录
   - 方法 2：按住 **F5** 键开始录音，松开键自动转录
3. **查看状态**：点击菜单栏图标查看当前状态
4. **退出应用**：点击菜单栏图标 > Quit

## 🔧 工作原理

1. **全局键盘监听**：使用 CGEventTap 监听系统键盘事件
2. **音频录制**：使用 AVAudioEngine 捕获麦克风音频
3. **语音转文字**：通过 Whisper API 进行转录
4. **文本插入**：模拟键盘输入将文本插入当前位置

## 📁 项目结构

```
v1/
├── AppDelegate.swift           # 主应用程序逻辑
├── GlobalKeyboardMonitor.swift  # 全局热键监听
├── AudioEngine.swift           # 音频录制引擎
├── WhisperService.swift        # Whisper API 集成
├── WhisperConfiguration.swift  # 配置管理
├── AudioUtilities.swift        # 音频处理工具
├── DotEnv.swift               # 环境变量加载
├── Info.plist                 # 应用配置
├── build.sh                   # 构建脚本
└── run.sh                     # 开发运行脚本
```

## 🚀 开发模式

```bash
# 快速运行（用于开发测试）
./run.sh
```

## ⚙️ 配置选项

在 `.env` 文件中可配置：

- `WHISPER_BASE_URL` - API 端点
- `WHISPER_API_KEY` - API 密钥
- `WHISPER_MODEL_ID` - 模型选择（whisper-large-v3）
- `WHISPER_LANGUAGE` - 语言设置（zh）
- `WHISPER_TEMPERATURE` - 温度参数（0.2）
- `WHISPER_PROMPT` - 提示词

## 🐛 故障排除

1. **无法监听键盘**：检查辅助功能权限
2. **无法录音**：检查麦克风权限
3. **F5 键被占用**：系统设置中禁用 F5 的听写功能
4. **转录失败**：检查 API key 和网络连接

## 📝 版本历史

- **v1.0** - 初始版本
  - 全局热键录音
  - 自动文本插入
  - 菜单栏应用
  - Whisper API 集成

## 🔮 未来计划

- [ ] 添加配置界面
- [ ] 支持自定义热键
- [ ] 转录历史记录
- [ ] 多语言支持
- [ ] 本地模型支持