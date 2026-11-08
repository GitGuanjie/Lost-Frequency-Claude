#!/usr/bin/env python3
"""Audit all F3 level entry prerequisites without claiming a Godot engine pass.

This checks actual project files, NOT only the 100-entry roster. For native
execution / collision / runtime confirmation, run RUN_100_LEVEL_ENTRY_QA_WINDOWS.ps1.
"""
from __future__ import annotations
import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'reports' / 'qa' / 'dev24_entry_100'
RESOURCE = re.compile(r'\[ext_resource[^\n]*?path="(res://[^"\n]+)"[^\n]*\]')
LITERAL_LOAD = re.compile(r'\b(?:preload|load)\(\s*["\'](res://[^"\']+)["\']\s*\)')


def res_exists(resource: str) -> bool:
    return resource.startswith('res://') and (ROOT / resource.removeprefix('res://')).is_file()


def check() -> tuple[list[dict], list[str]]:
    roster = json.loads((ROOT/'data/canon/levels.json').read_text(encoding='utf-8'))['levels']
    problems = []
    records = []
    if len(roster) != 100 or len({e['stable_id'] for e in roster}) != 100:
        problems.append('Canonical roster must have 100 unique level entries')
    for entry in roster:
        sid = entry['stable_id']
        local = []
        manifest_path = ROOT/'levels'/sid/'level.json'
        if not manifest_path.is_file():
            local.append('missing manifest')
            manifest = {}
        else:
            try:
                manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
            except (OSError, ValueError) as e:
                local.append('invalid manifest: '+str(e))
                manifest = {}
        if manifest.get('stable_id') != sid:
            local.append('manifest stable_id mismatch')
        status = manifest.get('status', 'NOT_STARTED')
        if status not in ('PLAYABLE','IN_DEVELOPMENT','ACCEPTED'):
            local.append('not selectable by F3: status '+str(status))
        sc = manifest.get('scene', '')
        if not res_exists(sc):
            local.append('missing scene '+repr(sc))
        else:
            scene_text = (ROOT/sc.removeprefix('res://')).read_text(encoding='utf-8')
            first = re.search(r'^\[node[^\n]*type="([^"]+)"', scene_text, re.MULTILINE)
            if not first or first.group(1) != 'Node3D':
                local.append('scene root must be Node3D')
            script_paths = [x for x in RESOURCE.findall(scene_text) if x.endswith('.gd')]
            if not script_paths:
                local.append('scene does not attach a GDScript root')
            for resource in RESOURCE.findall(scene_text):
                if not res_exists(resource):
                    local.append('scene ext_resource missing: '+resource)
            for script_path in script_paths:
                if not res_exists(script_path):
                    local.append('missing script: '+script_path)
                    continue
                src = (ROOT/script_path.removeprefix('res://')).read_text(encoding='utf-8')
                if script_path.endswith(f'/levels/{sid}/{sid}.gd') and not re.search(r'^extends\s+LevelBase\s*$',src,re.M):
                    local.append('level root script does not extend LevelBase')
                if script_path.endswith(f'/levels/{sid}/{sid}.gd') and not re.search(r'\badd_arrival\s*\(\s*["\']start["\']',src):
                    local.append('no explicit start arrival in level script')
                for resource in LITERAL_LOAD.findall(src):
                    if not res_exists(resource):
                        local.append('script literal load/preload missing: '+resource)
        records.append({'sid':sid,'manifest_status':status,'scene':sc,
                        'static_entry_prerequisites':'PASS' if not local else 'FAIL',
                        'native_entry_verified':'NOT_TESTED',
                        'problems':'; '.join(local)})
        problems.extend(f'{sid}: {issue}' for issue in local)
    for f in ['tests/LevelEntryProbe.gd','tests/LevelEntryProbe.tscn','RUN_100_LEVEL_ENTRY_QA_WINDOWS.ps1']:
        if not (ROOT/f).is_file(): problems.append('missing test helper: '+f)
    return records, problems


def main() -> int:
    OUTPUT.mkdir(parents=True,exist_ok=True)
    rows, errors = check()
    with (OUTPUT/'static_manifest.csv').open('w', newline='', encoding='utf-8-sig') as out:
        w=csv.DictWriter(out,fieldnames=list(rows[0]))
        w.writeheader();w.writerows(rows)
    obj={'status':'PASS' if not errors else 'FAIL',
         'test':'static file prerequisites for all 100 F3 entries',
         'levels_total':len(rows),'static_pass':sum(x['static_entry_prerequisites']=='PASS' for x in rows),
         'playable_marked':sum(x['manifest_status']=='PLAYABLE' for x in rows),
         'in_development_marked':sum(x['manifest_status']=='IN_DEVELOPMENT' for x in rows),
         'native_entry_pass':None,'native_entry_tested':False,
         'engine_verified':False,
         'problems':errors,
         'native_instructions':'RUN_100_LEVEL_ENTRY_QA_WINDOWS.ps1 -GodotExe <Godot4.5.exe>'}
    (OUTPUT/'static_summary.json').write_text(json.dumps(obj,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print(json.dumps(obj,indent=2,ensure_ascii=False))
    return 1 if errors else 0

if __name__ == '__main__':
    sys.exit(main())
