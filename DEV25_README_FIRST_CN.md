# LOST FREQUENCY v1.5.0-dev25 — 使用与验收说明

本版在 dev24 + 100 关独立入口测试工程基础上增加关卡独特的立体探索区，并修正几种交互/道具尺寸风险。

## 变更范围

- L041 黑色沥青湖：木栈桥观察环路、实体护栏、两条缓坡梯道、三处调查与回程捷径；保持沥青危险和原出口。
- L048 永恒夕照海岸：旅馆外观风格的滨海错层回廊与光影观察，不破坏海洋与森林分区。
- L140 Honey：向日葵田野观察棚架，保留本来的自然景观和原初无出口设置。
- L201 Vaporwave：霓虹数字遗迹多层廊道，沿用原终端 / Trench 选择逻辑。
- L149 Coconut Isles：13 片半径、高度不同的自然浮岛和新植物/岩石摆放，保留低重力跳跃和原有 Barrier。
- L100 A Brief Peace：不新增违背原站的建筑；已有四个墓碑调查可进入探索日志。
- L069 不增加公路服务站或城市建筑，保持浓雾公路的原貌。

四组主题拓扑合计 66 个实体楼板设计节点、84 条设计连线、8 段跨层楼梯、4 条可开启的非必经回程桥、118 处引用现有 GLB 的装饰摆放。L149 另有 13 个新岛、57 株棕榈、39 处岩石 GLB。全部项目仍有 100 关登记及 414 个 GLB 资源文件。以上均为源码/蓝图统计，不是 Godot 实机通过数据。

## 打开项目

使用 Windows Godot 4.5.1 Standard 导入 `3/project.godot`，首次等待资产导入，再按 F5，F3 选关。按 E 调查，按 J 查看探索日志。

## 严格验收

Windows PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File .\RUN_DEV25_PHYSICAL_QA_WINDOWS.ps1 -GodotExe 'C:\Godot\Godot_v4.5.1-stable_win64.exe'
```

运行时逐一从 F3 的同一加载接口加载 L041、L048、L100、L140、L149、L201，检查安全出生、实体楼板射线命中、调查灯和实体捷径开关、13 个浮岛碰撞。日志写入 `reports/qa/dev25_physical/`。本工具需由用户电脑上的 Godot 执行，本开发环境缺少 Godot，不可把测试脚本存在误认为测试已经通过。

全 100 关的 F3 进入验收：

```powershell
powershell -ExecutionPolicy Bypass -File .\RUN_100_LEVEL_ENTRY_QA_WINDOWS.ps1 -GodotExe 'C:\Godot\Godot_v4.5.1-stable_win64.exe'
```

查看 `reports/qa/dev24_entry_100/summary.csv`。**100 关仅静态文件检查通过，不是 100/100 已实机成功进入。**

## 实际测试范围

- 本机 Python `unittest` 离线套件：225/225 PASS（含 6 项新增 dev25 审计）。
- 100 场景入口文件和资源清单：静态检查，不提供运行时保证。
- Godot 原生：本环境无可执行文件，且下载站 DNS 解析失败，未验收。
- Wiki 内容：对照本工程 `sources/wiki_text`，新增内容是明确标注的 **改编**，不替换规范出口。

详细验收见另附 `LostFrequency_DEV25_开发报告.md`。
