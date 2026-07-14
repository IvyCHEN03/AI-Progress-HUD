<div align="center">

<img src="Assets/hero.svg" alt="AI Progress HUD" width="920">

# AI Progress HUD

### 扫一眼，就知道每个 AI 在做什么。

同时追踪 ChatGPT、Claude、Codex、DeepSeek 和腾讯元宝，不再反复切窗口。

[English](README.md) · [下载](../../releases/latest) · [安装指南](docs/INSTALLATION.md) · [产品路线图](PRODUCT_ROADMAP.md)

</div>

AI Progress HUD 是一个原生 macOS 悬浮工具，面向同时运行多个 AI 任务的人。它会显示：**哪个 AI、哪个任务、当前阶段、已经运行多久**；点击血条即可回到对应标签页或 App。

## 核心差异

- 同时覆盖普通 AI 网页、桌面客户端和 Codex 平行线程，而不只服务编码代理。
- Codex 同一个窗口里的多个主任务按标题和近期活动分别显示，内部 subagent 会自动去重。
- 用可靠状态与已运行时长表达进度，不制造虚假百分比。
- 完全本地：无账号、无云端、无遥测、不保存提示词和回答正文。
- 置顶、吸边、可折叠，保持沉浸而不打断工作。

## 你会看到什么

- 一个可以贴边常驻的半透明 HUD，不打断当前工作。
- 诚实状态：**待命、思考中、输出中、已完成、需操作、异常、失联**。
- 可以在设置里选择检测哪些 AI，避免不相关工具刷屏。
- 点击血条返回浏览器标签页、桌面 App，或尽力定位到对应 Codex 任务。
- 浏览器扩展只通过 `127.0.0.1` 和本机 App 通信，不上传提示词和回答。

## 支持范围

| AI | 网页 | macOS 桌面端 | 任务区分 |
|---|:---:|:---:|---|
| ChatGPT | ✅ Chromium | ✅ | 标签页 / 窗口 |
| Claude | ✅ Chromium | ✅ | 标签页 / 窗口 |
| Codex | — | ✅ | **线程 ID + 任务标题** |
| DeepSeek | ✅ Chromium | 实验性 | 标签页 |
| 元宝 | ✅ Chromium | ✅ | 标签页 / 窗口 |
| 灵感悬浮球 | — | ✅ | 桌面 App 存在状态 |

更完整的行为和限制见 [支持矩阵](docs/SUPPORT_MATRIX.md)。

## 三步开始

1. 从 [Releases](../../releases/latest) 下载 `.dmg` 或 `.zip`，打开 `AI Progress HUD.app`。
2. 在 `chrome://extensions` 开启开发者模式，加载 App 内附的 `Extension` 文件夹，并填写设置中的配对令牌。
3. 在 macOS“隐私与安全性 → 辅助功能”中授权，以识别 ChatGPT、Claude、元宝桌面端状态。

Codex 多线程监控读取本机线程索引，不需要辅助功能权限，也不会读取聊天正文。

源码构建：

```bash
make test
make package
open "AI Progress HUD.app"
```

详细信息请参阅 [安装指南](docs/INSTALLATION.md)、[架构](docs/ARCHITECTURE.md)、[隐私说明](docs/PRIVACY.md)、[FAQ](docs/FAQ.md)、[故障排查](docs/TROUBLESHOOTING.md) 和 [贡献指南](CONTRIBUTING.md)。

如果它让你的多 AI 工作流更从容，欢迎点亮 ⭐。
