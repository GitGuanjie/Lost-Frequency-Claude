"""Contract tests for DEV23. They DO NOT replace native Godot physics QA."""
from __future__ import annotations
import hashlib, json, math, subprocess, sys, unittest
from collections import Counter, defaultdict
from pathlib import Path
from tools.preflight_dev import string_and_delimiter_check
ROOT=Path(__file__).resolve().parents[2]
D=json.loads((ROOT/'data/dev23_landmark_spurs.json').read_text())
B={x['id']:x for x in json.loads((ROOT/'data/dev22_narrative_districts.json').read_text())['districts']}
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']

class TestLandmarkSpurs(unittest.TestCase):
    def test_01_all_10_sites_are_distinct_and_attached(self):
        sites=D['sites']
        self.assertEqual(len(sites),10)
        self.assertEqual({e['id'] for e in sites},set(B))
        self.assertEqual(len({e['style'] for e in sites}),10)
        self.assertEqual(len({e['title'] for e in sites}),10)
        source=(ROOT/'core/world/NarrativeDistrict.gd').read_text()
        self.assertIn('LandmarkSpurs.install(owner,rec,vista_x,z0,ybase',source)
        self.assertIn('DEV23: make a real 3.6m entry',source)
        for w in sites:
            b=B[w['id']]
            self.assertEqual(w['anchor'],b['anchor'])
            self.assertEqual(w['origin'],b['origin'])
            self.assertEqual(w['rise'],b['rise'])
            self.assertEqual(w['open_air'],b['open_air'])
            self.assertEqual(w['mat'],b['mat'])
            self.assertEqual(w['accent'],b['accent'])
            self.assertTrue((ROOT/f'sources/wiki_text/{w["id"]}.md').exists())

    def test_02_three_real_nodes_and_optional_bridge_is_nonessential(self):
        for w in D['sites']:
            edges=[(a,b) for a,b,mode in w['links'] if mode!='unlockable_bridge']
            nodes=set(w['node_positions'])
            self.assertEqual(len(nodes),5 if w['lower'] else 4)
            self.assertEqual(len(edges),len(nodes)-1)
            def reachable(links):
                adj=defaultdict(list)
                for a,b in links:adj[a].append(b);adj[b].append(a)
                seen={'old_vista'};todo=['old_vista']
                for node in todo:
                    for v in adj[node]:
                        if v not in seen:seen.add(v);todo.append(v)
                return seen
            self.assertEqual(reachable(edges),nodes)
            unlocked=edges+[('west','east')]
            self.assertEqual(reachable(unlocked),nodes)
            self.assertEqual(len(unlocked)-len(nodes)+1,1)
            self.assertIn(('west','east','unlockable_bridge'),list(map(tuple,w['links'])))

    def test_03_physical_stair_alignment_and_player_gradient(self):
        for w in D['sites']:
            p=w['node_positions']; y=float(w['origin'][1]);r=float(w['rise']);x=float(w['origin'][0])+10.5;z=float(w['origin'][2])
            self.assertAlmostEqual(p['old_vista'][2],z-11)
            self.assertAlmostEqual(p['hub'][2],z-19)
            self.assertAlmostEqual(p['west'][0],x-14.5)
            self.assertAlmostEqual(p['east'][0],x+14.5)
            self.assertAlmostEqual(p['west'][2],z-45)
            self.assertAlmostEqual(p['east'][1],y+r)
            self.assertLess(math.degrees(math.atan(r/21)),12)
            if w['lower']:
                self.assertAlmostEqual(p['lower'][1],y-r)
                self.assertAlmostEqual(p['lower'][0],x-31.5)
            self.assertEqual(w['lower'],w['style'] in {'keep_forge','highway','red_keep','shelter','roots','neon'})

    def test_04_existing_glb_assets_have_safe_scaled_bounds(self):
        total=Counter(); unique=set()
        for w in D['sites']:
            self.assertEqual(len(w['props']),16)
            for item in w['props']:
                self.assertIn(item['site'],{'hub','west','east','lower'})
                if item['site']=='lower':self.assertTrue(w['lower'])
                path=f'assets/packs/{item["pack"]}/{item["model"]}.glb'
                self.assertIn(path,CAT)
                self.assertTrue((ROOT/path).exists(),path)
                sx,sy,sz=map(float,CAT[path]['size'])
                factor=min(8,float(item['height'])/max(.18,sy))
                self.assertLessEqual(max(sx,sz)*factor,2.27,path)
                dx,dz=float(item['dx']),float(item['dz'])
                if item['site']=='hub':
                    self.assertLessEqual(abs(dx)+max(sx,sz)*factor*.5,6.0)
                    self.assertLessEqual(abs(dz)+max(sx,sz)*factor*.5,8.0)
                    self.assertFalse(abs(dx)>3.3 and dz<-3.5,'stair foot must remain visually clear')
                else:
                    self.assertLessEqual(abs(dx)+max(sx,sz)*factor*.5,6.0)
                    self.assertLessEqual(abs(dz)+max(sx,sz)*factor*.5,6.0)
                unique.add(path);total[w['id']]+=1
        self.assertEqual(sum(total.values()),160)
        self.assertGreaterEqual(len(unique),55)

    def test_05_real_stateful_actions_and_no_teleport(self):
        geom=(ROOT/'core/world/LandmarkSpurs.gd').read_text()
        state=(ROOT/'core/world/LandmarkSpurState.gd').read_text()
        self.assertIn('k.stairs(',geom)
        self.assertIn('k.slab(',geom)
        self.assertIn('k.commit()',geom)
        self.assertIn('Dress._place(owner,dressing,item)',geom)
        self.assertIn('Ambient.new()',geom)
        self.assertIn('Callable(state,"activate").bind(',geom)
        self.assertIn('Callable(state,"toggle_bridge")',geom)
        self.assertIn('CollisionShape3D.new()',state)
        self.assertIn('bridge_collision.disabled = true',state)
        self.assertIn('bridge_collision.set_deferred("disabled",not active)',state)
        self.assertIn('marked.has(false)',state)
        self.assertNotIn('add_exit(',geom)
        self.assertNotIn('TransitionService.',geom)
        self.assertEqual(sum(x['lower'] for x in D['sites']),6)

    def test_06_lexical_and_recipe_reproducibility(self):
        for name in ['core/world/LandmarkSpurState.gd','core/world/LandmarkSpurs.gd', 'core/world/NarrativeDistrict.gd', 'tests/qa_runner.gd']:
            self.assertEqual(string_and_delimiter_check((ROOT/name).read_text(),name),[])
        before=(ROOT/'data/dev23_landmark_spurs.json').read_bytes()
        subprocess.run([sys.executable,'tools/generate_dev23_landmarks.py'],cwd=ROOT,check=True,capture_output=True)
        self.assertEqual(hashlib.sha256(before).hexdigest(),hashlib.sha256((ROOT/'data/dev23_landmark_spurs.json').read_bytes()).hexdigest())

if __name__=='__main__':unittest.main()
