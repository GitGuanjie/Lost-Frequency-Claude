# Lost Frequency v1.5.0-dev16 — 大规模空间层次重构

> 验收状态：**源码与设计图已通过离线校验；Godot 运行 / 碰撞 / Windows EXE 尚未通过**。本报告严格区分设计连通图与玩家实际可走通的路线。

## 核心变更

本轮基于完整 dev15 源码扩建，未删改 414 个 GLB 模型、100 关登记数据、235 条出口声明或已有故事触发器。

- 新增 `core/world/SpatialBranchworks.gd`：可连续升高或下沉的双向台阶网络，每层中央实体楼面、两个侧向口袋空间、四条分支步道、可折返的双路连接，楼梯在实体楼板外侧运行，无需同楼板重叠的开洞。逐层添加结构柱、侧护栏与交替悬挑平台。
- 本轮修改 **14 个关卡 / 17 个结构站点**：L023、L028、L032、L048、L050、L073、L077、L085、L094、L108、L140、L320、L808、L998；包含 3 组跨站点双高度空桥。
- L023：在原根系洞穴的东侧石壁开通真实洞口，铺设 y=-6 m 的岩石地面廊道，连接地下五层结构；最深设计面到 y=-19.8 m。不改变原始水体或水出口。
- L048、L320、L808：新增相距数十米的两组实体建筑，每组 5–6 层，第一上层与最高层各用桥相连，桥接点位于楼梯运行范围之外；桥接层打开侧护栏中央通道。
- L032、L050、L077、L108、L140：排除新建活动区域的随机物体占位。L140 保持 480 个花束实例不变；L050 保持 17 辆静止车辆不变。
- L028、L073、L085、L094、L998：新增景观、城堡或城市外围多层可探索线路，不新增跨关卡出口。

## 设计拓扑（不是实机通过证明）

| 关卡 | 结构位置 | 站点 | 设计高度层 | 净高度跨度 |
|---|---|---:|---|---:|
| L023 | 地下根系岩窟 | 1 | 5 | 13.8 m 向下 |
| L028 | 风暴巨石与城堡外围 | 1 | 4 | 10.5 m |
| L032 | 黑暗骸骨森林 | 1 | 5 | 13.6 m |
| L048 | 海岸长廊双楼 | 2 | 各 5 | 14.0 m |
| L050 | 废弃公路信号站 | 1 | 4 | 10.5 m |
| L073 | 红色城堡外围 | 1 | 4 | 10.5 m |
| L077 | 牧场森林交界 | 1 | 5 | 14.0 m |
| L085 | 废弃郊区 | 1 | 4 | 10.5 m |
| L094 | 异常城镇远端 | 1 | 5 | 14.0 m |
| L108 | 坠坑森林树冠 | 1 | 5 | 14.0 m |
| L140 | 向日葵观景结构 | 1 | 4 | 10.5 m |
| L320 | 游乐园双站高架 | 2 | 各 5 | 14.0 m |
| L808 | 霓虹世界双站高架 | 2 | 各 6 | 17.5 m |
| L998 | 暴风云层高台 | 1 | 5 | 14.0 m |

来自源码数学建模的汇总：**905 个设计图节点 / 1123 条边 / 232 个独立循环 / 17 处站点 / 14 张地图**。节点是抽象路线取样点而非 905 个房间。完整可复算数据：`data/vertical_routes_dev16.json`，构造脚本 `tools/build_dev16_topology.py`。示意图：`docs/production/DEV16_SPATIAL_OVERVIEW.svg`。

## 已完成的验证

- `python -m unittest discover -s tests/static -p 'test_*.py' -q`：**133 项通过**，包括旧版回归和 8 项新的 DEV16 验证。
- `python tools/world_audit.py --no-render --fail-on-issues`：**100 关登记、235 条出口声明、0 条结构审计问题**。
- `tools/run_dev16_qa.py --plan-only`：生成完整 Godot 引擎验证计划，并显式覆盖新增的 14 个关卡、旧版 dev14/dev15 结构测试、Level 9 路径和全部 GLB 资源。
- 新增 `tests/qa_runner.gd` 的 `vertical_dev16`：计划真实加载 14 关，以物理射线检查楼面、四分支走廊、上下楼梯斜坡、跨站空桥和 L023 石壁洞口。该测试**只写入引擎真实报告**，不会读取静态设计图伪造通过。
- `RUN_DEV16_QA_WINDOWS.ps1`、`EXPORT_DEV16_WINDOWS.ps1`：使用本机 Godot 4.5.1 执行严格分阶段检查；只有完整 QA PASS 才允许导出实验性 Windows EXE。

## 未完成 / 风险（不得标记 PASS）

本执行环境**没有 Godot 引擎**。一次正式尝试在原生导入阶段失败，错误为 `No such file or directory: 'godot'`。详见 `reports/qa/v150_dev16/batch_summary.json`（`status: FAIL`）。因此尚未验证：

1. GDScript 是否由 Godot 正式解析和执行；楼梯、门洞、桥梁碰撞是否按预期生效。
2. 玩家身体尺寸在全部桥头、楼梯、支架旁的真实通行；是否存在薄碰撞边界、栏杆阻路或高空坠落。
3. 14 个场景的性能、画面与照明；随机环境摆设是否仍与路线相撞。
4. 100 关全量运行、414 模型实机导入与 Windows EXE 的实际启动和 FPS。
5. 特别是 L009 → L011 剧情链，依旧需要物理行走和故事测试确认。

## Windows 原生验收与导出

在 **安装 Godot 4.5.1 与 Windows Export Templates** 后，进入本目录，使用 PowerShell：

```powershell
.\RUN_DEV16_QA_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64_console.exe" -Full -Story
```

QA 通过之后再执行：

```powershell
.\EXPORT_DEV16_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64_console.exe" -Full -Story
```

未进行原生验证时，源码仍应标为 **开发实验版**，不可声称完成正式 Windows 可玩验收。此版本保留 `data/vertical_routes_dev14.json`、`data/vertical_routes_dev15.json` 和全部旧版测试供回归比较。
