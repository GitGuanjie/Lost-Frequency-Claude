# LOST FREQUENCY 1.5.0-dev21 — 材质/物件/空间多样性批量扩建

本版是从 dev20 **直接修改的完整 Godot 源码**，不是单独示例文件。基于 dev20 的 10 座多层迷宫/高架结构，增加实际现有 GLB 道具、主题建筑构件、带碰撞的延伸观景台、可互动的高度定位装置及局部声音线索。

## 本轮真实改动

- **330 处 GLB 摆放**（每关 33 处），使用 **68 种**已有模型、**9 个资产包**，涉及 L028、L032、L050、L073、L077、L085、L094、L108、L320、L808。
- 每关 **2 座北侧实心观景平台**，带真实实体栏杆、支撑柱、入口开洞。10 关共 20 座；每关按主题建造不同的边缘构件，而非统一换色。
- 每关 **3 个实体互动高度定位器**（OmniLight3D + 发光面板，按 E 确实改变亮度），**3 个可读物件**、**2 个靠近时触发的空间声音事件**；共 30 个定位器、30 个可读物件、20 个声音事件。原有 dev20 的开关/可移动支路障碍仍保留。
- 修复 dev20 `Interactable.interact(Player)` 的回调参数错误：原有 `toggle_circuit`、`toggle_shutter`、`observe` 现在接受传入的 Player。Godot 专项测试通过真实 `Interactable.interact()` 入口测试新定位器，而非直接调用状态函数。
- 模型不拥有障碍碰撞，避免几何碰撞挡住路径；角落摆放保证实际**室内地板**和更窄的**室外 5.14 米平台**不出现模型悬空；墙、地板、桥、楼梯和护栏仍由 GeoKit 生成真实可碰撞结构。隔层声音有独立高度门限。
- 主题细节来自 `sources/wiki_text/` 原始出处快照：如 Level 28 的 Stormstone Keep、Level 85 的豪华住宅与假食物、Level 94 的人工质感、Level 808 的合成波城市。新增故事、对象位置、观察行为均标为 **ADAPTATION**，不冒充 Wiki 原文中的设施与机制。

这些是针对 dev20 的 **10 个已有场景群的实质扩建**。并不是宣称 100 关都已达到同等完成度；原有 100 关登记、235 条出口声明、414 个 GLB 文件保持不变。

## 使用步骤

1. 在 Windows 安装 Godot **4.5.1 Standard**；下载并解压完整 ZIP，在项目管理器选择 `3/project.godot`，等待 GLB 首次导入完成。
2. 按 `F5` 运行，`F3` 选择上述 10 关，从原有分层建筑的两条楼梯上到第三个高度面（tier 2），沿东侧步道进入三层支路群。`E` 调查物件或点亮各层定位标记，`J` 打开调查日志。`F7` 可用作开发摄像机观察，但不是实机通行验收。
3. 只已有 dev20 的用户：备份项目，把 `LostFrequency_dev20_to_dev21_PATCH.zip` 直接解压覆盖到包含 `3` 目录的上层文件夹。

## 生成器与检验

```powershell
# 在项目根目录（project.godot 所在位置）
python tools/generate_dev21_scenarios.py
python -m unittest discover -s tests/static -q
.\RUN_DEV21_QA_WINDOWS.ps1 -GodotExe 'C:\path\Godot_v4.5.1-stable_win64_console.exe'
# 原生 QA 通过后可尝试实验导出
.\EXPORT_DEV21_WINDOWS.ps1 -GodotExe 'C:\path\Godot_v4.5.1-stable_win64_console.exe'
```

主要代码：`core/world/ScenarioDressing.gd`、`ScenarioArchitecture.gd`、`AtriumWeave.gd`、`AtriumWeaveState.gd`；可重复生成的数据：`data/dev21_wing_scenarios.json`。Godot 专项 QA：`tests/qa_runner.gd` 的 `scenario_dev21` 套件，验证 330 个真实 GLB 实例、实体 E 触发、发光装置及新增观景台楼板。

**测试诚实说明：** 本环境 189/189 项离线 Python 测试通过；但缺少 Godot 可执行文件，实际尝试原生导入就失败，日志和失败状态位于 `reports/qa/v150_dev21/batch_summary.json`。因此没有通过 Godot 脚本解析、角色跨层路径、碰撞、Windows FPS / 画面、原生导出测试；不能称这版已实机可玩。完成真正的 Godot 测试和玩家操作检验后才能升级质量标志。

## 批量扩建不是无上限堆砌

每关限定 33 个额外 GLB；资产由带上限的脚本预先生成，不在运行时随机无限实例化。场景图同一关、同一数据可精确复现。现有资源权利信息仍在 `assets/packs/LICENSE_AND_SOURCE.txt` 和 `assets/ASSET_PROVENANCE.csv`；Wiki 引用与署名仍见 `sources/wiki_text/` 及原仓库许可说明。
