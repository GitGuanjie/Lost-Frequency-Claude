# dev8 接手工作单

当前工程根目录 `project.godot` 标记版本 `1.5.0-dev8`。已修改 L001/L001_sys、L007、L009 和 `tests/qa_runner.gd`，新增 `tests/static/test_dev8_rework.py`、`tools/run_dev8_qa.py`、Windows QA/导出脚本。**不要从 dev7 重新解压覆盖 dev8。**

## 最小验证顺序

```powershell
cd E:\LostFrequency
python -m unittest discover -s tests/static -v
python tools/world_audit.py --fail-on-issues
python tools/run_dev8_qa.py --plan-only
.\RUN_DEV8_QA_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64_console.exe" -Story
```

如 QA 失败，不要把报告手改成 PASS。阅读 `reports/qa/v150_dev8/` 最新日志：`l009_route` 必须从 `from_L005` 正确出生，依次到达 `(38,7.6)`, `(30,7.6)`, `(22,7.6)`，再在 `(12,7.6)` 触发 L009→L011。检查 `L009_route_progress`、`progress_samples`、碰撞、NavMesh 多层楼连通、Area3D 条件和玩家实际位置。接着测试普通 10 个路牌的 STORY 机制。

## 后续重点

- 如果 Godot 编译提示 GDScript 类型推断或局部变量错误，以引擎错误为准，改源码后重测，不得声称静态扫描足以替代。
- 如果 Level1 维护夹层有栏杆堵梯、材质缺失或天花板碰头，修复生成几何并加真实机器人/人工回归。
- 将 Level9 车库和 L001 维护区的探索做深：异常档案、动态灯、可观察但不可滥用的实体、立体空间线索。不要破坏 Backrooms 设定的原出口。
- 在真实 Windows 上完成 Native Export + 截图审查 + GPU/CPU profiling、断点存档、F3/F6、Esc、游戏完整剧情路线测试。
- 每批保存短 report、提交 Git；避免 429 后重新阅读全库或将大量旧 QA 当作新验证。
