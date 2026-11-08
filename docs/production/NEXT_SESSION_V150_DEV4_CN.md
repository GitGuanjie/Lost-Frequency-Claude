# Lost Frequency v1.5.0-dev4 — 开发接力

项目版本 v1.5.0-dev4，56 个场景。阅读 `V150_DEV4_REPORT_CN.md`，不要重复抽取旧 ZIP 或重建现有 Git。

Windows 环境：Godot **4.5.1**，从仓库根目录运行：

```powershell
python -m unittest discover -s tests/static -v
python tools/world_audit.py
.\RUN_DEV4_QA_WINDOWS.ps1 -GodotExe 'C:\Godot\Godot_v4.5.1-stable_win64_console.exe'
```

分关验收示例：

```powershell
python tools/run_dev4_qa.py --godot 'C:\Godot\Godot_v4.5.1-stable_win64_console.exe' --level L022 --level L049 --level L053
```

首次必须把 `L001_1 L015 L022 L023 L027 L049 L053 L079 L320` 全部运行；逐条检查脚本导入、物理出生点、出口身位、从剧情外部连接的临时入口、截图与显卡帧率。该版本除 22 项离线测试外没有新增 Godot PASS 证据，不得将旧 QA 报告复制为新结果。

修复关键几何及 L009→L011 剧情后，按原设定继续开发剩余 Level，而不是批量复制静态方盒。维护真实 source citation、程序化生成的可玩性、场景差异性、垂直探索、目标入口和出口可到达性。每批都要留源文件、测试报告和可复现 Windows 构建，并保持稳定的 Git 提交点。
