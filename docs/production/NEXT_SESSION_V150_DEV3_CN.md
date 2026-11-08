# 交接 v1.5.0-dev3

不要重复解压或重新建立 Git。先读 `V150_DEV3_REPORT_CN.md`。当前文件数和出口数以 `python tools/world_audit.py` 结果为准。

运行：
````powershell
python -m unittest discover -s tests/static -v
python tools/world_audit.py
.\RUN_DEV3_QA_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64_console.exe"
````

提醒：离线 Python 测试并不是 Godot GDScript 编译。下一轮先验证新增 8 关以及历史的 Level9 路径，然后才做 GPU、Windows 正式导出。未验证的都保持 IN_DEVELOPMENT。
