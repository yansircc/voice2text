# Voice2Text v2.0 🎙️

<div align="center">

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Architecture](https://img.shields.io/badge/Architecture-Modular-purple.svg)

**全局语音转文字工具 - 让输入更简单**

[功能特性](#-功能特性) • [快速开始](#-快速开始) • [使用方法](#-使用方法) • [架构设计](#-架构设计) • [配置说明](#-配置说明)

</div>

## 📸 预览

Voice2Text 是一个 macOS 原生应用，通过全局热键快速将语音转换为文字，自动输入到任何应用程序中。

## ✨ 功能特性

### 核心功能
- 🎤 **全局热键录音** - 按住 Fn 键开始录音，松开自动转录
- 📝 **智能文本插入** - 转录结果自动输入到当前光标位置
- 🔄 **实时状态反馈** - 录音、处理、转录状态实时显示
- 🚀 **快速响应** - 使用 Whisper API 高精度转录

### 技术亮点
- 🏗️ **模块化架构** - 清晰的分层设计，易于维护和扩展
- 🎯 **中文优化** - 针对中文语音识别优化配置
- 🌐 **API 兼容** - 支持 OpenAI、Azure、自定义 API
- 💾 **配置管理** - 支持环境变量和用户界面配置

## 🚀 快速开始

### 系统要求
- macOS 13.0 或更高版本
- Xcode Command Line Tools
- Whisper API 密钥

### 安装步骤

1. **克隆仓库**
```bash
git clone https://github.com/yourusername/voice2text.git
cd voice2text
```

2. **配置 API**
```bash
cp .env.example .env
# 编辑 .env 文件，填入你的 WHISPER_API_KEY
```

3. **构建安装**
```bash
cd Scripts
./build.sh
# 或使用一键安装
./install.sh
```

## 🎮 使用方法

### 基本操作
1. 启动应用后，图标会出现在菜单栏
2. 将光标放在任何文本输入框
3. **按住 Fn 键** 开始录音（显示"🎙️ 正在录音..."）
4. **松开 Fn 键** 结束录音并自动转录
5. 转录的文字会自动输入到光标位置

### 菜单栏功能
- **状态显示** - 实时显示当前状态
- **偏好设置** - 配置 API、模型、语言等
- **关于** - 查看版本信息

## 🏗️ 架构设计

Voice2Text v2.0 采用模块化架构设计，提高代码的可维护性和可扩展性。

```
Sources/
├── App/              # 应用程序入口
├── Core/             # 核心业务逻辑
│   ├── Audio/        # 音频录制处理
│   ├── Transcription/# 语音转文字服务
│   └── Input/        # 键盘监听和文本输入
├── Services/         # 服务层
│   ├── RecordingCoordinator  # 录音流程协调
│   ├── PermissionManager     # 权限管理
│   └── ConfigurationManager  # 配置管理
├── UI/               # 用户界面
│   ├── StatusBar/    # 状态栏控制
│   └── Preferences/  # 偏好设置窗口
└── Models/           # 数据模型
```

详细架构文档：[Architecture.md](Documentation/Architecture.md)

## ⚙️ 配置说明

### 环境变量配置

创建 `.env` 文件并配置以下变量：

```bash
# 必需：API 密钥
WHISPER_API_KEY=your-api-key-here

# 可选：API 地址（默认：OpenAI）
WHISPER_BASE_URL=https://api.openai.com

# 可选：模型选择
WHISPER_MODEL_ID=whisper-large-v3

# 可选：语言设置（默认：中文）
WHISPER_LANGUAGE=zh

# 可选：温度参数（0.0-1.0）
WHISPER_TEMPERATURE=0.2
```

### 支持的 API 服务

- **OpenAI** - 官方 Whisper API
- **Azure OpenAI** - Azure 托管服务
- **自定义服务** - 兼容 OpenAI 格式的第三方服务

## 🔑 权限设置

首次运行需要授予以下权限：

### 辅助功能权限（必需）
```
系统设置 > 隐私与安全性 > 辅助功能
添加并勾选 Voice2Text
```

### 麦克风权限（必需）
```
系统设置 > 隐私与安全性 > 麦克风
允许 Voice2Text 访问
```

## 🛠️ 开发相关

### 构建项目
```bash
cd Scripts
./build.sh
```

### 运行测试
```bash
./run.sh  # 构建并直接运行
```

### 项目结构
- `Sources/` - 源代码（模块化组织）
- `Scripts/` - 构建和部署脚本
- `Documentation/` - 项目文档

## 📝 更新日志

### v2.0.0 (2024-01)
- 🏗️ 全新模块化架构
- ✨ 改进的录音指示器
- 🔧 更好的配置管理
- 🐛 修复音频回声问题
- 📚 完善的文档

### v1.0.0
- 🎉 初始版本发布
- 基本录音和转录功能

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 开发建议
1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

- [OpenAI Whisper](https://openai.com/research/whisper) - 强大的语音识别模型
- Swift 社区 - 优秀的开发工具和库

## 📮 联系方式

如有问题或建议，请提交 [Issue](https://github.com/yourusername/voice2text/issues)

---

<div align="center">
Made with ❤️ for macOS users
</div>