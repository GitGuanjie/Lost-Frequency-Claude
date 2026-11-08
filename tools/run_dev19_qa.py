#!/usr/bin/env python3
"""Native Godot 4.5.1 fail-closed QA for dev19.

Nothing in the offline asset audit is accepted as engine, physics or Windows
validation. Run on a machine with Godot installed and export templates available.
"""
from __future__ import annotations
import argparse, datetime as dt, json, subprocess, sys, time
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'reports/qa/v150_dev19'
R=json.loads((ROOT/'data/model_dressings.json').read_text())['levels']
LEVELS=list(dict.fromkeys(['L003','L010','L011','L025','L000','L001','L002','L004','L005','L007','L009','L037'] + list(R)))
FULL_LEVELS=[x['stable_id'] for x in json.loads((ROOT/'data/canon/levels.json').read_text())['levels']]

def qa_cmd(godot: str, suite: str, name: str, ids: list[str]|None=None) -> list[str]:
    cmd=[godot,'--headless','--path',str(ROOT),'--fixed-fps','60','res://tests/QARunner.tscn','--','--qa',f'--suite={suite}']
    if ids: cmd.append('--levels='+','.join(ids))
    cmd.append('--out=res://reports/qa/v150_dev19/'+name+'.json')
    return cmd

def main() -> int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--godot',default='godot',help='Godot 4.5.1 executable')
    p.add_argument('--level',action='append',choices=FULL_LEVELS,help='only selected level IDs')
    p.add_argument('--story',action='store_true',help='add isolated L009->L011 physical route suite')
    p.add_argument('--plan-only',action='store_true')
    p.add_argument('--full',action='store_true',help='run all 100 canonical level scenes')
    p.add_argument('--skip-model-smoke',action='store_true',help='diagnostic only; results never release-ready')
    args=p.parse_args()
    levels=args.level or (FULL_LEVELS if args.full else ['L000','L001','L009','L011','L002','L004','L005','L008','L037','L003','L025','L015','L016','L017','L020','L022','L024','L029','L030','L036'])
    levels=list(dict.fromkeys(levels + ['L023','L028','L032','L048','L050','L073','L077','L085','L094','L108','L140','L320','L808','L998']))
    stages=[('import',[args.godot,'--headless','--editor','--path',str(ROOT),'--import'],240,None,None)]
    if not args.skip_model_smoke:
        stages.append(('model_assets_smoke',[args.godot,'--headless','--path',str(ROOT),'--scene','res://tests/ModelAssetSmokeDev17.tscn'],240,OUT/'model_assets_smoke.json','models'))
    for suite in ('registry','lint','save','ui'):
        stages.append((suite,qa_cmd(args.godot,suite,suite),240,OUT/(suite+'.json'),suite))
    for idx in range(0,len(levels),4):
        group=levels[idx:idx+4]
        name='levels_'+str(idx//4+1)
        stages.append((name,qa_cmd(args.godot,'levels',name,group),max(480,220*len(group)),OUT/(name+'.json'),group))
    # Always test the physical route independently, even when doing a focused level pass.
    stages.append(('vertical_atrium',qa_cmd(args.godot,'vertical_atrium','vertical_atrium'),480,OUT/'vertical_atrium.json','vertical_atrium'))
    stages.append(('vertical_dev14',qa_cmd(args.godot,'vertical_dev14','vertical_dev14'),900,OUT/'vertical_dev14.json','vertical_dev14'))
    stages.append(('vertical_dev15',qa_cmd(args.godot,'vertical_dev15','vertical_dev15'),1200,OUT/'vertical_dev15.json','vertical_dev15'))
    stages.append(('vertical_dev16',qa_cmd(args.godot,'vertical_dev16','vertical_dev16'),2400,OUT/'vertical_dev16.json','vertical_dev16'))
    stages.append(('vertical_dev17',qa_cmd(args.godot,'vertical_dev17','vertical_dev17'),2400,OUT/'vertical_dev17.json','vertical_dev17'))
    stages.append(('interactions_dev18',qa_cmd(args.godot,'interactions_dev18','interactions_dev18'),2400,OUT/'interactions_dev18.json','interactions_dev18'))
    stages.append(('vertical_dev19',qa_cmd(args.godot,'vertical_dev19','vertical_dev19'),2400,OUT/'vertical_dev19.json','vertical_dev19'))
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
    output={'version':'1.5.0-dev19','timestamp_utc':dt.datetime.now(dt.timezone.utc).isoformat(),
            'claim':'Headless native Godot only. DEV19 checks raycast samples, E collision lifecycle and actual light values; NOT human walk, Windows FPS, or 100-level completeness.',
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
                        if report_body.get('passed')!=414 or report_body.get('failed')!=0 or report_body.get('version')!='1.5.0-dev17' or report_body.get('placements_tested')!=466 or report_body.get('placements_expected')!=466:
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
                            for ev in report_body.get('levels',[]):
                                if ev.get('stable_id') in ('L003','L010','L011','L025','L002','L004','L005','L037') and (ev.get('self_tests',0) < (4 if ev.get('stable_id') in ('L002','L004','L005','L037') else 2) or ev.get('qa_status')!='ENGINE_SMOKE_PASS'):
                                    error=error or f"Existing vertical collision checks missing/failed for {ev.get('stable_id')}"
                        if expected=='vertical_atrium':
                            ev=report_body.get('vertical_atrium_evidence',{})
                            if ev.get('storeys')!=3 or not all(ev.get(k) is True for k in ('landing_hit','bridge_hit','slot_clear')):
                                error=error or 'No reliable third-storey collision evidence'
                        if expected=='vertical_dev14':
                            ev=report_body.get('vertical_dev14_evidence',{})
                            check_levels=ev.get('levels',{})
                            if set(check_levels)!= {'L000','L001','L009','L011'}:
                                error=error or 'Dev16 evidence does not cover all four levels'
                            elif not (all(check_levels['L000'].get(k) is True for k in ('bridge','landing','slot_clear'))
                                and all(check_levels['L001'].get(k) is True for k in ('upper_floor','upper_slot_clear','lower_floor'))
                                and all(check_levels['L009'].get(k) is True for k in ('roof_spur','roof_slot_clear','third_floor','owner_untouched'))
                                and all(check_levels['L011'].get(k) is True for k in ('cross_bridge','stair_void_clear','third_floor'))):
                                error=error or 'Incomplete dev14 collision evidence'
                        if expected=='vertical_dev15':
                            ev=report_body.get('vertical_dev15_evidence',{})
                            checked=ev.get('levels',{})
                            expected_ids={'L015','L016','L017','L020','L022','L024','L029','L030','L036'}
                            if set(checked)!=expected_ids or any(v.get('all_ok') is not True or v.get('checks',0)<3 for v in checked.values()):
                                error=error or 'Incomplete DEV15 collision evidence'
                        if expected=='vertical_dev16':
                            ev=report_body.get('vertical_dev16_evidence',{})
                            checked=ev.get('levels',{})
                            ids={'L023','L028','L032','L048','L050','L073','L077','L085','L094','L108','L140','L320','L808','L998'}
                            if set(checked)!=ids or any(v.get('all_ok') is not True or v.get('checks',0)<24 for v in checked.values()):
                                error=error or 'Incomplete new DEV16 3D collision evidence'
                        if expected=='vertical_dev17':
                            ev=report_body.get('vertical_dev17_evidence',{})
                            checked=ev.get('levels',{})
                            if set(checked)!={'L008','L037'} or any(v.get('all_ok') is not True or v.get('checks',0)<10 for v in checked.values()):
                                error=error or 'DEV17 Godot L008+L037 physical route evidence absent or failing'
                        if expected=='interactions_dev18':
                            ev=report_body.get('interactions_dev18_evidence',{})
                            checked=ev.get('levels',{})
                            if set(checked)!={'L008','L037'} or any(
                                row.get('all_ok') is not True or row.get('found')!=row.get('expected')
                                for row in checked.values()
                            ):
                                error=error or 'DEV18 Godot interaction/callback/unload evidence missing or failing'
                        if expected=='vertical_dev19':
                            ev=report_body.get('vertical_dev19_evidence',{})
                            checked=ev.get('levels',{})
                            if (set(checked)!={'L001','L008','L037'}
                                or checked.get('L008',{}).get('checks',0)<6
                                or checked.get('L008',{}).get('observations')!=3
                                or checked.get('L037',{}).get('checks',0)<4
                                or checked.get('L037',{}).get('observations')!=4
                                or checked.get('L001',{}).get('checks',0)<4
                                or any(v.get('all_ok') is not True for v in checked.values())):
                                error=error or 'DEV19 physical route, E-interact or circuit evidence missing/failed'
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
