#!/usr/bin/env python3
"""Auditable design graphs of DEV17 runtime-authored geometry (NOT Godot verification).

Level 8 geometry is derived directly from the JSON read by CaveBraids.gd.
Level 37 exact tier heights and hub chunk origins are read from the same JSON
as the Godot constructor, with fixed footprint nodes in one place below.
"""
from pathlib import Path
import collections,hashlib,json,math,re
R=Path(__file__).resolve().parents[1]
CAVE=R/'data/dev17_cave_braids.json'
POOL=R/'data/dev17_pool_annexes.json'
OUT=R/'data/dev17_spatial_graphs.json'
# Exact immutable L008.ROAD spine points from CaveBuild.gd; source assertion below.
ROAD=[[13,0,2],[36,-.6,5],[60,-2,9],[82,-4,2],[104,-6,-6],[128,-8,-10],[150,-8,-12],[169,-8,-14],[169,4,-14],[190,4.5,-8],[212,5,4],[230,2,14],[242,-2,20],[256,1,27],[282,1,35],[312,.5,42],[336,0,46],[352,0,47]]

def add_graph():
    return {'nodes':{},'edges':[]}
def key(p):
    return ','.join(f'{float(x):.3f}' for x in p)
def point(g,p):
    k=key(p)
    if k not in g['nodes']:g['nodes'][k]=[float(v) for v in p]
    return k
def edge(g,a,b,kind):
    aa=point(g,a);bb=point(g,b)
    assert aa!=bb,(a,b)
    row=[aa,bb,kind]
    if row not in g['edges'] and [bb,aa,kind] not in g['edges']:g['edges'].append(row)

def cave_graph():
    data=json.loads(CAVE.read_text());g=add_graph()
    assert data['schema']=='dev17_sdf_routes_v1'
    for a,b in zip(ROAD,ROAD[1:]):edge(g,a,b,'road_ladder' if a[0]==b[0] and a[2]==b[2] else 'road')
    for route in data['braids']:
        pp=route['floor_nodes'];assert pp[0]==ROAD[route['entry_road']]
        assert pp[-1]==ROAD[route['exit_road']]
        for a,b in zip(pp,pp[1:]):edge(g,a,b,'braid')
    for link in data['links']:
        pp=link['floor_nodes'];aa=data['braids'][link['source_braid']]['floor_nodes'][link['source_node']]
        bb=data['braids'][link['target_braid']]['floor_nodes'][link['target_node']]
        assert pp[0]==aa and pp[-1]==bb,(link['id'],pp[0],aa,pp[-1],bb)
        for a,b in zip(pp,pp[1:]):edge(g,a,b,'crosslink')
    for route in data['braids']+data['links']:
        pp=route['floor_nodes']
        assert 1.8<=route['radius_m']<=2.5
        for a,b in zip(pp,pp[1:]):
            horiz=math.hypot(a[0]-b[0],a[2]-b[2]);grade=abs(a[1]-b[1])/horiz
            assert horiz>=5 and grade<=0.46,(route['id'],a,b,grade)
    return g

def pool_graph():
    data=json.loads(POOL.read_text());g=add_graph();global_origin=[0,-.18,20]
    # The east rim of the original stair-pit (x=61) is dry; the pit centre
    # is -7.5m deep and must NOT be represented by a fictional surface route.
    edge(g,[61,.05,20],[63,-.18,20],'hub_rim_step')
    edge(g,[63,-.18,20],[64,-.18,20],'hub_doorway')
    for name,site in data['annexes'].items():
        cx,cz=site['chunk'];ox=cx*32;oz=cz*32;tiers=site['tiers'];dy=site['rise_m'];floor=site['basin_floor_m']
        assert 2<=cx<=3 and cz==0 and floor>=-8.5
        portal_w=[ox,-.18,oz+20];portal_e=[ox+32,-.18,oz+20]
        near=[ox+5.5,-.18,oz+4.5];far=[ox+28.5,-.18,oz+4.5]
        edge(g,portal_w,[ox+5.5,-.18,oz+20],'ground_perimeter')
        edge(g,[ox+5.5,-.18,oz+20],near,'ground_perimeter')
        edge(g,near,far,'ground_perimeter')
        edge(g,far,[ox+28.5,-.18,oz+20],'ground_perimeter')
        edge(g,[ox+28.5,-.18,oz+20],portal_e,'ground_perimeter')
        # Local ground bathymetric loop: 2 independent entrances (x9,z9 / x9,z15)
        entry=[ox+9,-.18,oz+9];exit=[ox+9,-.18,oz+15];deep=[ox+21,floor,oz+21]
        edge(g,[ox+5.5,-.18,oz+20],entry,'base_water_approach')
        edge(g,[ox+5.5,-.18,oz+20],exit,'base_water_approach')
        chain_a=[[9,-.18,9],[13,-2,12],[18,-4.1,12],[22,-6.1,15],[21,floor,21]]
        chain_b=[[21,floor,21],[25,-6.25,19],[23,-4.25,14],[17,-2.25,11],[12,-.18,15],[9,-.18,15]]
        for chain in [chain_a,chain_b]:
            for pa,pb in zip(chain,chain[1:]):
                a=[ox+pa[0],pa[1],oz+pa[2]];b=[ox+pb[0],pb[1],oz+pb[2]]
                grade=abs(a[1]-b[1])/math.dist([a[0],a[2]],[b[0],b[2]])
                assert grade < .46,(name,a,b,grade)
                edge(g,a,b,'underwater_ramp')
        # Stair is continuous exactly at alternating ends. Decks and island
        # dual-approach edges are made by separate physical slabs in GDScript.
        for f in range(tiers-1):
            yl=-.18+f*dy;yh=yl+dy
            zl=oz+(4.5 if f%2==0 else 18.5);zh=oz+(18.5 if f%2==0 else 4.5)
            for x in [ox+5.5,ox+28.5]:
                edge(g,[x,yl,zl],[x,yh,zh],'stair')
        for f in range(1,tiers):
            y=-.18+f*dy;z=oz+(18.5 if f%2 else 4.5)
            left=[ox+5.5,y,z];right=[ox+28.5,y,z]
            edge(g,left,right,'landing')
            iz=oz+(10.8 if f%2 else 12)
            for xx in [ox+15.3,ox+20.8]:
                edge(g,left,[xx,y,z],'landing')
                edge(g,[xx,y,z],[xx,y,iz],'bridge')
                edge(g,[xx,y,iz],[ox+17.5,y,iz],'island')
                edge(g,[xx,y,z],right,'landing')
        # Both sections meet at the same floor-level opening x=96.
    assert point(g,[96,-.18,20])==key([96,-.18,20])
    return g

def metrics(g):
    adj=collections.defaultdict(set)
    for a,b,k in g['edges']:adj[a].add(b);adj[b].add(a)
    seen=set();parts=0
    for k in g['nodes']:
        if k in seen:continue
        parts+=1;seen.add(k);queue=collections.deque([k])
        while queue:
            for n in adj[queue.popleft()]-seen:
                seen.add(n);queue.append(n)
    ys=[p[1] for p in g['nodes'].values()]
    return dict(nodes=len(g['nodes']),edges=len(g['edges']),connected_components=parts,
        cycle_rank=len(g['edges'])-len(g['nodes'])+parts,
        min_height_m=min(ys),max_height_m=max(ys),height_span_m=max(ys)-min(ys))

def build():
    cave_source=(R/'levels/L008/CaveBuild.gd').read_text()
    raw_road=cave_source.split('const ROAD := [',1)[1].split(']\nconst LAKE',1)[0]
    parsed=[[float(x.strip()) for x in row.split(',')] for row in re.findall(r'Vector3\(([^)]+)\)',raw_road)]
    assert parsed==[[float(v) for v in row] for row in ROAD], 'Stable 9th Road source drifted' 
    a=cave_graph();b=pool_graph()
    for g in [a,b]:assert metrics(g)['connected_components']==1
    out={'version':'1.5.0-dev17','status':'DESIGN_GRAPH_ONLY',
         'not_verified':['Godot script parse','raycast collisions','character traversal','frame rate','Windows export'],
         'sources_sha256':{str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [CAVE,POOL]},
         'graphs':{'L008':a,'L037':b},'metrics':{'L008':metrics(a),'L037':metrics(b)}}
    OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
    print('DEV17 design topology:',json.dumps(out['metrics'],ensure_ascii=False))
    return out
if __name__=='__main__':build()
