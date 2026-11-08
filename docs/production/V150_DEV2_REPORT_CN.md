# Lost Frequency — v1.5.0-dev2 源码开发报告

> **性质：源码开发候选快照；未通过 Godot 引擎、GPU、Windows 发布验收。**
> 基线：用户上传的 v1.5.0-dev1 源码。不能把旧版截图/QA 报告视作本轮新关卡通过。

## 已落地的开发内容

本轮新增 8 关，全部拥有独立的 GDScript、TS res:// 场景文件、`level.json`、来源限定出口、场景坐标与关卡内机制：

| ID | 名称 | 有形建筑 / 地形 | 核心机制 | 真实出口声明 | 发布状态 |
|---|---|---|---|---:|---|
| L020 | Boreas Structure / Fun Zone | 等待大厅、游戏机房 | 三控制台开启来源出口 | 3 | IN_DEVELOPMENT |
| L055 | Pit Stop | 废旧餐厅、安全房、餐台、神秘日光 | 非 QA 模式随机倒计时自动请求返回来路 | 1 | IN_DEVELOPMENT |
| L058 | Water Wonder | 空泳池、破旧滑梯、蓝色人造草、储物走廊 | 供给箱和黑色滑梯、偶发停电 | 3 | IN_DEVELOPMENT |
| L083 | Sunken Submarine | 双层潜艇、舱室、桥、贯通楼梯 | 通向 L007 的舱口、远处敲击 | 1 | IN_DEVELOPMENT |
| L090 | Renovated Home | 两层房屋、可通往阁楼的楼梯、后院大橡树 | 旧橡树的来源未知出口、故障空调 | 1 | IN_DEVELOPMENT |
| L140 | Honey | 宽广的花田、蜂蜜小屋、480 朵 MultiMesh 花 | 日夜变化；**原始资料无可靠出口，故不编造** | 0 | IN_DEVELOPMENT |
| L197 | Crystal Caverns | 绿松石、紫水晶、红宝石、缟玛瑙四个洞穴分区 | 浅水、三条来源路径、未确认空间隔离 | 3 | IN_DEVELOPMENT |
| L201 | A E S T H E T I C | 沙漠、海洋边缘、霓虹城、网格天空 | 四个需先选择才能使用的 Trench 链接 | 4 | IN_DEVELOPMENT |

新增共 **16 条 manifest 出口**，包括未建目标/特殊目的地；**绝不将这些等同于可完整通行的路径**。每条均和 `data/canon/transitions.json` 中源 ID 比对；场景注明对原设定的有限区域化改编，未添加无来源怪物。

## 框架 / 工程变更

- F6 图中开发模式所有声明连接采用虚线，未验证关卡节点显示琥珀色；已走过的剧情路线仍为实线。
- 新增 Windows 可用 `RUN_DEV2_QA_WINDOWS.ps1` 与 `tools/run_dev2_qa.py`，独立执行注册表、lint、存档、UI、8 个新关、可选剧情测试。
- Godot 引擎启动失败、超时、缺失 **新生成** 的 JSON 报告、JSON 失败项或缺少所需 suite 时明确失败。旧结果不会被判为新的 PASS。
- 新增 `tests/static/test_dev2_world.py`，包括正规名册、原始文档、所有出口 ID、manifest/场景一致性、GDScript 界限符粗检、标记不越级等 6 项新测试。
- 修正关卡源码阶段发现的几个结构缺陷：L020 两个按钮不能提前开三按钮门；L083 上层楼板与下层天花板必须留出楼梯孔；L090 两层楼板都为楼梯留孔；L197 晶柱避开主路；L201 海岸区不再被沙地楼板遮住。

## 离线审计结果（新版本）

- 目标名单：100
- 已有场景文件：39（此前 31）
- 现有 manifest 出口：143（此前 127）
- 指向已构建场景的出口：60
- 按 manifest 从 L000 可达：23
- 基于 **旧 QA 触发器快照** 可达：17（不等于本版通过实际导航）
- 入口标签审计问题：24，其中有旧代码遗留及新增路径；暂未制造没有来源的落点。
- 新增 + 既有静态单测：12/12 PASS（2026-11-07 本地 Python 执行）。

## 未解决与局限

1. 本运行环境没有可用 Godot 4.5.1 编辑器，也无法联网获取；**没有执行导入/脚本解析/真实物理导航/QA/capture/Windows export**。新关卡可能仍有 GDScript 类型或运行时错误。
2. 既有 L009→L011 剧情失败没有在这一轮声称修复。先在目标 Windows+Godot 环境运行定向剧情测试。
3. 新关卡的敌对实体、完整无限世界、复杂玩家交互仍有取舍；以上均是有限 authored slices，不等于源文档全部内容已完成。
4. 需要逐关截图、人工查验碰撞物理、检查“真正可以触发出口”的路线、GPU 统计及存档往返，之后才能将状态从 IN_DEVELOPMENT 升为 PLAYABLE。
5. 既有部分关卡声明了来源出口，但缺少实际 arrival 标签；不能用“默认出生点 fallback”冒充与原设定一致。
6. 目前没有本轮 Windows `.exe`；交付的是完整源码与增量补丁。

## Windows Godot 环境验收

```powershell
# 在源码根目录使用有权执行脚本的 PowerShell
.\RUN_DEV2_QA_WINDOWS.ps1 -GodotExe 'C:\Godot\Godot_v4.5.1-stable_win64_console.exe' -Level L020,L055
.\RUN_DEV2_QA_WINDOWS.ps1 -GodotExe 'C:\Godot\Godot_v4.5.1-stable_win64_console.exe' -Story
```

脚本只执行 headless QA；之后还需真实 GPU 截图和人类试玩。不要仅凭 Python 测试或 headless 退出码修改关卡状态。
