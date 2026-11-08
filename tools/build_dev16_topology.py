#!/usr/bin/env python3
"""Reconstruct DEV16 source-authored 3D route graph and audit its topology.

This is a mathematical DESIGN audit; runtime collision, player control and
frame rate require native Godot. Do not label these edges gameplay verified.
"""
import collections, hashlib, json, math
from pathlib import Path
R=Path(__file__).resolve().parents[1]
SRC=R/'data/vertical_routes_dev16.json'

def graph(data):
    graphs={}
    for site in data['sites']:
        sid=site['level']
        G=graphs.setdefault(sid,{'nodes':{},'edges':[],'site_tags':[], 'inter_site_edges':0})
        origin=site['origin_xyz']; n=site['tiers'];rise=site['rise_m']; tag=site['tag']; descend=site['descending']
        G['site_tags'].append(tag)
        def node(k,x,y,z):
            key=f'{tag}:{k}';assert key not in G['nodes'];G['nodes'][key]=[round(x,5),round(y,5),round(z,5)];return key
        def edge(a,b,kind,width):
            assert a!=b;G['edges'].append([a,b,kind,width])
        core={};pockets={}
        for f in range(n):
            x,y0,z=origin; y=y0+f*rise*(-1 if descend else 1)
            c=node(f'{f}:core',x,y,z);core[f]=c
            for face,sign in [('north',-1),('south',1)]:
                pt=node(f'{f}:{face}_pocket',x,y,z+sign*19);pockets[(f,face)]=pt
                for side in [-5.2,5.2]:
                    wp=node(f'{f}:{face}_{side:g}_bridge',x+side,y,z+sign*12)
                    edge(c,wp,'walk',2.5);edge(wp,pt,'walk',2.5)
            if f>0:
                shift=(1 if f%2==0 else -1)
                o=node(f'{f}:cantilever',x+shift*15,y,z);edge(c,o,'balcony',4.0)
        for f in range(n-1):
            x,y0,z=origin; ya=y0+f*rise*(-1 if descend else 1);yb=y0+(f+1)*rise*(-1 if descend else 1)
            low=min(ya,yb);high=max(ya,yb)
            lc=f if ya==low else f+1; hc=f if ya==high else f+1
            for side,start_z,end_z in [(1,-8,8),(-1,8,-8)]:
                a=node(f'{f}:stair_{side}:lower',x+side*11.8,low,z+start_z)
                b=node(f'{f}:stair_{side}:upper',x+side*11.8,high,z+end_z)
                edge(core[lc],a,'landing',2.3);edge(a,b,'stair',2.3);edge(b,core[hc],'landing',2.3)
        G.setdefault('pocket_names',{})[tag]=pockets
    for spec in data['cross_site_bridges']:
        G=graphs[spec['level']]
        left,right=spec['site_tags']
        sites={s['tag']:s for s in data['sites'] if s['level']==spec['level']}
        a,b=sites[left],sites[right]
        assert a['tiers']==b['tiers'] and a['rise_m']==b['rise_m']
        for f in [1,a['tiers']-1]:
            face='south' if f%2==0 else 'north'
            la=G['pocket_names'][left][f,face]
            rb=G['pocket_names'][right][f,face]
            x1,y,z1=a['origin_xyz'];x2,_,_=b['origin_xyz']
            mid=f'{left}-{right}:bridge:{f}'
            G['nodes'][mid]=[round((x1+x2)/2,5),round(y+f*a['rise_m'],5),round(z1+(19 if face=='south' else -19),5)]
            G['edges'].append([la,mid,'cross_site',3.3]);G['edges'].append([mid,rb,'cross_site',3.3])
            G['inter_site_edges']+=2
    for sid,G in graphs.items():
        G.pop('pocket_names',None)
        adj=collections.defaultdict(set)
        for a,b,kind,width in G['edges']:
            adj[a].add(b);adj[b].add(a)
            p,q=G['nodes'][a],G['nodes'][b]
            if kind=='stair':
                assert 3.2<=abs(p[1]-q[1])<=4.0
                assert math.isclose(abs(p[2]-q[2]),16.0,abs_tol=1e-5)
                assert abs(p[1]-q[1])/math.dist([p[0],p[2]],[q[0],q[2]])<0.25
            else:assert math.isclose(p[1],q[1],abs_tol=1e-5),(sid,a,b,kind)
        seen=set();components=0
        for v in G['nodes']:
            if v in seen:continue
            components+=1
            q=collections.deque([v]);seen.add(v)
            while q:
                w=q.popleft()
                for t in adj[w]-seen:seen.add(t);q.append(t)
        G['metrics']={'nodes':len(G['nodes']),'edges':len(G['edges']),'components':components,
                      'cycle_rank':len(G['edges'])-len(G['nodes'])+components,
                      'site_count':len(G['site_tags']),
                      'max_height_m':max(p[1] for p in G['nodes'].values()),
                      'min_height_m':min(p[1] for p in G['nodes'].values()),
                      'cross_site_edges':G['inter_site_edges']}
    return graphs

def build():
    data=json.loads(SRC.read_text()); graphs=graph(data)
    data['provenance']='SOURCE-DERIVED DESIGN GRAPH ONLY: no Godot runtime traversal, GPU or Windows export verified'
    data['canon_roster_sha256']=hashlib.sha256((R/'data/canon/levels.json').read_bytes()).hexdigest()
    data['transitions_sha256']=hashlib.sha256((R/'data/canon/transitions.json').read_bytes()).hexdigest()
    data['manifests_sha256']={sid:hashlib.sha256((R/f'levels/{sid}/level.json').read_bytes()).hexdigest() for sid in graphs}
    data['graphs']=graphs
    data['aggregate']={k:sum(g['metrics'][k] for g in graphs.values()) for k in ('nodes','edges','cycle_rank','site_count')}
    data['aggregate']['levels']=len(graphs)
    (R/'data/vertical_routes_dev16.json').write_text(json.dumps(data,indent=2)+'\n')
    print(data['aggregate'])
if __name__=='__main__':build()
