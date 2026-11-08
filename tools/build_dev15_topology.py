#!/usr/bin/env python3
"""Reproduce DEV15 authored geometry's route DESIGN graph (not player verification).

Towers and routes are literal geometry parameters, cross-checked in static tests.
Exporting this graph cannot make a Godot collision test pass.
"""
from __future__ import annotations
import json, math, hashlib
from pathlib import Path
R=Path(__file__).resolve().parents[1]
TOWERS={
 'L015':((19,0,97),4,3.5,'Machine inspection / vent galleries'),
 'L016':((26,0,-22),4,3.4,'Rainforest low-gravity canopy'),
 'L017':((0,0,-1),4,3.45,'Carrier bulkhead service decks'),
 'L020':((0,0,59.5),4,3.45,'Electric service galleries'),
 'L024':((-37,0,-15),5,3.4,'PlasticWorks elevated process'),
 'L029':((46,0,-40),4,3.45,'Hyperia watchtower'),
 'L036':((0,0,-35),4,3.45,'Airport baggage overlook')
}
def add_edge(edges,a,b,typ,width):edges.append([a,b,typ,width])
def tower_graph(org,n,h):
    ox,oy,oz=org;nodes={};edges=[]
    for f in range(n):
        y=round(oy+f*h,4)
        for suffix,x,z in [('N',0,12),('S',0,-12),('C',0,0),('WL',-4,-10),('WU',-4,10),('EL',4,10),('EU',4,-10)]:
            nodes[f'{f}_{suffix}']=[ox+x,y,oz+z]
        for a,b in [('N','C'),('C','S'),('N','WU'),('S','WL'),('N','EL'),('S','EU')]:
            add_edge(edges,f'{f}_{a}',f'{f}_{b}','deck',2.5)
        if f<n-1:
            add_edge(edges,f'{f}_WL',f'{f+1}_WU','stair',2.6)
            add_edge(edges,f'{f}_EL',f'{f+1}_EU','stair',2.6)
    return {'nodes':nodes,'edges':edges,'origin':org,'storeys':n,'rise_m':h,'footprint_m':[16,28],
            'apertures_m':[[-5.5,-2.5,-10,10],[2.5,5.5,-10,10]]}
def l030():
    nodes={};edges=[]
    for row,z in [('low',-25),('far',42)]:
        for j in range(5):
            k=f'{row}_{j}';nodes[k]=[-66+33*j,12,z]
            if j>0:add_edge(edges,f'{row}_{j-1}',k,'bridge',2.2)
    for j in range(4):
        k=f'upper_{j}';nodes[k]=[-33+33*j,18,8.5]
        if j>0:add_edge(edges,f'upper_{j-1}',k,'bridge',3.1)
    for j,k in [(1,0),(4,3)]:
        add_edge(edges,f'low_{j}',f'upper_{k}','stair',3.4)
        add_edge(edges,f'far_{j}',f'upper_{k}','stair',3.4)
    return {'nodes':nodes,'edges':edges,'storeys':2,'top_y':18,
            'note':'Designed bridges are pale island shelves; reported dark false bridges are not asserted real.'}
def l022():
    nodes={'r0':[30,0,-47],'r1':[30,4,-18],
           's1':[35,4,-8],'s2':[35,8,22],
           'w2':[-30,8,6],'w3':[-30,12,44],
           'bridge2':[0,8,39],'bridge3':[0,12,44],
           'east3':[24,12,44], 'west2':[-30,8,39]}; e=[]
    for a,b,t in [('r0','r1','stair'),('r1','s1','deck'),('s1','s2','stair'),('s2','bridge2','deck'),('bridge2','west2','deck'),('west2','w2','deck'),('w2','w3','stair'),('w3','bridge3','deck'),('bridge3','east3','deck')]:
        add_edge(e,a,b,t,3.0)
    return {'nodes':nodes,'edges':e,'storeys':4,'top_y':12,'note':'Three repaired / new stair approaches have contiguous top landings.'}
def metrics(graph):
    ns=graph['nodes'];edges=graph['edges'];adj={n:set() for n in ns}
    for a,b,_,_ in edges:adj[a].add(b);adj[b].add(a)
    seen=set();stack=[next(iter(ns))]
    while stack:
        node=stack.pop()
        if node in seen:continue
        seen.add(node);stack.extend(adj[node]-seen)
    ys=[p[1] for p in ns.values()]
    return {'nodes':len(ns),'edges':len(edges),'cycle_rank':len(edges)-len(ns)+1,
            'vertical_span_m':round(max(ys)-min(ys),3),
            'stair_links':sum(e[2]=='stair' for e in edges),
            'graph_connected':len(seen)==len(ns)}
def main():
    entries={}
    for sid,(org,n,h,about) in TOWERS.items():
        o=tower_graph(org,n,h);o['description']=about;entries[sid]=o
    entries['L022']=l022();entries['L030']=l030()
    for sid,g in entries.items():g['metrics']=metrics(g)
    roster=R/'data/canon/levels.json';trans=R/'data/canon/transitions.json'
    out={'version':'1.5.0-dev15','provenance':'AUTHORED DESIGN GRAPH ONLY; NOT proof of physics, player traversal or Windows gameplay',
         'scene_geometries':entries,'canon_roster_sha256':hashlib.sha256(roster.read_bytes()).hexdigest(),
         'transitions_sha256':hashlib.sha256(trans.read_bytes()).hexdigest(),
         'manifests_sha256':{sid:hashlib.sha256((R/f'levels/{sid}/level.json').read_bytes()).hexdigest() for sid in entries}}
    p=R/'data/vertical_routes_dev15.json';p.write_text(json.dumps(out,indent=2,ensure_ascii=False)+'\n')
    for sid,graph in entries.items():print(sid,graph['metrics'])
if __name__=='__main__':main()
