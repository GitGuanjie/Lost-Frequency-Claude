#!/usr/bin/env python3
"""Deterministic authored palettes + blueprint-scoped model placement for dev21.
Every selected asset must exist in the project's catalog; positioning uses only
occupied tier cells and reserves the central 2.8m circulation lane.
"""
import json, hashlib, pathlib
ROOT=pathlib.Path(__file__).resolve().parents[1]
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']
BLUE=json.loads((ROOT/'data/dev20_atrium_blueprints.json').read_text())
# Packs are selected per the locally archived wiki descriptions, not at random.
PALETTES={
'L028':('Stormstone Keep: forge scraps, storerooms and impossible domestic details', [('mini-dungeon','column'),('mini-dungeon','barrel'),('mini-dungeon','chest'),('mini-dungeon','banner'),('graveyard-kit','lantern-glass'),('furniture-kit','books'),('furniture-kit','table'),('mini-dungeon','pot'),('mini-dungeon','wood-structure'),('furniture-kit','bookcaseclosed'),('furniture-kit','radio')], 'The blue light outside the keep has not reached these objects.'),
'L032':('Forest of the Skeleton Queen: bleached stone, memorials, hanging relics', [('graveyard-kit','grave'),('graveyard-kit','lantern-glass'),('graveyard-kit','debris-wood'),('graveyard-kit','bench-damaged'),('nature-kit','rock-tallc'),('nature-kit','rock-smalla'),('mini-dungeon','pot'),('graveyard-kit','lightpost-single'),('nature-kit','rock-talld'),('mini-dungeon','stones')], 'Something pale catches the moonlight between the trunks.'),
'L050':('Moribund Highway: derelict roadside maintenance and abandoned supplies', [('city-kit-roads','construction-cone'),('city-kit-roads','road-sign-warning'),('city-kit-roads','construction-light'),('city-kit-roads','dumpster'),('prototype-kit','crate'),('prototype-kit','pipe-section'),('city-kit-roads','construction-barrier'),('city-kit-roads','electricity-pole'),('city-kit-roads','sign-highway'),('prototype-kit','pipe-split')], 'The roadside supplies look recently rearranged, but the road is empty.'),
'L073':('Redlands: defensive ruined castle, crimson-worn gear and remnants', [('mini-dungeon','column'),('mini-dungeon','banner'),('mini-dungeon','chest'),('graveyard-kit','iron-fence-damaged'),('graveyard-kit','lantern-glass'),('mini-dungeon','barrel'),('mini-dungeon','rocks'),('mini-dungeon','gate'),('graveyard-kit','crypt-door'),('mini-dungeon','wood-support')], 'The scattered equipment suggests that this position once had a purpose.'),
'L077':('Oh Shenandoah: mist, weathered trail markers and deserted overlook', [('nature-kit','rock-smalla'),('nature-kit','rock-tallc'),('graveyard-kit','bench-damaged'),('graveyard-kit','lantern-glass'),('graveyard-kit','debris-wood'),('city-kit-roads','road-sign-warning'),('mini-dungeon','barrel'),('graveyard-kit','shovel'),('nature-kit','rock-smallb'),('city-kit-roads','sign-highway')], 'The same shape emerges again from the fog at a different height.'),
'L085':('Brilliant Evermore: immaculate interiors, false food, polluted exterior', [('furniture-kit','chair'),('furniture-kit','books'),('furniture-kit','bookcaseopen'),('furniture-kit','table'),('furniture-kit','cardboardboxopen'),('food-kit','cup-coffee'),('food-kit','plate-broken'),('furniture-kit','desk'),('furniture-kit','radio'),('furniture-kit','televisionmodern'),('furniture-kit','loungesofa')], 'Everything seems deliberately stocked, but some food is only an imitation.'),
'L094':('Motion: strange manufactured town and mis-scaled toy-like interiors', [('furniture-kit','chair'),('furniture-kit','table'),('furniture-kit','books'),('city-kit-suburban','planter'),('prototype-kit','crate'),('food-kit','cup'),('mini-dungeon','column'),('furniture-kit','ruground'),('furniture-kit','plantsmall1'),('furniture-kit','chairrounded')], 'The object is familiar, but its proportions seem oddly deliberate.'),
'L108':('Fertile Grounds: Craterwood debris, ancient stone and uncanny growth', [('nature-kit','rock-smalla'),('nature-kit','rock-smallb'),('nature-kit','rock-tallc'),('nature-kit','cliff-rock'),('graveyard-kit','debris-wood'),('mini-dungeon','pot'),('graveyard-kit','lantern-glass'),('nature-kit','rock-talle'),('nature-kit','cliff-half-rock'),('graveyard-kit','stone-wall-damaged')], 'The growth patterns give an impression of a path that was never built.'),
'L320':('Entertainland: abandoned attraction equipment, stalls and concessions', [('food-kit','pizza-box'),('food-kit','cup-saucer'),('city-kit-roads','construction-light'),('city-kit-roads','construction-cone'),('furniture-kit','chair'),('prototype-kit','crate'),('food-kit','soda-can-crushed'),('furniture-kit','table'),('food-kit','soda-bottle'),('furniture-kit','trashcan'),('prototype-kit','lever-double')], 'An attraction seems ready to reopen, but no operator is present.'),
'L808':('Synthwave World: luminous utility equipment and polygonal city remnants', [('space-kit','desk-computer'),('space-kit','barrel'),('space-kit','machine-generatorlarge'),('space-kit','pipe-open'),('prototype-kit','lever-single'),('city-kit-roads','light-square'),('space-kit','desk-chair'),('space-kit','desk-computerscreen'),('space-kit','machine-wireless'),('space-kit','satellitedish')], 'A soft electrical pulse crosses the surface without an obvious source.'),
}
# Three site-specific observations per site, tier 0/1/2. Fictional game adaptation.
SOUNDS={'L028':'wind','L032':'creak','L050':'knock','L073':'pipe_clank',
    'L077':'wind','L085':'creak','L094':'knock','L108':'scratch','L320':'creak','L808':'pipe_clank'}
STATIONS={
'L028':['Read the rusted forge inventory','Trace the blue-lit stone joint','Examine the upper keep watchpoint'],
'L032':['Listen for clattering branches','Study a pale trunk marker','Look across the moonlit canopy'],
'L050':['Inspect the derelict roadside beacon','Align the maintenance reflectors','Observe the highway from above'],
'L073':['Inspect the broken boundary standard','Check a sheltered battlement marker','Survey the redland approach'],
'L077':['Trace the old fogbound trail','Set a second mist landmark','Find the return line through the haze'],
'L085':['Test the air-filtration indicator','Inspect the unnaturally neat storeroom','Retune the upper ventilation light'],
'L094':['Examine a strangely scaled fixture','Trace the repeating painted motif','Align the rooftop perspective'],
'L108':['Read the growth-ring marker','Observe the fractured canopy','Find the higher forest boundary'],
'L320':['Inspect a deserted attraction panel','Test the silent sign lights','Trace the park overview route'],
'L808':['Tune a neon wayfinding signal','Inspect the geometric pulse','Synchronize the highest light marker'],
}

def candidate_cells(wing, tier):
 cells={tuple(c) for c in wing['floors'][tier]['cells']}
 # exclude passage edges near entrance, active controls and shutter position
 forbidden={(0,1),(3,1),(0,0),(4,3),(2,0),(4,2)}
 # Select corner-adjacent props in 13 cells per tier, no full-footprint meshes
 ordered=sorted(cells, key=lambda p: hashlib.sha256(f"dev21:{wing['id']}:{tier}:{p}".encode()).digest())
 return [p for p in ordered if p not in forbidden][:11]

def main():
 out={'schema':1,'version':'dev21','status':'PROCEDURAL_DRESSING_UNVERIFIED_IN_ENGINE',
      'source':'Local archived Wikidot level texts; in-game vignettes are clearly adaptations', 'wings':[]}
 for wing in BLUE['wings']:
  id=wing['id']; title,palette,observation=PALETTES[id]
  objects=[]
  for tier in range(3):
   for idx,(c,r) in enumerate(candidate_cells(wing,tier)):
    p,m=palette[(idx+tier*5+c*2+3*r)%len(palette)]
    key=f'assets/packs/{p}/{m}.glb'
    if key not in CAT: raise ValueError((id,key))
    size=CAT[key]['size']
    # Outdoor platform is only 5.14m wide; indoor tile is 7m wide.
    # Leave the centre 2.8m route empty, AND keep each full model footprint
    # inside the REAL slab (the previous 2.42m offsets could hang into void).
    footprint=0.84 if wing['open_air'] else 1.65
    scale=min(6.0, footprint/max(size[0],size[2],.01), 2.0/max(size[1],.01))
    height=round(max(.18,size[1])*scale, 4)
    # +/- 2.37m corner anchors, leaving >= 1.5m centre clearance.
    # Old DEV20 procedural pillars occupy the south-west (-x,-z) corner;
    # use only the other three corners to avoid visual intersections.
    off=2.04 if wing['open_air'] else 2.42
    corners=[(off,-off),(-off,off),(off,off)]
    xoff,zoff=corners[(idx+tier+c)%3]
    obj={'tier':tier,'cell':[c,r],'pack':p,'model':m,'height':height,
         'offset':[xoff,zoff],'yaw':(idx*71+tier*53+c*17+r*11)%360}
    # Only 1 room prop per storey has a readable examine interaction.
    if idx==5:
     obj['inspect']=observation
     obj['prompt']='Inspect the unusual object'
    objects.append(obj)
  origin=wing['origin'];rise=wing['rise'];x0=origin[0]+32.5;z0=origin[2]-14.0
  ambience=[]
  for tier,c,r in [(0,1,2),(2,3,2)]:
   ambience.append({'id':f'dev21:{id}:scene:{tier}',
    'pos':[round(x0+(c+.5)*7,2), round(origin[1]+(tier+1)*rise+1.1,2), round(z0+(r+.5)*7,2)],
    'radius':4.5,'height':2.0,'caption':observation if tier==0 else STATIONS[id][2]+'.',
    'sound':SOUNDS[id], 'source':'ADAPTATION'})
  out['wings'].append({'id':id,'anchor':wing['anchor'],'title':title,'models':objects,
      'ambience':ambience, 'station_prompts':STATIONS[id],
      'station_reports':[observation,'The level looks different from the next height.',
                        'A return path is now easier to distinguish from above.']})
 path=ROOT/'data/dev21_wing_scenarios.json'
 path.write_text(json.dumps(out,indent=2,ensure_ascii=False)+'\n')
 print(path, len(out['wings']), sum(len(w['models']) for w in out['wings']), 'model placements')

if __name__=='__main__': main()
