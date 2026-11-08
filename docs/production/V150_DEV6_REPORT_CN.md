# Lost Frequency v1.5.0-dev6 — 实际源码开发报告

日期：2026-11-07。基线：`LostFrequency_v1.5.0-dev5_source.zip`；本轮在源代码层面增加 **16** 个关卡候选场景，并改进 F6 有向路由图、临时出生点文档、物理出口设计与验证门槛。

## 整体状态

- Canon 目标：100；实际场景文件：**84**（此前 68）。
- 出口清单声明：**201**；连接两端已建场景：**121**。
- Level 0 配置级有向可达：**40**；历史 QA 快照图可达 **23**（不是本轮真实引擎测得）。
- 本轮新增的关卡状态：全部 `IN_DEVELOPMENT`；**0/16** 获得真实 Godot + Windows 人工验收。审计结构问题：**0**。
- `python -m unittest discover -s tests/static`: **36/36** 项 Python 静态测试通过，其中 dev6 新增 8 项。
- 本环境没有可运行的 Godot 4.5.1、Windows/Wine 实机环境；未编译验证 GDScript、未实际启动、未捕捉新版本 GPU 画面、未做物理巡航。

## 新增关卡

| ID | 独特设计（缩小规模的候选实现） | 源据出口数量 | 验收 |
|---|---|---:|---|
| L017 | Carrier ship: repeating bulkheads, sector clocks, closet threshold and cold machinery | 0 | IN_DEVELOPMENT |
| L018 | Childhood daycare, low furniture, plush dinosaur memory and quiet return | 1 | IN_DEVELOPMENT |
| L030 | Daylight floating grass islands above vast void; no confirmed escape | 0 | IN_DEVELOPMENT |
| L069 | Narrow infinite road between concrete walls and a vehicle safe zone | 2 | IN_DEVELOPMENT |
| L073 | Moonlit crimson island, rising castle, black sea and silent gate | 0 | IN_DEVELOPMENT |
| L000_2 | Pristine remodeled Level 0 gives way to exposed wall studs and unsafe debris | 1 | IN_DEVELOPMENT |
| L001_3 | Overbright sixteen-door medical corridor with delayed detox interactions | 1 | IN_DEVELOPMENT |
| L001_5 | Inverted illumination and receding whispers in a white room circuit | 0 | IN_DEVELOPMENT |
| L003_5 | Void-sky electrostatic tower cluster, intermittent discharge and extraction | 1 | IN_DEVELOPMENT |
| L005_1 | Hotel casino: slot banks, card tables, four chip colours and exit lobby | 1 | IN_DEVELOPMENT |
| L007_7 | Solitary 47m lighthouse, narrow upper stairs and dark ocean | 1 | IN_DEVELOPMENT |
| L010_1 | Contaminated crimson basin, exclusion fence and shoreline readings | 0 | IN_DEVELOPMENT |
| L011_3 | Red-fog gutted urban avenues, guarded perimeter bridges and mask cue | 1 | IN_DEVELOPMENT |
| L037_1 | Sanguine pool labyrinth, red ambient light and slow-return transition | 0 | IN_DEVELOPMENT |
| L096 | Quiet mountain house with porcelain, dust and a restorative interior | 0 | IN_DEVELOPMENT |
| L965 | Monochrome flood plain with silent turbines and no confirmed route mechanism | 0 | IN_DEVELOPMENT |

### 实质性系统改动

1. **F6 路径预览**：按有向边做 BFS，选定关卡显示从当前 Level 出发的最短已知路径；开发模式只承诺清单声明，故事模式仅用玩家目击过的路线。不生成新传送通道。
2. **入口对齐**：补齐 14 个缺失入口标签，老场景的新入口是显式标注的临时安全落点，不计入精细入口制作完成数。
3. **几何修复**：L007_7 灯塔改为相互衔接的折返爬升坡道，47m 近似高度且修正海面跳跃出口体；L096 房屋开设能走通的门；L003_5 将建筑移出主轴；L001_3 增加可进入的侧房隔墙；L000_2 倒塌事件后出现真实障碍物。
4. **探索风险与互动**：L073 室外停止移动逐步增加危险；L010_1 接近污染湖会累积暴露与伤害；L005_1 赌场机器和筹码计数；L018 旧玩具回忆；L011_3 面罩和幻觉提示；L037_1 灯光渐暗。
5. **发布阻断**：`tools/production_gate.py --release` 要求每关真实 Godot QA、Windows 手工测试、画面/出生点/物理出口/存档证明。缺证据就失败；不允许脚本解析和测试输出被跳过。

### 已知未实现或只部分实现

- L069 没有完整可驾驶汽车与 17 小时旅程模拟；隧道仍锁定。L017、L030、L073、L001_5、L096、L965 等无可靠已知目标的路线没有伪造回程。
- L007_7 的灯塔坡道虽在几何上连续定义，但未经玩家实际爬升测试。实体 AI、道具经济、真正的水体伤害、持续音频和高保真美术仍需推进。
- Level 9 → Level 11 的历史剧情失败尚无真实 Godot 运行验证。
- 配置图中的 40 可达关卡不能推断 40 关玩家已实测走通。

## 运行与验收

在 Windows + 官方 Godot 4.5.1 环境，从源码根目录运行：

```powershell
python -m unittest discover -s tests/static -v
python tools/world_audit.py --fail-on-issues
.\RUN_DEV6_QA_WINDOWS.ps1 -GodotExe "C:\Path\To\Godot_v4.5.1-stable_win64_console.exe" -Story
```

若已取得所有新关卡实际 QA 和手工报告，再用 `EXPORT_DEV6_WINDOWS.ps1` 做官方 Godot 导出。当前附送的 Windows 包仅复用旧版 Godot 引擎，替换嵌入资源：**资源完整性验证不等于能启动、能跑或没有脚本错误。**
