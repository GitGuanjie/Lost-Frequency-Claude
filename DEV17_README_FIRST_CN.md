# Lost Frequency v1.5.0-dev17 — 立体洞穴与多层 Poolrooms

**这是 Godot 4.5.1 的完整开发源码，不是 Windows EXE，也不是已通过玩家实测的正式发行版。**

本轮专门攻克两类不同的空间生成：

- **Level 8：** 保持第九号公路不变，新增六条 SDF 真实挖出的可探索侧洞与两条交叉连接，空间高度 -10 至 +11 m。洞穴随 chunk 流式生成、使用原来的 CaveGeo 碰撞网格，而不是只放装饰路径或传送点。新增的路线有两个端点接回主路；单段最大设计坡度不超过 0.46。
- **Level 37：** 在原来的 Poolrooms 主大厅和楼梯深坑东侧，增加两间固定附属大厅（区块 2,0 和 3,0），分别为 3 层与 4 层，最高楼层约 +7.47 m，最低深水底约 -8.25 m。每层双梯、双桥接中央观察平台，另有两条真实坡道通往水下深处。保留原有白瓷砖、青绿色水池、空无生物与出口设定。

设计图：`docs/production/DEV17_SpatialRoutes.png`。它是源码/几何参数导出的**路线设计示意**，不是实机截图或导航验收证明。

## Windows 打开和尝试运行

1. 安装 **Godot 4.5.1 Standard（非 .NET）**，解压开发 ZIP。
2. 在 Godot Project Manager 点击 Import，选中 ZIP 中 `3/project.godot`。
3. 第一次打开等资源导入完成，按 `F5` 启动主菜单。
4. `F3` 打开开发者关卡选择，选 Level 8 或 Level 37；`F7` 是自由镜头（它不会改变区块围绕角色加载的规则）。
5. 由于缺少原生 Godot 验证，此轮新增区域可能有碰撞或可达性问题，请记录第一条红色报错，并实测是否能走完闭环。

## 在 Windows 执行引擎 QA

PowerShell 中进入 `3` 项目目录，示例：

```powershell
.\RUN_DEV17_QA_WINDOWS.ps1 -GodotExe 'C:\Godot\Godot_v4.5.1-stable_win64_console.exe'
```

如需本机 Godot 导出 Windows 实验包（需要官方导出模板）：

```powershell
.\EXPORT_DEV17_WINDOWS.ps1 -GodotExe 'C:\Godot\Godot_v4.5.1-stable_win64_console.exe'
```

导出脚本不会跳过失败的 QA；**即使导出成功仍需实际 Windows 图形运行、帧率、完整角色移动测试**。

离线检查：

```powershell
python -m unittest discover -s tests/static -q
python tools/preflight_dev.py
python tools/world_audit.py
python tools/build_dev17_topology.py
```

**本环境的测试结果：** 143/143 项 Python 静态测试通过；100 关登记、235 条出口声明、世界配置审计 0 个问题；414 个 `.glb` 文件保留。真实 Godot 批次已尝试，但系统找不到 `godot` 可执行程序，状态为 `FAIL`（见 `reports/qa/v150_dev17/batch_summary.json`），绝不能把此结果称为“引擎通过”。

更完整的改造、测试与限制请读 `docs/production/V150_DEV17_SPATIAL_LABYRINTH_CN.md`。
