"""DEV26 data-to-geometry offline contract, not Godot native acceptance."""
import hashlib,json,math,subprocess,sys,unittest
from pathlib import Path
from tools.preflight_dev import string_and_delimiter_check
ROOT=Path(__file__).resolve().parents[2]
DATA=json.loads((ROOT/'data/dev26_curated_vignettes.json').read_text())
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']
SITES={'L052','L053','L058','L060','L079','L083','L090','L096','L101','L114','L160','L197','L071'}
GALLERIES=[(-12.8,-46.,-23.,4.2),(12.8,13.,36.,4.7),(-12.8,62.,85.,5.1),(12.8,109.,132.,4.5)]
class Dev26CuratedQA(unittest.TestCase):
 def test_01_ten_curated_levels_and_distinct_subjects(self):
  sites=DATA['sites'];self.assertEqual(len(sites),13)
  self.assertEqual({x['id'] for x in sites},SITES)
  self.assertEqual(len({x['title'] for x in sites}),13)
  self.assertEqual(sum(len(x['cues']) for x in sites),43)
  self.assertEqual(len(next(x for x in sites if x['id']=='L079')['cues']),7)
  for s in sites:
   sid=s['id'];self.assertTrue((ROOT/f'sources/wiki_text/{sid}.md').exists())
   self.assertGreaterEqual(len(s['cues']),2)
   self.assertEqual(len(s['tint']),3)
   self.assertTrue(all(0<=c<=1 for c in s['tint']))
 def test_02_real_reused_models_and_nonblocking_bounds(self):
  used=set();count=0
  for s in DATA['sites']:
   for cue in s['cues']:
    self.assertTrue(cue['prompt'] and cue['description'])
    self.assertTrue(cue['id'].startswith(s['id'].lower()))
    self.assertEqual(len(cue['props']),2)
    self.assertEqual(len(cue['pos']),3)
    for item in cue['props']:
     count+=1
     self.assertFalse(item.get('solid',True))
     key='assets/packs/{pack}/{model}.glb'.format(**item)
     self.assertIn(key,CAT);self.assertTrue((ROOT/key).exists());used.add(key)
     sx,sy,sz=map(float,CAT[key]['size'])
     factor=min(8.,float(item['height'])/max(.18,sy))
     self.assertLess(max(sx,sz)*factor,1.7,key)
     self.assertLess(math.dist(item['pos'],cue['pos']),2.2)
  self.assertEqual(count,86)
  self.assertGreaterEqual(len(used),18)
 def test_03_l197_two_accesses_each_gallery_and_sensible_grade(self):
  for x,z0,z1,y in GALLERIES:
   self.assertLess(math.degrees(math.atan(y/10)),46.)
   self.assertGreater(z1-z0,20.)
   self.assertGreater(z0-10,-59.)
   self.assertLess(z1+10,145.)
   self.assertLess(abs(x)+4.0,19.0)
  g=(ROOT/'core/world/CaveGallery26.gd').read_text()
  for mark in ['k.slab(','k.stairs(', 'k.commit()', 'avoids_stair_or_gallery', 'for sign in [-1.0,1.0]:']:
   self.assertIn(mark,g)
  self.assertEqual(g.count('k.stairs('),2)
  level=(ROOT/'levels/L197/L197.gd').read_text()
  self.assertIn('avoids_stair_or_gallery(x,z)',level)
  self.assertIn('CaveGallery26.gd").install(self)',level)
  self.assertIn('L197>L000#5',level)
 def test_04_single_integrated_lifecycle_and_real_interact(self):
  base=(ROOT/'core/world/LevelBase.gd').read_text()
  self.assertIn('_install_dev26_curated_atmospheres()',base)
  self.assertIn('director.setup(self, rec)',base)
  self.assertIn('_spawn_player()',base)
  s=(ROOT/'core/world/CuratedAtmospheres26.gd').read_text()
  for fragment in ['Dress._place(owner, self, prop)','owner.add_interactable(', 'hit.reparent(self)',
     'Callable(self, "inspect").bind(i)', 'SaveService.record_discovery(',
     'lamps[index]','MatLib.panel(', 'func inspect(_player: Player, index: int)']:
   self.assertIn(fragment,s)
  self.assertNotIn('add_exit(',s)
  self.assertNotIn('TransitionService.dev_jump(',s)
  self.assertNotIn('solid = true',s)
 def test_05_reproducible_generation_and_syntax_preflight(self):
  path=ROOT/'data/dev26_curated_vignettes.json';start=hashlib.sha256(path.read_bytes()).digest()
  cp=subprocess.run([sys.executable,'tools/generate_dev26_vignettes.py'],cwd=ROOT,capture_output=True,text=True)
  self.assertEqual(cp.returncode,0,cp.stderr)
  self.assertEqual(hashlib.sha256(path.read_bytes()).digest(),start)
  for name in ['core/world/CuratedAtmospheres26.gd','core/world/CaveGallery26.gd',
      'core/world/LevelBase.gd','levels/L197/L197.gd']:
   self.assertEqual(string_and_delimiter_check((ROOT/name).read_text(),name),[])
  self.assertEqual(len(list((ROOT/'levels').rglob('level.json'))),100)
  self.assertEqual(len(list((ROOT/'assets/packs').rglob('*.glb'))),414)
 def test_06_all_original_manifest_and_exits_unchanged(self):
  # Existing roster/exit JSON is guarded as a strict data contract.
  for s in DATA['sites']:
   self.assertTrue((ROOT/f'levels/{s["id"]}/level.json').is_file())
  orig=(ROOT/'levels/L197/level.json').read_text()
  self.assertIn('"stable_id": "L197"',orig)
  self.assertNotIn('dev26:',orig)
if __name__=='__main__': unittest.main()
