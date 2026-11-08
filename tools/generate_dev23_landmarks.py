#!/usr/bin/env python3
"""Generate curated, reproducible DEV23 GLB dressing and landmark records.

Only visual GLB props are algorithmically placed; structural clearance is
reserved explicitly, and ALL traversable geometry is built by LandmarkSpurs.gd.
The generator records Wiki-inspired themes as original *adaptations*.
"""
from __future__ import annotations
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BASE=json.loads((ROOT/'data/dev22_narrative_districts.json').read_text())['districts']
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']

# Curated prop packs per established level identity; not copied from Wiki artwork.
POOLS={
 'keep_forge':[('mini-dungeon','column'),('mini-dungeon','barrel'),('mini-dungeon','wood-structure'),('mini-dungeon','chest'),('mini-dungeon','banner'),('mini-dungeon','pot'),('furniture-kit','radio'),('mini-dungeon','chair')],
 'canopy':[('graveyard-kit','lantern-glass'),('graveyard-kit','grave'),('graveyard-kit','debris'),('graveyard-kit','fence-damaged'),('nature-kit','rock-tallc'),('graveyard-kit','stone-wall-damaged'),('graveyard-kit','lightpost-single'),('nature-kit','rock-smallb')],
 'highway':[('city-kit-roads','road-sign-warning'),('city-kit-roads','sign-highway'),('city-kit-roads','construction-barrier'),('city-kit-roads','construction-cone'),('city-kit-roads','traffic-light'),('city-kit-roads','electricity-pole'),('prototype-kit','crate'),('city-kit-roads','construction-light')],
 'red_keep':[('mini-dungeon','banner'),('mini-dungeon','chest'),('mini-dungeon','column'),('mini-dungeon','wood-support'),('mini-dungeon','pot'),('graveyard-kit','stone-wall-damaged'),('graveyard-kit','lantern-glass'),('mini-dungeon','rocks')],
 'fog_trail':[('nature-kit','rock-tallc'),('nature-kit','rock-smallb'),('graveyard-kit','bench-damaged'),('graveyard-kit','shovel'),('graveyard-kit','debris-wood'),('graveyard-kit','lantern-glass'),('nature-kit','cliff-rock'),('mini-dungeon','barrel')],
 'shelter':[('furniture-kit','radio'),('furniture-kit','cardboardboxclosed'),('furniture-kit','bookcaseclosed'),('furniture-kit','lamproundfloor'),('furniture-kit','laptop'),('furniture-kit','bedbunk'),('furniture-kit','books'),('furniture-kit','cabinettelevision')],
 'toy_town':[('furniture-kit','chairrounded'),('furniture-kit','plantsmall1'),('furniture-kit','loungechair'),('furniture-kit','bench'),('mini-dungeon','column'),('furniture-kit','table'),('furniture-kit','books'),('furniture-kit','coatrackstanding')],
 'roots':[('nature-kit','rock-talle'),('nature-kit','cliff-half-rock'),('nature-kit','cliff-large-rock'),('graveyard-kit','stone-wall-damaged'),('nature-kit','rock-smalld'),('nature-kit','cliff-rock'),('graveyard-kit','debris-wood'),('nature-kit','rock-smallflata')],
 'attraction':[('city-kit-roads','construction-cone'),('furniture-kit','trashcan'),('food-kit','soda-bottle'),('food-kit','pizza-box'),('city-kit-roads','traffic-light'),('food-kit','fries-empty'),('city-kit-roads','construction-fence'),('furniture-kit','bench')],
 'neon':[('space-kit','desk-computer'),('space-kit','machine-generator'),('space-kit','machine-wireless'),('prototype-kit','lever-single'),('space-kit','pipe-ring'),('prototype-kit','shape-hollow-hexagon'),('space-kit','desk-computerscreen'),('space-kit','machine-barrel')],
}
STORIES={
 'keep_forge':('Stormstone lower forge and blue watch bridge','Beyond the keep, blue metalwork records the storm rather than stopping it.','Metal echoes from the abandoned forge.','pipe_clank',True),
 'canopy':('The suspended bone-canopy passage','A pale marker hangs where the canopy should open to the sky.','Wood creaks above the skeleton-dark forest.','creak',False),
 'highway':('Road signs above a buried service spur','Both service routes lead back to the same highway sign.','Wind rasps against an unpowered warning sign.','wind',True),
 'red_keep':('Crimson outworks and forgotten magazine','The red parapet conceals a return gallery.','A hollow knock answers from the red wall.','knock',True),
 'fog_trail':('The vanishing survey ridge','The ridge marker reappears on the wrong side of the mist.','A sudden gust muffles the distant route.','wind',False),
 'shelter':('Sealed upper residences and lower service room','The service-room lamp glows beneath empty rooms.','A pipe clicks within the supposedly sealed residence.','pipe_clank',True),
 'toy_town':('Mismatched scalehouse balconies','A tiny lamp throws the shadow of a huge window.','A toy-sized door creaks far below.','creak',False),
 'roots':('The fractured root span','A root arches above a fissure that has no visible bottom.','Roots scratch across unseen stone.','scratch',True),
 'attraction':('The closed ride queue and overhead arcade','The park lights still guide visitors around a ride that never starts.','An empty queue rail rattles in the distance.','creak',False),
 'neon':('The magenta relay deck','The far city changes color when the return bridge energizes.','A distant machine hums beneath the neon grid.','pipe_clank',True),
}

def footprint(model):
    pack,name=model
    path=f'assets/packs/{pack}/{name}.glb'
    if path not in CAT or not (ROOT/path).exists():
        raise ValueError(f'missing: {path}')
    dims=CAT[path]['size']
    # Match ModelDress exactly to keep decoration within the platform margin.
    sx,sy,sz=map(float,dims)
    # constrain apparent span to <=2m using ModelDress scaling contract
    h=min(1.70, 1.95*max(.18,sy)/max(.18,sx,sz))
    h=max(.24,h)
    factor=min(8.0,h/max(.18,sy))
    if max(sx,sz)*factor>2.25+1e-6:
        h*=2.25/(max(sx,sz)*factor)
    return round(h,4)

records=[]
for w in BASE:
    sid=w['id']; style=w['style']; x,y,z=map(float,w['origin'])
    title,discovery,amb,sound,lower=STORIES[style]
    # Hub + west high gallery + east high gallery (+optional buried/gallery tier).
    # 16 themed props; alternate corners without placing anything in a 3m travel lane.
    sites=['hub']*4+['west']*5+['east']*5+(['lower']*2 if lower else ['hub']*2)
    offsets=[(-4.5,5), (4.5,5), (-4.5,1.0), (4.5,1.0),
             (-4.55,-4.55),(4.55,-4.55),(-4.55,4.55),(4.55,4.55),(-4.55,-3.85),
             (4.55,-4.55),(-4.55,-4.55),(4.55,4.55),(-4.55,4.55),(4.55,3.85),
             (-4.5,-1.0),(4.5,-1.0)]
    props=[]
    for i,(site,(dx,dz)) in enumerate(zip(sites,offsets)):
        pack,name=POOLS[style][(i*3+(int(sid[-2:])%8))%len(POOLS[style])]
        props.append({'site':site,'dx':dx,'dz':dz,'pack':pack,'model':name,
                      'height':footprint((pack,name)),'yaw':(i*47+int(sid[-2:])*11)%360})
    records.append({'id':sid,'anchor':w['anchor'],'style':style,'title':title,
        'origin':[x,y,z],'rise':w['rise'],'lower':lower,'mat':w['mat'],
        'accent':w['accent'],'open_air':w['open_air'],
        'discovery':discovery,'ambient_caption':amb,'sound':sound,
        'props':props,'links':[
            ['old_vista','hub','walk'],['hub','west','stair'],['hub','east','stair']]+
            ([['hub','lower','stair']] if lower else [])+
            [['west','east','unlockable_bridge']],
        'node_positions':{'old_vista':[x+10.5,y,z-11],
           'hub':[x+10.5,y,z-19],
           'west':[x+10.5-14.5,y+w['rise'],z-45],
           'east':[x+10.5+14.5,y+w['rise'],z-45],
           **({'lower':[x+10.5-31.5,y-w['rise'],z-21]} if lower else {})}
    })
out={'schema':'lf.dev23.landmark_spurs.v1','version':'1.5.0-dev23',
   'source':'Prior dev22 curated themes and owned Kenney GLB resources; original gameplay adaptations',
   'sites':records}
path=ROOT/'data/dev23_landmark_spurs.json'
path.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
print('wrote',path,'sites',len(records),'lower galleries',sum(r['lower'] for r in records),
      'GLB recipes',sum(len(r['props']) for r in records),
      'unique assets',len({(p['pack'],p['model']) for r in records for p in r['props']}))
