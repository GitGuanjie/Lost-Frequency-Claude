"""DEV22 exact data and topology contracts; NOT Godot engine evidence."""
from __future__ import annotations
import hashlib, json, math, subprocess, sys, unittest
from collections import defaultdict
from pathlib import Path
from tools.preflight_dev import string_and_delimiter_check
ROOT=Path(__file__).resolve().parents[2]
D=json.loads((ROOT/'data/dev22_narrative_districts.json').read_text())
B={w['id']:w for w in json.loads((ROOT/'data/dev20_atrium_blueprints.json').read_text())['wings']}
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']


def edge(e):
    a,b=sorted((tuple(e[:2]),tuple(e[2:])))
    return (a,b)


def graph_connected(nodes, edges):
    if not nodes:return False
    adj={n:set() for n in nodes}
    for a,b in edges:
        assert a in adj and b in adj
        adj[a].add(b);adj[b].add(a)
    todo=[next(iter(nodes))]; visited=set(todo)
    for a in todo:
        for b in adj[a]:
            if b not in visited: visited.add(b);todo.append(b)
    return len(visited)==len(nodes)


class TestDev22Districts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.ds=D['districts']
    def test_01_all_ten_authored_sites_have_different_themes(self):
        self.assertEqual(len(self.ds),10)
        self.assertEqual(set(w['id'] for w in self.ds),set(B))
        self.assertEqual(len({w['style'] for w in self.ds}),10)
        self.assertEqual(len({w['title'] for w in self.ds}),10)
        self.assertEqual(sum(w['tiers'] for w in self.ds),42)
        for d in self.ds:
            self.assertEqual(d['anchor'],B[d['id']]['anchor'])
            self.assertTrue((ROOT/f'sources/wiki_text/{d["id"]}.md').exists())
    def test_02_exact_floor_cell_and_graph_counts(self):
        self.assertEqual(sum(len(f['cells']) for w in self.ds for f in w['floors']),626)
        self.assertEqual(sum(len(f['doors']) for w in self.ds for f in w['floors']),782)
        self.assertEqual(sum(2*(w['tiers']-1) for w in self.ds),64)
        for w in self.ds:
            self.assertEqual(len(w['floors']),w['tiers'])
            for tier,f in enumerate(w['floors']):
                nodes=set(map(tuple,f['cells']))
                es=list(map(edge,f['doors']))
                self.assertEqual(len(es),len(set(es)))
                self.assertTrue(graph_connected(nodes,es),(w['id'],tier))
                self.assertEqual(f['cycle_rank'],len(es)-len(nodes)+1)
                self.assertGreaterEqual(f['cycle_rank'],4)
                self.assertEqual(set(es),set(map(edge,f['tree_edges']))|set(map(edge,f['extra_edges'])))
                self.assertEqual(set(map(edge,f['tree_edges']))&set(map(edge,f['extra_edges'])),set())
                self.assertEqual(len(f['tree_edges']),len(nodes)-1)
                self.assertEqual(len(f['voids']),0 if tier==0 else (2 if w['style'] in {'attraction','neon','canopy','roots'} else 1))
                self.assertTrue(all(a in nodes and b in nodes and sum(abs(a[i]-b[i]) for i in (0,1))==1 for a,b in es))
    def test_03_every_floor_has_real_stair_landing_cells(self):
        for w in self.ds:
            for tier,f in enumerate(w['floors']):
                nodes=set(map(tuple,f['cells']))
                self.assertTrue({(0,0),(0,3),(3,0),(3,3)}.issubset(nodes))
                if tier==0:
                    self.assertIn((2,3),nodes)
                    self.assertIn((1,0),nodes)
    def test_04_all_stairs_and_one_entry_connect_global_graph(self):
        for w in self.ds:
            nodes={(tier,*p) for tier,f in enumerate(w['floors']) for p in map(tuple,f['cells'])}
            es=[]
            for tier,f in enumerate(w['floors']):
                es.extend(((tier,*a),(tier,*b)) for a,b in map(edge,f['doors']))
            for tier in range(w['tiers']-1):
                es.append(((tier,3,0),(tier+1,3,3)))
                es.append(((tier,0,3),(tier+1,0,0)))
            self.assertTrue(graph_connected(nodes,es),w['id'])
            self.assertIn((0,2,3),nodes)
            # At closed gate, the remaining tree backbone still reaches all cells.
            gate=edge(w['shutter_edge'])
            self.assertIn(gate,set(map(edge,w['floors'][1]['extra_edges'])))
            blocked=tuple(((1,*gate[0]),(1,*gate[1])))
            self.assertTrue(graph_connected(nodes,[e for e in es if e!=blocked]),w['id'])
    def test_05_entrance_and_height_alignment_with_existing_wing(self):
        for w in self.ds:
            b=B[w['id']]
            oldx=float(b['origin'][0])+32.5
            oldz=float(b['origin'][2])-14.0
            x,y,z=w['origin']
            self.assertAlmostEqual(x,oldx,places=5)
            self.assertAlmostEqual(z,oldz-43.0,places=5)
            self.assertAlmostEqual(y,float(b['origin'][1])+2*float(b['rise']),places=5)
            self.assertAlmostEqual(z+28,oldz-15.0)
            self.assertAlmostEqual(x+2.5*7,oldx+2.5*7)
            self.assertAlmostEqual(w['rise'],b['rise'])
            self.assertLess(math.degrees(math.atan(float(w['rise'])/21)),13)
    def test_06_indoor_and_outdoor_geometry_are_separate(self):
        self.assertEqual(sum(w['open_air'] for w in self.ds),5)
        self.assertEqual(sum(not w['open_air'] for w in self.ds),5)
        s=(ROOT/'core/world/NarrativeDistrict.gd').read_text()
        for tag in ('k.wall(', 'k.slab(p.x-2.60', '_guard(k,p,side',
            'k.stairs(Vector3(x0+WIDTH+3.1','k.stairs(Vector3(x0-3.1',
            'k.slab(bridge_x-1.42','_landmark(k,vista_x,vista_z',
            'k.slab(vista_x-5.10','ModelDress', 'Dress._place(owner,dressing,item)'):
            if tag=='ModelDress':continue
            self.assertIn(tag,s)
        wing=(ROOT/'core/world/AtriumWeave.gd').read_text()
        self.assertIn('elif c == 2 and tier == 1',wing)
        self.assertIn('var terrace_access := (direction == "north" and c == 2 and r == 0)',wing)
        self.assertIn('NarrativeDistrict.install(owner, tag, x0, z0, ybase, rise)',wing)
    def test_07_new_models_are_included_restricted_and_not_in_walkway(self):
        allmodels=set();total=0
        for d in self.ds:
            plan=d['floors']
            cells=set()
            for m in d['models']:
                key=(m['tier'],*m['cell'])
                self.assertNotIn(key,cells)
                cells.add(key)
                self.assertIn(m['cell'],plan[m['tier']]['cells'])
                self.assertNotIn(tuple(m['cell']), {(0,0),(0,3),(3,0),(3,3),(2,3),(0,1),(3,1),(1,3)})
                path=f'assets/packs/{m["pack"]}/{m["model"]}.glb'
                self.assertIn(path,CAT)
                self.assertTrue((ROOT/path).is_file())
                allmodels.add(path)
                shape=CAT[path]['size']
                factor=min(8,float(m['height'])/max(.18,float(shape[1])))
                size=max(shape[0],shape[2])*factor
                allowed=.8 if d['open_air'] else 1.4
                self.assertLessEqual(size,allowed+0.001)
                self.assertLessEqual(size/2+abs(m['offset'][0]),2.60 if d['open_air'] else 3.5)
                self.assertLessEqual(size/2+abs(m['offset'][1]),2.60 if d['open_air'] else 3.5)
                total+=1
            self.assertEqual(len(d['landmark_models']),2)
            for m in d['landmark_models']:
                path=f'assets/packs/{m["pack"]}/{m["model"]}.glb'
                self.assertIn(path,CAT)
                allmodels.add(path)
                shape=CAT[path]['size']
                factor=min(8,float(m['height'])/max(.18,float(shape[1])))
                self.assertLessEqual(max(shape[0],shape[2])*factor,1.301)
                self.assertLessEqual(abs(m['offset_x'])+max(shape[0],shape[2])*factor/2,5.10)
        self.assertEqual(total,252)
        self.assertGreaterEqual(len(allmodels),40)
    def test_08_theme_landmarks_are_unique_and_accessible(self):
        s=(ROOT/'core/world/NarrativeDistrict.gd').read_text()
        for d in self.ds:
            self.assertIn('"'+d['style']+'":',s)
        self.assertIn('_opening(tier==0 and c==1)',s)
        self.assertIn('var landmark := side=="north"',s)
        self.assertIn('k.slab(vista_x-5.10',s)
        self.assertIn('Callable(state,"investigate").bind(2)',s)
    def test_09_real_stateful_e_interaction_and_optional_collision(self):
        s=(ROOT/'core/world/NarrativeDistrictState.gd').read_text()
        for token in ('func activate_signal(_p: Player, tier: int)',
            'func toggle_ambient(_p: Player, tier: int)',
            'func investigate(_p: Player, index: int)',
            'func toggle_gate(_p: Player)',
            'gate_shape.set_deferred("disabled", gate_open)',
            'ambient_lights[tier].light_energy = 2.4',
            'signal_lights[tier].light_energy = 2.0',
            'if signals.has(false):',
            'SaveService.record_discovery(',
            'StaticBody3D.new()', 'CollisionShape3D.new()'):
            self.assertIn(token,s)
        b=(ROOT/'core/world/NarrativeDistrict.gd').read_text()
        for token in ('owner.add_interactable(', 'Callable(state,"activate_signal").bind(tier)',
            'Callable(state,"toggle_ambient").bind(tier)',
            'Callable(state,"toggle_gate")'):
            self.assertIn(token,b)
    def test_10_audio_and_observation_without_entities_or_new_exits(self):
        for d in self.ds:
            self.assertEqual(len(d['ambience']),3)
            self.assertTrue(all(a['source']=='ADAPTATION' and a['height']<=2.0 for a in d['ambience']))
            self.assertEqual(len(d['signals']),d['tiers'])
            self.assertEqual(len(d['observations']),3)
        for p in ('core/world/NarrativeDistrict.gd','core/world/NarrativeDistrictState.gd'):
            s=(ROOT/p).read_text()
            self.assertNotIn('add_exit(',s)
            self.assertNotIn('teleport(',s)
            self.assertNotIn('spawn_entity(',s)
    def test_11_source_roster_unmodified_and_resources_retained(self):
        self.assertEqual(len(json.loads((ROOT/'data/canon/levels.json').read_text())['levels']),100)
        self.assertEqual(sum(len(json.loads(p.read_text())['exits']) for p in (ROOT/'levels').glob('*/level.json')),235)
        self.assertEqual(len(list((ROOT/'assets').rglob('*.glb'))),414)
        self.assertEqual(D['status'],'TOPOLOGY_ONLY_ENGINE_NOT_CERTIFIED')
    def test_12_generator_is_exactly_byte_reproducible(self):
        p=ROOT/'data/dev22_narrative_districts.json'
        old=hashlib.sha256(p.read_bytes()).hexdigest()
        cmd=[sys.executable,str(ROOT/'tools/generate_dev22_districts.py')]
        r=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True)
        self.assertEqual(r.returncode,0,r.stderr)
        self.assertEqual(old,hashlib.sha256(p.read_bytes()).hexdigest())
    def test_13_no_lexer_failures_in_new_or_modified_gdscript(self):
        rel=['core/world/AtriumWeave.gd','core/world/NarrativeDistrict.gd',
             'core/world/NarrativeDistrictState.gd','tests/qa_runner.gd']
        errors=[msg for f in rel for msg in string_and_delimiter_check((ROOT/f).read_text(),f)]
        self.assertEqual(errors,[])
    def test_14_no_false_claim_of_engine_certification(self):
        self.assertEqual(D['status'],'TOPOLOGY_ONLY_ENGINE_NOT_CERTIFIED')
        self.assertEqual(set(D),{'schema','version','status','source','districts'})
        self.assertTrue(all(not d.get('godot_passed') for d in self.ds))

if __name__=='__main__':unittest.main()
