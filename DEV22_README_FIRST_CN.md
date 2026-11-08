# LOST FREQUENCY v1.5.0-dev22 — 主题区域、真实层次与交互兼容修复

**交付类型：完整 Godot 4.5.1 源码，非实机验收完成版。**

本轮从 dev21 原工程继续修改，未另建游戏、没有删除旧关卡/模型，也没有虚构新关卡出口。dev22 的目标是让此前十座相似的副建筑继续生长出具有主题、实体楼梯、实体回环、独特路标和可调查内容的**第二组程序化立体区域**。

## 已加入的内容

- 十个已存在关卡：L028、L032、L050、L073、L077、L085、L094、L108、L320、L808，各在 dev20/21 原侧翼的北侧接入一座独立新区域。
- 新区域共 **42 个高度层、626 个设计可探索地板单元、782 条室内门洞/室外实体连接、198 个楼层内部回环、64 段独立跨层楼梯**。这些是程序蓝图/源码生成的几何数量，不是已经跑过角色的房间数量。
- 每个新区域拥有一座有实体楼板、护栏与开门连接的**主题观景台**，并使用不同造型：城堡工坊、树冠桥、交通信号架、残破城垛、雾中瞭望、净化避难站、错比例建筑、根系平台、游乐设施入口、霓虹光廊。
- 新增 **272 个实际 GLB 模型摆放定义**（楼层布景 252 + 观景点 20），使用原项目已有的模型文件和 MatLib 材质。所有模型是非阻挡装饰，房间、地板、楼梯、护栏和可开启挡板由 GeoKit 创建实物碰撞。
- 新增 E 键互动：**42 个高度标记、42 个独立环境照明开关、30 处调查点、10 个可开启的次要捷径**；此外为这十个区域新增 30 个高度限幅的环境音/氛围发现点。完成该区域全部标记调查后，玩家可以打开一扇物理挡板，但这条边是非树边，主路线在挡板关闭时依然连通。
- **重要系统性修复：** 在 `core/interaction/Interactable.gd` 使用 Godot `Callable.get_argument_count()` 兼容无参数回调、Player 参数回调及 `.bind()` 预绑定回调。代码扫描发现至少 54 处早期关卡互动直接使用 `func()`，此前一律传入 Player 可能产生参数数量错误。修复已写入，但尚未实机逐个验证。

**合计:** 与 dev20/21 同一批 10 关相比，新增模型摆放定义 272 个（原 dev21 为 330 个），是进一步增加内容层次，不等于现在 100 关同等质量。项目总体仍保留 100 关清单、235 条出口声明和 414 个 GLB 模型资源。

## 根据 Wiki 的设定控制

- L028：蓝色天空与 Stormstone Keep、城堡内的传统元素和违和的现代器物；《Level 28 - Final Virtue》当前网页与历史版本在叙事上有修订，新增区属于游戏改编，不冒充原站房间清单。
- L085：以严酷污染环境中的室内庇护、洁净而异常的室内陈设为主题；可操作灯光属于游戏改编，并非 Wiki 记载的官方净化机关。
- L320：参考现行《The new, and Improved, Entertainland!》的 Folding Point 多楼层游乐设施，构建五层高度差和可调查的服务路线，避免继续只做平面游乐园。
- L808：按 Synthwave World 的霓虹、几何网格和日夜色彩变化确定主题方向，不把它做成普通水泥楼房。

本轮设计参考原工程 `sources/wiki_text/` 快照及对照的当前 Wikidot 页面。故事文字、实体布局、操作站点都标为 **ADAPTATION**，不伪称原文。保留原有资源归属和许可文件。

## 运行

1. 在 Windows 下载 Godot **4.5.1 Standard**（或相应 4.5.x），解压本项目的完整 ZIP。
2. Godot Project Manager → **Import** → 选择 `3/project.godot`，等待 414 个 GLB 模型资源首次导入。
3. 进入编辑器按 **F5**，在游戏中按 **F3** 选择 L028/L032/L050/L073/L077/L085/L094/L108/L320/L808。沿原多层建筑的东侧通道进入 dev20 的中层房间，再从中层北门走向新区域。按 **E** 调查/操作，按 **J** 看日志，**F7** 是开发飞行视角。

仅从 dev21 升级：备份旧项目后，把 `LostFrequency_dev21_to_dev22_PATCH.zip` 内容覆盖到 dev21 压缩包解出的、包含 `3/` 的同级路径。补丁是增量文件，而不是可单独运行的项目。

## 验收要求与已知限制

```powershell
# 项目根目录：project.godot 所在位置
python -m unittest discover -s tests/static -q
python tools/generate_dev22_districts.py
.\RUN_DEV22_QA_WINDOWS.ps1 -GodotExe 'C:\path\Godot_v4.5.1-stable_win64_console.exe'
# 只在新版本原生 QA 全部通过后允许尝试 Windows 调试版导出
.\EXPORT_DEV22_WINDOWS.ps1 -GodotExe 'C:\path\Godot_v4.5.1-stable_win64_console.exe'
```

本开发环境离线静态回归为 **207/207 PASS**；但尝试原生 Godot 导入时未找到 `godot` 可执行文件，真实引擎验收失败，证据在 `reports/qa/v150_dev22/batch_summary.json`。因此未声称：Godot 脚本完整可解析、角色实际通过所有桥与梯、完整 100 关可玩、Windows 实机帧率、所有 GLB 视觉正确。必要的 Godot `district_dev22` QA 已接入 `tests/qa_runner.gd`，可在有 Godot 的系统验证真实地板/楼梯碰撞、GLB 实例、E 回调、信号灯和捷径挡板。

**地图资源布局图是源数据设计图，不是实机游戏截图。** 见 `docs/production/DEV22_ThemeDistricts_Overview.png` 和 `DEV22_L320_FiveStorey_Design.png`。
