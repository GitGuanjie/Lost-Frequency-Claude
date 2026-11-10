"""Independent static contracts for ContinuityLab v5.

These check the SOURCE contract of the new layers (world addressing, zone
identity, the multiscale regional plan and the native physical traversal
test). They are NOT a substitute for the native Godot tests: run

    godot --headless --path . --script res://tests/ContinuityRegionalPlanTest.gd
    godot --headless --path . res://tests/ContinuityPhysicalWalkTest.tscn

for the real evidence.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOP = (ROOT / 'core/world/ContinuityTopology.gd').read_text(encoding='utf-8')
PLAN = (ROOT / 'core/world/RegionalPlan.gd').read_text(encoding='utf-8')
ADDR = (ROOT / 'core/world/WorldAddress.gd').read_text(encoding='utf-8')
LAB = (ROOT / 'labs/Level0ContinuityLab.gd').read_text(encoding='utf-8')
WORLD = (ROOT / 'core/world/ChunkWorld3D.gd').read_text(encoding='utf-8')
WALK = (ROOT / 'tests/ContinuityPhysicalWalkTest.gd').read_text(encoding='utf-8')


class V5WorldIdentityContracts(unittest.TestCase):
    def test_hard_coded_x_split_is_gone(self):
        # The old rule was an x-threshold split into a yellow zone and a
        # proxy zone, which cut the central superdistrict hub in half and
        # passed a warehouse off as the canonical Level 1.
        self.assertNotIn('k.x >= 4', TOP)
        self.assertNotIn('L001_PROXY', TOP)
        self.assertNotIn('L001_PROXY', LAB)
        self.assertNotIn('"L000"', TOP)

    def test_zone_is_superdistrict_aligned(self):
        for item in ('const ZONE_YELLOW', 'const ZONE_PROXY', 'const ZONE_GENERIC',
                     'static func zone_id', 'static func proxy_super_key',
                     'static func zone_id_for_super', 'static func is_proxy_zone'):
            self.assertIn(item, TOP)
        self.assertIn('super_key(k)', TOP)

    def test_proxy_zone_never_covers_the_spawn_district(self):
        native = (ROOT / 'tests/ContinuityTopologyTest.gd').read_text(encoding='utf-8')
        self.assertIn('proxy zone is not the spawn district', native)
        self.assertIn('central hub is never split across zones', native)
        self.assertIn('hub stays in one zone for every seed', native)

    def test_explicit_address_type_exists(self):
        for item in ('class_name WorldAddress', 'var world_id', 'var zone_id',
                     'var chunk', 'var local_position', 'static func from_position',
                     'static func decode'):
            self.assertIn(item, ADDR)
        self.assertIn('WorldAddress.from_position', LAB)

    def test_canonical_level_identity_is_not_the_physical_address(self):
        # A canonical level is a story destination; the lab addresses places.
        self.assertIn('Canonical Backrooms identity', ADDR)
        self.assertNotIn('"L001"', LAB)


class V5RegionalPlanContracts(unittest.TestCase):
    def test_plan_layers_exist(self):
        for item in ('class_name RegionalPlan', 'const GENERATOR_VERSION',
                     'static func district_plan', 'static func super_plan',
                     'static func chunk_plan', 'static func structure_of',
                     'static func zone_material_family', 'static func family_materials',
                     'static func structure_accent'):
            self.assertIn(item, PLAN)

    def test_plan_spans_the_multiscale_layers(self):
        self.assertIn('const DISTRICT_SPAN := 16', PLAN)
        self.assertIn('const SUPER_SPAN := 8', PLAN)
        self.assertIn('const MACRO_SPAN := 4', PLAN)

    def test_megastructure_kinds_exist(self):
        for kind in ('arcade', 'machine_hall', 'shaft_stack', 'archive_block'):
            self.assertIn('"%s"' % kind, PLAN)

    def test_chunks_take_their_architecture_from_the_plan(self):
        self.assertIn('RegionalPlan.chunk_plan(world.seed_value, key)', LAB)
        self.assertIn('_add_megastructure', LAB)
        self.assertIn('plan["role"]', LAB)
        self.assertIn('plan["structure_kind"]', LAB)

    def test_level_zero_material_identity_is_preserved(self):
        self.assertIn('FAMILY_LEVEL0', PLAN)
        self.assertIn('"floor": "l0_carpet"', PLAN)
        self.assertIn('"wall": "l0_wallpaper"', PLAN)
        self.assertIn('"floor": "concrete_dark"', PLAN)

    def test_plan_never_consults_the_mutable_room_version(self):
        # The regional plan must not take the reshuffle counter as an input.
        head = PLAN[:PLAN.index('static func chunk_plan')]
        self.assertNotIn('version_of', head)
        self.assertNotIn(', version', head)
        self.assertNotIn('version:', head)


class V5PhysicalWalkContracts(unittest.TestCase):
    def test_native_walker_test_exists(self):
        for item in ('extends Node', 'func _walk_route', 'func _choose_direction',
                     'func _probe', 'player.test_move', 'CharacterBody3D'):
            self.assertIn(item, WALK)
        self.assertTrue((ROOT / 'tests/ContinuityPhysicalWalkTest.tscn').is_file())

    def test_walker_covers_the_required_traversals(self):
        for item in ('east portal', 'negative chunk coordinates',
                     'climbs the staircase', 'atrium bridge',
                     'returns to the spawn'):
            self.assertIn(item, WALK)

    def test_walker_is_not_a_teleport(self):
        # The only placement is the documented one next to the atrium bridge.
        self.assertEqual(WALK.count('player.global_position ='), 1)


class V5StreamingContracts(unittest.TestCase):
    def test_streamer_has_no_compile_time_autoload_dependency(self):
        # A hard `SaveService` identifier made the class unloadable in a
        # headless --script run, which is where the native tests live.
        self.assertNotIn('SaveService.scope()', WORLD)
        self.assertIn('_save_service()', WORLD)

    def test_streamer_persists_per_world(self):
        for item in ('disk_path', 'world_id', '.bak', '"schema"'):
            self.assertIn(item, WORLD)
        # A per-seed file name keeps worlds isolated from each other.
        self.assertIn('world_%d.json', LAB)


if __name__ == '__main__':
    unittest.main()
