# LOST FREQUENCY — 无限回廊 v5（Windows 可运行版）

> 引擎：Godot 4.7.2 stable（Windows 64 位）
> 本次会话在真实 Windows 机器上完成：**原生引擎测试全部通过 → 导出 → 实机运行验证**

---

## 一、这次到底做了什么

### 1. 先修 Bug，再谈功能

v4 这个包**从来没有在原生引擎里跑过一次**。一跑就发现了 5 个真实缺陷，其中包括
**整个项目唯一的 QA 入口从来就没能工作过**：

| # | 缺陷 | 后果 |
|---|---|---|
| 1 | `core/world/ChunkWorld3D.gd` 空格与 Tab 混用 | 脚本解析失败，421 个脚本里 3 个编译不过 |
| 2 | `ChunkWorld3D.gd` 在**编译期**引用 `SaveService` 自动加载 | 无头 `--script` 环境没有 autoload → 类加载不了 → `ContinuityTopologyTest` 在 `quit()` 之前中断 → **测试永久挂死** |
| 3 | 离线 Python 合约用 `read_text()` 读 UTF-8 源码却没指定编码 | 中文系统（GBK）上 29 个测试全部 `UnicodeDecodeError` 直接崩掉 |
| 4 | QA 批处理用 `set "ROOT=%~dp0"` 再 `--path "%ROOT%"` | `%~dp0` 末尾的反斜杠会把右引号转义，引擎收到 `"C:\...\项目" --import"` → **每个 QA 批处理都是坏的** |
| 5 | `ui/Overlay.gd` 在 toast 框正在加子节点时移除另一个 | 引擎报 *Parent node is busy*，旧 toast 留在屏幕上 |

第 4 条尤其关键：项目文档里写的验收命令一直是坏的。现在它能完整跑通。

### 2. 修掉“按 x 坐标切分区”的错误

v4 里写死了一条规则：

```gdscript
return "L001_PROXY" if k.x >= 4 else "L000"
```

它错在两处：

* **把中央 8×8 超级街区枢纽劈成两半** —— 枢纽在 chunk x = 3..4，这段 x=4 正好
  落进另一个分区，于是一个街区有两套建筑身份；
* **把一个普通混凝土仓库当成正典 Level 1** —— 这是非正典改编，不能顶着 L1 的名字。

现在**分区 = 一个完整的 8×8 超级街区（192 m 见方）**，用显式 id：

* `Z_L000_YELLOW` —— 出生街区，保留正典 Level 0 的原教旨外观（单调黄墙纸、潮湿地毯、嗡嗡的日光灯）
* `Z_PROXY_WAREHOUSE` —— 整块超级街区的裸混凝土仓库，**明确标注非正典**
* `Z_<sx>_<sz>` —— 其余街区

另外新增了 `core/world/WorldAddress.gd`：用
`world_id | zone_id | chunk_x:chunk_y:chunk_z | 局部坐标` 明确寻址，
**把“物理位置”和“正典关卡身份”彻底分开**——正典关卡是叙事目的地，不是坐标。

### 3. 建筑不再由单个 chunk 自己决定

原来是 24 m 一个 chunk 各自掷骰子。现在是分层结构：

```
世界 → 街区(16×16 chunk) → 超级街区(8×8 chunk) → 巨型建筑 → 宏单元(4×4 chunk) → chunk
```

每个超级街区**声明**自己的巨型建筑（占地 4×4 到 8×8 chunk，192 m × 96 m 到
192 m × 192 m），结构类型有四种：`arcade` 连拱长廊、`machine_hall` 工业厂房、
`shaft_stack` 竖井塔群、`archive_block` 档案库。

**关键点：巨型建筑的构件在世界坐标里对齐。** 每个 chunk 重复同一套柱网
（局部 4.0/20.0 × 3.7/20.3）、同一套墙垛、同一套顶梁、同两条地面嵌条——因为
24 m 的 chunk 尺寸正好整除柱距，柱子跨过 chunk 接缝时仍然是一条**连续的柱廊**，
读起来是一栋楼，而不是两间碰巧对上的房间。

同时**分区只改几何，不改身份**：黄色街区无论长出哪种巨型建筑，材质家族仍然是
Level 0 的黄墙纸 + 地毯。

### 4. 流式加载与存档

* 按**时间预算**（毫秒）+ 按个数双重限流，一块特别贵的 chunk 不会卡住一帧；
* 加载顺序**朝玩家朝向偏置 6 倍**，往哪走哪边先出现；
* 每帧重算需要集合 → 走远了还没建的 chunk 直接被取消；
* 每个 seed 一个独立存档文件，带 `.bak` 轮转、写入后回读校验、**生成器版本号**
  与迁移规则（换生成器时保留 seed 与玩家进度，丢弃只对旧生成器有意义的布局版本号）。

---

## 二、验证结果（全部是实跑出来的数字）

```bat
RUN_V5_QA_WINDOWS.bat "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
```

| 步骤 | 测试 | 结果 |
|---|---|---|
| 1 | 资源导入 | PASS |
| 2 | CompileAll | **PASS** — `scripts=425 failing=0` |
| 3 | ContinuityTopologyTest | **PASS** — `15593 checks, 0 failures` |
| 4 | ContinuityMacroStructureTest | **PASS** — `74529 assertions, 0 failures` |
| 5 | ContinuitySuperDistrictTest | **PASS** — `100997 assertions, 0 failures` |
| 6 | ContinuityRegionalPlanTest（新） | **PASS** — `6505 assertions, 0 failures` |
| 7 | ContinuityPhysicalWalkTest（新，**真物理**） | **PASS** — `14 checks, 0 failures` |
| 8 | 离线 Python 合约 | **PASS** — `Ran 45 tests ... OK` |

**原生断言总数：198 103 条**，外加 45 条离线合约、425 个脚本编译通过。

### 物理行走测试是这次的关键

`tests/ContinuityPhysicalWalkTest.gd` 用**真实的 CharacterBody3D** 在生成的世界里走，
靠引擎物理推着走（撞墙会自然滑动、像真人一样找到门洞）。**数值对得上不代表走得过去**——
声明的门口和实际建出来的墙只要对不上，这个测试就会失败。它验证了：

* 穿过**声明的**东侧门口，chunk 坐标真的变了；
* 原路返回；
* 走进**负坐标**并且再走回来；
* **爬楼梯上到上一层**（chunk 的 y 变了）；
* 走过 2×2 宏大厅的**中庭天桥**，且**没有掉进中庭空洞**；
* 卸载再重建的 chunk 结构完全一致（世界由坐标决定，与会话历史无关）。

### 100 关正典回归：零回归

同一套 QA 在**改动前**和**改动后**各跑一遍，逐个 suite 对比：

| | 改动前(v4 原样) | v5 | 差值 |
|---|---|---|---|
| 断言数 | 9 912 | 9 912 | **0** |
| 失败数 | 16 | 16 | **0** |
| 失败数不同的 suite | — | — | **0** |

那 16 个失败是 v4 原包就有的（L026 / L028 / L032 / L050 / L073 / L085 / L320 /
L808 各若干 + 1 条 story），与本次改动无关，**既没修好也没变坏**，已列入交接清单。

**正典 100 关、`data/canon/`、剧情转场图一个字都没改。**

### Windows 导出与实机验证

| 项目 | 值 |
|---|---|
| 预设 | `Windows Desktop`，PCK 内嵌 |
| 产物 | **单文件 238.8 MB**，不需要外挂 `.pck` |
| 实机渲染 | Vulkan 1.4.351，Forward+，NVIDIA GeForce RTX 3060 Laptop GPU |
| 启动检查 | `LostFrequency.exe --headless --quit-after 400` → 干净启动 |
| 进世界检查 | `LostFrequency.exe -- --lab --shot "C:\shot.png"` → `err=0 size=1600x900` |
| 画面检查 | 像素统计：33 689 种不同颜色，均值 RGB (99.7, 83.1, 50.5)，正是回廊的暖黄调 |
| 主菜单检查 | stderr 干净 |

新增了两个命令行入口：

```
LostFrequency.exe -- --lab                          直接进入程序化世界
LostFrequency.exe -- --lab --shot "C:\shot.png"     截一张世界图并退出
```

### 性能：**没有测，所以不编**

本次会话没有做帧时间采集，因此报告里**不写**任何中位数 / p95 / p99 帧时间、
内存显存占用或三角面数字。代码里已经有可用的采集点（实验室 HUD 显示已加载
三角面与碰撞体数量，流式器统计 built / unloaded / peak）。**把真实性能数字补上，
是下一个 session 的第一优先级之一。**

---

## 三、怎么玩

```
主菜单 → Experimental · Infinite Backrooms · Continuity Lab v5
```

| 键 | 作用 |
|---|---|
| F8 | 小地图（`H` 枢纽 / `=` 主干道 / `B` 巨型建筑 / `A` 中庭 / `*` 发现物 / `M` 标记） |
| F9 | 在当前 chunk 放一个**永久**标记 |
| F4 | 重掷当前房间的**陈设**（永远不会动门、井、天桥、建筑结构） |
| F5 / F6 | 切换 / 新建世界种子（每个种子一个独立存档，互不干扰） |
| F10 | 回主菜单 |
| F2 | 指向最近的未探索枢纽 |

HUD 顶部实时显示 `ZONE / 角色 / 巨型建筑 id / 完整寻址`，随时知道自己站在哪个
街区的哪一格里。

---

## 四、已知问题（诚实清单）

1. **Godot 4.7.2 每次切场景都会打印 *Parent node is busy adding/removing children***。
   用一个只含两个空场景、不含任何本项目代码的探针复现出来了，**是引擎行为，不是本包缺陷**。
2. **楼梯井是敞开的**：楼板洞 4.2 m 宽，填进去的坡道只有 2.4 m 宽，旁边 1.8 m 是
   没有护栏的通下一层。这是 v4 的设计，保留未动。
3. **门口可能正好开在楼梯井上**：门口偏移是 8/12/16，井的横向范围是 14.4…18.6，
   有重叠。值得修（让偏移避开井，或反过来让井避开偏移）。
4. **16 个正典关卡的既有失败**未处理（见上表）。
5. **实验室没有 noclip、没有任何正典出口**。三种连接类型已在坐标文档里定义清楚，
   但只有 PHYSICAL 落地了——不凭空发明正典出口，是刻意的。

---

## 五、文档索引

| 文件 | 内容 |
|---|---|
| `docs/production/INFINITE_BACKROOMS_V5_ARCHITECTURE.md` | 程序化生成架构（分层、巨型建筑、材质身份） |
| `docs/production/INFINITE_BACKROOMS_V5_COORDINATES.md` | 坐标系与连通性规格（共享面归属、楼梯、天桥、三种连接） |
| `docs/production/INFINITE_BACKROOMS_V5_SAVE_SCHEMA.md` | 带版本号的存档格式与迁移规则 |
| `reports/qa/INFINITE_BACKROOMS_V5_QA_REPORT.md` | 完整 QA 报告（真实数字、命令、缺陷清单） |
| `INFINITE_BACKROOMS_V5_HANDOFF.md` | 交接文档（改动清单、复现步骤、Git、下一步） |
| `RUN_V5_QA_WINDOWS.bat` | 一条命令跑完全部原生验证 |
