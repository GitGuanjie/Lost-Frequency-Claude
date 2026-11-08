#!/usr/bin/env python3
"""Fail-closed dev8 release evidence gate for all 100 roster slots."""
import argparse,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
roster=json.loads((ROOT/'data/canon/levels.json').read_text())['levels']

def main():
    p=argparse.ArgumentParser();p.add_argument('--release',action='store_true');p.add_argument('--json',action='store_true');a=p.parse_args()
    blockers=[]
    for entry in roster:
        sid=entry['stable_id'];man=json.loads((ROOT/'levels'/sid/'level.json').read_text())
        issues=[]
        if man.get('status')!='PLAYABLE':issues.append('not_playable')
        reports=[ROOT/'reports/qa/v150_dev8'/f'{sid}.json']
        matching=[]
        for path in reports:
            if not path.is_file():continue
            try:
                qa=json.loads(path.read_text())
                if qa.get('failures'):continue
                if any(v.get('failed',0)>0 for v in qa.get('suites',{}).values()):continue
                if any(row.get('stable_id')==sid for row in qa.get('levels',[])):matching.append(str(path.relative_to(ROOT)))
            except (ValueError,TypeError,OSError):continue
        if not matching:issues.append('missing_clean_godot_qa')
        manual=ROOT/'reports/manual'/f'{sid}.json'
        if not manual.is_file():issues.append('missing_manual_windows_evidence')
        else:
            try:
                v=json.loads(manual.read_text())
                if v.get('version')!='1.5.0-dev8':issues.append('manual_evidence_version_mismatch')
                for flag in ('windows_launch','spawn_clear','screenshots_reviewed','physical_exits_tested','save_load_tested'):
                    if v.get(flag) is not True:issues.append(f'manual_{flag}_missing')
            except (ValueError,OSError,TypeError):issues.append('invalid_manual_evidence')
        if issues:blockers.append({'level':sid,'blockers':issues})
    report={'source':'evidence files only — NOT a fresh engine test','roster':len(roster),'blocked':len(blockers),'ready':len(roster)-len(blockers),'blockers':blockers}
    dest=ROOT/'reports/production/dev8_release_readiness.json';dest.parent.mkdir(parents=True,exist_ok=True)
    dest.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(f'Dev8 release gate: {report["ready"]}/100 cleared; {report["blocked"]} blocked. Details: {dest}')
    if a.json:print(json.dumps(report,ensure_ascii=False,indent=2))
    return 1 if a.release and blockers else 0
if __name__=='__main__':sys.exit(main())
