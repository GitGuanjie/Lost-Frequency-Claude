# DEV15 — 先读这里

这是 100 关 Backrooms Godot 项目的 **完整可编辑源码**，不是已经通过引擎的 Windows EXE。

- 本轮改造九个关卡（L015、L016、L017、L020、L022、L024、L029、L030、L036），提高立体空间和上下路径复杂度。
- dev14 已有的 L000/L001/L009/L011 多层结构和剧情出口仍在。
- 414 个 GLB、100 个关卡目录、235 条出口定义均保留。
- 使用 `python VERIFY_DEV15_OFFLINE.py` 检查静态源代码；本机 Godot 验证见 `docs/production/V150_DEV15_VERTICAL_NETWORKS_CN.md`。
- 版本仍为开发状态。切勿把“设计拓扑图连通”写成“物理角色已全通关”。

**Windows 操作：** 工程所在目录右键以 PowerShell 打开，执行

```powershell
.\RUN_DEV15_QA_WINDOWS.ps1 -GodotExe 'C:\Path\Godot_v4.5.1-stable_win64_console.exe' -Story -Full
```

需要 Windows EXE 时，在 Godot 4.5.1 导出模板齐全、上述 QA 已 PASS 的前提下执行 `EXPORT_DEV15_WINDOWS.ps1`。
