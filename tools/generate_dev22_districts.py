#!/usr/bin/env python3
"""DEV22: build ten theme-specific 3D explorable districts.

This JSON is a deterministic source for *both* geometry and graph evidence.
No engine navigation/physics claim is made by the generator.
"""
from __future__ import annotations
import hashlib
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BLUE = json.loads((ROOT / 'data/dev20_atrium_blueprints.json').read_text())['wings']
DRESS = {s['id']: s for s in json.loads((ROOT / 'data/dev21_wing_scenarios.json').read_text())['wings']}
CAT = json.loads((ROOT / 'assets/packs/catalog.json').read_text())['models']

# Structural variants follow the local source notes and verified Wikidot material.
# In-game scenery and interaction texts are clearly marked original adaptations.
THEMES = {
    'L028': ('keep_forge', 4, 'Forge gallery and inverted guest wings', 'The metal below the stairs was never quenched.', 'The keep seems ordinary until a modern appliance hums beyond the arch.'),
    'L032': ('canopy', 4, 'Pale memorials above the night forest', 'An unlit lantern faces a path that doubles back.', 'The highest canopy seems to be rooted in the floor below.'),
    'L050': ('highway', 4, 'Signal maintenance gantry', 'Two road signs point toward the same distance.', 'An unused service track crosses the shadow of the highway.'),
    'L073': ('red_keep', 4, 'Broken battlements and signal crypt', 'The red masonry has a seam where it should have a door.', 'The ruined defenses form a complete loop at different heights.'),
    'L077': ('fog_trail', 4, 'Fogbound switchback lookout', 'The beacon is visible from an impossible direction.', 'The higher trail emerges into the same mist without a horizon.'),
    'L085': ('shelter', 4, 'Clean-air refuge and false storerooms', 'The air indicator flickers despite sealed windows.', 'The luxurious interior hides a maintenance return route.'),
    'L094': ('toy_town', 4, 'Distorted interior passage stack', 'Identical furniture is not identical in scale.', 'The viewpoint makes a neighboring wall look unexpectedly close.'),
    'L108': ('roots', 4, 'Craterwood root bridges and hollow trunks', 'The root growth surrounds a corridor without touching it.', 'The forest floor below is visible through several different crowns.'),
    'L320': ('attraction', 5, 'Folding Point multilayer attraction', 'The queue railing seems to turn through a larger space than its building.', 'A maintenance floor is visible beneath the closed attraction.'),
    'L808': ('neon', 5, 'Gridline transit and lightwell', 'The neon grid turns a different color without changing direction.', 'Several luminous walkways intersect without meeting at this height.'),
}
OPEN = {'canopy', 'highway', 'fog_trail', 'roots', 'neon'}
SOUNDS = {'keep_forge':'pipe_clank','canopy':'creak','highway':'wind','red_keep':'knock',
          'fog_trail':'wind','shelter':'pipe_clank','toy_town':'creak','roots':'scratch',
          'attraction':'creak','neon':'pipe_clank'}


def edge_key(e):
    a, b = sorted((tuple(e[:2]), tuple(e[2:])))
    return (*a, *b)


def layout(wid, tier, style):
    rng = random.Random(int.from_bytes(hashlib.sha256(f'DEV22:{wid}:{tier}'.encode()).digest()[:8],'big'))
    cells = [(c, r) for r in range(4) for c in range(4)]
    # Crucial endpoints for the two stair shafts and the level-0 incoming bridge
    # are never removed. Interior holes provide genuine floor-to-floor sightlines.
    omit = set()
    if tier > 0:
        holepool = [(1,1),(2,1),(1,2),(2,2)]
        rng.shuffle(holepool)
        if style in ('attraction','neon','canopy','roots'):
            # Keep the two voids edge-adjacent so each mezzanine retains
            # at least four independent alternative horizontal circuits.
            hole_pairs = [((1,1),(2,1)),((1,2),(2,2)),((1,1),(1,2)),((2,1),(2,2))]
            omit = set(hole_pairs[rng.randrange(len(hole_pairs))])
        else:
            omit = {holepool[0]}
    cells = [p for p in cells if p not in omit]
    allowed = set(cells)
    candidates = [edge_key((c,r,c+dx,r+dy)) for (c,r) in cells for (dx,dy) in ((1,0),(0,1)) if (c+dx,r+dy) in allowed]
    rng.shuffle(candidates)
    parent = {x:x for x in cells}
    def root(p):
        while parent[p]!=p:
            parent[p]=parent[parent[p]]
            p=parent[p]
        return p
    tree, spare = [],[]
    for e in candidates:
        a,b=e[:2],e[2:]
        ra, rb=root(a),root(b)
        if ra != rb:
            parent[ra]=rb
            tree.append(e)
        else:
            spare.append(e)
    # Per-tier loops are deliberately different in each level and on each storey.
    add = min(len(spare), 4 + rng.randrange(3))
    extra = sorted(spare[:add])
    doors = sorted(tree + extra)
    return {'cells':[list(x) for x in sorted(cells)],
            'doors':[list(x) for x in doors],
            'tree_edges':[list(x) for x in sorted(tree)],
            'extra_edges':[list(x) for x in extra],
            'voids':[list(x) for x in sorted(omit)],
            'cycle_rank':len(doors)-len(cells)+1}


def select_props(wid, style, floors):
    source = DRESS[wid]['models']
    # Existing palettes: reuse actual GLB files already catalogued and included.
    types = sorted({(m['pack'],m['model']) for m in source})
    selection=[]
    for tier, floor in enumerate(floors):
        rng = random.Random(int.from_bytes(hashlib.sha256(f'{wid}:props:{tier}:DEV22'.encode()).digest()[:8],'big'))
        cells = [tuple(c) for c in floor['cells'] if tuple(c) not in {(0,0),(0,3),(3,0),(3,3),(2,3),(0,1),(3,1),(1,3)}]
        rng.shuffle(cells)
        for index,(c,r) in enumerate(cells[:6]):
            pack,model=types[(index*3+tier*5+c+r)%len(types)]
            key=f'assets/packs/{pack}/{model}.glb'
            size=CAT[key]['size']
            allowed=0.80 if style in OPEN else 1.40
            scale=min(6.0, allowed/max(size[0],size[2],0.01), 1.85/max(size[1],0.01))
            height=round(max(.18,size[1])*scale,4)
            offset=1.91 if style in OPEN else 2.18
            # Use the three corners not used by the structural corner buttress.
            px,pz=((offset,-offset),(-offset,offset),(offset,offset))[(index+c+tier)%3]
            selection.append({'tier':tier,'cell':[c,r], 'pack':pack,'model':model,
                'offset':[px,pz], 'height':height,'yaw':(index*67+c*19+r*29+tier*53)%360})
    return selection


def build():
    out={'schema':1,'version':'1.5.0-dev22','status':'TOPOLOGY_ONLY_ENGINE_NOT_CERTIFIED',
        'source':'Original game adaptation based on locally archived Backrooms Wikidot descriptions',
        'districts':[]}
    for b in BLUE:
        wid=b['id']; style,tiers,title,first,second=THEMES[wid]
        rise=float(b['rise']); ox,oy,oz=b['origin']
        wing_x0=float(ox)+32.5; wing_z0=float(oz)-14.0
        # The entire district is north of the DEV20 structure. A 15m bridge
        # at wing tier 1 joins a new room; all other levels require real stairs.
        dx=round(wing_x0,4)
        dz=round(wing_z0-43.0,4)
        ybase=round(float(oy)+2*rise,4)
        floors=[layout(wid,tier,style) for tier in range(tiers)]
        # The optional gate blocks precisely one non-tree edge of tier 1;
        # removing it cannot disconnect a graph whose spanning tree remains.
        extras=floors[1]['extra_edges']
        eligible=[e for e in extras if tuple(e[:2]) not in {(0,0),(0,3),(3,0),(3,3)} and tuple(e[2:]) not in {(0,0),(0,3),(3,0),(3,3)}]
        gate=list((eligible or extras)[0])
        props=select_props(wid,style,floors)
        sound=SOUNDS[style]
        # A third, physically attached landmark terrace makes each district a
        # recognisable place instead of just another stacked room network.
        types=sorted({(m['pack'],m['model']) for m in DRESS[wid]['models']})
        landmark_models=[]
        for i in range(2):
            pack,model=types[(i*7+len(style))%len(types)]
            size=CAT[f'assets/packs/{pack}/{model}.glb']['size']
            scale=min(6.0, 1.3/max(float(size[0]),float(size[2]),.01), 2.0/max(float(size[1]),.01))
            landmark_models.append({'pack':pack,'model':model,'height':round(max(0.18,size[1])*scale,4),
                'offset_x':-3.65 if i==0 else 3.65,'yaw':(i*180+len(style)*13)%360})
        ambience=[]
        for tier in [0,tiers-1]:
            ambience.append({'id':f'dev22:{wid}:ambient:{tier}',
                'pos':[round(dx+2.5*7,2),round(ybase+tier*rise+1.0,2),round(dz+2.5*7,2)],
                'height':2.0,'radius':4.0,'caption': first if tier==0 else second,
                'sound':sound,'source':'ADAPTATION'})
        ambience.append({'id':f'dev22:{wid}:landmark',
            'pos':[round(dx+10.5,2),round(ybase+1.0,2),round(dz-7.0,2)],
            'height':2.0,'radius':4.5,'caption':first,
            'sound':sound,'source':'ADAPTATION'})
        msgs=[
            f'The {title.lower()} has a visible return route at this height.',
            first,second,
            'The upper tier gives another angle on the paths below.',
            'A higher path shows how the structure folds back on itself.'
        ]
        out['districts'].append({'id':wid,'anchor':b['anchor'],'style':style,'title':title,
            'rise':rise,'tiers':tiers,'origin':[dx,ybase,dz],
            'mat':b['mat'],'accent':b['accent'],'open_air':style in OPEN,
            'floors':floors,'shutter_edge':gate,'models':props,'ambience':ambience,
            'signals':msgs[:tiers], 'observations':[first,second, f'This landmark belongs to the {title.lower()}.'], 'landmark_models':landmark_models})
    p=ROOT/'data/dev22_narrative_districts.json'
    p.write_text(json.dumps(out,indent=2,ensure_ascii=False)+'\n')
    totals={k:sum(len(x['floors']) if k=='floors' else sum(len(f[k]) for f in x['floors']) if k in ('cells','doors') else len(x[k]) for x in out['districts']) for k in ('floors','cells','doors','models')}
    print(json.dumps({'path':str(p), 'districts':len(out['districts']), **totals},ensure_ascii=False))

if __name__=='__main__':build()
