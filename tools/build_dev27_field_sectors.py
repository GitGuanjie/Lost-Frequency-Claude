#!/usr/bin/env python3
"""Deterministic, provenance-aware field-sector blueprints for DEV27.

Only selects real models from the existing CC0 inventory; never rewrites level
manifests, exit targets, arrivals, or their review status.
"""
import json, random, math, pathlib
ROOT=pathlib.Path(__file__).resolve().parents[1]
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']
SITES=[
 # level, theme, title, location, half lengths, materials, tint, props, ambient, survey
 ('L016','canopy','Twilight Canopy Observatory',(-18,-16),(15,11),('l16_wood','l16_leaf'),(.50,.80,.57), ['nature-kit','graveyard-kit'], 'wind', 'The sunrise seems unchanged on both sides of the weather boundary.'),
 ('L024','mine','PlasticWorks Service Spines',(46,32),(12,16),('l24_steel','l24_plastic'),(.39,.75,.95), ['prototype-kit','space-kit','city-kit-roads'], 'room_tone','An unfinished conveyor runs into the unpainted horizon.'),
 ('L029','harbor','Hyperian Weathered Harbour',(-56,-45),(14,12),('l29_wood','l29_rock'),(.88,.70,.48),['mini-dungeon','food-kit','nature-kit'], 'wind','The wooden walkways face a sea that never approaches.'),
 ('L077','pasture','Pasture Listening Walk',(-40,68),(16,11),('d7_farm','d7_pasture'),(.55,.74,.38),['nature-kit','graveyard-kit','city-kit-suburban'], 'wind','The distant tree line feels much closer from above.'),
 ('L140','sunflower','Honey Field Observatory',(130,-130),(11,14),('l140_house','l140_grass'),(1,.79,.22),['nature-kit','food-kit','furniture-kit'], 'crickets','A seam in the sunflowers reveals the wrong direction of the wind.'),
 ('L737','ruins','Golden Ruins Traversal',(-90,-18),(14,16),('d7_ruin','d7_dune'),(.98,.78,.32),['mini-dungeon','nature-kit','graveyard-kit'], 'wind','The ruin stone is cooler than the gold dust around it.'),
 ('L899','settlement','Yonder Spring Garden Walk',(-50,0),(12,12),('d7_hut','d7_mushroom'),(.76,.66,.93),['furniture-kit','food-kit','nature-kit'], '', 'At the settlement, time seems to stay at nine in the morning.'),
 ('L998','stormfront','Three-Cloud Weather Observatory',(-55,-15),(16,14),('d7_office','d7_greycloud'),(.70,.78,.86),['prototype-kit','city-kit-roads','space-kit'], 'wind','The white and grey strata disagree about how close the storm is.'),
]
# Curated mini-props, chosen for landmark cohesion and acceptable normalized size.
# Optional above-ground exploration branches. Their ends have their own physical
# floor and are generated with the SAME blueprint as the audited route graph.
SPURS={
 'L016':[('nw','west',8.0),('se','east',7.0),('ne','north',9.0)],
 'L024':[('nw','north',8.0),('sw','west',7.0)],
 'L029':[('sw','south',7.0),('ne','east',9.0),('nw','north',8.0)],
 'L077':[('ne','east',8.0),('nw','north',9.0)],
 'L140':[('sw','west',7.0)],
 'L737':[('ne','east',10.0),('se','south',8.0),('nw','north',7.0)],
 'L899':[('nw','west',7.0),('sw','south',8.0)],
 'L998':[('se','east',9.0),('ne','north',7.0)],
}
MODEL_POOL={
 'nature-kit':['rock-smalla','rock-smallb','rock-smallc','rock-smalld','cliff-rock','cliff-top-rock'],
 'graveyard-kit':['lantern-glass','debris-wood','bench-damaged','shovel','debris'],
 'prototype-kit':['crate','pipe-corner','pipe-half-section','lever-single','column-low','column-triangle-low'],
 'space-kit':['barrel','barrels','desk-computerscreen','desk-chair','desk-computer'],
 'city-kit-roads':['construction-cone','construction-barrier','road-sign-warning','construction-light','dumpster'],
 'city-kit-suburban':['planter','path-stones-messy','fence-low'],
 'mini-dungeon':['barrel','pot','rocks','stones','chest','coin','column'],
 'food-kit':['barrel','bag','carton','glass','mug','bowl','cup'],
 'furniture-kit':['cardboardboxclosed','cardboardboxopen','books','bench','chair','planter'],
}
# No speculative geography or Wiki claims: purely new gameplay adaptations.
out=[]
for sid,style,title,anchor,half,mats,tint,packs,sound,caption in SITES:
    rng=random.Random(2700+int(sid[1:]))
    hx,hz=half
    upper=[(-hx,-hz),(hx,-hz),(hx,hz),(-hx,hz)]
    props=[]
    candidates=[]
    for pack in packs:
        for model in MODEL_POOL[pack]:
            path=f'assets/packs/{pack}/{model}.glb'
            if path not in CAT:continue
            dims=CAT[path]['size']
            # Fit in corner footprint after applying the same cap as ModelDress.
            h=.80
            f=min(8.,h/max(.18,float(dims[1])))
            if max(float(dims[0]),float(dims[2]))*f>1.75:continue
            candidates.append((pack,model))
    if len(candidates)<5:raise ValueError((sid,candidates))
    # 3 compact props per upper station (at outer corner positions; leave centre and bridge clear).
    offsets=[(-2.45,-2.45),(2.45,-2.45),(-2.45,2.45),(2.45,2.45)]
    for i,(x,z) in enumerate(upper):
        selected=[offsets[j] for j in range(4) if j!=(i%4)]
        for j,(dx,dz) in enumerate(selected):
            pack,model=candidates[rng.randrange(len(candidates))]
            props.append({'pack':pack,'model':model,'pos':[round(x+dx,3),3.60,round(z+dz,3)],'height':round(rng.uniform(.55,.85),2),'yaw':float(rng.randrange(0,4)*90)})
    # Ground investigation area: only outer periphery, never main stairs or ring centre.
    ground=[(-hx-6,0),(hx+6,0),(0,-hz-7),(0,hz+7),(-hx-7,-hz-2),(hx+7,hz+2),(-hx-7,hz+2),(hx+7,-hz-2),(-hx-6,7),(hx+6,-7),(hx+6,7),(-hx-6,-7)]
    for j,(x,z) in enumerate(ground):
        pack,model=candidates[rng.randrange(len(candidates))]
        props.append({'pack':pack,'model':model,'pos':[float(x),0.,float(z)],'height':round(rng.uniform(.55,.90),2),'yaw':float(rng.randrange(0,8)*45)})
    spurs=[]
    base={'sw':(-hx,-hz),'se':(hx,-hz),'ne':(hx,hz),'nw':(-hx,hz)}
    steps={'north':(0,1),'south':(0,-1),'east':(1,0),'west':(-1,0)}
    for idx,(from_node,direction,gap) in enumerate(SPURS[sid]):
        x,z=base[from_node]
        dx,dz=steps[direction]
        dist=3.55+float(gap)+2.75
        center=(round(x+dx*dist,3),round(z+dz*dist,3))
        spurs.append({'id':f'spur{idx}','from':from_node,'direction':direction,'gap':gap,'pos':[center[0],3.60,center[1]]})
        for offx,offz in [(-1.9,-1.9),(1.9,1.9)]:
            pack,model=candidates[rng.randrange(len(candidates))]
            props.append({'pack':pack,'model':model,'pos':[center[0]+offx,3.6,center[1]+offz],
                          'height':round(rng.uniform(.5,.72),2),'yaw':float(rng.randrange(0,4)*90)})
    links=[['ground','sw_foot','ground'],['ground','ne_foot','ground'],['sw_foot','sw','stair'],['ne_foot','ne','stair'],['sw','south_mid','walk'],['south_mid','se','walk'],['se','ne','walk'],['ne','north_mid','walk'],['north_mid','nw','walk'],['nw','sw','walk'],['north_mid','south_mid','optional']]
    # Additional physically modelled side branches, no fabricated travel destinations.
    for spur in spurs:
        links.append([spur['from'],spur['id'],'walk'])
    rec={'id':sid,'style':style,'title':title,'anchor':[float(anchor[0]),float(anchor[1])],'half':[hx,hz],
         'floor':mats[0],'accent':mats[1],'tint':list(tint),'sound':sound,'observation':caption,
         'points':{'ground':[0,0,0],'sw_foot':[-hx,0,-hz-12],'ne_foot':[hx,0,hz+12],
             'sw':[-hx,3.6,-hz],'se':[hx,3.6,-hz],'ne':[hx,3.6,hz],'nw':[-hx,3.6,hz],
             'north_mid':[0,3.6,hz],'south_mid':[0,3.6,-hz]},
         'links':links,'spurs':spurs,'props':props,'canonical_exits_unchanged':True,'source':'ADAPTATION'}
    out.append(rec)
obj={'version':'dev27.1','description':'optional physical exploration sectors, no exit changes',
     'sites':out,'static_only_note':'Real Godot F3 and physics acceptance required'}
path=ROOT/'data/dev27_field_sectors.json'
path.write_text(json.dumps(obj,indent=2,ensure_ascii=False)+'\n')
print('sites',len(out),'props',sum(len(x['props']) for x in out),'assets',len({(p['pack'],p['model']) for s in out for p in s['props']}),'bytes',path.stat().st_size)
