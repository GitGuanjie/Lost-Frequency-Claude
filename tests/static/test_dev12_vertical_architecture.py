"""Intended graph connectivity and source regressions only. Never claims engine physics."""
import json,math,unittest,hashlib
from pathlib import Path
from tools.preflight_dev import string_and_delimiter_check
ROOT=Path(__file__).resolve().parents[2]
DATA=json.loads((ROOT/'data/vertical_routes_dev12.json').read_text())

def source(rel):return (ROOT/rel).read_text()

class Dev12VerticalArchitecture(unittest.TestCase):
    def test_four_actual_modified_levels(self):
        self.assertEqual(set(DATA['levels']), {'L003','L010','L011','L025'})
        self.assertEqual(len(json.loads(source('data/canon/levels.json'))['levels']),100)
    def test_intended_route_graph_connected_from_ground_to_highest(self):
        for sid,l in DATA['levels'].items():
            nodes=l['nodes']; adj={p:set() for p in nodes}; edges=l['edges']
            for a,b,kind,rise,run,width in edges:
                self.assertIn(a,nodes);self.assertIn(b,nodes)
                self.assertIn(kind,('stairs','deck'))
                self.assertGreaterEqual(width,1.2)
                self.assertGreater(run,0)
                self.assertLessEqual(abs(nodes[a][1]-nodes[b][1]),rise+0.02)
                if kind=='stairs':
                    self.assertGreater(rise,1)
                    self.assertLess(rise/run,0.56)
                else:self.assertAlmostEqual(rise,0,places=5)
                adj[a].add(b);adj[b].add(a)
            floor=min(nodes,key=lambda n:nodes[n][1]); top=max(nodes,key=lambda n:nodes[n][1]);seen={floor};queue=[floor]
            while queue:
                u=queue.pop(0)
                for v in adj[u]-seen:seen.add(v);queue.append(v)
            self.assertEqual(set(nodes),seen, f'{sid} vertical graph disconnected')
            self.assertIn(top,seen)
            self.assertGreaterEqual(len(set(round(p[1],2) for p in nodes.values())),3)
            self.assertGreaterEqual(l['upper_clearance_m'],2.5)
    def test_upper_routes_include_real_loops(self):
        for sid in ['L011','L025']:
            l=DATA['levels'][sid]; upper=[n for n,p in l['nodes'].items() if p[1]>2.5]
            edges=[(a,b) for a,b,*_ in l['edges'] if a in upper and b in upper]
            # Connected cycle requires at least as many edges as vertices.
            self.assertGreaterEqual(len(edges),len(upper),sid)
    def test_gd_uses_real_collidable_decks_and_stairs(self):
        cases=[('L003','L003_rooms.gd','_assembly_upper_walk'),('L010','L010_barn.gd','watchtower'),('L011','L011.gd','_skywalk_upper'),('L025','L025.gd','_arcade_mezzanine')]
        for sid,filename,fn in cases:
            s=source(f'levels/{sid}/{filename}')
            chunk=s.split('func '+fn+'(',1)[1].split('\nfunc ',1)[0]
            self.assertIn('k.stairs(',chunk,sid)
            self.assertTrue('k.slab(' in chunk or 'bx(' in chunk,sid)
            self.assertNotIn('make_exit(',chunk,sid)
            self.assertNotIn('add_exit(',chunk,sid)
            self.assertNotIn('.fire(',chunk,sid)
    def test_l010_tower_only_for_authored_home_barn(self):
        s=source('levels/L010/L010_geo.gd')
        self.assertIn('if p["home"] and p["kind"] == "barn":',s)
        self.assertIn('b.watchtower()',s)
    def test_all_new_code_passes_basic_lexer(self):
        edits=['levels/L003/L003.gd','levels/L003/L003_rooms.gd','levels/L010/L010.gd','levels/L010/L010_geo.gd','levels/L010/L010_barn.gd','levels/L011/L011.gd','levels/L025/L025.gd']
        errors=[]
        for p in edits:errors+=string_and_delimiter_check(source(p),p)
        self.assertEqual(errors,[])
    def test_all_exit_manifests_unchanged_from_dev11(self):
        # Same user-owned baseline; changed levels are deliberately local gameplay additions.
        for sid, expected in DATA['baseline_level_manifests_sha256'].items():
            name=f'levels/{sid}/level.json'
            actual=hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
            self.assertEqual(actual,expected,sid)
    def test_asset_smoke_is_versioned_for_this_release(self):
        s=source('tests/model_asset_smoke.gd')
        self.assertIn('v150_dev12/model_assets_smoke.json',s)
        self.assertIn('"version": "1.5.0-dev12"',s)
        self.assertIn('placements_expected',s)
    def test_qa_runner_requires_all_four_per_level_engine_checks(self):
        s=source('tools/run_dev12_qa.py')
        for sid in DATA['levels']:
            self.assertIn("'"+sid+"'",s)
        self.assertIn('qa_status',s)
        self.assertIn('self_tests',s)
        self.assertIn('l009_route',s)
    def test_engine_tests_are_present_not_falsely_certified(self):
        for sid in DATA['levels']:
            path=ROOT/f'levels/{sid}/{sid}.gd';s=path.read_text()
            self.assertIn('func qa_self_test()',s)
            self.assertIn('intersect_ray(',s)

if __name__=='__main__':unittest.main()
