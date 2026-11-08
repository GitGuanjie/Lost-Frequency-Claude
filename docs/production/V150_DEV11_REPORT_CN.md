# Lost Frequency 1.5.0-dev11 — 源码开发报告

本次以 dev10 为唯一基线，不新增关卡数：仍然 100 个关卡场景。

## 已实现
- **L004**：在已有地面及上层办公室设三处可调查的维修回路终端；独立记忆旗标，全部调查有反馈；不篡改原出口。
- **L005**：酒店大厅、Beverly Room 和地下 Boiler Room 三段服务记录；位置分散、状态持久化，不改原电梯及危险规则。
- **L011**：固定可发现的城市公园；实际 18 级连续斜坡碰撞楼梯×2、3.6 米高步桥、两侧防跌落栏杆、互动告示及 QA 截图。
- **L037**：按玩家位置及水深触发三种声学异常，没有添加实体、出入口或任何与来源冲突的墙面破坏。
- **L009**：游戏启动时先构建真正来源入口所在地图分块，再实例化附近住宅内部；QA 记录路牌实际到达时间与所属分块。
- **ModelDress**：修复 GLB 调查对象的 Callable 少接收 Player 参数导致点击可能报错的问题；466 条配置按关卡及分块索引，不再每次生成分块都全表扫描。
- **引擎回归入口**：L004、L005、L009、L011、L037 增加可在 Godot 里执行的 qa_self_test（其中城市桥梁使用物理射线验证地板和楼梯）；提供 dev11 独立 QA + Windows 原生导出脚本。

## 不能宣称已完成的部分
- 容器缺少 Godot 4.5.1，未执行任何真实 Godot 脚本编译、导航网格、物理碰撞、资产导入测试。
- 没有 Windows GPU 运行或真实帧率证据。L009→L011 仍然未被实机走通确认。
- L011 桥梁目前有碰撞测试但尚无玩家从一侧实际走到另一侧的完整轨迹验收。
- L004 与 L005 的新记录属于明确的游戏改编环境叙事，不是 Backrooms 原文事件。

## Windows 验证
```
python VERIFY_DEV11_OFFLINE.py
.\RUN_DEV11_QA_WINDOWS.ps1 -GodotExe "C:\Tools\Godot_v4.5.1-stable_win64_console.exe" -Story
.\EXPORT_DEV11_WINDOWS.ps1 -GodotExe "C:\Tools\Godot_v4.5.1-stable_win64_console.exe" -Story
```

第二条命令不成功，则不应交付或分发新版本 EXE。即使 Godot headless QA 通过，Windows 渲染/GPU、手动路线和存档仍需单独验收。
