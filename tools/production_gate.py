#!/usr/bin/env python3
"""Strict evidence gate for candidate scenes. Does not execute Godot or grant acceptance.

Passing static tests is not a substitute for engine QA, physical exit checks,
manual traversal, or Windows launch. A candidate is release-ready only if all
explicit evidence exists and is affirmative.
"""
import argparse,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SIDS=('L017','L018','L030','L069','L073','L000_2','L001_3','L001_5','L003_5','L005_1','L007_7','L010_1','L011_3','L037_1','L096','L965')

def gather():
    result=[]
    for sid in SIDS:
        manifest=json.loads((ROOT/'levels'/sid/'level.json').read_text(encoding='utf8'))
        problems=[]
        if manifest.get('status')!='PLAYABLE': problems.append('not_marked_playable')
        qa=ROOT/'reports/qa/v150_dev6'/f'{sid}.json'
        if not qa.is_file():problems.append('missing_fresh_godot_qa')
        else:
            try:
                evidence=json.loads(qa.read_text(encoding='utf8'))
                if 'levels' not in evidence.get('suites',{}):problems.append('missing_levels_suite')
                if evidence.get('failures') or any(v.get('failed',0)>0 for v in evidence.get('suites',{}).values()):problems.append('engine_assertion_failed')
                if not any(r.get('stable_id')==sid for r in evidence.get('levels',[])):problems.append('level_not_in_engine_results')
            except (ValueError,OSError,TypeError):problems.append('corrupted_engine_result')
        manual=ROOT/'reports/manual'/f'{sid}.json'
        if not manual.is_file():problems.append('missing_manual_windows_evidence')
        else:
            try:
                m=json.loads(manual.read_text(encoding='utf8'))
                for field in ('windows_launch','spawn_clear','screenshots_reviewed','physical_exits_tested','save_load_tested'):
                    if m.get(field) is not True:problems.append('manual_'+field+'_not_confirmed')
            except (ValueError,OSError,TypeError):problems.append('corrupted_manual_report')
        result.append({'level':sid,'ready':not problems,'blockers':problems})
    return result

def main():
    p=argparse.ArgumentParser();p.add_argument('--release',action='store_true');a=p.parse_args()
    results=gather()
    report={'evidence_level':'offline evidence gate only; no engine executed','candidates':len(SIDS),'ready':sum(x['ready'] for x in results),'blocked':sum(not x['ready'] for x in results),'levels':results}
    out=ROOT/'reports/production/dev6_release_readiness.json';out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print(f"Release candidate scenes: {report['ready']}/{len(SIDS)} ready. Detailed blockers: {out}")
    for r in results:
        if not r['ready']:print('BLOCKED',r['level'],','.join(r['blockers']))
    return 1 if a.release and report['blocked'] else 0
if __name__=='__main__':sys.exit(main())
