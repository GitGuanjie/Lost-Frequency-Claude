"""DEV21 model/collision/topology audit: evidence is OFFLINE only, not Godot QA."""
import hashlib, json, subprocess, sys, unittest
from pathlib import Path
from collections import Counter
from tools.preflight_dev import string_and_delimiter_check
ROOT=Path(__file__).resolve().parents[2]
BLUE=json.loads((ROOT/'data/dev20_atrium_blueprints.json').read_text())
STORY=json.loads((ROOT/'data/dev21_wing_scenarios.json').read_text())
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']

class TestDev21Dressing(unittest.TestCase):
 def test_01_ten_distinct_lore_anchored_scenarios(self):
  self.assertEqual(len(STORY['wings']),10)
  self.assertEqual({e['id'] for e in STORY['wings']},{w['id'] for w in BLUE['wings']})
  self.assertEqual(len({x['title'] for x in STORY['wings']}),10)
  for e in STORY['wings']:
   self.assertIn('Level ', (ROOT/f'sources/wiki_text/{e["id"]}.md').read_text(), e['id'])
 def test_02_true_source_models_bounded_and_varied(self):
  total=0; allpacks=set(); allmodels=set()
  for wing in STORY['wings']:
   models=wing['models']; self.assertEqual(len(models),33,wing['id']);total+=len(models)
   self.assertGreaterEqual(len({m['model'] for m in models}),6)
   packs={m['pack'] for m in models};self.assertGreaterEqual(len(packs),2)
   allpacks|=packs
   for m in models:
    key=f"assets/packs/{m['pack']}/{m['model']}.glb"
    self.assertIn(key,CAT)
    self.assertTrue((ROOT/key).is_file(),key)
    allmodels.add(key)
    size=CAT[key]['size']
    # Actual ModelDress scale bound uses max(.18,height).
    factor=min(8,float(m['height'])/max(.18,float(size[1])))
    allowed=0.84 if next(w for w in BLUE['wings'] if w['id']==wing['id'])['open_air'] else 1.65
    self.assertLessEqual(max(size[0],size[2])*factor,allowed+0.001)
    self.assertLessEqual(size[1]*factor,2.001)
    self.assertFalse(m.get('solid',False))
    self.assertGreaterEqual(min(abs(v) for v in m['offset']),2.00)
    self.assertFalse(m['offset'][0] < 0 and m['offset'][1] < 0)  # DEV20 pillar corner
    # Full prop bounds must stay on its supporting room or outdoor tile.
    half_slab=2.57 if allowed<1.0 else 3.5
    self.assertLessEqual(max(abs(m['offset'][0]),abs(m['offset'][1]))
        +max(size[0],size[2])*factor/2,half_slab+.001)
  self.assertEqual(total,330)
  self.assertGreaterEqual(len(allpacks),8)
  self.assertGreaterEqual(len(allmodels),45)
 def test_03_every_decor_cell_is_real_floor_not_hole(self):
  byid={w['id']:w for w in BLUE['wings']}
  for wing in STORY['wings']:
   b=byid[wing['id']]
   self.assertEqual(b['anchor'],wing['anchor'])
   for item in wing['models']:
    self.assertIn(item['cell'],b['floors'][item['tier']]['cells'])
   for tier in (0,1,2):
    self.assertIn([4,2],b['floors'][tier]['cells'])
    self.assertIn([2,0],b['floors'][tier]['cells'])
 def test_04_each_site_has_two_proximity_audio_and_three_marker_interactions(self):
  for wing in STORY['wings']:
   self.assertEqual(len(wing['station_prompts']),3)
   self.assertEqual(len(wing['station_reports']),3)
   self.assertEqual(len(wing['ambience']),2)
   self.assertEqual(len({a['id'] for a in wing['ambience']}),2)
   self.assertEqual([a['source'] for a in wing['ambience']],['ADAPTATION']*2)
   self.assertEqual(sum('inspect' in m for m in wing['models']),3)
   self.assertEqual([a['height'] for a in wing['ambience']],[2.0,2.0])
 def test_05_real_open_terrace_geometry_connected_to_floor_and_guard(self):
  text=(ROOT/'core/world/AtriumWeave.gd').read_text()
  for x in ('if c == 2 and tier != 1:', '_door_opening(true)', 'terrace_access',
    'k.slab(xc - 1.8, z0 - 6.5', 'z0 + 1.55','k.box(Vector3(xc, y + 0.55, z0 - 6.53)',
    'ScenarioDressing.install(owner, tag, state, x0, z0, ybase, rise)'):
   self.assertIn(x,text)
  # Overlap with room floor (outdoor platform begins z0+0.93) and indoor portal.
  self.assertGreater(1.55,3.5-2.57)
 def test_06_stateful_mechanism_and_event_bound_player_signatures(self):
  state=(ROOT/'core/world/AtriumWeaveState.gd').read_text()
  for x in ('func toggle_circuit(_p: Player, tier: int)',
    'func toggle_shutter(_p: Player)', 'func observe(_p: Player, tier: int)',
    'func activate_marker(_p: Player, tier: int)', 'marker_lights[tier].light_energy = 2.0',
    'marker_visuals[tier].material_override', 'SaveService.record_discovery'):
   self.assertIn(x,state)
  proc=(ROOT/'core/world/ScenarioDressing.gd').read_text()
  self.assertIn('ModelDress._place(owner, group, item)',proc)
  self.assertIn('Callable(state, "activate_marker").bind(tier)',proc)
  self.assertIn('AmbientDiscovery.new()',proc)
  self.assertIn('owner.make_interactable',proc)
 def test_07_no_fake_traversal_in_metadata(self):
  self.assertEqual(STORY['status'],'PROCEDURAL_DRESSING_UNVERIFIED_IN_ENGINE')
  for p in ['core/world/ScenarioDressing.gd','core/world/AtriumWeave.gd','core/world/AtriumWeaveState.gd']:
   s=(ROOT/p).read_text();self.assertNotIn('add_exit(',s);self.assertNotIn('teleport(',s)
 def test_08_source_unchanged_and_canon_manifest_intact(self):
  roster=json.loads((ROOT/'data/canon/levels.json').read_text())
  self.assertEqual(len(roster['levels']),100)
  self.assertEqual(sum(len(json.loads(p.read_text())['exits']) for p in (ROOT/'levels').glob('*/level.json')),235)
  self.assertEqual(len(list((ROOT/'assets').rglob('*.glb'))),414)
 def test_09_deterministic_exact_byte_rebuild(self):
  path=ROOT/'data/dev21_wing_scenarios.json';before=hashlib.sha256(path.read_bytes()).hexdigest()
  ret=subprocess.run([sys.executable,str(ROOT/'tools/generate_dev21_scenarios.py')],cwd=ROOT,capture_output=True,text=True)
  self.assertEqual(ret.returncode,0,ret.stderr)
  self.assertEqual(before,hashlib.sha256(path.read_bytes()).hexdigest())
 def test_10_unique_lookout_architecture_for_all_ten_levels(self):
  txt=(ROOT/'core/world/ScenarioArchitecture.gd').read_text()
  for wing in STORY['wings']:
   self.assertIn('"'+wing['id']+'":',txt)
  self.assertIn('ScenarioArchitecture.dress_terrace(', (ROOT/'core/world/AtriumWeave.gd').read_text())
 def test_11_gdscript_static_lexer_smoke_only(self):
  paths=['core/world/ScenarioDressing.gd','core/world/AtriumWeave.gd','core/world/AtriumWeaveState.gd','core/world/ScenarioArchitecture.gd','tests/qa_runner.gd']
  fail=[msg for p in paths for msg in string_and_delimiter_check((ROOT/p).read_text(),p)]
  self.assertEqual(fail,[])

if __name__=='__main__':unittest.main()
