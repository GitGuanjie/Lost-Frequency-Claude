"""DEV25: source constraints, collision-envelope designs and deterministic data.
No results are mislabelled as a Godot engine run.
"""
import hashlib,json,math,subprocess,sys,unittest
from pathlib import Path
from collections import defaultdict
from tools.preflight_dev import string_and_delimiter_check
ROOT=Path(__file__).resolve().parents[2]
DATA=json.loads((ROOT/'data/dev25_immersive_networks.json').read_text())
ISLES=json.loads((ROOT/'data/dev25_coconut_island_variants.json').read_text())
CAT=json.loads((ROOT/'assets/packs/catalog.json').read_text())['models']
TARGET={'L041','L048','L140','L201'}


def reachable(site, optional_open):
    edges=defaultdict(set)
    for e in site['links']:
        if e['kind']=='optional' and not optional_open:continue
        edges[e['a']].add(e['b']);edges[e['b']].add(e['a'])
    visited={'b_16_0'}; pending=['b_16_0']
    for node in pending:
        for other in edges[node]:
            if other not in visited:visited.add(other);pending.append(other)
    return visited


class TestDev25SourceAccurate(unittest.TestCase):
 def test_01_sites_diverse_real_attached_and_source_types(self):
    self.assertEqual({r['id'] for r in DATA['sites']},TARGET)
    self.assertEqual(len({r['style'] for r in DATA['sites']}),4)
    self.assertEqual(sum(len(x['nodes']) for x in DATA['sites']),66)
    self.assertEqual(sum(len(x['props']) for x in DATA['sites']),118)
    # This fix deliberately does NOT add a motorway service town or ocean palace.
    motorway=(ROOT/'levels/L069/L069.gd').read_text()
    self.assertIn('for x in [-12.0,12.0]:k.box',motorway)
    self.assertNotIn('ImmersiveNetworks',motorway)
    sandbar=(ROOT/'levels/L100/L100.gd').read_text()
    self.assertIn('dev25:grave:',sandbar)
    self.assertNotIn('ImmersiveNetworks',sandbar)
    for s in DATA['sites']:
        self.assertTrue((ROOT/f'sources/wiki_text/{s["id"]}.md').exists())
        code=(ROOT/f'levels/{s["id"]}/{s["id"]}.gd').read_text()
        self.assertIn('ImmersiveNetworks.install(self)',code)
        self.assertIn(f'const ImmersiveNetworks := preload(',code)

 def test_02_all_walkways_stairs_and_locked_optional_have_valid_topology(self):
    for site in DATA['sites']:
        sid=site['id'];nodes=site['nodes']; edges=site['links']
        self.assertEqual(reachable(site,False),set(nodes),sid)
        self.assertEqual(reachable(site,True),set(nodes),sid)
        self.assertEqual(sum(e['kind']=='stair' for e in edges),2)
        self.assertEqual(sum(e['kind']=='optional' for e in edges),1)
        self.assertEqual(len(site['surveys']),3)
        a,b=site['optional_edge']
        self.assertTrue(any(e['kind']=='optional' and {e['a'],e['b']}=={a,b} for e in edges))
        self.assertEqual({site['nodes'][a][1],site['nodes'][b][1]},{site['origin'][1]+3.5})
        for edge in edges:
            a,b=nodes[edge['a']],nodes[edge['b']]
            distance=math.hypot(a[0]-b[0],a[2]-b[2])
            if edge['kind']=='stair':
                self.assertAlmostEqual(distance,28,places=2)
                self.assertAlmostEqual(b[1]-a[1],3.5)
                self.assertLess(math.degrees(math.atan(3.5/20)),15)
            else:
                self.assertAlmostEqual(a[1],b[1])
                self.assertAlmostEqual(distance,16,places=2)
                self.assertTrue(abs(a[0]-b[0])<.01 or abs(a[2]-b[2])<.01)
        self.assertAlmostEqual(math.hypot(site['entry'][0]-nodes['b_16_0'][0],
                                site['entry'][2]-nodes['b_16_0'][2]),16)
        # The entry connector MUST overlap the old deck. Previous iterations
        # accidentally created a 4m open-air drop before the new route.
        code=(ROOT/'core/world/ImmersiveNetworks.gd').read_text()
        self.assertIn('var begin := entry-dir*2.0',code)
        self.assertIn('var finish := first-dir*3.75',code)
        self.assertIn('_connector(k,entry,nodes[first]',code)

 def test_03_existing_props_exist_and_keep_center_portals_clear(self):
    used=set()
    for site in DATA['sites']:
        for item in site['props']:
            self.assertIn(item['node'],site['nodes'])
            key=f'assets/packs/{item["pack"]}/{item["model"]}.glb'
            self.assertIn(key,CAT);self.assertTrue((ROOT/key).exists());used.add(key)
            sx,sy,sz=map(float,CAT[key]['size'])
            factor=min(8.0,float(item['height'])/max(.18,sy))
            span=max(sx,sz)*factor
            self.assertLessEqual(span,1.56,key)
            self.assertLessEqual(abs(item['dx'])+span/2,4.0)
            self.assertLessEqual(abs(item['dz'])+span/2,4.0)
            self.assertGreaterEqual(min(abs(item['dx']),abs(item['dz']))-span/2,1.85)
    self.assertGreaterEqual(len(used),25)

 def test_04_l149_islands_physically_separate_but_hoppable(self):
    islands=ISLES['islands'];self.assertEqual(len(islands),13)
    self.assertGreaterEqual(sum(r['palms'] for r in islands),50)
    self.assertEqual(sum(len(r['props']) for r in islands),39)
    # First island really overlaps the main island (-30..30) of original scene.
    self.assertGreaterEqual(islands[0]['pos'][0]+islands[0]['radius'],-30.0)
    graph=defaultdict(set)
    for i,a in enumerate(islands):
        for j,b in enumerate(islands[i+1:],i+1):
            va=a['pos'];vb=b['pos']
            free=math.hypot(va[0]-vb[0],va[2]-vb[2])-(a['radius']+b['radius'])
            if free<=5.0 and abs(va[1]-vb[1])<=3.5:
                graph[i].add(j);graph[j].add(i)
        for p in a['props']:
            key=f'assets/packs/{p["pack"]}/{p["model"]}.glb'
            self.assertIn(key,CAT)
    seen={0};todo=[0]
    for a in todo:
        for b in graph[a]:
            if b not in seen:seen.add(b);todo.append(b)
    self.assertEqual(len(seen),len(islands))
    self.assertGreaterEqual(sum(map(len,graph.values()))//2-len(islands)+1,2)
    island_src=(ROOT/'levels/L149/L149.gd').read_text()
    self.assertIn('IslandBiomes25.install(self)',island_src)
    self.assertIn('_island_count==15',island_src) # baseline still intact

 def test_05_runtime_state_is_real_and_source_exits_unmodified(self):
    proc=(ROOT/'core/world/ImmersiveNetworks.gd').read_text()
    state=(ROOT/'core/world/ImmersiveNetworkState.gd').read_text()
    islands=(ROOT/'core/world/IslandBiomes25.gd').read_text()
    for flag in ['k.slab(', 'k.stairs(', 'k.commit()', 'Dress._place(owner,visuals,d)',
                 'Callable(state,"survey").bind(idx)', 'Callable(state,"operate_bridge")',
                 'Callable(state,"switch_light").bind(light_idx)']:
        self.assertIn(flag,proc)
    for flag in ['StaticBody3D.new()', 'CollisionShape3D.new()',
                 'bridge_shape.set_deferred("disabled",not active)',
                 'SaveService.record_discovery(', 'func survey(_player: Player, index: int)']:
        self.assertIn(flag,state)
    self.assertIn('k.cylinder(at+Vector3(0,-1.0,0),radius,2.0',islands)
    self.assertIn('Dress._place(owner,glb_owner,prop)',islands)
    for src in (proc,state,islands):
        self.assertNotIn('add_exit(',src)
        self.assertNotIn('TransitionService.',src)

 def test_06_generators_deterministic_and_sources_syntax_checked(self):
    files=[('tools/generate_dev25_immersive_networks.py','data/dev25_immersive_networks.json'),
           ('tools/generate_dev25_island_chain.py','data/dev25_coconut_island_variants.json')]
    for script,data in files:
        path=ROOT/data; original=hashlib.sha256(path.read_bytes()).hexdigest()
        subprocess.run([sys.executable,script],cwd=ROOT,check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        self.assertEqual(original,hashlib.sha256(path.read_bytes()).hexdigest())
    scripts=['core/world/ImmersiveNetworks.gd','core/world/ImmersiveNetworkState.gd',
             'core/world/IslandBiomes25.gd','core/world/IslandObservation25.gd']
    scripts += [f'levels/{sid}/{sid}.gd' for sid in ['L041','L048','L069','L100','L140','L149','L201']]
    for name in scripts:
        self.assertEqual(string_and_delimiter_check((ROOT/name).read_text(),name),[])
    self.assertEqual(len(list((ROOT/'assets/packs').rglob('*.glb'))),414)
    self.assertEqual(len(list((ROOT/'levels').rglob('level.json'))),100)

if __name__=='__main__':unittest.main()
