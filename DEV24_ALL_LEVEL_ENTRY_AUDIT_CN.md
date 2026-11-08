# dev24：100 关 F3 入口专项核查

## 当前已执行的检查（不是 Godot 引擎测试）

- Canonical roster：100 个唯一稳定 ID。
- 实际 `levels/<SID>/level.json`：100/100 存在且可解析。
- Scene `.tscn`：100/100 存在，根节点是 Node3D。
- 场景挂载的 GDScript：100/100 存在；根脚本继承 `LevelBase`。
- 对应脚本中的显式 `add_arrival("start",...)`：100/100。
- 场景 `ext_resource` 与 level 脚本中静态 `load/preload` 引用：本次范围内无丢失文件。
- 230 个 `.gd` 文件基本词法检查（括号/字符串）：0 项异常；这**不是** GDScript 编译。
- 原有 219 项 Python 静态回归：219/219 通过。
- Manifest 状态：27 个 `PLAYABLE`，73 个 `IN_DEVELOPMENT`。F3 的 `is_spawnable` 条件允许全部 100 个关卡进入尝试，但并不能证明引擎真的可以加载它们。

结论：**100/100 静态入口条件通过，但 Godot 真实逐关加载数为未测，绝不可写为 100/100 实机通过。**

## 如何真正测试 F3 的 100 关入口

1. 下载 Godot **4.5.x Standard（Windows x64）**，先备份原工程。
2. 将 `RUN_100_LEVEL_ENTRY_QA_WINDOWS.ps1` 与 `tests/LevelEntryProbe.*` 放到现有 `3` 工程目录（或使用附带的补丁）。
3. 打开 PowerShell：

```powershell
cd "D:\LostFrequency\3"
powershell -ExecutionPolicy Bypass -File .\RUN_100_LEVEL_ENTRY_QA_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64.exe"
```

脚本会先执行资源导入，然后依次使用 100 个**独立 Godot 进程**进行 F3 同路径的关卡跳转。每关检测：真实 `dev_jump` 载入、`LevelBase.built`、Player 生成、出生点 `spawn_ok`、15 帧物理稳定性。每关最长 120 秒；超时/崩溃记 FAIL，继续下一关。完整运行时间取决于机器和场景大小。

结果保存在：

- `reports/qa/dev24_entry_100/summary.csv`：100 行 PASS/FAIL 与失败原因
- `reports/qa/dev24_entry_100/summary.json`：汇总
- `reports/qa/dev24_entry_100/levels/LXXX.json`：引擎输出的逐关结果（失败过早可能没有该文件）
- `reports/qa/dev24_entry_100/logs/LXXX.stdout.log` 与 `.stderr.log`：Godot 原生日志

想先抽查少数易出问题的关卡：

```powershell
powershell -ExecutionPolicy Bypass -File .\RUN_100_LEVEL_ENTRY_QA_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64.exe" -Only "L000,L008,L037,L320,L808"
```

此脚本独立验证“点一个关卡能进入且出生正常”，**不**等于验证整个地图可通关、全部互动、导航和性能；那些仍需另跑项目完整 QA。

## 不要混淆的三个状态

- **文件存在**：场景和脚本路径正确（100/100）。
- **F3 可点**：登记状态和资源存在，F3 允许尝试打开（静态条件 100/100）。
- **真实可玩**：引擎能载入、出生正常、能够移动并达到相关出口（目前未能完成全部 100 关引擎验收）。

若出现失败，直接把 `summary.csv` 和失败关卡的 `.log` 文件提供给开发者，就可以针对具体 Level 修复；不必猜是哪一关。
