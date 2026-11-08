# Lost Frequency dev13 → 下次接续开发

## 基线

从 `1.5.0-dev13` 完整源码继续，不要重新从 dev11/dev12 开始。100 个关卡场景、235 个来源声明的出口保持不变，414 个 GLB 模型仍在资源库中。

## 本轮已实现（但没有真实 Godot 验收）

- `L002/L002_geo.gd`：第一处管道大厅 4.2m→5.0m 双坡道检修回环，仅 chunk(2,0)。要注意源场景上层甲板是 4.2m。
- `L004/L004_anchor.gd`：局部顶板开口、高位巡检桥、两端坡道和南向观察支路。
- `L005/L005_boiler.gd`：B1 西墙两处真实开口、分开的两条下降坡道与 -8.1m 地下连通廊。
- `L037/L037.gd`：深水楼梯井的两层水下平台与坡道，需按游泳能力验证。
- `data/vertical_routes_dev13.json` 和 `docs/production/DEV13_VERTICAL_ROUTES.svg`：设计路线，不能当成实机通行证明。

## 验证

`python VERIFY_DEV13_OFFLINE.py` 检查 111 项 Python 静态测试及关卡配置。`python tools/run_dev13_qa.py --godot <godot4.5.1> --level L002 --level L004 --level L005 --level L037 --story` 才真正导入 GLB 并检查碰撞、游戏逻辑和 Level 9 故障。缺少 Godot 时此工具必须返回 FAIL。任何验证失败都不能把关卡标记 PLAYABLE 或发布稳定版。

## 下一步优先级

1. 在 Windows 或可运行 Godot 4.5.1 的环境执行 dev13 QA，并把原生引擎编译错误修好。
2. 对四关截取所有机位画面（特别是两端坡道连接和空间净空），用角色胶囊体而非仅射线逐段走通。
3. 排查 Level 9→11 实际剧情自动化是否失败于动态 chunk 导航、路牌顺序或 ExitTrigger。
4. 扩展非线性多层分岔/竖井，但不要再增加空关卡或用新出口破坏 Backrooms 来源。
5. 基于这次的 `data/vertical_routes_dev13.json` 图数据扩充实际路线测试，生成同款更新设计图。

## Windows

通过 `RUN_DEV13_QA_WINDOWS.ps1` 进行原生 QA；通过 `EXPORT_DEV13_WINDOWS.ps1` 在全部原生 QA PASS 后生成实验 EXE。实际启动/FPS/画面/导航人工验收仍需要独立完成。
