# BarKeep

<p align="center">
  <strong>一款基于 Swift 和 SwiftUI 从零打造的轻量级、极致快速的 macOS 菜单栏管理工具。</strong>
</p>

<p align="center">
  <a href="README.md">English</a> •
  <a href="README.ru.md">Русский</a> •
  <a href="README.kk.md">Қазақша</a> •
  <a href="README.zh.md"><strong>简体中文</strong></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/平台-macOS%2014.0%2B-blue?style=flat-square" alt="平台: macOS 14.0+" />
  <img src="https://img.shields.io/badge/Swift-5.0-orange?style=flat-square" alt="Swift 5.0" />
  <img src="https://img.shields.io/badge/架构-Apple%20Silicon%20%7C%20Intel-green?style=flat-square" alt="架构" />
  <img src="https://img.shields.io/badge/许可证-MIT-purple?style=flat-square" alt="许可证" />
</p>

---

## 项目简介

**BarKeep** 是一款受 Bartender 和 Ice 启发的开源 macOS 菜单栏图标管理工具。它可以将多余的菜单栏图标收起至屏幕外，通过悬浮控制面板让您随心访问隐藏项目，支持跨语言即时拼音/转写模糊搜索，支持鼠标悬停自动展开，并提供一键紧急重置全局快捷键恢复所有图标。

本项目基于 **Swift、AppKit 和 SwiftUI** 原生开发，无任何第三方依赖。未复制任何 GPL-3.0 源代码，所有逻辑与底层交互均独立设计实现。

---

## 核心特性

- **屏幕外图标隐藏机制**：利用零占位分割线扩展至 10,000 px 的物理位移，将分割线左侧的图标优雅平滑地推移至屏幕可视范围之外。
- **悬浮 Bar Panel 面板**（*左键点击* BarKeep 图标）：高颜值的毛玻璃 HUD 窗口，实时呈现被隐藏图标的高清快照，支持触控板与鼠标滚轮平滑横向滚动。
- **多语言即时搜索**：内置智能音译匹配（无论使用拉丁字母、西里尔字母还是哈萨克语输入，均可准确检索对应应用）。按 `Enter` 直接激活首个匹配应用，按 `Esc` 或点击外部即可关闭。
- **原生模拟点击激活**：点击悬浮面板中的图标后，系统会短暂显示隐藏区域并使用 Accessibility API 触发原生 `AXPress` 事件弹出对应菜单，操作完成后自动重新收起。
- **鼠标悬停展开**：当鼠标悬停在菜单栏空白区域时，隐藏图标将自动滑动展开；移开光标后自动折叠。
- **进程管理右键菜单**：在悬浮面板中右键点击任意图标，可直接激活、隐藏、正常退出或强制退出对应应用程序（非系统应用附带安全确认弹窗）。
- **全局快捷键**（基于 Carbon `RegisterEventHotKey`）：
  - `⌃⌥⌘H` — 展开 / 折叠“已隐藏”区域
  - `⌃⌥⌘A` — 展开 / 折叠“始终隐藏”区域
  - `⌃⌥⌘R` — 紧急重置（立即恢复所有菜单栏图标）
- **多语言国际化支持**：
  - 英语（English，默认）
  - 俄语（Русский）
  - 哈萨克语（Қазақша）
  - 简体中文（Chinese Simplified）
  - 支持在状态栏菜单中实时切换语言，无需重启应用。
- **安全优雅退出**：退出 BarKeep 时自动复原所有分割线位移，杜绝菜单栏图标残留隐藏状态。
- **脚本与终端自动化友好**：内置功能完善的 CLI 命令行接口，可用于自动化巡检和控制。
- **可复现的本地代码签名**：自动在本地钥匙串生成自签名证书，即使反复执行 Debug 重新编译，系统 TCC 权限（辅助功能与屏幕录制）依然持久有效。

---

## 系统要求

- **macOS 14.0 (Sonoma)** 或更高版本（已在 macOS 15 Sequoia、Apple Silicon 及 Intel 架构设备上完成全面测试）。
- **Xcode 15.0+** 以及配套的 Command Line Tools。
- **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** (`brew install xcodegen`)。
- 无需付费 Apple 开发者账号：基于本地自签名证书即可完整体验。

---

## 快速上手与编译构建

克隆仓库并编译运行 Debug 版本：

```bash
git clone https://github.com/your-username/BarKeep.git
cd BarKeep

# 1. 创建本地开发自签名证书（仅需运行一次）
make signing

# 2. 生成 Xcode 工程并开始编译
make gen
make build

# 3. 运行 BarKeep
make run
```

### 常用 Makefile 指令

| 指令 | 说明 |
|---|---|
| `make signing` | 在钥匙串中配置名为 `BarKeep Dev` 的自签名证书 |
| `make gen` | 读取 `project.yml` 并重新生成 `BarKeep.xcodeproj` |
| `make build` | 在 `build/` 目录下完成编译和签名 |
| `make run` | 终止旧进程并启动全新编译的应用程序 |
| `make stop` | 正常终止 BarKeep 并恢复所有菜单栏图标 |
| `make logs` | 实时查看运行日志 (`~/Library/Logs/BarKeep.log`) |
| `make report` | 输出最近的诊断日志报告 |
| `make clean` | 清理编译产物及生成的 Xcode 工程文件 |

---

## 系统权限配置

首次启动 BarKeep 时，系统会引导您授予两项 macOS 隐私权限：

1. **辅助功能（Accessibility）**：用于扫描图标坐标、遍历 AX 元素树以及模拟点击第三方菜单栏项目。
2. **屏幕录制（Screen Recording）**：用于捕获隐藏图标的高清界面快照并呈现在悬浮面板中。

授权步骤：
1. 打开 **系统设置 → 隐私与安全性**。
2. 进入 **辅助功能（Accessibility）**，为 `BarKeep` 开启权限开关。
3. 进入 **屏幕录制（Screen Recording）**，为 `BarKeep` 开启权限开关。
4. 重启 BarKeep。

> **提示**：若直接在终端中运行二进制文件，macOS 会将权限归属于终端应用（如 Terminal、iTerm2）。如需独立测试，请使用 `open build/Build/Products/Debug/BarKeep.app`。

---

## 交互与快捷键

| 操作 | 触发方式 |
|---|---|
| **打开 / 关闭悬浮面板** | 左键点击 BarKeep 状态栏图标 |
| **打开菜单与设置** | 右键点击或 `⌃` + 左键点击 BarKeep 状态栏图标 |
| **切换隐藏区域** | `⌃⌥⌘H` |
| **切换始终隐藏区域** | `⌃⌥⌘A` |
| **紧急恢复所有图标** | `⌃⌥⌘R` |

### 调整菜单栏区域与分割线

BarKeep 将菜单栏自右向左划分为三个区域：
`[系统控制中心] [BarKeep] [可见图标] | 隐藏分割线 | [已隐藏图标] | 始终隐藏分割线 | [始终隐藏图标]`

1. 使用快捷键 `⌃⌥⌘H` 或打开面板展示所有隐藏图标。
2. 按住键盘上的 `⌘` 键，将菜单栏上的垂直细分割线向左或向右拖动，调整可见与隐藏的分界线。
3. 也可直接按住 `⌘` 键将任意第三方菜单栏图标拖动跨过分割线。
4. 再次按下 `⌃⌥⌘H` 重新折叠隐藏区域。

---

## 语言设置

BarKeep 原生支持 4 种语言，默认语言为英文：

1. 右键点击菜单栏中的 BarKeep 图标打开设置菜单。
2. 将光标移至 **Language**（语言）菜单项。
3. 选择您需要的语言：
   - **English**（英文，默认）
   - **Русский**（俄文）
   - **Қазақша**（哈萨克文）
   - **简体中文**（Simplified Chinese）

菜单、悬浮面板、搜索音译及系统弹窗将立即刷新，设置会自动保存在 `UserDefaults` 中并在下次启动时保持生效。

---

## 命令行（CLI）与自动化

编译后的二进制文件支持丰富的 CLI 调试和控制命令：

```bash
# 扫描并输出所有活动菜单栏图标详情（坐标、AX 状态、PID、Bundle ID）
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --scan

# 按应用名称或窗口 ID 模拟点击
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --press "控制中心"

# 向正在运行的 BarKeep 实例发送内部通信指令
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --send showHidden
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --send hideHidden
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --send toggleHidden
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --send reset
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --send panel
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --send "activate:Telegram"
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --send quit
```

---

## 项目代码结构

```
BarKeep/
├── App/
│   ├── AppDelegate.swift          # 应用生命周期、权限引导、全局快捷键、命令总线
│   ├── AppEnvironment.swift       # 屏幕尺寸计算、检测第三方同类软件冲突
│   ├── BarKeepApp.swift           # CLI 入口与 NSApplication 启动器
│   └── Info.plist                 # Bundle 元数据与 LSUIElement 常驻模式配置
├── Core/
│   ├── AX/                        # Accessibility 封装与 AXUIElement 辅助函数
│   ├── Capture/                   # ScreenCaptureKit / CGWindowList 截图缓存
│   ├── CommandBus.swift           # 进程间通信与 CLI 命令分发总线
│   ├── Hotkeys/                   # 基于 Carbon HIToolbox 的全局快捷键中枢
│   ├── Localization/              # AppLanguage 枚举与多语言词典（en, ru, kk, zh）
│   ├── Logging/                   # 本地日志记录（~/Library/Logs/BarKeep.log）
│   ├── MenuBar/                   # 图标扫描、坐标布局计算、光标悬停监听
│   └── Permissions/               # Accessibility 和 Screen Recording 权限检查
├── UI/
│   ├── BarPanel/                  # SwiftUI 悬浮毛玻璃面板、水平图标滚动与模糊搜索
│   ├── ClosureMenuItem.swift      # 基于闭包回调的优雅 NSMenuItem 子类
│   └── StatusItemController.swift # 状态栏主菜单、设置选项、多语言切换
├── Makefile                       # 开发与构建脚本
├── project.yml                    # XcodeGen 声明式工程配置
└── scripts/
    └── setup-signing.sh           # 本地钥匙串开发证书生成脚本
```

---

## 诊断与故障排除

- **实时日志**：文件位于 `~/Library/Logs/BarKeep.log`，也可直接执行 `make logs`。
- **诊断快照**：右键点击 BarKeep 图标 → 选择“复制诊断报告到剪贴板”。
- **紧急恢复**：若界面异常，随时按下 `⌃⌥⌘R` 或在终端运行 `BarKeep --send reset` 立即复原所有图标。
- **多软件冲突**：请避免同时运行 Ice、Bartender 等同类软件。当检测到冲突时，BarKeep 会在菜单中给出醒目提示。

---

## 开源许可证

本项目基于 [MIT 许可证](LICENSE) 开源发布。
