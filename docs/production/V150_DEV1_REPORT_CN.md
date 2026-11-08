# Lost Frequency v1.5.0-dev1 — 实际源码开发与审计报告

审计范围：基于用户提供的 `LostFrequency_v1.4.0-m5_source.zip` 修改。日期：2026-11-07。

> **状态：源码开发快照，不是 Windows 可执行正式版。** 此环境没有 Godot 4.5.1/Windows 导出模板，未运行游戏引擎、物理导航、GPU 截图、人工试玩或 Windows 导出。不要把离线测试通过解释为 GAMEPLAY PASS。

## A. 本次实际落地的功能

1. `ui/WorldGraph.gd`、`ui/Overlay.gd`、`autoload/Settings.gd`：**F6 有向关卡连通图**。开发模式显示已建关卡的声明连线；剧情模式只显示玩家到过的关卡和已实际记录的出口；支持缩放、拖动、节点选择以及关卡详细信息。与 F3 选关浏览器分离，普通玩家不能借此传送。
2. `autoload/SaveService.gd`：新存档不直接删除旧主存档；在正式替换前备份旧文件，增加并恢复玩家上次来源边（`last_arrival_edge`），修复成功保存后遗留错误状态。
3. `autoload/TransitionService.gd`：超时边界和失败提示；成功进入目标关卡后持久化来源，支持 `@origin` 类返回机制。所有错误路径仍需引擎级测试。
4. `tests/qa_runner.gd`：逐路牌定位与记录进度；不能在远离交互范围时直接 `interact()`；增加世界图剧情/开发模式与存档来源的检查。此前 L009→L011 故障**尚未证明修复**，但现在能够更早定位首个失败路牌。
5. `tools/world_audit.py`：源清单→已建世界有向边、到达标签、已有 QA 快照证据，生成可复核 CSV、JSON、DOT、SVG。
6. `tools/preflight_dev.py` + `tests/static/test_world_integrity.py`：无 Godot 环境下执行源码词法粗检与约束检查（共 6 个静态测试），并严格区分这类检查与引擎验收。
7. `tools/run_dev1_qa.py` + `RUN_DEV1_QA_WINDOWS.ps1`：按注册表、清单、存档、UI、四个候选关卡分批运行真正的 Godot QA。保存日志，按阶段限制超时；若没有生成**新** QA JSON 即判失败。支持 `--story` 继续专项剧情测试。

## B. 四个新候选关卡（均为 `IN_DEVELOPMENT`）

| 关卡 | 实际新增的场景代码 | 还缺什么 |
|---|---|---|
| L036 Timeless Airport | 8 组行李传送带、18 个无人值守柜台、26 个 A–Z 区域、抽象航班计数、错误导向牌；来源支持的 L036_1 舱门及来自 L009 的落点 | 真正的航站楼高质量截图、候机/登机过程验证、尚未建的 36.1 子关卡 |
| L060 The Baywalk | 260m 双高度海边通道、三组真实台阶（墙体为阶梯开口留空）、失效路灯、水位/暗沙/洋流/门户状态、通往 L007 的有条件海域出口 | Godot 碰撞/游泳与入口验证、L007 的 `from_L060` 专用海中落点、文档规定的实体/风险行为 |
| L075 Sandrooms | 6×5 有种子连接的沙地房间、脚印痕迹、旧玩具、无声源氛围、沙地结束的隐蔽门 | 动态布局与出生点的导航验证、截图质量、`EXT` 未知出口的正规边界表现 |
| L999 | 无色悬浮岛、倒锥形岩体、静止树林、废弃屋、中央地板门 | 几何碰撞验证、垂直通路/实体细节、`EXT` 未知出口边界 |

全部四关在 `level.json` 中保留了来源文字与原始边 ID；目的地尚不明确的出口保留 `EXT`，不捏造连接。所有新关卡使用源码生成几何与材质，不增添未经许可外部资源。

## C. 本轮静态审计的**可复现指标**

- 100 个预定 Level；**31 个有场景文件的 Level**，包括原有 27 个与本轮新增 4 个未验收候选。
- 127 条关卡清单出口声明，**45 条**连接两个已建场景。
- 以 L000 为起点，配置图上可达 **19** 个已建关卡；按历史 QA 快照中观察到的出口边仅 **16** 个。两组数据都**不能**代表玩家实际能通行的数量。
- 当前静态审计报告仍有 **15** 处到达标签匹配问题，主要涉及遗留场景；其中新关卡 L060→L007 的目标落点需下一轮处理。把缺少标签视作待核验问题而不是自动注入 start 落点。
- `python tools/preflight_dev.py`：九份变更 GDScript 的字符串/定界符粗检通过；该检查不是 Godot GDScript 编译器。
- `python -m unittest discover -s tests/static -v`：**6/6 通过**。校验清单/来源边、状态隔离、保存来源及测试源码结构，不包含引擎运行。

离线审计文件：`reports/world_audit/WORLD_AUDIT.md`、`exit_evidence.csv`、`world_report.json`、`world_graph.dot`、`world_graph.svg`。

## D. 下一轮在 Windows 上必须完成的验收

在已安装 Godot **4.5.1-stable**、Python 3 的 Windows 环境，运行：

```powershell
python tools/preflight_dev.py
python -m unittest discover -s tests/static -v
python tools/world_audit.py
.\RUN_DEV1_QA_WINDOWS.ps1 -GodotExe "C:\path\Godot_v4.5.1-stable_win64_console.exe" -Story
```

脚本的 `--story` 预计可能暴露遗留 L009 路牌问题；这应视为真实失败，不能通过硬改 QA 来伪造通过。全部日志与独立 JSON 写在 `reports/qa/v150_dev1/`，失败时停止，不覆盖旧 `latest_results.json`。

必要人工验证：在 Forward+ 环境检查 F6 的视图尺寸与节点可读性、F3 开发者进入四关、上下层实际行走/海水游泳、出口条件、关卡入口、关卡间读档、实际帧率与碰撞体数量；每关至少两张经人工审核的截图。未完成前不要把候选标为 PLAYABLE。

可选 Windows 导出（Godot 4.5.1 发行模板已安装且所有发布关卡已验收后）：

```powershell
godot --headless --path . --export-release "Windows Desktop" "export/windows/LostFrequency.exe"
```

以上命令在此环境**没有执行**，不存在已完成的 v1.5 Windows EXE。

## E. 仍需优先处理的系统性问题

- 解决 L009→L011 物理路牌路径（已强化失败证据，但根因尚未通过引擎复现）。
- 修复历史 15 个入口标签缺失，特别是新 L060→L007 来源落点，先给真正合理安全的物理位置，而不是无条件回退 `start`。
- 将 27 个原有关卡声明的出口逐条跑流式探索/进入/返回测试，区分声明、实例化、可触发、成功转场。
- 改进大型场景的物理性能（尤其已有 QA 显示的高碰撞体数量）以及 GPU/人工视觉审查。
- 让所有 100 个名单条目逐步取得**场景源码+引擎测试+截图+玩家路线**的闭环，不能复制空模板凑数。

## F. 执行原则

从本快照继续开发，不要重新初始化 Git，不要把四个候选关卡描述为已验收，不要重写/覆盖既有 QA 证据。每批完成单关代码→新独立 QA→截图审阅→真实游戏验收→升级状态→提交。受平台 RPM 限制时减少代理并行与重复仓库全盘阅读，保留一份简短 handoff。
