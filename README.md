# Worklifebalance

一款简洁的 macOS 菜单栏专注计时器。

## 功能

- 菜单栏倒计时，专注时长可自定义（1–120 分钟）
- 专注结束后可自动开始下一轮
- 暂停 / 继续、重新开始
- 全局快捷键（可自定义）：
  | 功能 | 默认快捷键 |
  | --- | --- |
  | 开始 / 停止 | ⌃⌥S |
  | 暂停 / 继续 | ⌃⌥P |
  | 重新开始 | ⌃⌥R |
  | 显示 / 隐藏面板 | ⌃⌥T |
  | 滴答声开关 | ⌃⌥M |
- 界面语言：简体中文 / 繁體中文 / English / Español / 日本語（或跟随系统）
- 发条声、结束提示音、滴答声，音量可单独调节
- 登录时自动启动
- URL 控制：`open worklifebalance://startstop`、`worklifebalance://pauseresume`、`worklifebalance://reset`

## 安装

1. 在 [Releases](../../releases) 页面下载最新的 `Worklifebalance-x.x.pkg`
2. 双击安装，应用会被安装到「应用程序」文件夹并自动启动

> 安装包未经 Apple 公证。如果系统提示“无法打开”，请在 Finder 中**右键点击 pkg → 打开**，
> 或前往「系统设置 → 隐私与安全性」中点击“仍要打开”。

系统要求：macOS 13 及以上（Apple 芯片与 Intel 均支持）。

## 从源码构建

只需要 Xcode 或 Command Line Tools：

```bash
./scripts/build.sh
```

生成的 `build/Worklifebalance-<版本>.pkg` 即为安装包。版本号写在 `VERSION` 文件中。

## 许可证

MIT
