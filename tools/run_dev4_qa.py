#!/usr/bin/env python3
"""Godot 4.5.1 stage runner: fails closed if fresh QA JSON is absent.

Needs a local Godot executable. Never changes status to PLAYABLE, and the
headless suite alone is insufficient for human/GPU acceptance.
"""
from __future__ import annotations
import argparse
import datetime as dt
import json
import subprocess
import sys
import time
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'reports/qa/v150_dev4'
NEW=('L001_1','L015','L022','L023','L027','L049','L053','L079','L320')
PREVIOUS=('L031','L048','L000_3','L006_1','L021','L808','L922','L149','L020','L055','L058','L083','L090','L140','L197','L201')


def command(godot, name, sid=None):
    args=[godot,'--headless','--path',str(ROOT),'--fixed-fps','60','res://tests/QARunner.tscn','--','--qa']
    if sid:
        args+=['--suite=levels',f'--levels={sid}']
    else:
        args+=[f'--suite={name}']
    args+=[f'--out=res://reports/qa/v150_dev4/{name}.json']
    return args


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--godot',default='godot')
    p.add_argument('--level',choices=NEW+PREVIOUS,action='append',help='test only selected levels (repeatable)')
    p.add_argument('--story',action='store_true')
    p.add_argument('--plan-only',action='store_true')
    a=p.parse_args()
    levels=tuple(a.level or NEW)
    stages=[('import',[a.godot,'--headless','--path',str(ROOT),'--import'],180)]
    stages += [(name,command(a.godot,name),240) for name in ('registry','lint','save','ui')]
    stages += [(sid,command(a.godot,sid,sid),420) for sid in levels]
    if a.story:
        args=command(a.godot,'story')
        args.insert(-1,'--story_hops=8')
        stages.append(('story',args,900))
    if a.plan_only:
        for name,args,timeout in stages:
            print(f'{name:10} timeout={timeout}s ::', ' '.join(args))
        return 0
    OUT.mkdir(parents=True,exist_ok=True)
    log={'created_utc':dt.datetime.now(dt.timezone.utc).isoformat(),
         'godot':a.godot,'source_status':'UNVERIFIED until this runner and human review',
         'stages':[]}
    for name,args,timeout in stages:
        target=OUT/f'{name}.json' if name!='import' else None
        if target and target.exists():
            target.unlink()  # never accept a stale successful file
        began=time.monotonic()
        err=''
        code=None
        try:
            with (OUT/f'{name}.log').open('w',encoding='utf8') as lf:
                run=subprocess.run(args,cwd=ROOT,stdout=lf,stderr=subprocess.STDOUT,
                                   timeout=timeout,check=False)
            code=run.returncode
            if code: err=f'Godot exited {code}'
        except subprocess.TimeoutExpired:
            err=f'Timeout after {timeout}s'
        except (OSError,FileNotFoundError) as e:
            err=f'Godot unavailable: {e}'
        checks={}
        failures=[]
        if target:
            if not target.is_file():
                err=err or 'Missing fresh QA JSON despite process exit'
            else:
                try:
                    doc=json.loads(target.read_text(encoding='utf8'))
                    suites=doc.get('suites',{})
                    expected='levels' if name in NEW+PREVIOUS else name
                    if expected not in suites:
                        err=err or f'Expected suite {expected} missing'
                    for key,value in suites.items():
                        checks[key]={'passed':value.get('passed',0),'failed':value.get('failed',0)}
                    failures=doc.get('failures',[])
                    if failures or any(x['failed'] for x in checks.values()):
                        err=err or f'Reported test failures: {len(failures)}'
                    if name in NEW+PREVIOUS and not doc.get('levels'):
                        err=err or 'No per-level result in fresh QA JSON'
                except (ValueError,TypeError,KeyError,OSError) as e:
                    err=err or f'Invalid QA report: {e}'
        ok=code==0 and not err
        rec={'stage':name,'status':'PASS' if ok else 'FAIL',
             'seconds':round(time.monotonic()-began,2), 'reason':err,'exit_code':code,
             'checks':checks,'failures':failures}
        log['stages'].append(rec)
        print(f'{name}: {rec["status"]} {err}',flush=True)
        if not ok: break
    log['status']='PASS' if len(log['stages'])==len(stages) and all(x['status']=='PASS' for x in log['stages']) else 'FAIL'
    (OUT/'batch_summary.json').write_text(json.dumps(log,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print('Wrote',OUT/'batch_summary.json')
    return 0 if log['status']=='PASS' else 1

if __name__=='__main__':
    sys.exit(main())
