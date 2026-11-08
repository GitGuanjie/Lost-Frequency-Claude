# Lost Frequency v1.5.0-dev27 — 立体地图与互动扩建记录

## 本轮直接写入的源码

在 dev26 的完整工程基础上，增加按 Level 配置的 `FieldSectors27.gd` 批量实体生成器，并让 `LevelBase._ready()` 在完成原有地形后装配新的可选探索区域。八个改造关卡：**L016、L024、L029、L077、L140、L737、L899、L998**。程序化内容只是 **Wiki 氛围基础上的游戏原创适配（ADAPTATION）**，不是 Wiki 明文设施，也没有新增任何虚构出口。

### 地图复杂度

- 8 种主题建筑语法：树冠观测、塑料矿区检修、海港步道、牧场听音、向日葵棚架、金色遗迹、蘑菇聚落、三层云带观测。
- 8 处主区域与 **18 条分叉延伸路线**；共 **50 处可探索高层平台**（32 个四角主平台 + 18 个分支端点）。
- **16 段真实碰撞的阶梯斜坡**，每区域两条独立登高路线；**8 条非必经可伸缩实体捷径**，关闭时基本高层路线仍在蓝图连通。
- 原有 GLB 资源再使用 **228 次摆放**，使用约 40 余种原有模型；默认不新增道具碰撞，以优先保护主通路。每关配置不同材质、主色与空间装饰构件。
- 为 L016、L029、L077、L140、L737 的部分原有随机植被或石块生成规则增加排除区，避开新梯道和通行空间。

### 可互动与沉浸

- 每关 3 个调查标记（共 24 个），完成后在现场点亮标记并写入 J 键探索日志。
- 每关 2 个可操作光照装置（共 16 个），按 E 会实际改变 OmniLight3D 的亮度。
- 每关 1 个可操作桥梁装置（共 8 个），调查完成后才能在实体桥面与封闭护栏之间切换；关闭不会切断必经环路。
- 每关 3 个高度与距离双限制的氛围发现点（共 24 处）；调用现有声景、探索提示与记录系统，避免隔层触发。
- 总计 **48 处 E 键互动**。交互通过项目现有的 `Interactable` 类挂接，包含带玩家参数与 bind 额外参数的回调。

## 实际执行的验证

| 验证项目 | 状态 |
| --- | --- |
| `python -m unittest discover -s tests/static -p 'test_*.py'` | **237/237 PASS** |
| `python tools/audit_100_entry_static.py` | **100/100 静态入口前提 PASS** |
| `python tools/world_audit.py --no-render --fail-on-issues` | 100 个场景、235 条出口声明、0 项清单问题 |
| `python tools/preflight_dev.py` | 新旧关卡 GDScript 基础词法检查 0 错误 |
| `RUN_DEV27_NATIVE_QA_WINDOWS.ps1` | **NOT RUN**：当前执行环境找不到 Godot 引擎 |
| 全部 100 关真实点击、进入、实体碰撞、性能测试 | **NOT VERIFIED** |

**重要：** 静态连通图只能说明生成数据的路径连通，不能证明 Godot 中角色实际上可以走通。100 个 Level 有源文件并不等于 100 个已认证可玩；原项目依然只有 27 关标记 `PLAYABLE`、73 关 `IN_DEVELOPMENT`，本轮没有更改其状态。编译器、引擎导入、运行时交互和物理碰撞尚未在本环境获得通过结果。

## Windows 实测方法

1. 备份旧工程，使用完整 ZIP 解压，或者在 dev26 工程外层解压增量补丁覆盖到 `3/` 目录。
2. 用 **Godot 4.5.1 Standard** 导入 `3/project.godot`，按 F5 运行主菜单。
3. 用 F3 进入 L016、L024、L029、L077、L140、L737、L899、L998，观察上层路线，E 调查、操作灯光、开启桥梁。
4. 在 `3/` 目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\RUN_DEV27_NATIVE_QA_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64.exe"
```

此脚本尝试逐关执行真正的 `TransitionService.dev_jump()` 路线，检测出生点、上层实体楼面、斜坡、GLB 导入、开关回调和物理桥梁变化。分别保存每关日志和结果到 `3/reports/qa/dev27_native/`。

旧版的全 100 关进入测试也保留：`RUN_100_LEVEL_ENTRY_QA_WINDOWS.ps1`，但它同样需要本机 Godot 才能产生真实验收结果。

## 工程文件

- `core/world/FieldSectors27.gd` — 多主题实体楼板、楼梯、观测设施、可移动物理桥及 E 键交互实现。
- `data/dev27_field_sectors.json` — 按主题固定种子的结构布局、现有模型放置和空间图。
- `tools/build_dev27_field_sectors.py` — 可复现的离线蓝图生成器。
- `tools/draw_dev27_field_sectors.py` — 结构设计图脚本。
- `tests/static/test_dev27_field_sectors.py` — 6 项本轮静态回归。
- `tests/Dev27FieldSectorsProbe.gd`/`.tscn` — Godot 原生入关、物理与 E 键验收，当前未运行。
- `docs/production/DEV27_FieldSectors_Design.png` — 8 种不同空间的蓝图，而非游戏实机截图。
