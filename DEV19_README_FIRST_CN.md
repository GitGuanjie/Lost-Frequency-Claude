# Lost Frequency v1.5.0-dev19 — 立体空间 + 环境互动

此版本是在 dev18 源码基础上的真实增量开发；完整包仍包含原有 100 个登记关卡、所有旧几何/交互，以及 414 个 GLB 模型。

## 新增的内容

- **Level 8 / Cave Systems：** 三条接入并回到旧 SDF 洞穴网的稳定分叉；新洞道不是悬空 GLB，而进入原有体素切割流程。三处地质观察点加入 E 互动、局部缓亮、短时风声和探索日志。
- **Level 37 / Sublimity：** 顺着原有两个附属大厅，再增建两个彼此连接的 32 米网格大厅。第一个以双深度水池、瓷砖拱廊、跨池高架回环为主；第二个设两条相互独立的潜水往返坡道。四处 E 交互会顺次改变实际水光灯，给玩家辨别路线的反馈。保持 Level 37 安静、洁净、无实体的主题。
- **Level 1 / Habitable Zone：** 在已有检修夹层加入四盏真实 OmniLight3D，玩家可以从底层或上层操作两只开关，共同切换应急灯；状态随着该关卡的分块重新载入保持。没有关闭原有随机闪灯机制，也未改变出口。

对照网站：Level 8（https://backrooms-wiki.wikidot.com/level-8）、Level 37（https://backrooms-wiki.wikidot.com/level-37）、Level 1（https://backrooms-wiki.wikidot.com/level-1）。上述特殊互动和附属空间属于**受设定启发的游戏改编**，不是 Wiki 原文里的新设施。

## 在 Godot 里启动

1. 使用官方 **Godot 4.5.1 Standard**（不需要 .NET）。
2. 解压完整源码，导入根目录的 `project.godot`（完整 ZIP 内的 `3/project.godot`）。
3. 等待模型导入结束，按 **F5** 启动主菜单；使用 **F3** 开发者关卡浏览器，选择 Level 1 / 8 / 37；靠近调查点按 **E**。
4. 按 **J** 打开探索日志。

### Windows 质量门

在 PowerShell 中运行：

```powershell
.\RUN_DEV19_QA_WINDOWS.ps1 -GodotExe 'C:\path\Godot_v4.5.1-stable_win64_console.exe'
```

只有引擎 QA 全通过时，`EXPORT_DEV19_WINDOWS.ps1` 才允许生成实验 EXE；导出仍需实际 Windows 上人工检查入口、长距离寻路、性能及地图完整度。

**No real Godot 4.5.1 executable is installed in the build environment.** 目前实际完成的是离线静态测试、源码几何合同检查和压缩包完整性检查。不能宣称已经做过 Godot 实测、自动穿关、玩家巡游或 Windows 运行测试。地图拓扑相连不等于物理路线已通行。

如果遇到运行错误，先保留 Godot Debugger 第一条报错以及 `reports/qa/v150_dev19` 下生成的报告。
