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

- Flutter 3.29+
- Dart 3.8+
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
└── android/            # Android 原生代码

```

---
## 🎯 开发进度

| 里程碑         | 状态     | 说明                 |
| -------------- | -------- | -------------------- |
| M1 Live2D 渲染 | ✅ 完成   | Texture 方案，60fps  |
| M2 LLM + 情感  | ✅ 完成   | DeepSeek/OpenAI 兼容 |
| M3 情感同步    | ✅ 完成   | 9 种情绪映射         |
| M4 记忆系统    | ✅ 完成   | RAG + 压缩去重       |
| M5 TTS 语音    | 🚧 规划中 | -                    |
| M6 iOS 适配    | 🚧 规划中 | -                    |

---

## 🛠️ 技术栈

- **框架:** Flutter 3.29+
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
