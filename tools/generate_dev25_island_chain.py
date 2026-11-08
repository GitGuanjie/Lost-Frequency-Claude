#!/usr/bin/env python3
"""Generate accessible, visually distinct low-gravity floating islands for L149.

The first island touches the original main island; remaining hops have <=6m
horizontal free gaps and <=3.5m height change. Players can take either fork.
These are static level design bounds, not native physics certification.
"""
import json,random,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
# x, top_y, z, radius. Deliberately irregular: main chain + two reconnecting loops.
ISLANDS=[(-36,0,-4,9),(-55,.8,-5,9),(-74,1.2,1,9),(-93,2,7,10),(-113,2.7,6,10),(-134,3.2,-1,11),(-157,2.2,-8,12),(-179,1.3,-2,11),(-199,.7,7,11),(-220,1.9,6,11),(-92,1.8,25,10),(-113,2.2,29,11),(-150,3.0,13,12)]
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']
ROCKS=['rock-smalla','rock-smallb','rock-smallc','rock-smalld','rock-smallflata','cliff-rock','rock-tallc','rock-talle']
assert all('assets/packs/nature-kit/'+n+'.glb' in CAT for n in ROCKS)
rng=random.Random(25149)
records=[]
for i,(x,y,z,r) in enumerate(ISLANDS):
    props=[]
    for j in range(3):
        model=ROCKS[(i*3+j*5)%len(ROCKS)]
        angle=math.radians((25+110*j+17*i)%360)
        props.append({'pack':'nature-kit','model':model,
            'x':round(x+math.cos(angle)*r*.66,3),'y':y,
            'z':round(z+math.sin(angle)*r*.66,3),'height':round(1.1+.2*(j%3),2),
            'yaw':rng.randrange(360)})
    records.append({'id':i,'pos':[x,y,z],'radius':r,'palms':3+i%4,'props':props})
# Wide slabs and walkable leap distances. Confirm first deck overlaps the old island.
assert ISLANDS[0][0]+ISLANDS[0][3]>=-30
adj={i:set() for i in range(len(records))}
for i,ri in enumerate(records):
    for j in range(i+1,len(records)):
        rj=records[j]
        ax,ay,az=ri['pos'];bx,by,bz=rj['pos']
        gap=math.hypot(ax-bx,az-bz)-(ri['radius']+rj['radius'])
        if gap<=5.0 and abs(ay-by)<=3.5:
            adj[i].add(j);adj[j].add(i)
seen={0};todo=[0]
for i in todo:
    for j in adj[i]:
        if j not in seen:seen.add(j);todo.append(j)
assert len(seen)==len(records),(len(seen),len(records))
assert len(records)>=12
payload={'version':25,'level':'L149','islands':records,
         'notes':'Optional natural island field. All original exits and Barrier probability unchanged.'}
out=ROOT/'data/dev25_coconut_island_variants.json'
out.write_text(json.dumps(payload,indent=2,ensure_ascii=False,sort_keys=True)+'\n')
print('islands',len(records),'rocks',sum(len(r['props']) for r in records),
      'palms',sum(r['palms'] for r in records),'edges',sum(map(len,adj.values()))//2)
