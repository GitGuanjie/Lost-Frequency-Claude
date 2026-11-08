#!/usr/bin/env python3
"""Generate ten distinct playable expedition graphs from existing wiki-themed
landmarks and the OWNED GLB catalogue. Deterministic, without engine claims.

All walkable decks, steps and rail gaps are built from these records in Godot.
Optional edges are chosen from graph cycles, never from the spanning tree.
"""
from pathlib import Path
import hashlib
import json
import random
from collections import deque

ROOT=Path(__file__).resolve().parents[1]
PREV=json.loads((ROOT/'data/dev23_landmark_spurs.json').read_text())['sites']
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']
DIST={d['id']:d for d in json.loads((ROOT/'data/dev22_narrative_districts.json').read_text())['districts']}

# Deliberately different macro footprints. Each begins at (0,0) and contains
# a side-loop, whose redundant bridge can be unlocked by exploration.
BASE={
 'keep_forge':[(0,0),(1,0),(2,0),(0,-1),(1,-1),(2,-1)],
 'canopy':[(0,0),(1,0),(1,-1),(2,-1),(2,0),(3,0)],
 'highway':[(0,0),(1,0),(2,0),(3,0),(2,-1),(3,-1)],
 'red_keep':[(0,0),(1,0),(2,0),(0,1),(1,1),(2,1)],
 'fog_trail':[(0,0),(1,0),(1,1),(2,1),(2,0),(3,0)],
 'shelter':[(0,0),(1,0),(2,0),(1,-1),(2,-1),(1,-2)],
 'toy_town':[(0,0),(0,1),(1,1),(1,0),(2,0),(2,1)],
 'roots':[(0,0),(1,0),(1,-1),(2,-1),(2,0),(1,1)],
 'attraction':[(0,0),(1,0),(1,1),(2,1),(2,0),(1,-1)],
 'neon':[(0,0),(1,0),(2,0),(2,-1),(3,-1),(3,0)],
}
UPPER={
 'keep_forge':[(0,0),(1,0),(1,-1),(0,-1)],
 'canopy':[(0,0),(0,-1),(1,-1),(2,-1)],
 'highway':[(0,0),(1,0),(2,0),(2,1)],
 'red_keep':[(0,0),(1,0),(1,1),(0,1)],
 'fog_trail':[(0,0),(0,1),(1,1),(2,1)],
 'shelter':[(0,0),(1,0),(1,-1),(2,-1)],
 'toy_town':[(0,0),(1,0),(1,1),(0,1)],
 'roots':[(0,0),(0,-1),(1,-1),(1,0)],
 'attraction':[(0,0),(1,0),(1,-1),(2,-1)],
 'neon':[(0,0),(1,0),(1,1),(2,1)],
}
STORIES={
 'keep_forge':('Ruin forge and inverted watch hall','The forge echoes under blue stone, while familiar appliances seem completely out of place.'),
 'canopy':('Bone-chime branchwalk','The branches are suspended above an ever-dark forest. Nothing here explains the clattering.'),
 'highway':('Displaced highway junction','A road marker points towards both the near bridge and the far one.'),
 'red_keep':('Redoubts beyond the crimson keep','The outer defensive platforms return to a courtyard the same height as the first.'),
 'fog_trail':('Twinned mist switchbacks','The ridge remains visible while the path behind it disappears.'),
 'shelter':('Two-level service apartments','Empty rooms surround a maintenance hall that still answers to its switches.'),
 'toy_town':('False-scale balcony quarter','A small door is paired with a gigantic step, without explaining who used either.'),
 'roots':('Split canopy and buried roots','The root arches join across an unseen hollow.'),
 'attraction':('Silent ride queue','The queue doubles back under an elevated ride platform, without moving machinery.'),
 'neon':('Afterimage relay fields','The grid changes its color in bands while the static sunset refuses to move.'),
}

def edges_from(cells):
    found={tuple(p) for p in cells}
    return sorted([[(x,z),(x+dx,z+dz)] for x,z in found for dx,dz in ((1,0),(0,1)) if (x+dx,z+dz) in found])

def graph(cells, stage):
    nodes=[tuple(v) for v in cells]
    edges=edges_from(nodes)
    seen={nodes[0]}; tree=[]
    # BFS deterministic: map coordinate edge names to node indices.
    while len(seen)<len(nodes):
        choices=[e for e in edges if (e[0] in seen) != (e[1] in seen)]
        if not choices: raise ValueError(f'disconnected graph {stage}: {nodes}')
        edge=choices[0]; tree.append(edge);seen.update(map(tuple,edge))
    spare=[e for e in edges if e not in tree]
    return tree,spare

def bounds_key(model):
    return f'assets/packs/{model[0]}/{model[1]}.glb'

def prop_height(pack,model,cap):
    dims=CAT[bounds_key((pack,model))]['size']
    x,y,z=map(float,dims)
    h=min(1.8,cap*max(.18,y)/max(.18,x,z))
    f=min(8., h/max(.18,y))
    if max(x,z)*f>cap:
        h*=cap/(max(x,z)*f)
    return round(max(.08,h),4)

def generate():
    sites=[]
    for old in PREV:
        sid=old['id']; style=old['style']; oy=float(old['node_positions']['east'][1])
        gx=float(old['node_positions']['east'][0]); gz=float(old['node_positions']['east'][2])
        # 24m east of DEV23 gallery centre. West entry spans the old 6m rail gap.
        x0=round(gx+24.,3);z0=round(gz,3);rise=float(old['rise'])
        lows=BASE[style]; highs=UPPER[style];lowtree,lowspare=graph(lows,'low:'+sid)
        hitree,hispare=graph(highs,'high:'+sid)
        if not lowspare: raise ValueError('no optional non-tree edge '+sid)
        terminal=max(lows,key=lambda p:(p[0],-abs(p[1])))
        highx=x0+14*terminal[0]+29.
        highz=z0+14*terminal[1]
        base_positions={f'b{i}':[x0+14*c,oy,z0+14*r] for i,(c,r) in enumerate(lows)}
        upper_positions={f'u{i}':[highx+14*c,oy+rise,highz+14*r] for i,(c,r) in enumerate(highs)}
        node_pos={**base_positions,**upper_positions}
        def endpoints(x):
            return [f'b{lows.index(tuple(x[0]))}',f'b{lows.index(tuple(x[1]))}']
        links=[{'a':a,'b':b,'kind':'walk'} for a,b in map(endpoints,lowtree)]
        optional=endpoints(lowspare[0])
        links.append({'a':optional[0],'b':optional[1],'kind':'unlockable'})
        for a,b in hitree:
            links.append({'a':f'u{highs.index(tuple(a))}','b':f'u{highs.index(tuple(b))}','kind':'walk'})
        # More side circuits are physically reachable; optional bridge is the
        # ONLY one excluded from initial walkability.
        for extra in lowspare[1:]:
            a,b=endpoints(extra)
            links.append({'a':a,'b':b,'kind':'walk'})
        for a,b in hispare:
            links.append({'a':f'u{highs.index(tuple(a))}','b':f'u{highs.index(tuple(b))}','kind':'walk'})
        links.append({'a':f'b{lows.index(terminal)}','b':'u0','kind':'stair'})
        # Distinct level GLB pools: old landmark + curated district models.
        source=(old['props']+DIST[sid]['models']+DIST[sid]['landmark_models'])
        choices=sorted({(p['pack'],p['model']) for p in source if bounds_key((p['pack'],p['model'])) in CAT})
        if len(choices)<4: raise ValueError('too few prop identities '+sid)
        rng=random.Random(int.from_bytes(hashlib.sha256(f'DEV24:{sid}'.encode()).digest()[:8],'big'))
        props=[]
        # Three decorations per platform, at different offset corners; center
        # lanes and portal locations are reserved.
        corners=[(-3.56,-3.45),(3.56,-3.45),(-3.56,3.45),(3.56,3.45)]
        for index,node in enumerate(node_pos):
            for j in range(3):
                pack,model=choices[(index*5+j*7+rng.randrange(len(choices)))%len(choices)]
                dx,dz=corners[(index+j)%4]
                props.append({'node':node,'pack':pack,'model':model,'dx':dx,'dz':dz,
                    'height':prop_height(pack,model,1.25),'yaw':rng.randrange(360)})
        title,observation=STORIES[style]
        rec={'id':sid,'style':style,'mat':old['mat'],'accent':old['accent'],'title':title,
             'observation':observation,'sound':old['sound'],'rise':rise,
             'entry_gallery':[gx,oy,gz], 'origin':[x0,oy,z0],
             'morphology':{'base':lows,'upper':highs},
             'nodes':node_pos,'links':links,'optional_edge':optional,
             'survey':['b0',f'b{len(lows)-1}',f'u{len(highs)-1}'],'props':props,
             'cycle_rank_base':len(edges_from(lows))-len(lows)+1,
             'cycle_rank_upper':len(edges_from(highs))-len(highs)+1}
        sites.append(rec)
    return {'schema':'lf.dev24.expeditions.v1','version':'1.5.0-dev24',
       'validation':'BLUEPRINT_ONLY_NOT_NATIVE_QA','source':'Original gameplay adaptation; owned GLB models and previously researched Wikidot themes',
       'sites':sites}

if __name__=='__main__':
    result=generate()
    p=ROOT/'data/dev24_expeditions.json'
    p.write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n')
    print('sites:',len(result['sites']),'nodes:',sum(len(s['nodes']) for s in result['sites']),
          'links:',sum(len(s['links']) for s in result['sites']),
          'props:',sum(len(s['props']) for s in result['sites']),
          'unique assets:',len({(p['pack'],p['model']) for s in result['sites'] for p in s['props']}))
