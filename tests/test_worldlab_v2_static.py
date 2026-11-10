"""Offline architecture contract checks; NOT a substitute for Godot QA.
Run: python3 -m unittest tests/test_worldlab_v2_static.py -v
"""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
LAB = (ROOT / "labs/Level0ContinuityLab.gd").read_text(encoding='utf-8')
TOP = (ROOT / "core/world/ContinuityTopology.gd").read_text(encoding='utf-8')
WORLD = (ROOT / "core/world/ChunkWorld3D.gd").read_text(encoding='utf-8')
MAIN = (ROOT / "ui/MainMenu.gd").read_text(encoding='utf-8')


class WorldLabV2StaticContracts(unittest.TestCase):
    def test_four_side_walls_created(self):
        self.assertIn('["west", "east", "south", "north"]', LAB)
        for face in ("west", "east", "south", "north"):
            self.assertIn('"%s":' % face, LAB)

    def test_shared_door_owner_contract(self):
        self.assertIn('func face_owner', TOP)
        self.assertIn('k + Vector3i(-1, 0, 0)', TOP)
        self.assertIn('k + Vector3i(0, 0, -1)', TOP)
        self.assertIn('face_owner(k, face)', TOP)
        self.assertIn('"w": 4.0', TOP)  # V3's shared face_openings owns the baseline width

    def test_floor_stair_and_guardrail(self):
        self.assertIn('_floor_with_slot', LAB)
        self.assertIn('ContinuityTopology.incoming_shaft', LAB)
        self.assertIn('ContinuityTopology.outgoing_shaft', LAB)
        self.assertIn('var railing := "metal"', LAB)

    def test_macro_and_local_motifs(self):
        self.assertIn('func macro_theme', TOP)
        self.assertIn('func room_type', TOP)
        self.assertIn('func _add_room_partitions', LAB)
        self.assertIn('"abandoned_archive"', LAB)
        self.assertIn('"structural_gallery"', LAB)

    def test_discovery_and_visited_persistence(self):
        self.assertIn('func _collect_discovery', LAB)
        self.assertIn('"discovered", true', LAB)
        self.assertIn('"visited", true', LAB)
        self.assertIn('func save_to_disk', WORLD)
        self.assertIn('"changes": chunk_changes', WORLD)

    def test_seed_isolation(self):
        self.assertIn('selected_seed.txt', LAB)
        self.assertIn('world_%d.json', LAB)
        self.assertIn('func _new_world', LAB)
        self.assertIn('func refresh_chunk', WORLD)
        self.assertIn('world.call_deferred("refresh_chunk"', LAB)

    def test_explicit_non_canon_separation(self):
        self.assertIn('NON-CANON', LAB)
        self.assertIn('res://labs/Level0ContinuityLab.tscn', MAIN)
        self.assertIn('SessionState.Mode.DEVELOPER', LAB)
        self.assertNotIn('SaveService.save_story', LAB)

    def test_minimap_and_controls(self):
        for key in ('KEY_F4', 'KEY_F6', 'KEY_F8', 'KEY_F9', 'KEY_F10'):
            self.assertIn(key, LAB)

    def test_old_level_registry_not_modified(self):
        self.assertFalse((ROOT / 'data/canon/transitions.json').stat().st_size == 0)
        self.assertTrue((ROOT / 'levels/L000/L000.gd').exists())


if __name__ == "__main__":
    unittest.main()
