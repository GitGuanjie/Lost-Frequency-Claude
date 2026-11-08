"""DEV28 structural/asset/canon checks; NOT substitute for native Godot QA."""
import hashlib,json,math,subprocess,sys,unittest,zipfile
from pathlib import Path
from tools.preflight_dev import string_and_delimiter_check
ROOT=Path(__file__).resolve().parents[2]
DATA=json.loads((ROOT/'data/dev28_story_rooms.json').read_text())
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']
SITES={'L015','L018','L026','L031','L049','L055','L079','L083','L090'}
PREV=Path('/mnt/data/LostFrequency_v1.5.0-dev27_SOURCE.zip')

class Dev28QATest(unittest.TestCase):
 def test_01_unique_narrative_scenarios_with_specific_models(self):
  sites=DATA['sites'];self.assertEqual(len(sites),9)
  self.assertEqual({s['id'] for s in sites},SITES)
  self.assertFalse(DATA['canon_exits_modified'])
  identities=[]; props=[]
  for site in sites:
   self.assertEqual(len(site['cues']),3)
   self.assertTrue((ROOT/f'sources/wiki_text/{site["id"]}.md').is_file())
   self.assertEqual([cue['kind'] for cue in site['cues']],['inspect','switch','listen'])
   for cue in site['cues']:
    identities.append(cue['id']);self.assertGreater(len(cue['description']),45)
    self.assertEqual(len(cue['props']),3)
    for p in cue['props']:
     key=f'assets/packs/{p["pack"]}/{p["model"]}.glb'
     self.assertIn(key,CAT)
     self.assertTrue((ROOT/key).is_file())
     self.assertFalse(p['solid'])
     f=min(8,float(p['height'])/max(.18,float(CAT[key]['size'][1])))
     self.assertLess(max(float(v) for v in (CAT[key]['size'][0],CAT[key]['size'][2]))*f,2.4)
     props.append(key)
  self.assertEqual(len(set(identities)),27)
  self.assertEqual(len(props),81)
  self.assertGreaterEqual(len(set(props)),18)

 def test_02_gameplay_has_physical_second_route_and_no_exit_edits(self):
  ship=(ROOT/'levels/L026/L026.gd').read_text()
  rink=(ROOT/'levels/L031/L031.gd').read_text()
  clinic=(ROOT/'levels/L079/L079.gd').read_text()
  self.assertIn('DEV28: a second, independent way up',ship)
  self.assertIn('k.stairs(Vector3(0,0.05,40.0), Vector3.BACK',ship)
  self.assertIn('k.slab(-3.2,59.6,3.2,67.6,4.0',ship)
  self.assertIn('k.slab(43.75,z-2.3,45.25,z+2.3',rink)
  self.assertIn('k.stairs(Vector3(47.5,.05,-44.0)',rink)
  self.assertIn('k.stairs(Vector3(47.5,.05,44.0)',rink)
  self.assertIn('k.slab(45.7,-29.5,49.3,29.5,4.2',rink)
  self.assertIn('for i in 16:',clinic)
  self.assertIn('SaveService.record_discovery(stable_id,"dev28:sixteen_clocks"',clinic)
  self.assertEqual(len(list((ROOT/'levels').glob('*/level.json'))),100)
  if PREV.is_file():
   with zipfile.ZipFile(PREV) as z:
    for sid in SITES:
     name=f'3/levels/{sid}/level.json'
     self.assertEqual(z.read(name),(ROOT/name.removeprefix('3/')).read_bytes())
    self.assertEqual(z.read('3/docs/canon/LEVEL_100_MATRIX.csv'),(ROOT/'docs/canon/LEVEL_100_MATRIX.csv').read_bytes())

 def test_03_submarine_independent_stairways_and_two_ceiling_cutouts(self):
  sub=(ROOT/'levels/L083/L083.gd').read_text()
  self.assertIn('k.stairs(Vector3(-1.6, 0, -3)',sub)
  self.assertIn('k.stairs(Vector3(0, 0, 40)',sub)
  self.assertIn('k.slab(-7, 38.5, -1.65, 51.5',sub)
  self.assertIn('k.slab(1.65, 38.5, 7, 51.5',sub)
  self.assertIn('for xside in [-4.325,4.325]:',sub)
  self.assertIn('k.slab(-1.6, 49.4, 2.0, 51.8',sub)
  self.assertIn('Aft independent deck ascent',sub)

 def test_03_godot_interaction_pipeline_and_state_effects(self):
  story=(ROOT/'core/world/StoryRooms28.gd').read_text()
  base=(ROOT/'core/world/LevelBase.gd').read_text()
  for phrase in ['Dress._place(owner,self,prop)','owner.make_interactable(',
    'Callable(self,"investigate").bind(i)','light.light_energy = 1.65',
    'SaveService.record_discovery(', 'Ambient.new()', 'func investigated_count(']:
   if phrase=='func investigated_count(':continue
   self.assertIn(phrase,story)
  self.assertIn('func inspected_count()',story)
  self.assertIn('_install_dev28_story_rooms()',base)
  self.assertIn('story.setup(self, entry)',base)
  self.assertNotIn('add_exit(',story)
  self.assertNotIn('dev_jump(',story)

 def test_04_native_rig_checks_actual_F3_E_physics(self):
  native=(ROOT/'tests/Dev28WorldProbe.gd').read_text()
  runner=(ROOT/'RUN_DEV28_NATIVE_QA_WINDOWS.ps1').read_text()
  for phrase in ['TransitionService.dev_jump(sid,"start")',
      'Interactable).interact(level.player)','_floor(world,',
      'sixteen separate clock hands','nine real imported GLB instances',
      'safe spawn','real switch light brightens']:
   self.assertIn(phrase,native)
  self.assertIn('res://tests/Dev28WorldProbe.tscn',runner)
  self.assertIn('summary.csv',runner)
  self.assertEqual(len([x for x in SITES if "'"+x+"'" in runner]),9)

 def test_05_stable_build_and_preflight(self):
  p=ROOT/'data/dev28_story_rooms.json'
  before=hashlib.sha256(p.read_bytes()).digest()
  cp=subprocess.run([sys.executable,'tools/build_dev28_story_rooms.py'],cwd=ROOT,capture_output=True,text=True)
  self.assertEqual(cp.returncode,0,cp.stderr)
  self.assertEqual(hashlib.sha256(p.read_bytes()).digest(),before)
  for path in [ROOT/'core/world/StoryRooms28.gd',ROOT/'core/world/LevelBase.gd',
    ROOT/'tests/Dev28WorldProbe.gd']+[ROOT/f'levels/{sid}/{sid}.gd' for sid in ['L026','L031','L079']]:
   self.assertEqual(string_and_delimiter_check(path.read_text(),str(path)),[])

if __name__=='__main__':unittest.main()
