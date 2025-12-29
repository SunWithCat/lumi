# Project Lumi 🌸

> 次世代虚拟伴侣应用 - Flutter + Live2D + LLM

一个有"灵魂"的 AI 伴侣，能够通过 Live2D 展现丰富表情，进行自然对话，并记住你的重要信息。

---

## ✨ 功能特性

- 🎭 **Live2D 渲染** - 60fps 流畅动画，丰富的表情和动作
- 🧠 **AI 对话** - 基于 LLM 的自然语言对话
- 💕 **情感系统** - 9 种情感状态，自动映射到表情动作
- 💾 **记忆系统** - 记住用户的重要信息，实现长期记忆
- 🎨 **精美 UI** - 粉色系可爱风格界面

---

## 🚀 快速开始

### 环境要求

- Flutter 3.10+
- Dart 3.0+
- Android Studio / VS Code
- Android 设备或模拟器

### 安装步骤

```bash
# 1. 克隆项目
git clone <项目地址>
cd lumi

# 2. 安装依赖
flutter pub get

# 3. 生成代码
dart run build_runner build

# 4. 配置 API Key (重要!)
cp lib/core/config/api_config.local.dart.example lib/core/config/api_config.local.dart
# 编辑文件，填入你的 API Key

# 5. 运行
flutter run
```

### API 配置

推荐使用 DeepSeek API（便宜好用）：

```dart
// lib/core/config/api_config.local.dart
class ApiConfig {
  static const baseUrl = 'https://api.deepseek.com';
  static const apiKey = 'sk-your-key-here';
  static const model = 'deepseek-chat';
}
```

详细配置说明：[API 配置指南](docs/API_SETUP_GUIDE.md)

---

## 📁 项目结构

```
lumi/
├── lib/
│   ├── core/           # 核心工具
│   └── features/       # 功能模块
│       ├── body/       # Live2D 模块
│       ├── soul/       # AI 对话模块
│       ├── memory/     # 记忆模块
│       └── settings/   # 设置模块
├── android/            # Android 原生代码
├── docs/               # 文档
└── assets/             # 资源文件
```

---

## 📚 文档

### 项目文档

| 文档 | 说明 |
|------|------|
| [PROJECT_STATUS.md](docs/PROJECT_STATUS.md) | 项目进度总览 |
| [ONBOARDING_GUIDE.md](docs/ONBOARDING_GUIDE.md) | 新手入门指南 |
| [API_SETUP_GUIDE.md](docs/API_SETUP_GUIDE.md) | API 配置指南 |
| [FAQ.md](docs/FAQ.md) | 常见问题 |

### 学习文档

| 文档 | 说明 |
|------|------|
| [01_Project_Structure.md](docs/learning/01_Project_Structure.md) | 项目结构详解 |
| [02_Riverpod_State_Management.md](docs/learning/02_Riverpod_State_Management.md) | 状态管理 |
| [03_Data_Flow_Analysis.md](docs/learning/03_Data_Flow_Analysis.md) | 数据流分析 |
| [04_Memory_System_Deep_Dive.md](docs/learning/04_Memory_System_Deep_Dive.md) | 记忆系统详解 |
| [05_Live2D_Integration.md](docs/learning/05_Live2D_Integration.md) | Live2D 集成 |
| [06_Practice_Tasks.md](docs/learning/06_Practice_Tasks.md) | 实践任务 |

### 模块文档

| 文档 | 说明 |
|------|------|
| [M4_Memory_System_Overview.md](docs/M4_Memory_System_Overview.md) | 记忆系统总览 |
| [M4_Context_Manager.md](docs/M4_Context_Manager.md) | 上下文管理器 |
| [M4_Memory_Evaluator.md](docs/M4_Memory_Evaluator.md) | 记忆评估器 |
| [M4_Memory_Compactor.md](docs/M4_Memory_Compactor.md) | 记忆压缩器 |

---

## 🎯 开发进度

| 里程碑 | 状态 | 说明 |
|--------|------|------|
| M1 Live2D 渲染 | ✅ 完成 | Texture 方案，60fps |
| M2 LLM + 情感 | ✅ 完成 | DeepSeek/OpenAI 兼容 |
| M3 情感同步 | ✅ 完成 | 9 种情绪映射 |
| M4 记忆系统 | ✅ 完成 | RAG + 压缩去重 |
| M5 TTS 语音 | 🚧 规划中 | - |
| M6 iOS 适配 | 🚧 规划中 | - |

---

## 🛠️ 技术栈

- **框架:** Flutter 3.x
- **状态管理:** Riverpod
- **数据库:** Drift (SQLite)
- **网络:** Dio
- **渲染:** Live2D Cubism SDK
- **AI:** DeepSeek / OpenAI API

---

## 📝 License

MIT License

---

## 🙏 致谢

- [Live2D Cubism SDK](https://www.live2d.com/)
- [DeepSeek](https://www.deepseek.com/)
- [Flutter](https://flutter.dev/)
