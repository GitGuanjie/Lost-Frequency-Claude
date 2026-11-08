# v1.5.0-dev1 最新接手说明（优先阅读）

本仓库为已有游戏的增量开发快照，**禁止重复解压/覆盖/重建基线仓库**。最新变更及真实状态见 `docs/production/V150_DEV1_REPORT_CN.md`。

## 新增源码
`ui/WorldGraph.gd`（F6 图），修改 `ui/Overlay.gd`、`autoload/Settings.gd`、`autoload/SaveService.gd`、`autoload/TransitionService.gd`、`tests/qa_runner.gd`；候选关卡 `levels/L036`, `levels/L060`, `levels/L075`, `levels/L999`；离线审计与 QA 分批工具在 `tools/`。

## 验收现状
离线 GDScript 词法粗检 0 错，六项静态完整性测试通过；Godot import/GPU/物理导航/Windows export 均**未在此环境执行**。4 个新关卡必须保持 `IN_DEVELOPMENT`，不要仅凭静态结果升级。100 关名册、31 场景文件、127 出口声明、配置可达 19、旧 QA 快照可达 16、入口标签缺失 15。后两个“可达”不是经玩家验证的结果。

## 下一步
1. Godot 4.5.1 运行 `python tools/run_dev1_qa.py --godot <exe> --story`，产生新结果；逐关定位 import/类型错误、碰撞、场景出生点和条件出口。先特别检查 Level60 挡墙阶梯缺口及 Level36 机场出口。
2. 真实修复 L009→L011；已有测试在首次路牌失败时直接报错。
3. 处理清单缺失 arrival ID，尤其 L060→L007 安全海域落点。不要捏造不存在的出口。
4. 用 Windows GPU 截图与人工实际游玩验收后再变更 `status`。
5. 稳定后继续制作 L036_1 等有来源的子关卡及下一批 100 关，重制老关场景内容。

日志保存在 `reports/qa/v150_dev1`。**不要**在没有实际引擎验证的情况下生成虚假的 PASS 或宣称存在 Windows 可玩发布包。
