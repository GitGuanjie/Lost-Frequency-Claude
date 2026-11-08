# Lost Frequency v1.5.0-dev26 — 地标叙事与晶洞回环

这一轮基于 **dev25 完整工程** 增量开发。核心目标：避免只累计空平台，转而用真实资源、状态变化和可探索的立体环路，增强不同关卡的辨识度。

## 可运行的项目结构

解压 ZIP 后，用 Godot 4.5.1 Standard 导入 `3/project.godot`，按 F5 启动，F3 选关，E 调查，J 查日志。

本轮通过 `LevelBase` 的统一生命周期对 **L052、L053、L058、L060、L071、L079、L083、L090、L096、L101、L114、L160、L197** 安装按关卡主题编写的内容。具体有 **43 处可按 E 调查的位置、86 处现有 GLB 摆放**，以及对应位置、带楼层高度限制和冷却时间的 **43 个环境线索**。所有新摆放为无碰撞装饰，避免增加新场景却堵住原来的出入口。

Level 197 额外增加 **4 处真实建模的高层矿物步道、8 条独立上下梯道（每处步道各有两处上下口）**。梯道使用 Godot 物理斜坡碰撞，走廊有实体楼板和护栏；生成晶体时为梯道与横向接近路线留空。与此前单纯画三维节点图不同，这批几何调用 `GeoKit.slab`、`GeoKit.stairs`、`GeoKit.commit` 实际创建实体碰撞。

新增互动现场会改变 OmniLight3D 的真实亮度和发光面板材质，同时写入探索日志。观察完整组线索后，该区域的定位灯会全部亮起，但**不会擅自解锁或改写原站没有的出口**。宁静的 Level 96 和 Level 114 故意不增加多余音效和怪物。

## 关卡设定边界

- **L052、L053、L058**：分别保持石灰岩洞穴、循环住宅、干涸水乐园的原始结构；新物件与事件均为可选调查，不替换出口。
- **L060**：危险上层与相对安全的施工下层保持不变；环境线索仍在下层，参照 Backrooms Wiki 的 The Baywalk 描述。
- **L071**：继续呈现破损的地下室记录，未虚构逃生边。
- **L079**：七个医疗/研究房间各有一处独立观察点，与原有七室布局对应。
- **L083**：潜艇两层与既有应急舱口原样保留。
- **L090、L096、L101、L114**：将住宅/童年空间的细节限制在小型无碰撞物件、微弱声音与探索记录，不套大型空中建筑。
- **L160**：保留不确定叙事，不虚构城市或出口。
- **L197**：四个晶体区域使用不同高程、物件和照明，新增支路属于明确标记的游戏改编。

项目自带的 `sources/wiki_text/`、`docs/canon/` 及许可证文件仍保留。游戏新写的描述标记为 `ADAPTATION`，不冒充 Wiki 原文。

## 验证

在当前开发环境执行了：

- `python -m unittest discover -s tests/static -q`：**231/231 PASS**。
- `python tools/audit_100_entry_static.py`：**100/100 静态入口条件通过**，但 73 个 Level 依然是开发中状态。
- `python tools/world_audit.py`：**100 关 / 235 条出口声明 / 0 项登记问题**。
- `python tools/preflight_dev.py`：词法预检通过。
- 原有 **414 个 GLB** 全部保留，全部新增 GLB 路径经真实资源目录及尺寸索引核验。

**Godot 原生验收未执行成功。** 这个容器没有 Godot 可执行文件，外部下载站点 DNS 不可访问。上面的静态成功不能替代碰撞、实际进入、GLB 导入及真实 E 交互验收。所有新增 Level 都**保持原来的 PLAYABLE/IN_DEVELOPMENT 状态**。

Windows PowerShell 在 `3` 目录：

```powershell
powershell -ExecutionPolicy Bypass -File .\RUN_DEV26_NATIVE_QA_WINDOWS.ps1 -GodotExe 'C:\Godot\Godot_v4.5.1-stable_win64.exe'
```

脚本按独立进程对上述 13 关使用和 F3 相同的 `TransitionService.dev_jump` 进入，检查安全出生、模型是否真实加载、通过 E 触发亮灯、L197 的实体楼板及 8 条上/下坡。结果写入 `reports/qa/dev26_native/summary.csv`。

原有的 **全部 100 关进入测试** 仍在：

```powershell
powershell -ExecutionPolicy Bypass -File .\RUN_100_LEVEL_ENTRY_QA_WINDOWS.ps1 -GodotExe 'C:\Godot\Godot_v4.5.1-stable_win64.exe'
```

## 重要限制

这是一轮**13 关高密度内容/互动和 1 关深度物理空间改造**，不能说 100 关的质量与性能都已完成。仍需用 Godot 逐关渲染、行走与碰撞验收。实际实机结果为 **未验证**，不是 13/13 或 100/100 通过。
