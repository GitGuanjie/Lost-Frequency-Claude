# Lost Frequency v1.5.0-dev11 — 续接开发交接

本次以 `v1.5.0-dev10` 为唯一源码基线。使用 `LostFrequency_v1.5.0-dev11_source.zip` 作为下一轮起点，不要重新引入 dev10 文件或未经验证的 Windows 实验 EXE。

## 已完成的源码改动
- `L004`：三处可用的维修记录互动点；按关卡保存调查标志，3/3 完成有反馈，原出口未修改。
- `L005`：酒店大堂／舞厅／锅炉层三处可调查叙事记录，保存调查状态。
- `L011`：固定公园 (2,0)，两侧各 18 级楼梯、带碰撞的 3.6m 高架步道与护栏，调查告示；关卡 QA 增加真实物理射线检查。
- `L037`：3 种符合原设定的深水声学事件，没有 NPC 或新出口。
- `L009`：从实际来源入场点预生成地图分块；QA 路牌轨迹含时间及分块坐标。
- `ModelDress`：模型调查 Callback 参数修复，静态与分块模型摆放按索引分组。

## 已知限制（不要虚构通过）
- `python VERIFY_DEV11_OFFLINE.py`：90 项 Python 测试通过；世界审计仍是 100 场景、235 声明出口、配置可达 43 关，入口审计 0 错误。
- 本环境执行 `python tools/run_dev11_qa.py --godot godot --level L009 --story`：在 import 阶段失败，找不到 `godot`；证据见 `reports/qa/v150_dev11/batch_summary.json`。
- 因此 Godot 脚本解析、GLB 资源导入、L009→L011 真实过关、L011 桥梁物理行走、Windows GPU 帧率全部仍待验证。dev11 没有 Windows EXE。

## 下一轮最优先任务
1. 在具备 **Godot 4.5.1** 和 Windows 导出模板的环境运行：`python tools/run_dev11_qa.py --godot <path-to-godot> --level L009 --story`。必须保存每个路牌 waypoint 的位置、`qa_prog` 与碰撞诊断。若失败修复真实路径，不可传送或强设进度。
2. 运行 `--level L004 --level L005 --level L011 --level L037`；检验新互动节点实际可见可触达，城市高架步道两侧都能从地面走到顶、不会卡碰撞。测试脚本也有 `qa_self_test()`，但单纯 raycast 通过不等于玩家已实走成功。
3. 对 GLB 装饰层做 FPS、内存、重复卸载/重载和实际玩家互动检查。注意 `ModelDress` 只有在原生引擎中才可证实 callback 修复已生效。
4. 完成高质量材质、可玩范围与来源设定的手工视觉审查。根据真实截图和性能数据重制 Level 4/5/11/37，绝不只追加无人能到达的物体。
5. QA 全部通过后才允许生成原生 Windows debug EXE；正式版还需人工 FPS、崩溃、存档与路线验收。

## Windows 命令
```
python VERIFY_DEV11_OFFLINE.py
.\RUN_DEV11_QA_WINDOWS.ps1 -GodotExe "C:\Tools\Godot_v4.5.1-stable_win64_console.exe" -Story
.\EXPORT_DEV11_WINDOWS.ps1 -GodotExe "C:\Tools\Godot_v4.5.1-stable_win64_console.exe" -Story
```

不要推送到 `claude-EO` 等无关仓库。需要远程同步时先核实目标是游戏项目仓库。
