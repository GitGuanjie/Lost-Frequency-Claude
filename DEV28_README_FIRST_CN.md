# Lost Frequency 1.5.0-dev28 — 使用与验收说明

**这是待 Godot 实机验收的开发源码，不是已经证实 100 关都能进入的发布版。**

## 新版实际改动

- L026 游轮：船尾增加第二条物理楼梯及横跨左右舷的连接桥；船首原有楼梯保留，成为上下层完整回路。
- L031 溜冰场：补齐主溜冰区与街机区之间的 1 米接缝（三处接驳）；新增有两条楼梯的高架街机观景廊。
- L083 潜艇：修正原楼梯位置并增加独立后舱楼梯；同时在上层楼板和下层天花板开洞，补充楼梯顶平台。
- L079 医疗设施：依照本地保存的 Wiki 文本制作 16 个不同钟面，允许调查后改变钟针方位，写入探索日志；不增加虚构出口。
- L015/L018/L026/L031/L049/L055/L079/L083/L090：总计 27 个可使用 E 键的主题调查点、81 处原有 GLB 装饰实例以及高度门控的环境事件。所有新增 GLB 装饰均无额外碰撞；其中 9 个开关具备真实灯光切换。

本轮不更改 `level.json`、目标 100 关清单或任何 Wiki 正式出口。来源描述取自工程自带的 2026-11 Wiki 存档；具体互动是游戏改编。

## Windows 上启动

1. 使用 Godot 4.5.1 Standard 版，导入 `3/project.godot`。
2. 等待模型导入，按 F5；按 F3 选择想进入的关卡。
3. 按 E 调查附近物件；按 J 查看发现记录。

## 必须执行的原生验收

PowerShell 进入 `3` 目录后运行：

```powershell
.\RUN_DEV28_ALL100_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64.exe"
```

该脚本先逐关使用真实 `TransitionService.dev_jump()` 验证 **100 个关卡 F3 入口**，每关独立 Godot 进程；然后独立验收本轮 9 关的 GLB 导入、实体碰撞、E 键回调、灯光状态以及 L079 的 16 钟面状态。任意关失败均不可宣称 100/100 通过。

报告位于：
- `reports/qa/dev24_entry_100/summary.csv`
- `reports/qa/dev28_native/summary.csv`

## 当前验收状态

- `python -m unittest discover -s tests/static -q`：**243/243 PASS**。
- `python tools/preflight_dev.py`：**0 项词法结构异常**，不属于 GDScript 编译。
- `python tools/world_audit.py`：**100 关 / 235 出口 / 0 清单错误**，声明图 43 可达，QA 快照 24 已观测可达。
- **Godot Native NOT RUN**：当前构建环境没有 Godot 可执行文件，下载服务器无法解析。因此所有新增碰撞与互动属于待引擎验收，不能标记 PLAYABLE。
- 全部 414 个 GLB 原始文件保留。本轮新增 81 处引用模型的摆放，不代表新增模型资源种类。

参见 `docs/production/DEV28_IMPLEMENTATION_CN.md`。
