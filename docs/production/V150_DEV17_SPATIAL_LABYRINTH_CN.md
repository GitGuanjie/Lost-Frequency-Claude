# v1.5.0-dev17 / 三维迷宫地形与复层 Poolrooms 开发报告

版本：2026-11-07。前置版本：`v1.5.0-dev16`。状态：**仅源码修改完成，静态检查通过；Godot 引擎验收失败（当前环境没有 Godot）。**

## 设计目标与修改界限

比起给新关卡增加无联系的装饰平台，这一轮优先升级实际地形的**路径拓扑**：可返回主线的分叉，向上/向下连续坡道，双向梯道、不同楼层的替代路径与完整闭环。严格保留 Backrooms 设定下的第九号公路、Level 37 白瓷砖水体、现有剧情出口和关卡登记。

## Level 8 / Cave Systems：六条编织支洞 + 两条跨支路

修改：`levels/L008/CaveBuild.gd`、`levels/L008/CaveBraids.gd`、`levels/L008/L008.gd`、`data/dev17_cave_braids.json`。

- 第九号公路 `ROAD` 原始 18 个锚点完全保留。
- 六条支洞：Fissure switchbacks、Drowned quarry switchback、Overlook and underpass、Dark antechambers、Deep detour of drowned dip、Upper calcite skyloop。
- 两条连接：Upper interleaving crosslink、Road-shaft alternate。它们不止接回公路，还让支洞之间直接互通。
- 生成 `tube`（沿路插值的 `fa/fb` 实际洞穴地面）和 `room`（带平底的椭球穴室），共同进入 `Cave.Field` 的 SDF 表面网格计算。
- 支路的定义文件在运行时被 Godot 读取，并同时作为静态拓扑报告的输入，避免复制两份不一致的路径。
- 设计范围高度 -10 至 +11 m；46 个**设计图**节点、53 条边、8 个独立环路；不是 46 个独立房间。
- 风险：洞道局部冲刷与原洞穴地板交叉、生成的坑洞、远距离块加载时的 FPS 与内存开销，仍需 Godot 引擎及完整步行实测。

## Level 37 / Sublimity：连续两间多层大厅

修改：`levels/L037/L037.gd`、`levels/L037/L037_kinds.gd`、`levels/L037/L037_vertical_annex.gd`、`data/dev17_pool_annexes.json`。

- 原主大厅 `(0,0)` 和原深水楼梯坑 `(1,0)` 保持不变，东侧添 `(2,0)`、`(3,0)` 两间 **固定布局**的附属大厅。
- 在 `HUB_BORDERS` 中为 `1,0,x` 和 `2,0,x` 保持低层入口，并封闭新增外端边界；门洞从同一份边界表在两侧生成，不会出现两间房 doorway 不一致的拼接错误。
- 两间附属大厅分别 3 层 / 4 层，各楼层由两条真实 `GeoKit.stairs` 坡面碰撞连接，每层末端存在连贯楼板与双接入观察岛。
- 深水区域最低标高 -7.25 / -8.25 m。两套下行/回升的分段 `GeoKit.ramp` 连接地面与深水区，避免只靠角色下潜才能探索。
- 最高楼面 +7.47 m；对应顶棚 10.5 m，标称有超过 3 m 净高；实物碰撞仍需验证。
- 两间大厅连同原深坑边缘入口的**设计图**合计 68 节点、89 边、22 个环路，最大高差约 15.72 m。
- 不新增 NPC，不新增跨关出口、不改变投票/沉浸时长/剧情转场。

## 路线图来源与可用性

`data/dev17_spatial_graphs.json` 包含每条设计连接的三维节点、连边类别、源文件 SHA-256 与分析指标。生成命令：

```bash
python tools/build_dev17_topology.py
python tools/draw_dev17_topology.py
```

`docs/production/DEV17_SpatialRoutes.png` 是分析示意，非实际渲染截图。图的节点和边说明**源码计划了什么**，不能替代 `CharacterBody3D` 的走通证据。

## QA、复现与发行门槛

- Python `unittest discover`：**143/143 通过**。
- `preflight_dev.py`：0 个词法检查问题（并非 GDScript 真正编译）。
- `world_audit.py`：**100 关、235 个出口声明、0 个世界登记问题**。
- 资源：`414` 个 GLB 保持不变。
- 完成 `tools/run_dev17_qa.py` 和新的 `vertical_dev17` Godot QA 套件：可以对 L008 的实际 SDF 物理地板及 L037 梯道、楼板、水池执行 headless RayCast；还会调用 DEV14–16 回归以及 414 模型烟雾测试。
- **已真实执行尝试** `python tools/run_dev17_qa.py --level L008 --level L037`；第一阶段 Godot 导入失败：`[Errno 2] No such file or directory: 'godot'`。因此没有 GDScript 编译通过、物理碰撞通过、玩家走通、Windows EXE 或帧率通过的证据。QA JSON 明确记录 FAIL。

### 推荐的人工验收

Windows Godot 4.5.1 Standard 导入 `3/project.godot` 后按 F5；先进入 Level 37，从原生大厅走向原深坑东侧的连续低门洞，沿两个新增大厅完成上下层双路线/深水路线闭环；再进入 Level 8 沿第九号公路，测试每条侧洞的两端是否真实连接，并注意洞室地面和坡度。检查遮挡、碰撞穿模、卡住的上下楼梯、进出区块时的帧率突降和长距离跑图时的存档。

### 尚未做的事

没有 Godot 编辑器二进制或导出模板，也没有 Windows GPU 实机。本轮优先实现真正的地形与拓扑的代码，不将“新建的源码结构”混同为“已完成可玩的关卡”。后续应该先用引擎调试证据修复堵路和碰撞，再决定是否对其他 100 关推广大型生成器。
