# Voice2Text 架构文档

## 概述

Voice2Text v2.0 采用模块化架构设计，提高代码的可维护性、可测试性和可扩展性。

## 目录结构

```
Voice2Text/
├── Sources/
│   ├── App/                    # 应用程序入口
│   │   ├── AppDelegate.swift   # 主应用代理（协调各模块）
│   │   ├── main.swift          # 程序入口点
│   │   └── Info.plist          # 应用配置文件
│   │
│   ├── Core/                   # 核心业务逻辑
│   │   ├── Audio/              # 音频处理
│   │   │   ├── AudioEngine.swift        # 音频录制引擎
│   │   │   └── AudioUtilities.swift     # 音频工具函数
│   │   │
│   │   ├── Transcription/      # 转录服务
│   │   │   ├── WhisperService.swift     # Whisper API 集成
│   │   │   ├── WhisperConfiguration.swift # 配置管理
│   │   │   └── WhisperError.swift       # 错误定义
│   │   │
│   │   └── Input/              # 输入处理
│   │       ├── GlobalKeyboardMonitor.swift # 全局键盘监听
│   │       └── TextInsertionService.swift  # 文本插入服务
│   │
│   ├── Models/                 # 数据模型
│   │   └── RecordingState.swift # 录音状态枚举
│   │
│   ├── Services/               # 服务层
│   │   ├── RecordingCoordinator.swift   # 录音流程协调器
│   │   ├── PermissionManager.swift      # 权限管理
│   │   └── ConfigurationManager.swift   # 配置管理
│   │
│   ├── UI/                     # 用户界面
│   │   ├── StatusBar/          # 状态栏
│   │   │   └── StatusBarController.swift # 状态栏控制器
│   │   │
│   │   └── Preferences/        # 偏好设置
│   │       ├── PreferencesWindowController.swift # 设置窗口
│   │       └── EditableTextField.swift          # 可编辑文本框
│   │
│   └── Utilities/              # 工具类
│       └── DotEnv.swift        # 环境变量加载
│
├── Scripts/                    # 构建脚本
│   ├── build.sh               # 构建脚本
│   ├── install.sh             # 安装脚本
│   ├── run.sh                 # 运行脚本
│   └── test.sh                # 测试脚本
│
└── Documentation/              # 文档
    ├── README.md              # 项目说明
    └── Architecture.md        # 架构文档（本文件）
```

## 核心组件

### 1. AppDelegate（应用程序代理）
- **职责**：应用程序生命周期管理，协调各个模块
- **依赖**：所有主要服务和控制器
- **设计模式**：代理模式、观察者模式

### 2. RecordingCoordinator（录音协调器）
- **职责**：协调整个录音和转录流程
- **依赖**：AudioEngine, WhisperService, TextInsertionService
- **设计模式**：协调器模式、代理模式

### 3. StatusBarController（状态栏控制器）
- **职责**：管理菜单栏UI和用户交互
- **依赖**：无
- **设计模式**：MVC模式

### 4. PermissionManager（权限管理器）
- **职责**：统一管理系统权限请求和检查
- **依赖**：系统框架
- **设计模式**：单例模式

### 5. ConfigurationManager（配置管理器）
- **职责**：管理应用配置和设置
- **依赖**：WhisperConfiguration
- **设计模式**：单例模式

## 数据流

```
用户按下Fn键
    ↓
GlobalKeyboardMonitor 检测到按键
    ↓
AppDelegate 接收事件
    ↓
RecordingCoordinator.startRecording()
    ↓
AudioEngine 开始录音
    ↓
用户松开Fn键
    ↓
RecordingCoordinator.stopRecording()
    ↓
AudioEngine 停止录音并返回音频数据
    ↓
WhisperService 发送音频到API
    ↓
WhisperService 接收转录结果
    ↓
TextInsertionService 插入文本到当前应用
    ↓
StatusBarController 更新状态显示
```

## 设计原则

### 1. 单一职责原则（SRP）
每个类只负责一个功能领域：
- AudioEngine 只负责音频录制
- WhisperService 只负责API通信
- TextInsertionService 只负责文本插入

### 2. 开闭原则（OCP）
通过协议和抽象实现扩展性：
- 可以轻松添加新的转录服务
- 可以扩展新的输入方式

### 3. 依赖倒置原则（DIP）
高层模块不依赖低层模块：
- RecordingCoordinator 依赖抽象接口
- 具体实现可以替换

### 4. 接口隔离原则（ISP）
使用精简的协议定义：
- RecordingCoordinatorDelegate
- StatusBarControllerDelegate
- WhisperServiceDelegate

## 扩展点

### 添加新的转录服务
1. 创建新的服务类实现转录逻辑
2. 在 RecordingCoordinator 中注入新服务
3. 在设置界面添加服务选择选项

### 添加新的触发方式
1. 创建新的监听器类
2. 在 AppDelegate 中初始化监听器
3. 连接到 RecordingCoordinator

### 添加新的输出方式
1. 创建新的输出服务类
2. 在 RecordingCoordinator 中调用新服务
3. 在设置中添加输出选项

## 测试策略

### 单元测试
- 每个核心类都应有对应的单元测试
- 使用协议实现依赖注入，便于模拟测试

### 集成测试
- 测试完整的录音-转录流程
- 测试权限请求流程
- 测试配置更新流程

### UI测试
- 测试状态栏交互
- 测试设置窗口功能
- 测试键盘快捷键响应

## 性能优化

### 内存管理
- 使用弱引用避免循环引用
- 及时释放音频缓冲区
- 限制音频文件大小

### 响应速度
- 异步处理网络请求
- 使用流式处理（如API支持）
- 优化键盘事件响应

## 安全考虑

### API密钥保护
- 密钥存储在本地环境变量
- 不在代码中硬编码密钥
- 使用 HTTPS 传输

### 权限管理
- 最小权限原则
- 明确告知用户所需权限
- 提供权限撤销选项

## 版本迁移

### 从 v1.0 到 v2.0
- 配置自动迁移
- 保持向后兼容
- 提供迁移指南

## 未来规划

### 短期（v2.1）
- 添加更多快捷键选项
- 支持更多语言
- 改进错误处理

### 中期（v3.0）
- 支持本地模型
- 添加历史记录功能
- 支持批量处理

### 长期
- 跨平台支持
- 云同步功能
- 插件系统