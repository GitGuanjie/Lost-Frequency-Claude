# Lost Frequency dev12 开发接续

**项目：** Godot 4.5.1；基线 dev12 完整源码包；不应重新初始化工程或误用 dev11/旧 QA 结果。

**新增内容：** L003 电力站三高度、L010 家园谷仓四高度、L011 公园三高度闭环、L025 街机厅双段楼梯与上层闭环。内部路线图见 `docs/production/DEV12_VERTICAL_ROUTES.svg`，配置见 `data/vertical_routes_dev12.json`。现有 100 场景、235 出口未变。

**已真实执行：** `python VERIFY_DEV12_OFFLINE.py` 100/100 静态通过；world audit 0 结构问题。Godot 原生 QA 运行失败，因为当前环境没有引擎，失败证据位于 `reports/qa/v150_dev12/batch_summary.json`。

**Windows 机器执行：**
```powershell
python VERIFY_DEV12_OFFLINE.py
.\RUN_DEV12_QA_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64_console.exe" -Story
# 引擎验收成功之后，才尝试：
.\EXPORT_DEV12_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64_console.exe" -Story
```

**必须继续做的事：** 逐关测真实玩家从地面上行至最高层，再走回；截图检查平台/栏杆/楼板；修复 L009→L011 的历史剧情障碍；性能测量与真实 Windows 原生导出。不可将 100 项 Python 静态检查等同于引擎编译或实际游玩。为每个任务保留可重复的 QA evidence 并在 Git 提交中关联证据；不应修改测试来掩盖失败。
