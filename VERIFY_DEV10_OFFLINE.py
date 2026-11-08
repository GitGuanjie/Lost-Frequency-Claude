#!/usr/bin/env python3
"""Offline-only version/asset/source integrity gate. Does not certify playability."""
from __future__ import annotations
import argparse, json, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parent

def cmd(*args):
    print('+',' '.join(map(str,args)),flush=True)
    return subprocess.call(list(map(str,args)),cwd=ROOT)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--no-world-audit',action='store_true')
    args=p.parse_args()
    result=cmd(sys.executable,'-m','unittest','discover','-s','tests/static','-p','test_*.py','-q')
    if not args.no_world_audit:
        result=max(result,cmd(sys.executable,'tools/world_audit.py','--no-render'))
    # Never print a pass that implies engine or real-game verification.
    summary={'version':'1.5.0-dev10','offline_status':'PASS' if result==0 else 'FAIL',
        'native_godot': 'NOT RUN', 'windows_runtime': 'NOT RUN',
        'story_L009_to_L011': 'UNVERIFIED BY REAL PHYSICS'}
    path=ROOT/'reports/qa/v150_dev10/offline_summary.json'
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(summary,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print(json.dumps(summary,ensure_ascii=False,indent=2))
    return result
if __name__=='__main__':
    sys.exit(main())
