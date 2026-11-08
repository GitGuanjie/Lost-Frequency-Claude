# Lost Frequency v1.5.0-dev10 — 源码开发及风险审计

## 目标与基线

基于 v1.5.0-dev9 的完整 Godot 4.5.1 项目直接修改；原有 100 份关卡 scene/manifest、235 条出口声明及 Kenney CC0 414 个 GLB 资产保持不变。**本轮不把静态检查、模型文件哈希或 Windows 资源封装当成可玩性测试。**

## 交付源码内容

1. **L000 三层中庭（`levels/L000/L000.gd`）**：对已有程序化中庭的约三分之一布局，基于关卡种子决定是否加一层观察廊。增加第三层的分片楼板、中庭悬空跨桥、栏杆、18 级实体坡道碰撞、楼板楼梯孔、维护笔记和受资源池管理的灯光。保留 Level 0 的随机空间变化、原设定出口与其余双层/单层形态。
2. **L009 夜间郊区（`levels/L009/L009.gd`）**：原十个路牌增设可调查交互，记录各自已观察状态、显示所指方向，保留原来的逐点路线判定，交互不会跳过前进条件、增加 `qa_prog` 或直接开出口。继续沿用 dev8 的多层车库。
3. **物理导航 QA（`tests/qa_runner.gd`）**：Level 9 定向测试在烘焙导航前加载玩家附近和短距离目标附近的 ChunkWorld 区块，增加导航开始点投影偏差、路径端点距离、触发器体积内久候、无前进/物理卡阻、分段位置/碰撞次数等证据。保留真实 CharacterBody3D 控制，不直接 `fire()`，不传送玩家，不人工设定路线进度。L009 加载等待增加 30 秒超时以确保生成失败报告。
4. **垂直空间验收（`vertical_atrium` Godot suite）**：根据确定性种子选择三层中庭，用物理射线检查平台、跨桥和楼梯孔的碰撞。该 suite 是几何烟雾测试，并不是机器人从楼下走到三楼的证明。
5. **模型和关卡 QA（`tools/run_dev10_qa.py`）**：导入 Godot 工程、实例化 414 个 GLB 和 466 条摆放记录、基础系统/针对性关卡批次、L000 几何和 L009 实际物理路线。可选 `--story` 和 `--full`。所有阶段要求新鲜报告；任一失败即停，拒绝生成通过证明。
6. **Windows 原生导出门槛（`EXPORT_DEV10_WINDOWS.ps1`）**：必须先跑完真正的 Godot 导入/测试，且日志和报告 PASS，才用 Godot 原生命令 `--export-debug` 生成实验版 EXE；人工实机验收依然单独要求。
7. **离线回归（`VERIFY_DEV10_OFFLINE.py`、`tests/static/test_dev10_vertical_route.py`）**：总计 78 项 Python 静态测试，含新几何、物理测试防作弊、源码字符串/括号、资产和世界清单测试。

## 验证事实（2026-11-07）

| 项目 | 结果 | 不能推出什么 |
|---|---|---|
| Python 离线回归 | 78/78 通过 | Godot 脚本通过编译 |
| `world_audit --no-render` | 100 scenes，235 exits，43 manifest reachable，0 issues | 关卡可走通 |
| GLB 已存在及 SHA-256（dev9 测试）| 414/414 通过 | Godot 导入/材质正确 |
| `run_dev10_qa.py` 真实尝试 | FAIL：环境中找不到 Godot 引擎，停在 import stage | 模型导入已通过 |
| Level 9 → Level 11 | **没有新的真实物理成功证据** | 故障已经修复 |
| Windows x86_64 | **没有可验证的新 EXE** | 能直接试玩 |

## Windows 用户验收命令

在解压的源码根目录，安装与项目相同的 **Godot 4.5.1** 与 Windows x86_64 Export Templates，然后：

```powershell
python VERIFY_DEV10_OFFLINE.py
python tools/run_dev10_qa.py --godot "C:\Tools\Godot_v4.5.1-stable_win64_console.exe" --story
.\EXPORT_DEV10_WINDOWS.ps1 -GodotExe "C:\Tools\Godot_v4.5.1-stable_win64_console.exe" -Story
```

若第一项以外的测试失败，优先阅读 `reports/qa/v150_dev10/*.log` 与对应 JSON。不要通过修改测试 PASS 标志、调用 `fire()` 或直接传送玩家绕过问题。若实际观测 L009 → L011 失败，优先比较三个 `waypoint` 的 `before/after`、`spawn_projection_error`、`progress_samples` 与末端 `distance_to_target`。

## 待办与不确定性

- Godot 真实 GDScript 编译、三层碰撞、渲染截图以及 L009 实体路线必须在引擎上验证。静态扫描并非编译器。
- Level 0 三层楼梯是否能由玩家稳定登顶、视距与照明是否合理，还需要人工/自动导航验证。
- Level 9 原来失败的具体原因尚未由引擎日志确定；本轮补足了诊断，不应说“已修复”。
- 下一步建议对 Level 4、5、11、37 的内容密度、垂直动线和交互进行实机重制，筛查 Kenney 模型材质与遮挡。
- 未经引擎、Windows 人工测试，不得把任何 `IN_DEVELOPMENT` 关卡改成 `PLAYABLE`，也不得将本版命名为稳定正式版本。
