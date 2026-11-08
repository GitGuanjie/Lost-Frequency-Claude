# dev10 下一次开发会话交接

1. **唯一基线**：本源码包 `LostFrequency_v1.5.0-dev10_source.zip`；不要重新从 dev8/dev9 复制覆盖它。
2. **先验证**：`python VERIFY_DEV10_OFFLINE.py`，然后 Windows/Godot 4.5.1 环境跑 `python tools/run_dev10_qa.py --godot ... --story`；检查新 JSON/日志，不能重用旧报告。
3. **若 Godot 编译失败**：逐条修复 .gd 解析报错，保留失败证据，严禁仅改测试。
4. **若 L009 路线失败**：先抓 `l009_route_evidence`，判断 from_L005 入口、起点 NavMesh 投影、三路牌顺序、运行时地形流式加载、最后条件触发器是否为根因；绝不能为了 PASS 传送角色、直接 fire 或预置 qa_prog。
5. **若三层中庭验证失败**：检查 `vertical_atrium_evidence` 的 landing/bridge/slot 项；修复楼板孔与坡道碰撞，之后再做完整真人/机器人走到三楼的自动化测试。
6. **后续大规模升级**：在 Level 4、5、11、37 做 2–3 个真正复杂的立体结构、解谜/环境反馈、实体行为改进；每个改动给出物理出口和可交互动作验证，且依 Backrooms 来源和改编标记。
7. **发布**：全部引擎测试 PASS 后再尝试 `EXPORT_DEV10_WINDOWS.ps1`，Windows 人工玩过/截图/测 FPS 后才宣称稳定版；持续保留全源码、变更补丁、Godot QA 证据和世界图。
