# Worklifebalance

一款简洁的 macOS 菜单栏专注计时器。

## 功能

- 圆环倒计时，带流畅的动画效果；macOS 26 及以上使用 Liquid Glass 液态玻璃风格按钮
- 专注时长可以直接输入，也可以用加减按钮调整（1–120 分钟）
- 专注结束后在屏幕右上角弹出提醒，大小和样式接近系统通知，可直接“开始下一轮”；
  提醒会一直显示，直到鼠标在上面停留 3 秒或点击左上角的 ×
- 提醒声音：可以选择自己的音频文件并调节音量；不选则只弹出提醒、不出声
- 专注结束后可自动开始下一轮
- 暂停 / 继续、重新开始
- 全局快捷键（可自定义）：
  | 功能 | 默认快捷键 |
  | --- | --- |
  | 开始 / 停止 | ⌃⌥S |
  | 暂停 / 继续 | ⌃⌥P |
  | 重新开始 | ⌃⌥R |
  | 显示 / 隐藏面板 | ⌃⌥T |
  | 退出 | ⌘Q |

  ⌘Q 只在本应用的面板中生效，不会影响其他应用的 ⌘Q；如果改成其他组合键，则在任何地方都能用。
- 界面语言：简体中文 / 繁體中文 / English / Español / 日本語（或跟随系统）
- 登录时自动启动
- 体积小巧：安装包不到 1 MB
- 覆盖安装即可升级，快捷键和其他设置都会保留
- URL 控制：`open worklifebalance://startstop`、`worklifebalance://pauseresume`、`worklifebalance://reset`

## 安装

1. 在 [Releases](../../releases/latest) 页面下载 `Worklifebalance-x.x.pkg`
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
