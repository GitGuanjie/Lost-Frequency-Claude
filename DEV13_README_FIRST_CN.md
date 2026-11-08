# Lost Frequency dev13 — 立体地图深度重制

本版本从 dev12 升级，重新设计 Level 2、4、5、37 四个关卡内部空间，不改变 100 关清单与 235 条跨关卡出口。414 个 GLB 模型仍随源码提供。

- 中文技术报告：`docs/production/V150_DEV13_VERTICAL_REBUILD_CN.md`
- 内部路线 SVG：`docs/production/DEV13_VERTICAL_ROUTES.svg`
- 离线测试：`python VERIFY_DEV13_OFFLINE.py`
- 原生测试：`./RUN_DEV13_QA_WINDOWS.ps1 -GodotExe C:\Tools\Godot_v4.5.1-stable_win64_console.exe -Story`
- 原生实验导出：`./EXPORT_DEV13_WINDOWS.ps1 -GodotExe C:\Tools\Godot_v4.5.1-stable_win64_console.exe -Story`

**注意：** 本轮没有在当前环境成功执行 Godot（未安装）。源码级路线图不代表物理导航已走通。切勿将本版本宣称为已验收的正式 Windows 版。
