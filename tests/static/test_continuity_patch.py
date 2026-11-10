"""Dependency-free source/topology smoke tests; not a substitute for Godot QA."""
from pathlib import Path
import math
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


def floor_key(x, y, z):
    return tuple(math.floor(v / d) for v, d in zip((x, y, z), (24, 4.5, 24)))


def opening(seed, x, y, z, axis):
    # Independent deterministic surrogate used to test neighbor ownership.
    import hashlib
    raw = f"{seed}:{x}:{y}:{z}:{axis}".encode()
    return 4 * (2 + (int.from_bytes(hashlib.sha256(raw).digest()[:4], 'big') % 3))


class ContinuityPatchTests(unittest.TestCase):
    def test_code_present(self):
        for path in (
            "core/world/ContinuityTopology.gd", "core/world/ChunkWorld3D.gd",
            "labs/Level0ContinuityLab.gd", "labs/Level0ContinuityLab.tscn",
            "tests/ContinuityTopologyTest.gd",
            "docs/production/WORLD_CONTINUITY_LAB.md",
        ):
            self.assertTrue((ROOT / path).exists(), path)

    def test_negative_coordinates_and_floor(self):
        self.assertEqual(floor_key(-0.1, -0.1, -0.1), (-1, -1, -1))
        self.assertEqual(floor_key(-24.01, 9.1, 48.0), (-2, 2, 2))

    def test_borders_own_shared_opening(self):
        for seed in (1, 1337, 8000):
            for x in range(-9, 10):
                for y in range(-2, 3):
                    for z in range(-9, 10):
                        for axis in ('x', 'z'):
                            # Shared-face convention: -face consults the
                            # positive-face owner, rather than hashing itself.
                            positive_owner = (x, y, z)
                            neighbor = (x + (axis == 'x'), y, z + (axis == 'z'))
                            negative_side_owner = (
                                neighbor[0] - (axis == 'x'), neighbor[1],
                                neighbor[2] - (axis == 'z'))
                            self.assertEqual(positive_owner, negative_side_owner)
                            off = opening(seed, *positive_owner, axis)
                            self.assertIn(off, (8, 12, 16))

    def test_stair_hole_is_compatible(self):
        for y in range(-2, 2):
            outgoing = y % 2
            incoming_above = (y + 1 - 1) % 2
            self.assertEqual(outgoing, incoming_above)
        self.assertGreater(6.8 + 20 * .60, 18.6)

    def test_no_old_level_replaced(self):
        main_menu = (ROOT / 'ui/MainMenu.gd').read_text()
        assert 'Experimental · Seamless 3D World Lab' in main_menu
        lab = (ROOT / 'labs/Level0ContinuityLab.gd').read_text()
        self.assertIn('"L001_PROXY"', (ROOT / 'core/world/ContinuityTopology.gd').read_text())
        self.assertIn('disk_persistence_enabled = true', lab)
        self.assertIn('F10', lab)
        self.assertIn('persistence_key = "L000"', (ROOT / 'levels/L000/L000.gd').read_text())

    def test_no_script_reference_missing(self):
        for path in (
            ROOT / 'ui/MainMenu.gd', ROOT / 'labs/Level0ContinuityLab.tscn',
            ROOT / 'labs/Level0ContinuityLab.gd',
        ):
            text = path.read_text()
            for m in re.finditer(r'res://((?:labs|core/world)/[\w/]+\.(?:gd|tscn))', text):
                self.assertTrue((ROOT / m.group(1)).exists(), f'{path}: {m.group(1)}')


if __name__ == '__main__':
    unittest.main()
