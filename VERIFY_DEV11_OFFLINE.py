#!/usr/bin/env python3
"""Dev11 offline QA only. Does not verify GDScript compilation or Windows gameplay."""
import subprocess,sys,json,datetime
from pathlib import Path
r=Path(__file__).resolve().parent
steps=[([sys.executable,'-m','unittest','discover','-s','tests/static','-p','test_*.py','-q'],'python_static'),
       ([sys.executable,'tools/world_audit.py','--no-render','--fail-on-issues'],'world_manifest')]
status=[]
for cmd,name in steps:
    result=subprocess.run(cmd,cwd=r,check=False)
    status.append({'name':name,'status':'PASS' if result.returncode==0 else 'FAIL','exit_code':result.returncode})
report={'version':'1.5.0-dev11','scope':'offline source and manifest checks ONLY',
        'timestamp_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'checks':status,'godot_engine':'NOT RUN','windows_runtime':'NOT RUN',
        'l009_to_l011_physical_route':'NOT VERIFIED'}
out=r/'reports/qa/v150_dev11/offline.json';out.parent.mkdir(parents=True,exist_ok=True)
out.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
print(json.dumps(report,indent=2,ensure_ascii=False))
sys.exit(0 if all(v['status']=='PASS' for v in status) else 1)
