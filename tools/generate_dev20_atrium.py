#!/usr/bin/env python3
"""Emit deterministic, audited, playable-topology room plans for DEV20.

A single JSON contract drives *both* Godot construction and offline graph tests.
Never claim Godot collision or agent navigation validation from this file.
"""
import json, hashlib, random
from pathlib import Path
R=Path(__file__).resolve().parents[1]
# Checked against the anchored SpatialBranchworks.install calls in each source.
SITES=[
 ('L028','StormstoneUpperShelves',(60,0,-35),4,3.5,'l28_blue','l28_iron','ruin'),
 ('L032','NightCanopyBranchedWalk',(80,0,40),5,3.4,'d7_trunk','d7_bone','forest'),
 ('L050','DesertRoadSignalDeck',(67,0,65),4,3.5,'l50_sand','l50_vehicle','desert'),
 ('L073','CrimsonKeepBoundary',(32,0,-39),4,3.5,'d6_darkstone','d6_redwood','ruin'),
 ('L077','ShepherdNightOutlook',(127,0,-12),5,3.5,'d7_farm','d7_nightwood','forest'),
 ('L085','AbandonedSunsetTerraces',(93,0,-51),4,3.5,'d7_luxury','d7_road','domestic'),
 ('L094','ImpossibleTownArcades',(70,0,60),5,3.5,'l94_house','l94_roof','surreal'),
 ('L108','CraterwoodCanopyCircuit',(108,0,72),5,3.5,'d7_trunk','d7_mutant','forest'),
 ('L320','SilentRideWestTransit',(-60,0,-50),5,3.5,'l320_path','l320_paint','leisure'),
 ('L808','NeonOuterCityOverpass',(48,0,-66),6,3.5,'l808_city','l808_magenta','surreal'),
]

def key(e):
 a,b=sorted((tuple(e[:2]),tuple(e[2:])))
 return (*a,*b)

def floor_plan(sid, tier, hole_c):
 seed=int.from_bytes(hashlib.sha256((sid+':DEV20:'+str(tier)).encode()).digest()[:8],'big')
 rng=random.Random(seed)
 cells=[(c,r) for r in range(4) for c in range(5) if not(tier>=1 and c==hole_c and r in (1,2))]
 allowed=set(cells)
 edges=[key((c,r,c+dx,r+dy)) for c,r in cells for dx,dy in [(1,0),(0,1)] if(c+dx,r+dy) in allowed]
 rng.shuffle(edges)
 parent={p:p for p in cells}
 def root(p):
  while parent[p]!=p:
   parent[p]=parent[parent[p]]
   p=parent[p]
  return p
 tree=[]; extra=[]
 for e in edges:
  a=e[:2];b=e[2:]
  ra,rb=root(a),root(b)
  if ra!=rb:
   parent[ra]=rb;tree.append(e)
  else:extra.append(e)
 # Sample additional real physical short-circuits, keeping some walls closed.
 extra=sorted(extra, key=lambda e:hashlib.sha256(f'{sid}:{tier}:{e}'.encode()).digest())
 loops=min(7,len(extra))
 chosen=tree+extra[:loops]
 return {'cells':[list(p) for p in sorted(cells)],'tree_edges':[list(p) for p in tree],
         'extra_edges':[list(p) for p in extra[:loops]],
         'doors':[list(p) for p in sorted(chosen)],'closed_internal_walls':len(edges)-len(chosen),
         'cycle_rank':loops}

out={'schema':1,'version':'dev20','status':'DESIGN_GRAPH_ONLY_NOT_GODOT_WALKED',
     'cell_metres':7,'columns':5,'rows':4,'tiers':3,'wings':[]}
for sid,tag,origin,tiers,rise,mat,accent,style in SITES:
 hole_c=1+int.from_bytes(hashlib.sha256(sid.encode()).digest()[:2],"big")%3
 levels=[floor_plan(sid,i,hole_c) for i in range(3)]
 assert levels[1]['extra_edges']
 out['wings'].append({'id':sid,'anchor':tag,'origin':list(origin),'anchor_tiers':tiers,
       'rise':rise,'mat':mat,'accent':accent,'style':style,
       'tier_index_at_entry':2,'atrium_hole_column':hole_c,
       'open_air':style in ('forest','garden','desert','leisure'),'floors':levels,
       'shutter_edge':levels[1]['extra_edges'][0],
       'interactions':{'light_circuits':3,'shutter':1,'observations':2}})
p=R/'data/dev20_atrium_blueprints.json'
p.write_text(json.dumps(out,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('Wrote',p, 'wings',len(out['wings']), 'rooms',sum(len(f['cells']) for w in out['wings'] for f in w['floors']),
      'doors',sum(len(f['doors']) for w in out['wings'] for f in w['floors']),
      'loop_rank',sum(f['cycle_rank'] for w in out['wings'] for f in w['floors']))
