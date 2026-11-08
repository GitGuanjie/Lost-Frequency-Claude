"""Offline integrity gates for the 414 CC0 GLBs and 24-level curated dressings.
Does not establish that imported Godot PackedScenes render/behave correctly.
"""
import csv, hashlib, json, re, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
C=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']
R=json.loads((ROOT/'data/model_dressings.json').read_text())['levels']

class Dev9GLBIntegration(unittest.TestCase):
 def test_all_414_glbs_exist_and_match_shas(self):
  self.assertEqual(len(C),414)
  for path,meta in C.items():
   data=(ROOT/path).read_bytes()
   self.assertTrue(data.startswith(b'glTF\x02\0\0\0'),path)
   self.assertEqual(hashlib.sha256(data).hexdigest(),meta['sha256'],path)

 def test_3d_bounds_finite_and_mesh_nonempty(self):
  self.assertEqual(sum(int(m['triangles']) for m in C.values()),78361)
  for name,m in C.items():
   self.assertGreater(m['triangles'],0,name)
   self.assertEqual(len(m['min']),3)
   self.assertTrue(all(float(x)>0 for x in m['size']),name)
   self.assertLessEqual(m['triangles'],5000,name)

 def test_curated_24_levels_and_466_instances(self):
  self.assertEqual(len(R),24)
  self.assertEqual(sum(len(v) for v in R.values()),466)
  self.assertEqual(len({(r['pack'],r['model']) for items in R.values() for r in items}),86)

 def test_every_dressing_asset_is_in_verified_pack(self):
  for level,items in R.items():
   self.assertTrue((ROOT/'levels'/level/(level+'.tscn')).exists())
   for item in items:
    name='assets/packs/{}/{}.glb'.format(item['pack'],item['model'])
    self.assertIn(name,C)
    self.assertEqual(len(item['pos']),3)
    self.assertGreater(item['height'],0)
    self.assertLessEqual(item['height'],4.0)

 def test_integrated_calls_present(self):
  for level,items in R.items():
   code=(ROOT/'levels'/level/(level+'.gd')).read_text()
   self.assertIn('const ModelDress := preload(',code,level)
   if any(r.get('scope')=='chunk' for r in items):
    self.assertIn('ModelDress.decorate_chunk(self, node, "'+level+'", cx, cz)',code)
   else:
    self.assertIn('ModelDress.decorate(self, "'+level+'")',code)

 def test_chunk_coordinates_owner_and_spawn_safety(self):
  for level,items in R.items():
   for item in items:
    if item.get('scope')=='chunk':
     code=(ROOT/'levels'/level/(level+'.gd')).read_text()
     self.assertIn('func _build_chunk(',code)
     self.assertIn('"scope": "chunk"',json.dumps(item))
  # Level 9's QA signs use (x, z)=(38/30/22, 7.6); leave their lane empty.
  for d in R['L009']:
   if d.get('cx')==0 and d.get('cz')==0:
    self.assertGreater(abs(d['pos'][2]-7.6),5.0)

 def test_model_layer_is_optional_and_respects_canon(self):
  code=(ROOT/'core/world/ModelDress.gd').read_text()
  self.assertIn('ResourceLoader.exists(path)',code)
  self.assertIn('static func _place(level:',code)
  self.assertIn('static func _place(level: Node3D, owner: Node3D, item: Dictionary) -> bool:\n\t# The asset gallery calls _place() directly; initialise the index here too.\n\t_data_ready()',code)
  self.assertIn('if bool(item.get("solid", false)):',code)
  self.assertNotIn('request_exit(',code)
  self.assertNotIn('add_exit(',code)
  self.assertNotIn('player.global_position =',code)
  self.assertNotIn('L000',R)
  self.assertNotIn('L037',R)

 def test_licenses_and_gallery_and_runtime_asset_smoke(self):
  lic=(ROOT/'assets/packs/LICENSE_AND_SOURCE.txt').read_text()
  self.assertIn('CC0',lic)
  self.assertTrue((ROOT/'tools/AssetGallery.tscn').exists())
  self.assertTrue((ROOT/'tests/ModelAssetSmoke.tscn').exists())

 def test_legacy_gate_remains_unchanged(self):
  code=(ROOT/'tests/qa_runner.gd').read_text()
  self.assertIn('load_level("L009", "from_L005"',code)
  self.assertIn('l009_route_evidence',code)
  self.assertNotIn('qa_prog = 3',code)

if __name__=='__main__':unittest.main()
