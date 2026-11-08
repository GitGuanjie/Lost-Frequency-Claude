#!/usr/bin/env python3
"""DEV28 authored stories; stable GLB manifests grounded in bundled Wikidot text.
Only decorative geometry; existing exits and arrivals are untouchable.
"""
from pathlib import Path
import json, hashlib
ROOT=Path(__file__).resolve().parents[1]
# [site id, name, tint, ambient, cue positions/prompts/details/interaction mode, valid catalogue models]
SITES=[
 ('L015','Machine-city maintenance',[.38,.80,.94],'fluorescent_hum',
  [([0,0,-46],'Read the maintenance ledger','The desk is powered, but no responsible operator is listed.','inspect'),
   ([0,0,24],'Test the inactive relay','The local warning strip lights, while the larger machinery remains silent.','switch'),
   ([0,0,89],'Listen through the conduit','A distant repeated metallic rhythm does not seem to come from the same floor.','listen')],
  ['space-kit/machine-wireless','space-kit/desk-computer','prototype-kit/pipe-section']),
 ('L018','Preschool memories',[.95,.72,.43],'whisper',
  [([0,0,-23],'Examine the drawing','The artwork resembles a memory, but no child has signed it.','inspect'),
   ([0,0,0],'Turn the toy projector','Colours briefly brighten around the toys and slowly fade.','switch'),
   ([0,0,22],'Listen beside the bookcase','A reassuring voice dissolves before any words can be understood.','listen')],
  ['furniture-kit/books','furniture-kit/bookcaseopenlow','furniture-kit/chair']),
 ('L026','Adventure / SS Fun =)',[.59,1,.54],'creak',
  [([0,0,-32],'Check a cabin roster','The vessel name has been overwritten more than once.','inspect'),
   ([0,0,23],'Test the power circuit','The emergency strip responds despite the absence of a generator.','switch'),
   ([-7,4,21],'Listen above the deck','The sea and the distant party cannot be located in the same direction.','listen')],
  ['food-kit/soda-can','furniture-kit/chair','prototype-kit/pipe-section']),
 ('L031','Roller rink',[.96,.37,.74],'fluorescent_hum',
  [([-60,0,30],'Examine the rental counter','Pairs of skates are arranged, though very few people seem to use them.','inspect'),
   ([47,0,-9],'Switch the arcade overlook lights','Pink and blue lights change the gallery above the cabinet row.','switch'),
   ([0,0,18],'Listen at the rink centre','A familiar melody echoes long after the DJ has changed the track.','listen')],
  ['furniture-kit/chair','food-kit/soda-can','furniture-kit/bench']),
 ('L049','Flooded trench',[.48,.67,.89],'wind',
  [([0,-3,-84],'Read the wet route notes','A warning repeats the same instruction: remain below the parapet.','inspect'),
   ([0,-3,5],'Check a bunker signal','The emergency light works intermittently, as if it is responding to the weather.','switch'),
   ([0,-3,68],'Listen near the sandbags','The wind becomes distant; water can be heard beneath the earth.','listen')],
  ['prototype-kit/crate','mini-dungeon/barrel','graveyard-kit/debris-wood']),
 ('L055','Pit Stop restaurant',[1,.72,.41],'creak',
  [([0,0,-40],'Inspect the safe room','The table has been set even though no one is working here.','inspect'),
   ([0,0,21],'Try the empty switch','A small light warms the room without revealing the source of the sunlight.','switch'),
   ([0,0,56],'Listen beyond the booths','Floorboards creak in a room whose furniture no longer matches your memory.','listen')],
  ['food-kit/plate','food-kit/cup','furniture-kit/chair']),
 ('L079','Ghosts in the Machine',[.58,.93,.81],'fluorescent_hum',
  [([13,0,-37],'Read the office records','A burned document refers to the unfinished second phase of an experiment.','inspect'),
   ([-13,0,-21],'Test the equipment display','An unfamiliar machine briefly displays a status, then clears itself.','switch'),
   ([0,0,41],'Listen beside the time machine','The electrical sound resembles sobbing; the clocks do not agree.','listen')],
  ['furniture-kit/desk','furniture-kit/cabinetbed','space-kit/desk-computer']),
 ('L083','Submarine deep decks',[.53,.81,.95],'water_bed',
  [([0,0,-38],'Check the provision stores','The shelves remain stocked despite the crew having disappeared.','inspect'),
   ([0,4.2,18],'Adjust bridge observation lamps','The observation port glows, but its view seems impossibly deep.','switch'),
   ([0,0,50],'Listen against the pressure bulkhead','Three knocks can be distinguished from the ocean noise.','listen')],
  ['space-kit/machine-generator','space-kit/desk-computer','prototype-kit/pipe-section']),
 ('L090','Renovated house',[.93,.82,.64],'creak',
  [([0,0,-14],'Inspect the new paint','Every surface seems freshly renovated, yet the finish does not match.','inspect'),
   ([0,0,8],'Toggle the hallway lamp','The warm lamp reveals a different shadow pattern along the hallway.','switch'),
   ([0,4,20],'Listen above the attic floor','A faint noise comes from below the floor you are standing on.','listen')],
  ['furniture-kit/books','furniture-kit/lamproundfloor','furniture-kit/chairdesk'])]
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']
def build():
 sites=[]
 for sid,title,tint,sound,cues,assets in SITES:
  assert (ROOT/f'sources/wiki_text/{sid}.md').exists()
  out=[]
  for i,(coord,prompt,detail,kind) in enumerate(cues):
   props=[]
   for j,off in enumerate([(-2.2,-1.4),(2.15,-1.35),(2.1,1.7)]):
    pack,model=assets[(i+j)%3].split('/')
    path=f'assets/packs/{pack}/{model}.glb';assert path in CAT
    dims=CAT[path]['size']; h=.65 if kind=='listen' else .75
    max_d=max(.01,float(dims[0]),float(dims[2]))
    h=min(h,2.1*max(.18,float(dims[1]))/max_d)
    factor=min(8,h/max(.18,float(dims[1])))
    assert max_d*factor<2.4,path
    pos=[round(float(coord[0])+off[0],2),float(coord[1]),round(float(coord[2])+off[1],2)]
    props.append({'pack':pack,'model':model,'height':h,'pos':pos,'yaw':float(90*(i+j)%360),'solid':False})
   out.append({'id':f'{sid.lower()}_{i+1}', 'pos':coord,'prompt':prompt,'description':detail,'kind':kind,'props':props})
  sites.append({'id':sid,'title':title,'tint':tint,'sound':sound,'source':'ADAPTATION','cues':out})
 obj={'version':'dev28','canon_exits_modified':False,'sites':sites}
 out=ROOT/'data/dev28_story_rooms.json';out.write_text(json.dumps(obj,indent=2,ensure_ascii=False)+'\n')
 print('sites',len(sites),'cues',sum(len(s['cues']) for s in sites),'props',sum(len(c['props']) for s in sites for c in s['cues']))
 print('sha256',hashlib.sha256(out.read_bytes()).hexdigest())
if __name__=='__main__':build()
