#!/usr/bin/env python3
"""DEV26 reproducible, bounded, wiki-themed vignettes for existing static levels.
No source manifest, exit, or player spawn modification.
"""
from __future__ import annotations
from pathlib import Path
import json, hashlib
R=Path(__file__).resolve().parents[1]
# x, floor y, z ; all near existing constructed floors, never invented entrances
SITES={
'L060':('The Baywalk - unfinished lower path','l60_rust',[0.97,0.73,0.41],
 [(6,0,37),(6,0,137),(6,0,235)],
 [('Check the dry equipment','You notice that the equipment is dry despite the sea air.'),('Inspect the stairway lamp','One functioning lamp marks the stairs to a far more dangerous path.'),('Examine a storm-stained warning','No wall protects the lower path from the changing sea.')],
 [('city-kit-roads','construction-cone'),('city-kit-roads','construction-light'),('prototype-kit','crate'),('city-kit-roads','construction-barrier')]),
'L079':('Ghosts in the Machine - clinic','l79_metal',[0.57,0.91,0.81],
 [(13.2,0,-37),(-13.2,0,-21),(13.2,0,-5),(-13.2,0,11),(13.2,0,27),(-13.2,0,43),(2.8,0,49)],
 [('Inspect the office records','A note mentions an experiment moved to its next phase.'),('Inspect the equipment store','The dial of a medical instrument has no recognizable scale.'),('Examine the treatment room','The bed is made, but an object has left an imprint in the linen.'),('Read the sealed research sheet','The recorded time disagrees with the corridor clock.'),('Listen to the next room','A rhythm seems to come from within the walls.'),('Inspect the empty cabinet','The contents of this drawer have been carefully removed.'),('Inspect the central machine','The machine reports a value that nobody wrote down.')],
 [('furniture-kit','computerscreen'),('furniture-kit','desk'),('prototype-kit','pipe-section'),('furniture-kit','cabinetbed')]),
'L083':('The Sunken Submarine - sealed decks','l83_metal',[0.56,0.83,0.96],
 [(-4.6,0,-53),(4.5,4.2,27),(-4.6,0,55)],
 [('Inspect the store inventory','The log records provisions where no recent crew have been seen.'),('Examine the bridge panel','A faint reflection passes behind the submerged viewport.'),('Read the hatch checklist','The escape hatch must remain available; the checklist is incomplete.')],
 [('space-kit','desk-computer'),('space-kit','barrel'),('space-kit','machine-wireless'),('space-kit','machine-generator')]),
'L090':('Newly Renovated Home - domestic anomalies','l90_floor',[1.0,0.79,0.54],
 [(-5.5,0,-13),(5.5,4.0,8),(5.5,0,41)],
 [('Look at the changed furniture','There are no fingerprints on a piece of furniture you remember moving.'),('Inspect the upstairs frame','The new paint has dried, but the same damp patch remains.'),('Observe the old oak','The air is still, even around the oldest branches.')],
 [('furniture-kit','books'),('furniture-kit','chair'),('furniture-kit','cardboardboxclosed'),('furniture-kit','bench')]),
'L096':('Solace - quiet house','d6_porcelain',[0.96,0.90,0.78],
 [(-4.5,6.1,4),(4.5,6.1,-3),(7,6.1,7)],
 [('Inspect a porcelain pitcher','Dust rests on the rim; nobody demands that you clean it.'),('Observe the clean windowsill','For a moment, the mountains seem farther away.'),('Notice the silence','There is no task here except the one you choose for yourself.')],
 [('food-kit','cup-tea'),('food-kit','bowl'),('furniture-kit','books'),('food-kit','plate-dinner')]),
'L101':('The Nearly Familiar Home - missing details','d7_furniture',[0.89,0.68,0.49],
 [(-4.2,0,-25),(4.2,0,4),(-4.2,0,24)],
 [('Examine the misplaced book','The cover is right, but the last page is empty.'),('Inspect the empty coat rack','The rack holds a shadow without a coat.'),('Look at the familiar cup','The cup is still warm. You cannot recall using it.')],
 [('furniture-kit','books'),('furniture-kit','coatrackstanding'),('food-kit','cup-tea'),('furniture-kit','chair')]),
'L114':('Childhood Bedroom - small remembered objects','l114_blue',[0.54,0.72,0.96],
 [(4.5,0,-4),(4.5,0,3)],
 [('Look at an old notebook','The handwriting is recognizable; the event described is not.'),('Check the lamplight','The room seems smaller when you look toward the void.')],
 [('furniture-kit','books'),('furniture-kit','chair'),('furniture-kit','cardboardboxclosed')]),
'L160':('The Pact - uncertain testimony','d7_light',[0.74,0.48,0.95],
 [(-4.8,0,-42),(4.8,0,0),(-4.8,0,42)],
 [('Listen under the first arch','The voice changes the terms of its own promise.'),('Study the reflection','The surface repeats your movement a moment too late.'),('Listen at the last pillar','The promise no longer has a speaker.')],
 [('prototype-kit','column-rounded'),('prototype-kit','shape-hollow-hexagon'),('mini-dungeon','column'),('prototype-kit','column-triangle')]),
'L197':('Crystal Caverns - four distinct mineral galleries','l197_rock',[0.41,0.93,0.90],
 [(-12.8,4.2,-28),(12.8,4.7,31),(-12.8,5.1,75),(12.8,4.5,121)],
 [('Observe turquoise resonance','The mineral light is steady and the water sounds far below.'),('Observe amethyst layering','The violet fragments change how deep the gallery appears.'),('Inspect a ruby fault','The red veins remain strikingly visible in the darkness.'),('Observe the onyx edge','Even the last glint seems to be swallowed by the stone.')],
 [('nature-kit','rock-smalla'),('nature-kit','rock-smallb'),('nature-kit','rock-tallc'),('nature-kit','rock-smallc')]),
'L071':('Void Basement - corrupted storage rows','l71_pipe',[0.64,0.72,0.82],
 [(-18,-0.1,-45),(18,-0.1,10),(-18,-0.1,60)],
 [('Examine a corrupted file','An entire row of recorded locations has been erased.'),('Listen to the pipework','A signal passes through pipes that do not appear connected.'),('Inspect a sealed crate','The crate label is unreadable, except for the number 0071.')],
 [('prototype-kit','crate'),('furniture-kit','cardboardboxclosed'),('space-kit','barrel'),('graveyard-kit','debris')]),
'L052':('DESTINATION REACHED - old cave markings','d7_limestone',[0.76,0.66,0.47],
 [(-18,0,-30),(18,0,-2),(-18,0,37)],
 [('Study the first cave marks','The marks overlap the older limestone scratches.'),('Examine the abandoned rock pile','There are traces of work, but no signed route onward.'),('Read the faded charcoal lines','The message is incomplete and the campfire has long gone cold.')],
 [('nature-kit','rock-smalla'),('mini-dungeon','stones'),('nature-kit','rock-smallb'),('graveyard-kit','debris')]),
'L053':('Alone - the looping suburban house','l53_wood',[0.90,0.78,0.56],
 [(-5,0,-17),(5,0,3),(-5,0,16)],
 [('Observe the front-door memory','The angle of the entrance seems familiar even after the house loops.'),('Inspect the kitchen counter','A place setting has been prepared, but there is no guest.'),('Examine a folded note','The note mentions a red door without explaining where it leads.')],
 [('furniture-kit','chair'),('food-kit','cup-tea'),('furniture-kit','books'),('furniture-kit','cardboardboxclosed')]),
'L058':('Water Wonder - empty pools and dark storerooms','l58_tile',[0.29,0.72,0.89],
 [(-34,0,-30),(30,0,-5),(-8,0,87)],
 [('Inspect the pool edge','The turquoise tiles are dry; no one has been swimming here.'),('Study the abandoned walkway','The plastic-blue ground gives no hint of ordinary grass.'),('Examine the storage label','The label is damaged and the slide machinery is quiet.')],
 [('food-kit','soda-can'),('city-kit-roads','construction-cone'),('space-kit','barrel'),('food-kit','plate-broken')]),

}
cat=json.loads((R/'assets/packs/catalog.json').read_text())['models']
result={'version':26,'source':'ADAPTATION','sites':[]}
for sid,(title,mat,glow,anchors,words,props) in SITES.items():
 cues=[]
 for i, (xyz, (prompt,description)) in enumerate(zip(anchors,words)):
  # Two deterministic, small, off-route props per observation. These have no collisions.
  deco=[]
  for j in range(2):
   pack,model=props[(i+j*2)%len(props)]
   key=f'assets/packs/{pack}/{model}.glb'
   assert key in cat,key
   x,y,z=xyz
   offset=(-0.92 if i%2 else 0.92) * (1 if j==0 else -1)
   # This size cap prevents the off-route GLB becoming a full-sized blocking structure.
   target_height=round(.52 + (i+j)%3*.14,2)
   size=cat[key]['size'];ratio=max(size[0],size[2])/max(.18,size[1])
   target_height=round(min(target_height,1.48/max(.01,ratio)),3)
   factor=min(8.,target_height/max(.18,size[1]))
   assert max(size[0],size[2])*factor<1.7,key
   deco.append({'pack':pack,'model':model,'height':target_height,'pos':[round(x+offset,2),round(y,2),round(z+(1.05 if j==1 else -.85),2)],'solid':False})
  cues.append({'id':f'{sid.lower()}_{i+1}', 'pos':list(xyz), 'prompt':prompt,'description':description,'props':deco})
 result['sites'].append({'id':sid,'title':title,'accent':mat,'tint':glow,'cues':cues})
p=R/'data/dev26_curated_vignettes.json';p.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print('generated',p,len(result['sites']),'levels',sum(map(lambda x:len(x['cues']),result['sites'])),'cues',sum(len(c['props']) for s in result['sites'] for c in s['cues']),'GLB instances')
