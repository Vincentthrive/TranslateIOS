# 实时英文会议中文字幕 App 设计文档

- 日期：2026-08-11
- 状态：已确认（方案 A：Apple 原生离线识别 + 翻译）
- 目标平台：iPadOS 17.4+

## 1. 目标

开发一个 iPad 应用：用户以 iPad 分屏方式参加 Zoom 英文会议时，App 通过麦克风听取扬声器声音，实时识别英文并显示中文字幕，让不懂英文的用户能跟上会议内容。

## 2. 核心场景

1. 用户在 iPad 上开启 Zoom 会议，会议声音从扬声器播放。
2. 用户将本 App 放在分屏另一侧，点击“开始聆听”。
3. App 实时显示英文原文和中文翻译，中文为大字、英文为辅助小字。
4. 会议结束或不需要字幕时，点击“停止”。

## 3. MVP 范围

### 必须做

- 麦克风实时听声。
- Apple 本地英文语音识别（实时 partial + final 结果）。
- Apple 本地英中翻译，全部离线。
- A 方案字幕界面：底部通栏，中文大字、英文小字在上。
- 顶部控制：开始/停止、字号调整、显示/隐藏英文、清空字幕。
- 首次使用权限说明：麦克风、语音识别；被拒绝后提供跳转系统设置入口。
- 明确错误提示：无权限、识别不可用、翻译不可用、系统版本低于 iPadOS 17.4、长时间听不到声音。
- 支持 iPad 分屏、横竖屏、深色模式。
- 全程离线，不注册、不登录、不收集数据。

### 本次不做（为后续预留）

- 自己的视频播放器。
- iPhone 单屏悬浮字幕。
- 云端翻译引擎（OpenAI / DeepL 等）。
- Zoom SDK / 直接加入会议。
- 会议录音、字幕历史导出。
- 与 Zoom 同时使用麦克风时的冲突处理（真机验证后再决定方案）。

## 4. 系统架构

App 拆成独立小模块，每个模块只负责一件事：

1. **AudioCaptureService**：管理音频会话与麦克风权限，使用 `AVAudioEngine` 获取麦克风音频缓冲，送入识别引擎。
2. **SpeechRecognitionService**：使用 `SFSpeechRecognizer`（en-US，on-device）实时识别，输出 partial（正在识别）和 final（已确认）文本。
3. **TranslationService**：使用 Apple `Translation` framework 将英文翻译为中文；通过协议抽象，未来可无缝替换为云端引擎。
4. **CaptionSession / ViewModel**：组合识别与翻译结果，处理节流、合并、状态机（空闲/聆听中/出错），驱动界面。
5. **CaptionView + 控制栏**：SwiftUI 界面，负责字幕渲染与用户操作。
6. **SettingsStore**：保存字号、是否显示英文等本地偏好。

### 数据流

```
麦克风 → AudioCaptureService → SpeechRecognitionService
      → CaptionSession（合并、节流）
      → TranslationService（英 → 中）
      → CaptionView（中文大字 + 英文小字）
```

识别到 partial 文本时先快速显示，识别到 final 文本时用更准确的译文覆盖，保证及时且逐步修正。

## 5. 错误处理

| 场景 | 用户看到 |
| --- | --- |
| 麦克风权限被拒绝 | 明确说明并给“去设置打开”按钮 |
| 语音识别权限被拒绝 | 明确说明并给“去设置打开”按钮 |
| 设备不支持英文识别 | 提示识别不可用 |
| 翻译不可用或系统版本过低 | 提示，并降级只显示英文 |
| 长时间听不到清晰语音 | 显示“没听到声音，请靠近扬声器”提示 |
| 识别/翻译过程异常 | 自动停止并显示错误，可重新开始 |

## 6. 技术选型

- 语言/UI：Swift + SwiftUI。
- 语音识别：`SFSpeechRecognizer`，on-device，英文（en-US）。
- 翻译：`Translation` framework，英文 → 简体中文，on-device。
- 最低系统：iPadOS 17.4（Translation framework 要求）。
- 工程生成：XcodeGen（`project.yml`），在任何 Mac 或云端 Mac 上一键生成并编译。
- 无后端、无第三方 SDK、无网络依赖。

## 7. 工程结构

```
iostranslate/
├── project.yml                 # XcodeGen 工程定义
├── Sources/
│   ├── CaptionApp/
│   │   ├── CaptionApp.swift
│   │   └── ContentView.swift
│   ├── CaptionCore/
│   │   ├── AudioCaptureService.swift
│   │   ├── SpeechRecognitionService.swift
│   │   ├── TranslationService.swift
│   │   └── CaptionSession.swift
│   └── CaptionUI/
│       ├── CaptionView.swift
│       ├── ControlsView.swift
│       └── SettingsStore.swift
├── Tests/
│   └── CaptionCoreTests/
└── README.md                   # 安装与使用说明
```

## 8. 安装与后续发布

- MVP 测试：免费 Apple ID + Sideloadly 安装，7 天有效期，过期重装。
- 构建：GitHub Actions 使用 macOS 云端 runner 编译生成 `.ipa`，作为构建产物下载。
- 后续：注册付费 Apple Developer 后，可走 TestFlight 或 App Store。

## 9. 测试策略

### 单元测试

- CaptionSession 的状态切换、文本合并、节流逻辑。
- TranslationService 的协议抽象与降级逻辑（使用 mock）。
- 错误映射：权限、不可用、超时等场景。

### 真机手动测试清单

- 首次启动权限流程。
- 拒绝权限后的引导与设置跳转。
- 播放英文音频时字幕实时出现并持续更新。
- iPad 分屏与 Zoom 同时使用。
- 横竖屏、不同分屏宽度下的字幕可读性。
- 长时间运行的稳定性与耗电。
- 停止/重新开始/清空等控制。

## 10. 验收标准

在 iPadOS 17.4+ 的 iPad 上，点击“开始聆听”后播放英文语音：

- 1-2 秒内出现中文翻译字幕。
- 字幕随语音持续更新，停顿后停止更新。
- 中文大字清晰可读，分屏场景下不遮挡会议操作。
- 停止、字号、显示英文、清空均正常工作。
