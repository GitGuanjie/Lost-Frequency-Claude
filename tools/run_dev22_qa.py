#!/usr/bin/env python3
"""Fail-closed Godot 4.5.1 DEV22 import, native physics and interaction QA.

This script intentionally fails if the engine is missing or output is stale.
It cannot substitute for actual player-controlled movement and Windows GPU review.
"""
from __future__ import annotations
import argparse, datetime as dt, json, subprocess, time, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'reports/qa/v150_dev22'
D=json.loads((ROOT/'data/dev22_narrative_districts.json').read_text())
IDS={w['id'] for w in D['districts']}


def command(godot, suite, output):
 return [godot,'--headless','--path',str(ROOT),'--fixed-fps','60','res://tests/QARunner.tscn','--','--qa',f'--suite={suite}',f'--out=res://reports/qa/v150_dev22/{output}.json']


def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--godot',default='godot',help='Godot 4.5.1 executable')
 ap.add_argument('--plan-only',action='store_true')
 ap.add_argument('--core-only',action='store_true',help='Diagnose just DEV22, not a release gate')
 args=ap.parse_args()
 stages=[('import',[args.godot,'--headless','--editor','--path',str(ROOT),'--import'],300)]
 suites=['district_dev22'] if args.core_only else ['registry','lint','district_dev22','vertical_dev20','scenario_dev21']
 stages.extend((s,command(args.godot,s,s),3000 if s=='district_dev22' else 2400) for s in suites)
 if args.plan_only:
  for name,cmd,timeout in stages:print(f'{name} timeout={timeout}s: {" ".join(cmd)}')
  return 0
 OUT.mkdir(parents=True,exist_ok=True)
 summary={'version':'1.5.0-dev22','timestamp_utc':dt.datetime.now(dt.timezone.utc).isoformat(),
  'status':'FAIL','engine_certified':False,'release_ready':False,
  'scope':'Native Godot import+ray/GLB/E/hatch tests; NOT human traversal, FPS, full 100-level playtest',
  'stages':[]}
 for name,cmd,timeout in stages:
  evidence=OUT/(name+'.json')
  if evidence.exists():evidence.unlink() # never accept old reports
  error=''; returncode=None; started=time.monotonic()
  try:
   with (OUT/(name+'.log')).open('w') as log:
    p=subprocess.run(cmd,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=timeout,check=False)
   returncode=p.returncode
   if returncode!=0:error=f'Godot process returned {returncode}'
  except (FileNotFoundError, OSError, subprocess.TimeoutExpired) as exc:
   error=f'Godot executable missing or timed out: {exc}'
  if name!='import':
   if not evidence.exists():error=error or 'Fresh native QA JSON was not emitted'
   else:
    try:
     body=json.loads(evidence.read_text())
     if body.get('failures') or body.get('suites',{}).get(name,{}).get('failed',0):
      error=error or 'Native QA suite reports failures'
     if name not in body.get('suites',{}):error=error or 'Required native QA suite is missing'
     if name=='district_dev22':
      ev=body.get('district_dev22_evidence',{}).get('levels',{})
      if set(ev)!=IDS:error=error or 'DEV22 engine evidence does not cover ten districts'
      elif any(not row.get('all_ok') or row.get('checks',0)<20 or row.get('samples',0)<10
               for row in ev.values()):error=error or 'DEV22 native floor/stair/E/GLB evidence incomplete'
    except (ValueError,OSError,TypeError) as exc:
     error=error or f'Malformed evidence JSON: {exc}'
  stage={'name':name,'status':'FAIL' if error else 'PASS','seconds':round(time.monotonic()-started,2),
   'exit_code':returncode,'error':error}
  summary['stages'].append(stage)
  print(name,stage['status'],error,flush=True)
  if error:break
 summary['engine_certified']=not args.core_only and len(summary['stages'])==len(stages) and all(s['status']=='PASS' for s in summary['stages'])
 summary['status']='PASS' if summary['engine_certified'] else 'FAIL'
 # Full Windows gameplay + GPU test remains a separate, mandatory release gate.
 summary['release_ready']=False
 (OUT/'batch_summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False)+'\n')
 return 0 if summary['engine_certified'] or (args.core_only and all(s['status']=='PASS' for s in summary['stages'])) else 1

if __name__=='__main__':sys.exit(main())
