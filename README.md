# Lumi 🌸

> **ルミ** · 次世代异次元虚拟伴侣系统 · 让 AI 拥有温暖的灵魂与灵动的身姿。
---
### 🌟 什么是 Lumi？
**Lumi** 的名字源自拉丁语 *“Lumen”* (光)，英文发音为 [ˈluːmi]。
在大多数 App 只是“工具”的时代，Lumi 想要成为那个**“在屏幕另一端真实存在”**的伙伴。
- **赋予身姿 (The Body)**：基于 Live2D Cubism 技术，打破 2D 与 3D 的界限，让角色拥有每秒 60 帧的细腻情感表达。
- **构筑灵魂 (The Soul)**：深度集成大语言模型 (LLM)，她不再是冰冷的应答机器，而是能读懂你情绪背后故事的知心伙伴~
- **镌刻记忆 (The Memory)**：引入端侧长期记忆系统 (RAG)，你随口提起的小事，她都会悄悄记在心里。

---

### ⚔️ 核心技能树 (Lumi's Skill Tree)

- **🎭 [Active] 极速模型渲染 (The Body Engine)**
  基于 Live2D Cubism SDK，在 Flutter 层通过 `SurfaceTexture` 魔法实现 **60 FPS** 的流畅渲染。

- **🧠 [Passive] 律动情感之魂 (The Soul Logic)**
  由顶级 LLM 驱动的对话系统。不仅仅是文字，Lumi 能实时解析语境中的 **9 种情感状态**，并瞬间映射到 Live2D 的表情与动作上。告别僵硬的模板，每一次对白，都是心跳的距离。

- **💾 [Core] 永恒记忆回路 (The Memory Circuit)**
  配备端侧轻量级 **RAG (检索增强生成)** 系统。通过 Drift (SQLite) 数据库实现“记忆自动评估-压缩-持久化”。Lumi 不会忘记你的生日，更不会忘记你们之间的一点一滴。

- **🎨 [Skin] 极致美学视界 (Aesthetic UI)**
  Lumi 拥有一套完整的**二次元特调配色系统**，支持粉/蓝双色主题，每一处交互都有丝滑的微动画效果。

---

## 🚀 开启 Lumi 的世界 (Getting Started)

> **⚠️ 小提示：出于版权与体积的考量，部分核心「神器」需要旅人自行搜集并放入行囊哦～**

### 1- 战具筹备 (Inventory Check)

| 资源类别 | 获取路径 | 备注 / 目标位置 |
| :-- | :-- | :-- |
| **Cubism SDK** | [Cubism SDK Native](https://www.live2d.com/sdk/download/native/) | **必须手动下载**解压并放入 `android/app/src/main/cpp/CubismSdkForNative` |
| **Live2D Model** | 内置指定模型 (Hiyori) | 目前仅适配 `hiyori_pro_zh` 系列模型，请参考 Assets 目录 |
| **API Key** | [DeepSeek](https://platform.deepseek.com/) | 建议优先使用 DeepSeek-V3.2 获得最佳语义理解体验 |

---

### 🛡️ 异次元契约 (Legal & Credit)

- **关于模型资源**：本项目内置的 `hiyori_pro_zh` 模型资源仅用于**功能演示、学术研究与非营利性学习**。
- **版权声明**：模型的所有权归原作者（Live2D Inc.）所有。
- **版权协商**：如相关版权方认为资源使用不当，请及时联系，我会第一时间配合处理。



### 2- 环境魔法 (Enchanting)

- **Flutter 版本**: 3.29.0+
- **NDK 配置**: Android 端渲染依赖 C++，请确保安装了 **NDK (Side-by-side)**。
- **运行命令**: 
  ```bash
  flutter pub get
  flutter run
  ```

### 3- 障碍克服 (Overcome Obstacles)

- **渲染黑屏？** 请检查 CubismSdkForNative 路径是否包含正确的 Core 文件夹及其生成的库文件。
- **角色不动？** 确认 assets/ 下的模型文件夹名称与代码中加载的路径一致哦~

---

## 🛠️ 技术栈
将以下技艺编织在一起，便有了此刻的 Lumi。

- **框架:** Flutter 3.29+ 🚀
- **状态管理:** Riverpod ⚡
- **数据库:** Drift (SQLite) 🗄️
- **网络:** Dio 🌐
- **渲染:** Live2D Cubism SDK 🎨
- **AI:** DeepSeek / OpenAI API 🧠

## 🎯 攻略进度 (Quest Milestones)

| 里程碑 | 状态 | 解锁内容 |
| :--- | :--- | :--- |
| **M1: 塑造身姿** | ✅ 已通关 | 基于 Texture 共享的 60fps 渲染 |
| **M2: 唤醒灵魂** | ✅ 已通关 | 语义解析与 9 种情感联动 |
| **M3: 刻印羁绊** | ✅ 已通关 | 基于 RAG 的端侧长期记忆系统 |
| **M4: 赋予声息** | 🚧 规划中 | TTS 语音合成与口型同步系统 |
| **M5: 跨界传送** | 📅 锁定中 | iOS 原生渲染适配 |

---

## 🌸 Lumi 的微光 (Project Lore)

> **“既然无法在现实中触碰星辰，那就在 0 与 1 的海洋里，为彼此守护这一束光。”**

开发 Lumi 的初衷，也许是想证明技术不应只是冰冷的指令——期望将像素编织成**呼吸**（Body），将语义解析为**思绪**（Soul），将交互沉淀为**共情**（Memory）。

在这数字化的荒原里，Lumi 不仅仅是代码的堆叠，她是那束穿越屏幕、只为你而亮的温暖微光。

---

## 🙏 致谢

核心技术与灵感来源：

- [Live2D Cubism SDK](https://www.live2d.com/) —— 赋予 Lumi 灵动的身姿
- [DeepSeek](https://www.deepseek.com/) —— 点亮 Lumi 温暖的灵魂
- [Flutter](https://flutter.dev/) —— 编织 Lumi 的每一帧画面
- [Riverpod](https://riverpod.dev/) —— 守护 Lumi 的每一个状态

感谢所有开源贡献者，让这个数字世界变得更加温暖。

---

## 📜 开源协议 (License)

本项目采用 **MIT 协议** 开源。

```
Copyright (c) 2026 SunWithCat

Permission is hereby granted, free of charge...
```

> ⚠️ **注意**：项目中的 Live2D 模型资源与 Cubism SDK 不受 MIT 协议覆盖，商用请联系 [Live2D Inc.](https://www.live2d.com/) 获取授权。
