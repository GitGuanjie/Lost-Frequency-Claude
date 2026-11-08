#!/usr/bin/env python3
"""Fail-closed Godot 4.5.1 QA for dev5. A process exit code is never evidence alone.

Use --plan-only without Godot. Full runtime / Windows GPU must be run externally.
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
OUT=ROOT/'reports/qa/v150_dev5'
NEW=('L001_2','L016','L024','L026','L028','L029','L041','L050','L071','L094','L100','L114')


def command(godot,suite,sid=None):
    args=[godot,'--headless','--path',str(ROOT),'--fixed-fps','60','res://tests/QARunner.tscn','--','--qa']
    args+=['--suite=levels',f'--levels={sid}'] if sid else [f'--suite={suite}']
    args.append(f'--out=res://reports/qa/v150_dev5/{suite}.json')
    return args


def run():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--godot',default='godot')
    p.add_argument('--level',action='append',choices=NEW,help='repeat to limit QA to selected new levels')
    p.add_argument('--story',action='store_true')
    p.add_argument('--plan-only',action='store_true')
    args=p.parse_args()
    levels=args.level or list(NEW)
    stages=[('import',[args.godot,'--headless','--path',str(ROOT),'--import'],180)]
    stages += [(suite,command(args.godot,suite),240) for suite in ('registry','lint','save','ui')]
    stages += [(sid,command(args.godot,sid,sid),420) for sid in levels]
    if args.story:
        cmd=command(args.godot,'story')
        cmd.insert(-1,'--story_hops=8')
        stages.append(('story',cmd,900))
    if args.plan_only:
        for name,cmd,timeout in stages:
            print(name,f'timeout={timeout}s',' '.join(cmd))
        return 0
    OUT.mkdir(parents=True,exist_ok=True)
    log={'utc':dt.datetime.now(dt.timezone.utc).isoformat(),'godot':args.godot,
         'evidence_level':'headless engine only; neither GPU nor manual play is proven', 'stages':[]}
    for name,cmd,timeout in stages:
        report=OUT/f'{name}.json' if name!='import' else None
        if report and report.exists():report.unlink()
        start=time.monotonic()
        err=''
        code=None
        try:
            with (OUT/f'{name}.log').open('w',encoding='utf8') as f:
                run=subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=timeout,check=False)
            code=run.returncode
            if code:err=f'Godot returned {code}'
        except (OSError,subprocess.TimeoutExpired) as e:
            err=f'engine unavailable/timeout: {e}'
        suites={}
        failures=[]
        recorded=[]
        if report:
            if not report.is_file():
                err=err or 'Fresh QA JSON missing'
            else:
                try:
                    doc=json.loads(report.read_text(encoding='utf8'))
                    suites=doc.get('suites',{})
                    failures=doc.get('failures',[])
                    expected='levels' if name in NEW else name
                    if expected not in suites:
                        err=err or f'Missing expected suite {expected}'
                    if any(v.get('failed',0) for v in suites.values()) or failures:
                        err=err or f'QA asserts failed; failures={len(failures)}'
                    recorded=[x.get('stable_id') for x in doc.get('levels',[])]
                    if name in NEW and name not in recorded:
                        err=err or f'Expected level {name} absent, observed={recorded}'
                except (OSError,TypeError,ValueError) as e:
                    err=err or f'Invalid QA report: {e}'
        status='PASS' if code==0 and not err else 'FAIL'
        log['stages'].append({'name':name,'status':status,'elapsed_s':round(time.monotonic()-start,2),
                              'reason':err,'exit_code':code,'levels_recorded':recorded,
                              'suite_counts':{k:{'pass':v.get('passed',0),'fail':v.get('failed',0)} for k,v in suites.items()},
                              'failures':failures})
        print(name,status,err,flush=True)
        if status!='PASS':break
    log['status']='PASS' if len(log['stages'])==len(stages) and all(x['status']=='PASS' for x in log['stages']) else 'FAIL'
    (OUT/'batch_summary.json').write_text(json.dumps(log,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print('Summary:',OUT/'batch_summary.json')
    return 0 if log['status']=='PASS' else 1

if __name__=='__main__':sys.exit(run())
