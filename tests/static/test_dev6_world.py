"""Dev6 offline contract tests. Not a GDScript compiler or actual game runtime."""
from pathlib import Path
import json,re,unittest,sys
ROOT=Path(__file__).resolve().parents[2]
SIDS=('L017', 'L018', 'L030', 'L069', 'L073', 'L000_2', 'L001_3', 'L001_5', 'L003_5', 'L005_1', 'L007_7', 'L010_1', 'L011_3', 'L037_1', 'L096', 'L965')
sys.path.insert(0,str(ROOT/'tools'))
from preflight_dev import string_and_delimiter_check
class Dev6Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.roster={x['stable_id'] for x in json.loads((ROOT/'data/canon/levels.json').read_text())['levels']}
        cls.canon={x['id']:x for x in json.loads((ROOT/'data/canon/transitions.json').read_text())['edges']}
    def test_new_scene_manifest_roster_and_status(self):
        for sid in SIDS:
            with self.subTest(sid=sid):
                self.assertIn(sid,self.roster)
                d=ROOT/'levels'/sid
                self.assertTrue((ROOT/'docs/canon/levels'/f'{sid}.md').exists())
                self.assertTrue((d/f'{sid}.gd').exists())
                self.assertTrue((d/f'{sid}.tscn').exists())
                m=json.loads((d/'level.json').read_text())
                self.assertEqual(m['status'],'IN_DEVELOPMENT')
                self.assertIn('NOT ENGINE VERIFIED',m['qa_status'])
                self.assertIn('start',m['arrivals'])
                self.assertGreaterEqual(len(m['mechanics']),3)
                self.assertEqual(m['scene'],f'res://levels/{sid}/{sid}.tscn')
    def test_all_created_exits_are_exact_canonical(self):
        for sid in SIDS:
            with self.subTest(sid=sid):
                d=ROOT/'levels'/sid
                gd=(d/f'{sid}.gd').read_text()
                manifest=json.loads((d/'level.json').read_text())
                physical=re.findall(r'add_exit\("([^"\n]+)"',gd)
                self.assertEqual(len(physical),len(set(physical)))
                self.assertEqual(set(physical),{e['id'] for e in manifest['exits']})
                for e in manifest['exits']:
                    self.assertIn(e['id'],self.canon)
                    self.assertEqual(e['basis'],'SOURCE')
                    self.assertEqual(self.canon[e['id']]['from'],sid)
                    self.assertEqual(e['to'],self.canon[e['id']]['to'] or 'EXT')
                    self.assertTrue(e['source_url'].startswith('https://'))
    def test_no_fabricated_exits_for_unknown_destinations(self):
        for sid in ('L017','L030','L073','L001_5','L010_1','L037_1','L096','L965'):
            with self.subTest(sid=sid):
                m=json.loads((ROOT/'levels'/sid/'level.json').read_text())
                self.assertEqual(m['exits'],[])
    def test_individual_scene_cameras_interactivity_and_physical_geometry(self):
        for sid in SIDS:
            with self.subTest(sid=sid):
                gd=(ROOT/'levels'/sid/f'{sid}.gd').read_text()
                for required in ('extends LevelBase','func build()->void:','k.commit()','add_arrival("start"','add_landmark(','add_shot(','func qa_self_test()->Array:'):
                    self.assertIn(required,gd)
                self.assertGreaterEqual(gd.count('add_shot('),2)
                self.assertFalse(string_and_delimiter_check(gd,sid+'.gd'))
    def test_complex_scenes_have_nonshared_mechanics(self):
        checks={'L017':['CarrierBulkheads','_read_clock'], 'L018':['MemoriesPreschool','_remember'],
        'L030':['ShiftedVoid','_hear'], 'L069':['RoadTrip','_vehicle_safe'],
        'L073':['MoonlitRedlands','_knock'], 'L000_2':['CollapseDebris','_collapsed'],
        'L001_3':['WhiteHalls','_rest'], 'L001_5':['InvertedHalls','_silence'],
        'L003_5':['ElectropolisBrutalism','_discharge_active'], 'L005_1':['GrandCasino','_chips'],
        'L007_7':['CarrierLighthouse','k.ramp(','i%2==0'],
        'L010_1':['ContaminatedLake','_exposure'],
        'L011_3':['RedLightDistrict','_masked'], 'L037_1':['SanguineReservoir','_water_darken'],
        'L096':['SolaceHouse','_sweep'], 'L965':['ColorfulColorlessPlain','turbine']}
        for sid,parts in checks.items():
            gd=(ROOT/'levels'/sid/f'{sid}.gd').read_text()
            for part in parts:self.assertIn(part,gd)
    def test_world_map_shows_directed_preview_not_teleport(self):
        s=(ROOT/'ui/WorldGraph.gd').read_text()
        self.assertIn('func preview_route_to(target: String)',s)
        self.assertIn('var parent := {}',s)
        self.assertIn('str(edge.get("from", "")) == source',s)
        overlay=(ROOT/'ui/Overlay.gd').read_text()
        self.assertIn('DIRECTED ROUTE PREVIEW',overlay)
        self.assertIn('physical traversal not verified',overlay)
    def test_arrival_audit_clear_and_provisional_is_explicit(self):
        from world_audit import audit
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            report=audit(root=ROOT,output=Path(d),render=False)
            self.assertEqual(report['issues'],[])
            self.assertGreaterEqual(report['built_count'],84)
    def test_fail_closed_windows_release_gates(self):
        s=(ROOT/'EXPORT_DEV6_WINDOWS.ps1').read_text()
        self.assertIn('run_dev6_qa.py',s)
        self.assertIn('refusing release build',s)
        self.assertIn('Manual launch and GPU checks',s)
        self.assertIn('production_gate.py --release',s)
if __name__=='__main__':unittest.main()
