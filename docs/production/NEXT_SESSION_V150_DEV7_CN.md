# Next-session handoff — v1.5.0-dev7

**Do not re-create the 100 scene files**; continue from the dev7 source package. The 100 slots are files, NOT 100 validated levels. First confirm version `1.5.0-dev7`, `python -m unittest discover -s tests/static -v`, `python tools/world_audit.py --fail-on-issues` and repository state.

1. Get official Godot 4.5.1 Linux/Windows engine, import source and **save actual error logs**. Use `python tools/run_dev7_qa.py --godot <path>` (or Windows `RUN_DEV7_QA_WINDOWS.ps1`) for the 16 dev7 levels. No Godot binary was available in the previous development environment.
2. Fix true parse/runtime/geometry issues first. Prioritize L005_3 ramp and upper gallery, L007_8 pier accessibility, L011_2 apartment threshold, L899 exposed lake, L101 conditional exit, L737→L998 arrival. Maintain canon edge IDs. Never mark candidate `PLAYABLE` merely due to static tests.
3. Reproduce and fix historical L009→L011 physical story route. Ensure bot reaches each sign and trigger; don't bypass conditions or fake `qa_prog`.
4. Test Windows EXE physically with GPU screenshots, save/load and repeated scene transitions. Existing dev7 experimental EXE only contains structurally validated resources; no boot assertion.
5. Replace provisional arrival aliases with actual authored door/route geometry. Add source-specific exploration and 3D verticality to weaker levels rather than creating more empty files.
6. Preserve `docs/canon`, attribution and license. Record all acceptance evidence (build logs, screenshots, QA, performance, human checks) and use `tools/production_gate_dev7.py --release` to block improper stable exports.

Native export (Windows PowerShell): `./EXPORT_DEV7_WINDOWS.ps1 -GodotExe 'C:\Path\Godot_v4.5.1-stable_win64_console.exe'`. Add `-Release` only once *all* 100 scenes have real evidence.
