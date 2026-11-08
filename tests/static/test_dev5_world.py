"""Dev5 static provenance, scene wiring, and conditional-exit guard tests.

These ARE NOT Godot runtime, Windows launch, physical navigation, or GPU tests.
"""
from pathlib import Path
import json
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
SIDS = ('L001_2','L016','L024','L026','L028','L029','L041','L050','L071','L094','L100','L114')

sys.path.insert(0, str(ROOT/'tools'))
from preflight_dev import string_and_delimiter_check

class Dev5Integrity(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.edges = {e['id']:e for e in json.loads((ROOT/'data/canon/transitions.json').read_text())['edges']}
        cls.roster = {e['stable_id'] for e in json.loads((ROOT/'data/canon/levels.json').read_text())['levels']}

    def test_source_and_runtime_files(self):
        for sid in SIDS:
            with self.subTest(level=sid):
                self.assertIn(sid,self.roster)
                self.assertTrue((ROOT/f'docs/canon/levels/{sid}.md').is_file())
                m=json.loads((ROOT/f'levels/{sid}/level.json').read_text())
                self.assertEqual(m['status'],'IN_DEVELOPMENT')
                self.assertIn('NOT ENGINE VERIFIED',m['qa_status'])
                self.assertIn('start',m['arrivals'])
                self.assertGreaterEqual(len(m['mechanics']),3)
                self.assertEqual(m['scene'],f'res://levels/{sid}/{sid}.tscn')
                t=(ROOT/f'levels/{sid}/{sid}.tscn').read_text()
                self.assertIn(f'res://levels/{sid}/{sid}.gd',t)

    def test_actual_exit_definitions_match_exact_canon_ids(self):
        for sid in SIDS:
            with self.subTest(level=sid):
                m=json.loads((ROOT/f'levels/{sid}/level.json').read_text())
                gd=(ROOT/f'levels/{sid}/{sid}.gd').read_text()
                physical=re.findall(r'add_exit\("([^"\n]+)"', gd)
                self.assertEqual(len(physical),len(set(physical)))
                self.assertEqual(set(physical),{e['id'] for e in m['exits']})
                for e in m['exits']:
                    self.assertIn(e['id'],self.edges)
                    self.assertEqual(self.edges[e['id']]['from'],sid)
                    self.assertEqual(e['basis'],'SOURCE')
                    self.assertEqual(e['to'],self.edges[e['id']]['to'] or 'EXT')
                    self.assertTrue(e['source_url'].startswith('https://'))

    def test_interact_exits_need_physical_occupancy(self):
        gd=(ROOT/'core/routing/ExitTrigger.gd').read_text()
        self.assertIn('_inside != _p',gd)
        self.assertIn('condition.is_valid() and not condition.call()',gd)
        self.assertIn('if condition.is_valid() and condition.call():\n\t\t\t\tfire()',gd)

    def test_scene_files_are_lexically_balanced(self):
        files=[ROOT/f'levels/{sid}/{sid}.gd' for sid in SIDS]
        files += [ROOT/'core/routing/ExitTrigger.gd']
        for f in files:
            with self.subTest(path=str(f.relative_to(ROOT))):
                self.assertFalse(string_and_delimiter_check(f.read_text(),f.name))

    def test_no_unsourced_exits_in_uncertain_levels(self):
        for sid in ('L050','L071'):
            m=json.loads((ROOT/f'levels/{sid}/level.json').read_text())
            self.assertEqual(m['exits'],[])

    def test_distinctive_builds_have_real_3d_mechanics(self):
        expect={
            'L001_2':['for i in 165:','_vision(idx)','add_exit('],
            'L016':['rules["gravity"]=4.6','_switch_clock','k.slab('],
            'L024':['"l24_paint"','_alarms','add_exit('],
            'L026':['k.stairs(','_cabins','_fog_time'],
            'L028':['k.stairs(','for i in 6:','_lightning'],
            'L029':['_harbor_count','for i in 30:','add_exit('],
            'L041':['k.slab(-28,17,32,24','_islands'],
            'L050':['_vehicles','_inspect_count','k.slab('],
            'L071':['_data_errors','_fade_seconds','add_note('],
            'L094':['k.stairs(','_night','k.cylinder('],
            'L100':['WaterVolume.new()','_read_count','end.hold_seconds'],
            'L114':['void_exit.fall_y','bed.condition','_ready_for_sleep()'],
        }
        for sid,needles in expect.items():
            with self.subTest(level=sid):
                gd=(ROOT/f'levels/{sid}/{sid}.gd').read_text()
                for needle in needles:
                    self.assertIn(needle,gd)
                self.assertIn('add_shot(',gd)
                self.assertIn('qa_self_test()',gd)

if __name__=='__main__':unittest.main()
