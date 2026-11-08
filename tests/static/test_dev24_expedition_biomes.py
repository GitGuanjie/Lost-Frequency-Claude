"""DEV24 independent blueprint/collision-envelope contracts.
Does not claim that Godot physics/navigation was executed.
"""
import hashlib, json, math, subprocess, sys, unittest
from collections import defaultdict
from pathlib import Path
from tools.preflight_dev import string_and_delimiter_check
ROOT=Path(__file__).resolve().parents[2]
DATA=json.loads((ROOT/'data/dev24_expeditions.json').read_text())
OLD={r['id']:r for r in json.loads((ROOT/'data/dev23_landmark_spurs.json').read_text())['sites']}
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']

def reach(nodes, links, skip_optional=False):
    adj=defaultdict(set)
    for e in links:
        if skip_optional and e['kind']=='unlockable':continue
        adj[e['a']].add(e['b']);adj[e['b']].add(e['a'])
    seen={'b0'};todo=['b0']
    for n in todo:
        for v in adj[n]:
            if v not in seen:seen.add(v);todo.append(v)
    return seen

class TestDev24Expeditions(unittest.TestCase):
 def test_01_all_distinct_and_physical_existing_anchors(self):
    sites=DATA['sites'];self.assertEqual(len(sites),10)
    self.assertEqual({s['id'] for s in sites},set(OLD))
    self.assertEqual(len({s['style'] for s in sites}),10)
    self.assertEqual(len({tuple(map(tuple,s['morphology']['base'])) for s in sites}),10)
    for site in sites:
        old=OLD[site['id']]
        self.assertEqual(site['entry_gallery'],old['node_positions']['east'])
        self.assertEqual(site['mat'],old['mat']);self.assertEqual(site['accent'],old['accent'])
        self.assertAlmostEqual(site['origin'][0],old['node_positions']['east'][0]+24)
        self.assertEqual(len(site['nodes']),10)
        self.assertEqual(len(site['survey']),3)
        self.assertTrue(all(s in site['nodes'] for s in site['survey']))
        self.assertTrue((ROOT/f'sources/wiki_text/{site["id"]}.md').exists())

 def test_02_connected_locked_and_unlocked_and_no_critical_gate(self):
    for site in DATA['sites']:
        nodes=set(site['nodes']);links=site['links']
        self.assertEqual(reach(nodes,links,True),nodes,site['id'])
        self.assertEqual(reach(nodes,links,False),nodes)
        self.assertEqual(sum(l['kind']=='unlockable' for l in links),1)
        self.assertEqual(sum(l['kind']=='stair' for l in links),1)
        self.assertGreaterEqual(site['cycle_rank_base'],1)
        self.assertEqual([e['a'] for e in links if e['kind']=='unlockable'][0],site['optional_edge'][0])
        self.assertEqual([e['b'] for e in links if e['kind']=='unlockable'][0],site['optional_edge'][1])
        # Every ordinary bridge joins same-height cells exactly 14m apart.
        for link in links:
            a=site['nodes'][link['a']];b=site['nodes'][link['b']]
            if link['kind']=='stair':
                self.assertAlmostEqual(b[0]-a[0],29)
                self.assertAlmostEqual(b[1]-a[1],site['rise'])
                self.assertAlmostEqual(b[2],a[2])
                self.assertLess(math.degrees(math.atan(site['rise']/21)),15)
            else:
                self.assertAlmostEqual(a[1],b[1])
                self.assertAlmostEqual(abs(a[0]-b[0])+abs(a[2]-b[2]),14)

 def test_03_original_assets_real_and_corner_clearance(self):
    unique=set()
    self.assertEqual(sum(len(s['props']) for s in DATA['sites']),300)
    for s in DATA['sites']:
        self.assertEqual(len(s['props']),30)
        for item in s['props']:
            self.assertIn(item['node'],s['nodes'])
            path=f'assets/packs/{item["pack"]}/{item["model"]}.glb'
            self.assertIn(path,CAT);self.assertTrue((ROOT/path).is_file())
            unique.add(path)
            x,y,z=map(float,CAT[path]['size'])
            fact=min(8,float(item['height'])/max(.18,y))
            span=max(x,z)*fact
            self.assertLessEqual(span,1.28,path)
            self.assertLessEqual(abs(item['dx'])+span/2,5.0)
            self.assertLessEqual(abs(item['dz'])+span/2,5.0)
            self.assertGreater(min(abs(item['dx']),abs(item['dz'])),3.0)
    self.assertGreaterEqual(len(unique),80)

 def test_04_data_generation_is_deterministic(self):
    path=ROOT/'data/dev24_expeditions.json'
    digest=hashlib.sha256(path.read_bytes()).hexdigest()
    subprocess.run([sys.executable,'tools/generate_dev24_expeditions.py'],cwd=ROOT,check=True,capture_output=True)
    self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),digest)

 def test_05_runtime_has_real_collision_interaction_and_props(self):
    proc=(ROOT/'core/world/ExpeditionBiomes.gd').read_text()
    state=(ROOT/'core/world/ExpeditionState.gd').read_text()
    prev=(ROOT/'core/world/LandmarkSpurs.gd').read_text()
    for needle in ['k.slab(', 'k.stairs(', 'k.commit()', 'Dress._place(owner,dressing,place)',
       'ExpeditionBiomes', 'Callable(state,"survey").bind(idx)',
       'Callable(state,"operate_bridge")', 'Callable(state,"toggle_light").bind(idx)']:
        self.assertIn(needle, proc+'\n'+prev)
    for needle in ['CollisionShape3D.new()', 'floor_shape.disabled = true',
       'floor_shape.set_deferred("disabled",not value)',
       'barriers.append(', 'SaveService.record_discovery(', 'survey(_player: Player, idx: int)']:
        self.assertIn(needle,state)
    self.assertNotIn('add_exit(',proc)
    self.assertNotIn('TransitionService.',proc)
    self.assertIn('Expeditions.install(owner,rec)',prev)
    self.assertIn('if flank>0.0:',prev)

 def test_06_static_syntax_delimiters_and_world_manifest_untouched(self):
    for fname in ['core/world/ExpeditionBiomes.gd','core/world/ExpeditionState.gd',
                  'core/world/LandmarkSpurs.gd','tests/qa_runner.gd']:
        src=(ROOT/fname).read_text()
        self.assertEqual(string_and_delimiter_check(src,fname),[])
    self.assertRegex((ROOT/'project.godot').read_text(),r'config/version="1\.5\.0-dev(2[4-9]|[3-9][0-9])"')
    self.assertEqual(len(list((ROOT/'assets/packs').rglob('*.glb'))),414)

if __name__=='__main__': unittest.main()
