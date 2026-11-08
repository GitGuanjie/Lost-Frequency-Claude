# 最新开发交接：v1.5.0-dev2

**重要：** 已有 39 关源码，但只有旧版通过 QA 的一部分可被认定可玩；新加 L020 L055 L058 L083 L090 L140 L197 L201 均是 `IN_DEVELOPMENT`，没有 Windows 正式可执行版本。先读 `V150_DEV2_REPORT_CN.md`。

## 恢复原则

1. 恢复现有源码工作目录；不要重复解压成多个 Git 仓库、覆盖用户更改或删除 reports。核对当前 Git 分支及 `.git` 是否存在；当前打包的是源码快照，**不声称自动 push 成功**。
2. 在 Windows Godot 4.5.1 导入项目，优先挑 L020、L083、L090 验证 GDScript 类型和楼梯贯通；其余 5 关逐一跑 `--suite=levels`。开发工具见 `RUN_DEV2_QA_WINDOWS.ps1`。
3. 生成新 QA JSON，与历史 27 关旧 QA 记录严格区分。新报告缺失或发现失败时不能升格 PLAYABLE。
4. 为新关卡补充真实两张 GPU 图片（最大 640x360）和视频人工检查，不能使用搜图/AI 概念图充当游戏截图。
5. 专注解决 24 个来源入口缺失标签，优先已有路径 L020→L002、L083→L007、L201→L001/L003/L004/L025；不要捏造世界通道，物理入口落点必须检查周围碰撞、水体和危险。
6. 重现并修复老 L009→L011 的 QA 路牌/导航问题；之后全剧情回归。
7. 开发持续进行：针对资料允许的复杂空间设计继续制作尚未实现的 Level，给已有但质量差的 27 关做内容和性能提升。不要通过复制空盒或偷换 status 来凑 100 关。
8. 最后才做 Godot Windows x86_64 export，交付实际 `.exe`/PCK 的 ZIP 和源码 ZIP，并写明每关当前完成度。

## 实际文件

- 8 个新关：`levels/{L020,L055,L058,L083,L090,L140,L197,L201}/`。
- 合约检测：`tests/static/test_dev2_world.py`。
- 引擎分批验收：`tools/run_dev2_qa.py` / `RUN_DEV2_QA_WINDOWS.ps1`。
- 可信连通审计：`python tools/world_audit.py`，看 `reports/world_audit/world_report.json`。
- 来源：`docs/canon/levels/<SID>.md` / `sources/wiki_text/<SID>.md` / `data/canon/transitions.json`。

## 优先检查可能引发的引擎问题

- `L140` MultiMesh SphereMesh 与 materials、光照更新兼容性；
- `L083`, `L090` 楼板开孔和楼梯物理在 Jolt 下的实际运行；
- `L055` `_time_left` 到时调用 `TransitionService.request_exit` 对 `@origin` 的映射；
- `L058` 黑屏环境变化是否影响其他场景设置；
- `L201` Trench 条件出口选择、WaterVolume 海岸碰撞；
- `L197` 主廊晶柱阻塞与洼地水位。

停止标准：有崩溃或无法验收就报告具体日志与失败，而不是继续把关卡标为 PLAYABLE。
