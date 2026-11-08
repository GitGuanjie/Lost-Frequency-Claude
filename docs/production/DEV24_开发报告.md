# Lost Frequency v1.5.0-dev24 开发交付报告

2026-11-08 · 开发源码版本 · **尚未通过 Godot 原生 QA**

## 改造目标与真实交付范围

本轮基于用户提供的 **dev23 完整工程**修改，而不是单独输出设计提示词。新增 `ExpeditionBiomes.gd`、`ExpeditionState.gd` 及对应确定性生成数据，并将新模块接入 dev23 已有的 `LandmarkSpurs.install`。十组改造关卡：L028、L032、L050、L073、L077、L085、L094、L108、L320、L808。

### 实际新增计数（从最终 JSON 计算）

- 10 组主题探险区，每组 6 个底层平台 + 4 个上层平台 = **100 个平台蓝图**；
- **107 条图连接**，其中 87 条普通水平路线、10 段跨层实体楼梯和 10 处可解锁的非关键物理桥；
- 两个高度层，源数据中底层/上层总计 17 条独立水平回环自由度（按两个分离子图计算）；
- 每区 3 个观测标记、2 处灯光开关、1 个可控实体跨桥和 1 个空间观察点，即每区至少 7 处新增交互位置；
- 300 条 GLB 摆放定义，使用**现有 85 种**模型；这些仍是原资源库的实例，并非 300 个新模型；
- 30 条位置相关环境声音／氛围记录，每区 3 条；
- 原始 100 关登记、235 条出口声明、414 个 GLB 资产完整保留，没有增加自创出口。

与前几轮规则的四层大楼不同，程序化生成先以关卡风格挑选十种不一样的空间拓扑；楼板、通道、门洞、楼梯边界、GLB 选取及环境反馈从同一份数据生成。地形骨架既有环形庭院、枝状栈道、线性道路、折返山路，也有高层小环路；局部造型采用城堡柱拱、森林枝干、路牌龙门、雾中护栏、异常住宅框架、霓虹结构等不同语法。

## 可互动内容

- 3 个调查点共同解锁一段可选的实体连桥。未解锁时桥面不可见、不可碰撞，同时两端有可碰撞的防坠落护栏；解锁时桥面与碰撞一起出现，护栏撤销。主路不用解锁亦保持连通。
- 2 个局部照明开关改变实际 OmniLight3D 亮度，不依赖纯文字反馈。
- 位置相关的声音、调查和记录被加入现有 Overlay / Soundscape / SaveService 接口；玩家可通过 E 互动，通过 J 查看日志。
- 对角色站在可动桥上的回收操作有防护逻辑。

## 改造的工程文件

- `core/world/ExpeditionBiomes.gd`：生成楼板、护栏、水平桥、21 米台阶与斜坡碰撞，并从现有 GLB 库放置物件；
- `core/world/ExpeditionState.gd`：真实碰撞体、动态护栏、开关与日志状态；
- `core/world/LandmarkSpurs.gd`：给 dev23 东侧上层平台打开真实通行缺口，并接入新增探险区；
- `data/dev24_expeditions.json` / `tools/generate_dev24_expeditions.py`：可以重建的确定性蓝图；
- `tests/static/test_dev24_expedition_biomes.py`：图连通、冗余边、资源存在性、占地面积与生成一致性；
- `tests/qa_runner.gd`：`expedition_dev24` 原生 QA；
- `tools/run_dev24_qa.py`：无 Godot 时明确 FAIL 的引擎测试驱动器；
- `RUN_DEV24_QA_WINDOWS.ps1` / `EXPORT_DEV24_WINDOWS.ps1`：Windows 验收和受验收约束的调试导出；
- `docs/production/DEV24_ExpeditionMorphologies.png`：源数据路线设计示意图（**不是实机截图**）。

## 本轮发现与修正的几何缺陷

首次生成的高层楼梯末端会侵入上层完整楼板的下方。已经把上下层主中心的相对水平距离改为 **29 米**，让 21 米长的梯道从底层中心东侧 3 米处起步、恰好抵达上层平台西侧边缘（距上层中心 5 米）。这避免了新结构中明显的楼板覆盖式断头楼梯。但本轮未逐一修正早期所有关卡的旧楼梯，它们仍需真机碰撞检查。

## Wiki 参考与适配边界

关卡身份继续使用原有的英语 Wikidot Backrooms 版本及本地归档资料。为避免全部主题混同，特别核对了：

- L028：<https://backrooms-wiki.wikidot.com/level-28>，蓝光城堡、现代物品与地下锻造区；
- L032：<https://backrooms-wiki.wikidot.com/level-32>，常暗骸骨森林及相关危险设定；
- L808：<https://backrooms-wiki.wikidot.com/level-808>，霓虹网格、电子景观与异常日落；
- L320：<https://backrooms-wiki.wikidot.com/level-320>，承袭娱乐园区概念的文献档案主题。

上述建筑支路、机械观察点、物件组合等均为**本游戏新设计的改编内容**，不能说 Wiki 原文明确出现了这些设施。当前交付的数值不证明全 100 关都达到 Wiki 所描绘的场景密度。

## 验证记录

- `python -m unittest discover -s tests/static -p 'test_*.py'`：**219/219 PASS**。
- `python tools/preflight_dev.py`：9 个重点 GDScript 文件词法/括号扫描无问题；这不是 GDScript 编译。
- 原生命令 `python tools/run_dev24_qa.py --godot godot --core-only`：**FAIL**，Godot 可执行文件不存在，日志已写入 `reports/qa/v150_dev24/summary.json`。此项不是代码已经在引擎里运行失败的证据，而是引擎未能启动。
- 本环境 DNS 无法解析 Godot 官方下载域名，因此没有完成本机 Godot 安装；**不能声称 Godot 场景成功加载、角色跨层走通、模型真实渲染、碰撞性能达到要求，也没有 Windows EXE**。
- Windows 上推荐提供 Godot 4.5.1 Standard 可执行文件给 `RUN_DEV24_QA_WINDOWS.ps1`，完成 headless import、100 平台物理射线、模型实例、真实 E 回调、可选桥碰撞及旧版回归。之后还需人工检查 10 关的行走、灯光、材质和 FPS。

## 如何安装和体验

1. 将 dev24 完整包解压；在 Godot 4.5.1 中导入 `3/project.godot`；
2. 资源导入结束后按 F5，打开 F3 关卡浏览器；
3. 前往 L028、L032、L050、L073、L077、L085、L094、L108、L320、L808；
4. 沿之前的 dev22 / dev23 主题高架通道前往东侧新分支；用 E 操作新机关、J 看记录。

**结论：** 本轮交付了新的、可重复生成的差异化场景与可互动的 Godot 源码，静态图和资源一致性已经验证；原生游戏引擎与实机体验仍待验收。不得把设计图节点数冒充已完成的可玩关卡数。
