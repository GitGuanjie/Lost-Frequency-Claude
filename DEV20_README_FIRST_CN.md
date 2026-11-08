# LOST FREQUENCY v1.5.0-dev20 — 批量程序化立体空间实验

这是 **dev19 的完整后续源码版本**。这一轮的目标是减少“10 关只是同一种搭楼层模板”的问题：共享的蓝图数据分别构建有墙体与实际门洞的多层迷宫，以及无墙、带真实间隙和护栏的露天高架路径。

## 具体开发内容

- `data/dev20_atrium_blueprints.json` 作为 Godot 建造和 Python 结构验收共同的唯一蓝图。生成脚本：`python tools/generate_dev20_atrium.py`（重复生成字节完全一致）。
- 10 个扩建关卡：L028、L032、L050、L073、L077、L085、L094、L108、L320、L808。对应已有 `SpatialBranchworks` 的升高步道，**不是另开一个孤立传送点**。
- 560 个设计可步行单元（室内为房间，室外为高架平台），740 条横向连接；40 段双向外侧楼梯，210 个楼层内部的设计环路。关闭捷径后图仍连通。
- 每一关新增 6 个 E 调查/操作点（3 个可控制的真实光照回路、2 个环境观察点、1 个实体捷径障碍）；共 60 处新增互动，以及对应的探索日志记录。
- 内室风格以旧关卡自有材质构建墙、地面、洞口、屋顶挑空；室外场景使用真实分离的平台、只有在蓝图有连接时才架设的步桥，不把森林变成统一的楼房。
- 原有 100 关登记、235 条出口声明、414 个 GLB 保留；绝不因随机生成改变 Wiki 的出入口关系。

**Wiki 对照与内容边界：** 本版本沿用 `docs/canon/levels/*.md` 对每个关卡的场景限制；本轮扩建是标注为 `ADAPTATION` 的原创探索结构，不是声称 Wikidot 原文记载了这 560 个位置。Level 8/37 的原有专用洞穴和泳池生成器在本轮保持不变；Level 998 的平坦云层场景不会被套入本轮建筑模板。

## 寻找新结构

用 Godot 4.5.1 Standard 导入解压后的 `3/project.godot`，按 F5 运行游戏，F3 选上述 10 关。新结构附着于原来在远处的分层建筑或高架平台：沿该结构双楼梯上到 **第三个高度面**（以底层为 0，即 tier 2），穿过靠东侧被打开的护栏口，沿带扶手的步道进入新房间群。可以使用 F7 自由摄像机定位，但 F7 飞行不等于玩家真正走过。

在新房间/平台探索时按 E 开关照明或遮挡物，按 J 看探索日志。室内和室外会显示不同的交互用语；仅有标记为非树边的额外通道可开关，因此它关闭也不应把玩家困死。

## 检查与构建

```powershell
# 在项目目录（含 project.godot）运行
python -m unittest discover -s tests/static -v
.\RUN_DEV20_QA_WINDOWS.ps1 -GodotExe 'C:\path\Godot_v4.5.1-stable_win64_console.exe'
# 通过全部引擎阶段且安装了导出模板后：
.\EXPORT_DEV20_WINDOWS.ps1 -GodotExe 'C:\path\Godot_v4.5.1-stable_win64_console.exe'
```

*离线结构与单元测试：178/178 PASS。*

**Godot 实机：FAIL / 未验证。** 实际尝试 `tools/run_dev20_qa.py --godot godot` 时在第一阶段发现不存在 `godot` 可执行文件；因此没有完成脚本编译、真实碰撞、自动角色寻路、视觉审查或 Windows 导出。失败证据在 `reports/qa/v150_dev20/batch_summary.json`。所有“连通”数字都是数据图连通，不是实机能走通的证据。只有真实 Godot 通过 + 玩家游玩证据后才可宣布可玩。

开发资料：`docs/production/V150_DEV20_PROCEDURAL_DEPTH_CN.md`。拓扑示意图是脚本绘制的数据可视化，非 Godot 实机截图。
