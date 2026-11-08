# Lost Frequency dev16 — 开发源码

新版本大规模立体线路改造覆盖 14 个关卡、17 处站点；此前 dev14/dev15 的结构仍保留。项目文件位于此文件夹内，打开 `project.godot` 使用 Godot 4.5.1。

开发报告：`docs/production/V150_DEV16_LARGE_SCALE_SPATIAL_REBUILD_CN.md`

立体结构图：`docs/production/DEV16_SPATIAL_OVERVIEW.svg`

运行前离线检查：`python -m unittest discover -s tests/static -p 'test_*.py' -q`

Windows Godot QA：`.\RUN_DEV16_QA_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64_console.exe" -Full -Story`

Windows 实验导出：`.\EXPORT_DEV16_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64_console.exe" -Full -Story`

**状态：离线源码检查通过；Godot 未安装，实机碰撞与 Windows 游戏包未认证。**
