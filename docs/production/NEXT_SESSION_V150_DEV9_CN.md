# dev9 下一轮接手

基于 dev9 源码，不要再次解压 dev8、重复注入 ModelDress 或重新生成 GLB 目录。

1. 先阅读 `docs/production/V150_DEV9_MODEL_INTEGRATION_CN.md` 与 `reports/qa/v150_dev9/batch_summary.json`。
2. 在 Godot 4.5.1 执行 `python tools/run_dev9_qa.py --godot <godot_path> --story`。引擎缺失或报告缺失必须算 FAIL。先修复实际编译/导入错误。
3. 在 24 个已增添 GLB 的关卡逐关验证实际 3D 摆放、碰撞、导航、视觉对比和异步分块卸载；收集截图并保留测试报告。
4. 实机复现 L009→L011，逐个路牌监控 qa_prog；修复根因而不是绕过条件。
5. 经 QA 验收后才执行 `EXPORT_DEV9_WINDOWS.ps1` 导出 Windows debug 构建，并在真实 Windows GPU 上测试。
6. 持续重制老关卡的高差、层间交通、环境交互、实体和世界连通性。不要为了通过数字指标复制空场景。
