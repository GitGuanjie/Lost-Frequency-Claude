#!/usr/bin/env python3
"""Fail-closed DEV23 real Godot headless import+E/collision/model tests.

Exit 1 and write FAIL if the executable is absent. Never recycle old results.
This is not Windows GPU performance, 100-level story, or hands-on QA.
"""
from __future__ import annotations
import argparse, datetime as dt, json, subprocess, sys, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'reports/qa/v150_dev23'
IDS={row['id'] for row in json.loads((ROOT/'data/dev23_landmark_spurs.json').read_text())['sites']}
def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--godot',default='godot')
    ap.add_argument('--plan-only',action='store_true')
    ap.add_argument('--core-only',action='store_true')
    args=ap.parse_args()
    steps=[('import',[args.godot,'--headless','--editor','--path',str(ROOT),'--import'],300)]
    suites=['landmark_dev23'] if args.core_only else ['registry','lint','landmark_dev23','district_dev22','scenario_dev21','vertical_dev20']
    steps.extend((s,[args.godot,'--headless','--path',str(ROOT),'--fixed-fps','60',
        'res://tests/QARunner.tscn','--','--qa',f'--suite={s}',f'--out=res://reports/qa/v150_dev23/{s}.json'],1800) for s in suites)
    if args.plan_only:
        for s,c,_t in steps:print(s,' '.join(c))
        return 0
    OUT.mkdir(parents=True,exist_ok=True)
    result={'version':'1.5.0-dev23','time_utc':dt.datetime.now(dt.timezone.utc).isoformat(),
            'status':'FAIL','engine_certified':False,'release_ready':False,'steps':[]}
    for name,cmd,timeout in steps:
        evidence=OUT/(name+'.json')
        if evidence.exists():evidence.unlink()
        started=time.monotonic();error='';code=None
        try:
            with (OUT/(name+'.log')).open('w') as log:
                p=subprocess.run(cmd,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=timeout)
            code=p.returncode
            if code:error=f'Godot returned {code}'
        except (FileNotFoundError,OSError,subprocess.TimeoutExpired) as exc:error=f'Engine unavailable or timed out: {exc}'
        if name!='import' and not error:
            if not evidence.exists():error='Missing newly produced evidence JSON'
            else:
                try:
                    j=json.loads(evidence.read_text())
                    if j.get('failures') or j.get('suites',{}).get(name,{}).get('failed',0):error='Native suite failure'
                    if name not in j.get('suites',{}):error='Required suite missing'
                    if name=='landmark_dev23':
                        ev=j.get('landmark_dev23_evidence',{}).get('levels',{})
                        if set(ev)!=IDS:error='Some themed sites were not engine-tested'
                        elif any(not row.get('all_ok') or row.get('checks',0)<10 or row.get('samples',0)<5 for row in ev.values()):
                            error='Landmark physics and interaction evidence incomplete'
                except (OSError,ValueError,TypeError) as exc:error=f'Malformed native report: {exc}'
        result['steps'].append({'stage':name,'status':'FAIL' if error else 'PASS','error':error,
                                'exit_code':code,'elapsed_s':round(time.monotonic()-started,2)})
        print(name, 'FAIL: '+error if error else 'PASS',flush=True)
        if error:break
    result['engine_certified']=len(result['steps'])==len(steps) and all(x['status']=='PASS' for x in result['steps'])
    result['status']='PASS' if result['engine_certified'] else 'FAIL'
    (OUT/'summary.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    return 0 if result['engine_certified'] else 1
if __name__=='__main__':sys.exit(main())
