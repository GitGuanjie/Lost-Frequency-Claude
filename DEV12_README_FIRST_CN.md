# Lost Frequency v1.5.0-dev12 — 地图多层空间改造

本版本基于 v1.5.0-dev11 **完整源码**，直接修改了 Level 3、10、11、25 的场景生成器，添加可碰撞的楼梯、露台、桥廊与高架闭合路线，以及 3D 节点/边关系数据、可放大的 SVG/PNG 路线图。原有 100 个关卡场景和 414 个 GLB 模型保留。

**请注意：本 ZIP 是 Godot 4.5.1 源码，不是 Windows EXE，也不是声称验收过的正式版本。** 当前环境缺少 Godot，原生导入无法进行。100 项 Python 离线测试已经通过，但 L009 → L011 仍未实机验证，新增桥廊等尚需真实碰撞和走路测试。

快速检查：

```powershell
python VERIFY_DEV12_OFFLINE.py
.\RUN_DEV12_QA_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64_console.exe" -Story
```

引擎 QA 全部通过后再尝试 `EXPORT_DEV12_WINDOWS.ps1`。真正稳定的 Windows 发布还需要用显卡启动、截图、FPS、人工上楼、下楼及保存/恢复测试。

详见 `docs/production/V150_DEV12_VERTICAL_REBUILD_CN.md`，立体通行设计图见 `docs/production/DEV12_VERTICAL_ROUTES.svg`。
