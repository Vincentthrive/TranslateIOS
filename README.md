# 会议字幕

iPad 应用：分屏参加 Zoom 英文会议时，通过麦克风聆听扬声器声音，实时显示中文翻译字幕。

## 功能

- 本地英文语音识别 + 本地英中翻译，全程离线
- A 方案字幕布局：底部通栏，中文大字、英文小字在上
- 控制：开始/停止、字号、显示/隐藏英文、清空
- 最低系统：iPadOS 17.4+

## 在 Windows 上安装到 iPad（免费 Apple ID）

1. 将本仓库推送到 GitHub。
2. 打开 GitHub 仓库的 Actions 页面，运行 `Build IPA`，等待构建完成。
3. 下载 `caption-subtitle-unsigned` 构建产物里的 `.ipa`。
4. Windows 上安装 Sideloadly（https://sideloadly.io）。
5. iPad 连接电脑，打开 iTunes/Finder 信任电脑。
6. Sideloadly 中填入 Apple ID 和密码，拖入 `.ipa`，点击 Start。
7. iPad 上到"设置 → 通用 → VPN 与设备管理"信任开发者证书。
8. 打开"会议字幕"即可使用。

免费 Apple ID 签名的有效期是 7 天，过期后重复第 3-6 步重新安装。

## 在 Mac 上构建

```bash
brew install xcodegen
xcodegen generate
open CaptionSubtitle.xcodeproj
```

选择 iPad 模拟器或真机运行。

## 技术栈

- Swift 5.9 + SwiftUI
- Apple Speech（英文 on-device 识别）
- Apple Translation（英中 on-device 翻译）
- XcodeGen 工程配置
- GitHub Actions 云端 macOS 构建
