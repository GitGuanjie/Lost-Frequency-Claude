"""Offline-only integrity checks. These are not Godot scene or gameplay tests."""
from __future__ import annotations
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
import world_audit

NEW_LEVELS = ('L036', 'L060', 'L075', 'L999')


class WorldIntegrityTests(unittest.TestCase):
    def test_reachability_is_directed(self):
        n = {'L000','L001','L002','L999'}
        edges = [{'from':'L000','to':'L001'}, {'from':'L002','to':'L001'}]
        self.assertEqual(world_audit.reach(n, edges), {'L000','L001'})

    def test_declared_scene_and_source(self):
        roster = json.loads((ROOT/'data/canon/levels.json').read_text())['levels']
        ids = {e['stable_id'] for e in roster}
        source = {e['id']:e for e in json.loads((ROOT/'data/canon/transitions.json').read_text())['edges']}
        self.assertEqual(len(ids), 100)
        for sid in NEW_LEVELS:
            with self.subTest(sid=sid):
                self.assertIn(sid, ids)
                manifest=json.loads((ROOT/'levels'/sid/'level.json').read_text())
                self.assertEqual(manifest['stable_id'], sid)
                self.assertEqual(manifest['status'], 'IN_DEVELOPMENT')
                self.assertIn('UNVERIFIED', manifest['qa_status'])
                self.assertEqual(manifest['scene'], f'res://levels/{sid}/{sid}.tscn')
                self.assertTrue((ROOT/'levels'/sid/(sid+'.tscn')).is_file())
                text=(ROOT/'levels'/sid/(sid+'.gd')).read_text()
                self.assertIn('extends LevelBase', text)
                self.assertTrue(manifest['exits'])
                for edge in manifest['exits']:
                    self.assertIn(edge['id'], source)
                    self.assertIn('source_quote', edge)
                    self.assertEqual(edge['basis'], 'SOURCE')
                    self.assertEqual(source[edge['id']]['to'], edge['to'] if edge['to']!='EXT' else None)
                    self.assertIn(f'add_exit("{edge["id"]}"', text)
                for a in manifest['arrivals']:
                    if a in manifest.get("arrival_aliases", []):
                        self.assertTrue(a.startswith("from_"))
                        self.assertIn("_register_provisional_arrivals", (ROOT/"core/world/LevelBase.gd").read_text())
                    else:
                        self.assertIn(f'add_arrival("{a}"', text)

    def test_complete_roster_exits_have_ids_and_arrivals(self):
        entries, built, edges, problems = world_audit.read_data(ROOT)
        self.assertEqual(len(entries), 100)
        self.assertGreaterEqual(len(built), 31)
        self.assertGreaterEqual(len(edges), 127)
        types = {p['type'] for p in problems}
        # Arrival gaps in original manifests are known and must remain visible.
        self.assertTrue(types.issubset({'missing_arrival'}), types)

    def test_recovered_story_origin_is_persistent(self):
        code=(ROOT/'autoload/SaveService.gd').read_text()
        self.assertIn('"last_arrival_edge": {}', code)
        self.assertIn('func set_arrival_edge(', code)
        self.assertIn('gp + ".bak"', code)
        route=(ROOT/'autoload/TransitionService.gd').read_text()
        self.assertIn('SaveService.story.get("last_arrival_edge"', route)
        self.assertIn('SaveService.set_arrival_edge(arrived_via)', route)
        self.assertIn('level build / ready timed out', route)

    def test_menu_and_test_gates(self):
        overlay=(ROOT/'ui/Overlay.gd').read_text()
        mapcode=(ROOT/'ui/WorldGraph.gd').read_text()
        settings=(ROOT/'autoload/Settings.gd').read_text()
        qa=(ROOT/'tests/qa_runner.gd').read_text()
        self.assertIn('world_map_panel = _build_world_map()', overlay)
        self.assertIn('"world_map": [KEY_F6]', settings)
        self.assertIn('func _layout(', mapcode)
        self.assertIn('if developer:', mapcode)
        self.assertIn('physically reached waypoint', qa)
        self.assertIn('qa_prog_before', qa)

    def test_no_extraneous_levels_marked_accepted(self):
        for sid in NEW_LEVELS:
            man=json.loads((ROOT/'levels'/sid/'level.json').read_text())
            self.assertNotIn(man['status'], ('PLAYABLE','ACCEPTED'))


if __name__ == '__main__':
    unittest.main(verbosity=2)
