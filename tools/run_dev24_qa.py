#!/usr/bin/env python3
"""Fail-closed DEV24 native QA, requires a real Godot 4.5.x executable.
If unavailable, report FAIL with exit code 1. Static success is separate.
"""
import argparse, datetime as dt, json, subprocess, sys, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'reports/qa/v150_dev24'
IDS={r['id'] for r in json.loads((ROOT/'data/dev24_expeditions.json').read_text())['sites']}

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--godot',default='godot')
    ap.add_argument('--plan-only',action='store_true')
    ap.add_argument('--core-only',action='store_true')
    args=ap.parse_args()
    suites=['expedition_dev24'] if args.core_only else ['registry','lint','expedition_dev24','landmark_dev23','district_dev22','scenario_dev21','vertical_dev20']
    jobs=[('import',[args.godot,'--headless','--editor','--path',str(ROOT),'--import'],300)]
    jobs.extend((s,[args.godot,'--headless','--path',str(ROOT),'--fixed-fps','60',
        'res://tests/QARunner.tscn','--','--qa',f'--suite={s}',f'--out=res://reports/qa/v150_dev24/{s}.json'],1800) for s in suites)
    if args.plan_only:
        for name,cmd,_ in jobs:print(name,' '.join(cmd))
        return 0
    OUT.mkdir(parents=True,exist_ok=True)
    log={'version':'1.5.0-dev24','started_utc':dt.datetime.now(dt.timezone.utc).isoformat(),
         'status':'FAIL','engine_certified':False,'release_ready':False,'stages':[]}
    for name,cmd,timeout in jobs:
        evidence=OUT/(name+'.json')
        if evidence.exists():evidence.unlink()
        start=time.monotonic();error=None;code=None
        try:
            with (OUT/(name+'.log')).open('w') as dest:
                result=subprocess.run(cmd,stdout=dest,stderr=subprocess.STDOUT,cwd=ROOT,timeout=timeout)
            code=result.returncode
            if code:error=f'Godot return code {code}'
        except (FileNotFoundError,OSError,subprocess.TimeoutExpired) as exc:
            error=f'Godot unavailable or timed out: {exc}'
        if name!='import' and not error:
            if not evidence.exists():error='No newly generated JSON evidence'
            else:
                try:
                    data=json.loads(evidence.read_text())
                    if data.get('failures') or data.get('suites',{}).get(name,{}).get('failed',0):error='Native suite has failures'
                    if name not in data.get('suites',{}):error='Expected native suite absent'
                    if name=='expedition_dev24':
                        rec=data.get('expedition_dev24_evidence',{}).get('levels',{})
                        if set(rec)!=IDS:error='Missing levels in native evidence'
                        elif any(not x.get('all_ok') or x.get('checks',0)<15 or x.get('samples',0)<12 for x in rec.values()):
                            error='Missing physical collision / interaction evidence'
                except (OSError,ValueError,TypeError) as exc:error=f'Bad evidence: {exc}'
        log['stages'].append({'name':name,'status':'PASS' if not error else 'FAIL',
            'error':error,'returncode':code,'duration_s':round(time.monotonic()-start,2)})
        print(name,'PASS' if not error else 'FAIL: '+error,flush=True)
        if error:break
    log['engine_certified']=len(log['stages'])==len(jobs) and all(x['status']=='PASS' for x in log['stages'])
    log['status']='PASS' if log['engine_certified'] else 'FAIL'
    (OUT/'summary.json').write_text(json.dumps(log,indent=2,ensure_ascii=False)+'\n')
    return 0 if log['engine_certified'] else 1
if __name__=='__main__':sys.exit(main())
