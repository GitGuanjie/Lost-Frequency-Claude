# Lost Frequency v1.5.0-dev9 — 414 GLB 模型集成开发报告

## 实际完成

- 在 v1.5.0-dev8 原有 **100 个关卡场景**上增量开发；本轮没有虚构新 Level 或新增跨关卡出口。
- 解包和校验上传的 **414/414 个 glTF 2.0 `.glb`**，共 10 个资源系列，合计约 78,361 个网格三角面；逐文件 SHA-256 与用户资源包清单一致。这是资产总复杂度，不是实际单帧渲染负载。
- 把 414 个模型都导入 `assets/packs/`，建立包含实际包围盒尺寸、顶点几何统计和授权信息的 `catalog.json` / `model_catalog.csv`。
- 在 **24 个已有 Level** 中实际编写 **466 条模型摆放配置**，选用 **86 种独立模型**；不是 414 个模型全放到世界里。按场景包含酒店、餐厅、赌场、潜艇、图书馆、仓库、城镇、洞穴等不同环境。具体逐关数量见 `V150_DEV9_MODEL_COVERAGE.csv`。
- 给这 24 个 Level 各新增至少一项环境调查对象，总计 **27 条**独立观察文本，未新增传送门或绕过出口条件。
- `core/world/ModelDress.gd` 作为可选装饰层，对 GLB 原始包围盒做尺寸归一化；大多数实例不生成碰撞体，原有 GeoKit 路径、楼梯、出口优先。四个流式关卡的物件跟随 Chunk 生命周期卸载。
- 新增 **414 模型开发者展厅**（`tools/AssetGallery.tscn`，20 个/页，可左右翻页）。它不添加到正式剧情关卡注册表。
- 新增引擎级资源烟雾测试 `tests/ModelAssetSmoke.tscn`：预期在真正 Godot 导入后逐个载入并实例化全部 414 模型，再实例化所有 466 个摆放记录。注意这是**待运行的测试代码，不是测试已通过**。
- 新增 `tools/run_dev9_qa.py`，覆盖模型导入烟雾测试、全局基础 QA、24 个改造关卡的分批 QA、可选 L009→L011 物理剧情路径；只认本轮新生成的 JSON 证据。新增 Windows 上的 `EXPORT_DEV9_WINDOWS.ps1`：实际 Godot 验证不通过就拒绝导出。

## 资产许可证与画面取舍

上传包内 `LICENSE_AND_SOURCE.txt` 声明素材为 Kenney CC0，原始元数据已保存在 `assets/packs/`；许可声明为随包文件所载，本轮没有独立联网核实。模型整体属于低多边形风格，不能仅靠模型数量证明视觉质量已达到写实水平。保留原建筑几何与既有材质，仅做有选择的细节层；画面品质仍需截图与玩家试玩确认。

## 验证状态

| 检查 | 本轮结果 |
|---|---|
| 414 个文件完整性与哈希 | 通过 |
| 466 条摆放与 24 关引用的静态一致性 | 通过 |
| Python 离线回归 | **67/67 通过** |
| 414 个模型在 Godot 4.5.1 实际导入/脚本编译 | **未通过验收：当前环境无 Godot** |
| 24 个改造关卡的真实场景载入、碰撞、材质 | **未验收** |
| L009→L011 实际物理通路 | **未验证成功，原先故障不能宣称已修复** |
| Windows x86_64 原生导出和实机启动 | **未构建、未验收** |

`reports/qa/v150_dev9/batch_summary.json` 保留了引擎无法启动的失败证据。**本轮不提供换壳重新封装的 Windows EXE**：新 GLB 依赖 Godot 原生导入缓存，将资源插进旧 EXE 而不导入不能保证可玩。

## 在 Windows 运行真实引擎测试并导出

安装官方 **Godot 4.5.1** 引擎及同版本的 Windows Export Templates，解压本源码 ZIP。运行 PowerShell：

```powershell
python tools/run_dev9_qa.py --godot 'C:\Tools\Godot_v4.5.1-stable_win64_console.exe' --story
```

测试全部通过之后再运行：

```powershell
.\EXPORT_DEV9_WINDOWS.ps1 -GodotExe 'C:\Tools\Godot_v4.5.1-stable_win64_console.exe' -Story
```

正式发布还需要 Windows 上的实际启动、GPU/帧率、场景截图、物理路径、读档/存档与出口全部人工验证。开发者展厅可使用：

```powershell
& 'C:\Tools\Godot_v4.5.1-stable_win64_console.exe' --path . res://tools/AssetGallery.tscn
```

## 后续必须解决的事项

1. 首先跑 Godot 导入与 414 资产烟雾测试，修复 GDScript 解析、缺失材质和可能的模型方向问题。
2. 24 关至少各截取一张新旧比较截图，确认物件不悬浮、不穿墙、不压住出口；生成每关真实可达的物理 QA 证据。
3. 对 Level 9 进行 `from_L005` 正确抵达、三路牌序列进度、出口条件与触发体进入的完整检验，不能靠设置 `qa_prog` 或直接 fire() 跳过。
4. 对 Level 1、5、9、11 和已完成多层结构的关卡继续深化高度差、非线性路径和实体行为，而不是只增加装饰密度。
5. 完成 Godot 原生 Windows 调试导出、启动与实机性能/碰撞/存档验收后，再考虑稳定版发行。
