#!/usr/bin/env python3
"""Native Godot 4.5.1 fail-closed QA for dev10.

Nothing in the offline asset audit is accepted as engine, physics or Windows
validation. Run on a machine with Godot installed and export templates available.
"""
from __future__ import annotations
import argparse, datetime as dt, json, subprocess, sys, time
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'reports/qa/v150_dev10'
R=json.loads((ROOT/'data/model_dressings.json').read_text())['levels']
LEVELS=list(dict.fromkeys(['L000','L001','L004','L007','L009','L011'] + list(R)))
FULL_LEVELS=[x['stable_id'] for x in json.loads((ROOT/'data/canon/levels.json').read_text())['levels']]

def qa_cmd(godot: str, suite: str, name: str, ids: list[str]|None=None) -> list[str]:
    cmd=[godot,'--headless','--path',str(ROOT),'--fixed-fps','60','res://tests/QARunner.tscn','--','--qa',f'--suite={suite}']
    if ids: cmd.append('--levels='+','.join(ids))
    cmd.append('--out=res://reports/qa/v150_dev10/'+name+'.json')
    return cmd

def main() -> int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--godot',default='godot',help='Godot 4.5.1 executable')
    p.add_argument('--level',action='append',choices=LEVELS,help='only selected level IDs')
    p.add_argument('--story',action='store_true',help='add isolated L009->L011 physical route suite')
    p.add_argument('--plan-only',action='store_true')
    p.add_argument('--full',action='store_true',help='run all 100 canonical level scenes')
    p.add_argument('--skip-model-smoke',action='store_true',help='diagnostic only; results never release-ready')
    args=p.parse_args()
    levels=args.level or (FULL_LEVELS if args.full else LEVELS)
    stages=[('import',[args.godot,'--headless','--editor','--path',str(ROOT),'--import'],240,None,None)]
    if not args.skip_model_smoke:
        stages.append(('model_assets_smoke',[args.godot,'--headless','--path',str(ROOT),'--scene','res://tests/ModelAssetSmoke.tscn'],240,OUT/'model_assets_smoke.json','models'))
    for suite in ('registry','lint','save','ui'):
        stages.append((suite,qa_cmd(args.godot,suite,suite),240,OUT/(suite+'.json'),suite))
    for idx in range(0,len(levels),4):
        group=levels[idx:idx+4]
        name='levels_'+str(idx//4+1)
        stages.append((name,qa_cmd(args.godot,'levels',name,group),max(480,220*len(group)),OUT/(name+'.json'),group))
    # Always test the physical route independently, even when doing a focused level pass.
    stages.append(('vertical_atrium',qa_cmd(args.godot,'vertical_atrium','vertical_atrium'),480,OUT/'vertical_atrium.json','vertical_atrium'))
    stages.append(('l009_route',qa_cmd(args.godot,'l009_route','l009_route'),900,OUT/'l009_route.json','l009_route'))
    if args.story:
        cmd=qa_cmd(args.godot,'story','story')
        cmd.append('--story_hops=10')
        stages.append(('story',cmd,1500,OUT/'story.json','story'))
    if args.plan_only:
        for name,cmd,timeout,report,_ in stages:
            print(name, 'timeout='+str(timeout)+'s', ' '.join(cmd))
        return 0
    OUT.mkdir(parents=True,exist_ok=True)
    output={'version':'1.5.0-dev10','timestamp_utc':dt.datetime.now(dt.timezone.utc).isoformat(),
            'claim':'Headless Godot only. GPU performance and Windows real gameplay NOT verified.',
            'status':'FAIL','stages':[]}
    for name,command,timeout,report,expected in stages:
        if report and report.exists():report.unlink()
        start=time.monotonic();code=None;error=''
        try:
            with (OUT/(name+'.log')).open('w',encoding='utf8') as log:
                result=subprocess.run(command,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=timeout,check=False)
            code=result.returncode
            if code!=0:error=f'Godot exit {code}'
        except (OSError,subprocess.TimeoutExpired) as exc:
            error=f'Godot not available or timed out: {exc}'
        report_body=None
        if report:
            if not report.is_file():error=error or 'New evidence JSON was not created'
            else:
                try:
                    report_body=json.loads(report.read_text(encoding='utf8'))
                    if expected=='models':
                        if report_body.get('passed')!=414 or report_body.get('failed')!=0 or report_body.get('version')!='1.5.0-dev10' or report_body.get('placements_tested')!=466 or report_body.get('placements_expected')!=466:
                            error=error or 'Not all 414 imported GLBs instantiated successfully'
                    else:
                        suites=report_body.get('suites',{})
                        suite='levels' if isinstance(expected,list) else expected
                        if suite not in suites:error=error or f'Missing QA suite {suite}'
                        if report_body.get('failures') or any(int(row.get('failed',0))>0 for row in suites.values()):
                            error=error or 'QA assertions failed'
                        if isinstance(expected,list):
                            got={x.get('stable_id') for x in report_body.get('levels',[])}
                            if not set(expected).issubset(got):error=error or f'Level evidence missing {set(expected)-got}'
                        if expected=='vertical_atrium':
                            ev=report_body.get('vertical_atrium_evidence',{})
                            if ev.get('storeys')!=3 or not all(ev.get(k) is True for k in ('landing_hit','bridge_hit','slot_clear')):
                                error=error or 'No reliable third-storey collision evidence'
                        if expected=='l009_route':
                            ev=report_body.get('l009_route_evidence',{})
                            wp=ev.get('waypoints',[])
                            if len(wp)!=3 or not all(x.get('walk',{}).get('fired') and x.get('after')==x.get('before',-1)+1 for x in wp):
                                error=error or 'Route waypoints have no complete physical trace'
                            if not ev.get('exit',{}).get('fired'):
                                error=error or 'Real conditional L009>L011 trigger was not fired'
                except (ValueError,TypeError,OSError) as exc:
                    error=error or f'Invalid report: {exc}'
        stage={'name':name,'status':'PASS' if code==0 and not error else 'FAIL',
               'seconds':round(time.monotonic()-start,2),'exit_code':code,'error':error}
        output['stages'].append(stage)
        print(stage['name'],stage['status'],stage['error'],flush=True)
        if stage['status']=='FAIL':break
    output['status']='PASS' if len(stages)==len(output['stages']) and all(s['status']=='PASS' for s in output['stages']) and not args.skip_model_smoke else 'FAIL'
    (OUT/'batch_summary.json').write_text(json.dumps(output,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    return 0 if output['status']=='PASS' else 1

if __name__=='__main__':sys.exit(main())
