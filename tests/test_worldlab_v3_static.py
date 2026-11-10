"""Independent architecture invariants for the v3 continuity lab.

These check shared topological specifications *and* sample walkable floor
occupancy. No Godot physics, render or Windows claims are made here.
"""
from pathlib import Path
import collections
import math
import unittest

ROOT = Path(__file__).resolve().parents[1]
TOP = (ROOT / "core/world/ContinuityTopology.gd").read_text(encoding='utf-8')
LAB = (ROOT / "labs/Level0ContinuityLab.gd").read_text(encoding='utf-8')
ORIGINAL = ROOT / "levels/L000/L000.gd"


def core(k):
    x, y, z = k
    return x % 4 in (1, 2) and z % 4 in (1, 2)


def hole(k):
    x, y, z = k
    if not core(k) or y == -2:
        return None
    return (19 if x % 4 == 1 else 0, 19 if z % 4 == 1 else 0, 5, 5)


def bridge(k):
    x, y, z = k
    h = hole(k)
    return (h[0], 20 if z % 4 == 1 else 1, 5, 3) if h else None


def in_rect(x, z, rect):
    if not rect:
        return False
    a, b, w, h = rect
    return a <= x < a + w and b <= z < b + h


def walkable(k, x, z):
    if k[1] == -2:
        return True
    # Incoming stair slot: its shaft alternates with storey parity.
    shaft_x = 6.0 if (k[1] - 1) % 2 == 0 else 15.0
    stair = (shaft_x - 0.6, 5.4, 4.2, 13.2)
    return not in_rect(x, z, stair) and (not in_rect(x, z, hole(k)) or in_rect(x, z, bridge(k)))


class V3WorldTopologyTests(unittest.TestCase):
    def test_godot_implementation_uses_megascale_plan(self):
        for item in ["func macro_structure", "func is_core_edge", "func face_openings",
                     "func atrium_hole", "func atrium_bridge", "func macro_anchor"]:
            self.assertIn(item, TOP)
        for item in ["_floor_with_slot_and_atrium", "_atrium_safety_rails",
                     "_add_superstructure", "_add_power_relay", "_toggle_relay"]:
            self.assertIn(item, LAB)

    def test_four_quadrants_meet_in_one_ten_meter_well(self):
        for y in (-1, 0, 1, 2):
            h = {k: hole(k) for k in ((1, y, 1), (2, y, 1), (1, y, 2), (2, y, 2))}
            self.assertEqual(h[(1, y, 1)], (19, 19, 5, 5))
            self.assertEqual(h[(2, y, 1)], (0, 19, 5, 5))
            self.assertEqual(h[(1, y, 2)], (19, 0, 5, 5))
            self.assertEqual(h[(2, y, 2)], (0, 0, 5, 5))
        for x in (1, 2):
            for z in (1, 2):
                self.assertIsNone(hole((x, -2, z)))  # solid bottom

    def test_well_never_intersects_stair_footprints(self):
        for y in range(-1, 3):
            for x in (1, 2):
                for z in (1, 2):
                    h = hole((x, y, z))
                    assert h
                    sx = 6 if (y - 1) % 2 == 0 else 15
                    stair = (sx - .6, 5.4, 4.2, 13.2)
                    mx = max(h[0], stair[0])
                    mz = max(h[1], stair[1])
                    self.assertGreaterEqual(mx, min(h[0] + h[2], stair[0] + stair[2]) - 1e-7)
                    # Separation by x is guaranteed on these geometry choices.

    def test_main_face_portals_remain_walkable(self):
        # The 11 m core doorway is centred at 12 on every shared face.
        # Check near-edge material floor at all four sides of each centre chunk.
        for y in (-2, -1, 0, 1, 2):
            for x in (1, 2):
                for z in (1, 2):
                    k = (x, y, z)
                    for xx, zz in ((0.5, 12), (23.5, 12), (12, 0.5), (12, 23.5)):
                        self.assertTrue(walkable(k, xx, zz), (k, xx, zz))

    def test_bridge_has_floor_to_floor_continuity_across_x(self):
        for y in (-1, 0, 1, 2):
            for z in (1, 2):
                # west chunk -> east chunk, along z centre of its bridge
                zlocal = 21.5 if z == 1 else 2.5
                for x in (1, 2):
                    k = (x, y, z)
                    for dx in (0.3, 2.5, 4.7):
                        xx = 19 + dx if x == 1 else dx
                        self.assertTrue(walkable(k, xx, zlocal), (k, xx, zlocal))

    def test_relay_persistence_and_world_separation(self):
        self.assertIn('world.set_change(anchor, "relay_active", not old)', LAB)
        self.assertIn('world.change_of(macro_anchor, "relay_active", false)', LAB)
        self.assertIn('world_%d.json', LAB)
        self.assertIn('macro_key(k) == ContinuityTopology.macro_key(anchor)', LAB)

    def test_original_game_canon_untouched(self):
        self.assertTrue(ORIGINAL.is_file())
        self.assertTrue((ROOT / "data/canon/transitions.json").is_file())
        self.assertIn('NON-CANON', LAB)
        self.assertNotIn('SaveService.save_story', LAB)


if __name__ == '__main__':
    unittest.main()
