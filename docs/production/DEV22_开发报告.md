# Lost Frequency — v1.5.0-dev22 开发报告

**交付：Godot 4.5.1 源码 + dev21 增量补丁；实机状态：待验证。**

### 本次目标与具体实现

由 dev21 的 10 组通用三层迷宫进一步扩展为 10 组新的主题副区域：L028 城堡工坊、L032 夜林树冠、L050 公路检修、L073 红色城垛、L077 雾中回转山路、L085 避难居室、L094 错比例城镇、L108 原始森林根系、L320 五层游乐设施、L808 霓虹高架网格。

核心生成器 `tools/generate_dev22_districts.py` 通过稳定种子生成 4×4 单元空间树，再加入非树回环、局部楼板开洞以及二组外侧独立楼梯。每个关卡各层设计图均可通过 BFS 到达；关闭可选挡板不会中断主通路。真正的地板、门洞、梯道、横向桥、楼板孔与护栏由 `core/world/NarrativeDistrict.gd` 的 GeoKit API 生成，并从原侧翼的中层北门经 15m 实体桥相连。为了避免“只变颜色”，另外设置十种不同的可登上主题观景点造型，配套 272 个已有 GLB 摆放定义。

`core/world/NarrativeDistrictState.gd` 实现 42 个实体发光定位标记、42 个真实灯光开关、30 个环境调查点、10 个非必经物理捷径挡板；`AmbientDiscovery` 增设 30 处楼层高度受限的声音线索。修复 `Interactable.interact()` 在不区分参数数目时对零参数 lambda 传入 Player 的旧缺陷：至少 54 处关卡互动在旧实现下有潜在调用错误。

### 可复核数字（新增 dev22，非项目总量）

| 项目 | 数量 | 含义 |
|---|---:|---|
| 新的主题副区域 | 10 | 接到旧的 10 个关卡内，不新增关卡登记 |
| 高度层 | 42 | 8 个区域为 4 层，2 个区域为 5 层 |
| 地板单元 | 626 | 蓝图中真实实例化地板的单元 |
| 横向边 | 782 | 门洞或实体桥所对应的连接边 |
| 楼层内独立环路 | 198 | `E - V + 1` 的图论计数 |
| 跨层楼梯段 | 64 | 相邻高度层的两侧独立楼梯 |
| GLB 模型摆放 | 272 | 252 个楼层道具 + 20 个观景台模型 |
| E 互动位置 | 124 | 42 信号 + 42 灯光 + 30 调查 + 10 物理挡板 |
| 环境发现点 | 30 | 新增声音及文字情境 |
| 主题观景台 | 10 | 带实体楼板、连接门洞与护栏 |

原项目的 100 个关卡登记、235 条出口声明、414 个 GLB 文件保持不变。相比 dev21 的 330 个场景模型，**这十个关卡的两个阶段合计 602 处模型摆放定义**；并非 602 种不同的模型。

### 文档与源代码

- `data/dev22_narrative_districts.json`：单一真实来源，生产几何、模型、交互与路线审计的数据。
- `core/world/NarrativeDistrict.gd`：实例化实体地形、楼梯、连接桥、装饰模型及互动。
- `core/world/NarrativeDistrictState.gd`：独立灯光和可选物理挡板的状态机。
- `core/world/AtriumWeave.gd`：打开北侧中层门洞并链接新区域。
- `core/interaction/Interactable.gd`：零参数/单玩家参数/绑定回调统一分发。
- `tests/static/test_dev22_narrative_districts.py`、`test_dev22_interaction_dispatch.py`：数据复现、模型边界、门户高度、图连通、无关卡出口变化的离线验证。
- `tests/qa_runner.gd` → `district_dev22`：真实 Godot 碰撞射线、GLB 实例、真实 `Interactable.interact` 与灯光/物理门验收。
- `tools/run_dev22_qa.py` 及 Windows PowerShell 脚本：自动导入与验收；失败即拒绝导出。

### 测试证据与不足

**离线 Python 回归 207/207 通过**，几何数据和模型摆放均可字节级重复生成，图论保证存在两条跨层路线且可关闭额外挡板。**Godot 4.5.1 原生测试没有通过：环境缺少 godot 可执行文件，导入即失败。** 已记录失败证据，不能宣称实际角色走通、碰撞完整、性能达标或源代码已被引擎编译成功。需要在 Windows 上执行新的测试脚本并进行人工游玩后才能给出可玩完成版。

### 网站设定的使用方式

世界设定基于 `sources/wiki_text/` 的原存档，并参考正在运营的 Backrooms Wikidot：Level 28 / Final Virtue 的蓝色天色和 Stormstone Keep、Level 85 / Brilliant Evermore 的污染室外环境、Level 320 / Entertainland 的多层 Folding Point、Level 808 / Synthwave World 的霓虹网格。所有新增设备、房间细节与叙事只是明确标记的游戏改编，不冒称官方原著设施。

- https://backrooms-wiki.wikidot.com/level-28
- https://backrooms-wiki.wikidot.com/level-85
- https://backrooms-wiki.wikidot.com/level-320/offset/10
- https://backrooms-wiki.wikidot.com/level-808

**最终状态：dev22 源码扩建完成；原生 QA 未验证，Windows EXE 未生成。**
