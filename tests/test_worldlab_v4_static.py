"""Independent grid-level checks for ContinuityLab v4 (NOT native physics).

The Python oracle reproduces only the geometric invariants, not Godot's
collider behaviour. Run with `python -m unittest discover -s tests
-p 'test_worldlab*static.py' -v`.
"""
import itertools
import math
import unittest
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOP = (ROOT / 'core/world/ContinuityTopology.gd').read_text(encoding='utf-8')
LAB = (ROOT / 'labs/Level0ContinuityLab.gd').read_text(encoding='utf-8')
WORLD = (ROOT / 'core/world/ChunkWorld3D.gd').read_text(encoding='utf-8')


def ssuper(k):
    return (k[0] // 8, k[2] // 8)


def spine(k):
    return k[0] % 8 in (3, 4) or k[2] % 8 in (3, 4)


def hub(k):
    return k[0] % 8 in (3, 4) and k[2] % 8 in (3, 4)


def core(k):
    return k[0] % 4 in (1, 2) and k[2] % 4 in (1, 2)


def super_hole(k):
    if not hub(k) or k[1] == -2:
        return None
    return (20 if k[0] % 8 == 3 else 0,
            20 if k[2] % 8 == 3 else 0, 4, 4)


def super_bridge(k):
    h = super_hole(k)
    return None if h is None else (h[0], h[1] + .8, 4, 2.4)


def in_rect(x, z, rect):
    return bool(rect) and rect[0] <= x < rect[0] + rect[2] and rect[1] <= z < rect[1] + rect[3]


def walkable_at(k, x, z):
    if k[1] == -2:
        return True
    xshaft = 6 if (k[1] - 1) % 2 == 0 else 15
    stair = (xshaft - .6, 5.4, 4.2, 13.2)
    h = super_hole(k)
    return not in_rect(x, z, stair) and (not in_rect(x, z, h) or in_rect(x, z, super_bridge(k)))


def face(k, direction):
    dx, dz = {'east': (1, 0), 'west': (-1, 0), 'north': (0, 1), 'south': (0, -1)}[direction]
    n = (k[0] + dx, k[1], k[2] + dz)
    if core(k) and core(n) and (k[0]//4,k[2]//4)==(n[0]//4,n[2]//4):
        return ('core', 12)
    if hub(k) and hub(n) and ssuper(k)==ssuper(n):
        return ('hub', (12, 22 if (k[2] if direction in ('east','west') else k[0])%8==3 else 2))
    if spine(k) and spine(n):
        return ('spine', 12)
    # V3 random position uses one canonical face owner. We verify ownership.
    owner = n if direction in ('west', 'south') else k
    return ('default', owner[0], owner[1], owner[2], 'x' if direction in ('east','west') else 'z')


class V4SuperDistrictContracts(unittest.TestCase):
    def test_v4_godot_functions_exist(self):
        for item in ('func super_key', 'func super_type', 'func is_super_spine',
                     'func is_superhub', 'func superhub_hole', 'func superhub_bridge',
                     'func continuity_hole', 'func continuity_bridge',
                     'func is_superhub_edge', 'func is_super_spine_edge'):
            self.assertIn(item, TOP)
        for item in ('_add_super_spine_architecture', '_add_super_terminal',
                     '_toggle_super_network', '_locate_unexplored_hub'):
            self.assertIn(item, LAB)

    def test_8_by_8_superregions_have_coherent_spines(self):
        for mx in range(-3,4):
            for mz in range(-3,4):
                x0,z0 = mx*8,mz*8
                cells = {(x0+x,z0+z) for x in range(8) for z in range(8) if spine((x0+x,0,z0+z))}
                self.assertEqual(len(cells),28)
                self.assertEqual(len({(x0+x,z0+z) for x in (3,4) for z in (3,4)}),4)
                for z in range(8):
                    self.assertIn((x0+3,z0+z),cells)
                    self.assertIn((x0+4,z0+z),cells)
                for x in range(8):
                    self.assertIn((x0+x,z0+3),cells)
                    self.assertIn((x0+x,z0+4),cells)

    def test_negative_space_coordinate_contract(self):
        self.assertEqual(ssuper((-1,0,-1)),(-1,-1))
        self.assertEqual(ssuper((-8,0,-8)),(-1,-1))
        self.assertEqual(ssuper((-9,0,-9)),(-2,-2))
        for x in (-13,-12,-5,-4,3,4,11,12):
            self.assertEqual(x//8, math.floor(x/8))

    def test_every_shared_face_has_identical_design_both_sides(self):
        opposites={'east':'west','west':'east','north':'south','south':'north'}
        steps={'east':(1,0),'west':(-1,0),'north':(0,1),'south':(0,-1)}
        for x,z in itertools.product(range(-17,18),repeat=2):
            k=(x,0,z)
            for f,step in steps.items():
                n=(x+step[0],0,z+step[1])
                self.assertEqual(face(k,f),face(n,opposites[f]))

    def test_hub_void_is_four_aligned_quadrants_at_every_level(self):
        for sx,sz in itertools.product(range(-3,4),repeat=2):
            x,z=sx*8,sz*8
            for y in range(-1,3):
                coords=[(x+3,y,z+3),(x+4,y,z+3),(x+3,y,z+4),(x+4,y,z+4)]
                self.assertEqual([super_hole(k) for k in coords],
                                 [(20,20,4,4),(0,20,4,4),(20,0,4,4),(0,0,4,4)])
                self.assertTrue(all(super_hole((k[0],-2,k[2])) is None for k in coords))

    def test_hub_bridge_crosses_x_seam_with_supported_floor(self):
        for sx,sz in itertools.product(range(-2,3),repeat=2):
            x,z=sx*8,sz*8
            for y in range(-1,3):
                for iz in (3,4):
                    zz=21.9 if iz==3 else 2.1
                    for ix in (3,4):
                        k=(x+ix,y,z+iz)
                        for xx in ((20.2,22.0,23.8) if ix==3 else (.2,2.,3.8)):
                            self.assertTrue(walkable_at(k,xx,zz),(k,xx,zz))

    def test_stair_and_hub_opening_do_not_overlap(self):
        for floor in range(-1,3):
            xshaft=6 if (floor-1)%2==0 else 15
            ax,bx=xshaft-.6,xshaft+3.6
            for ix,iz in itertools.product((3,4), repeat=2):
                h=super_hole((ix,floor,iz))
                self.assertTrue(bx<=h[0] or ax>=h[0]+h[2])

    def test_walkable_cross_shaped_portal_centres(self):
        for floor in range(-2,3):
            for x,z in itertools.product(range(-17,18),repeat=2):
                k=(x,floor,z)
                if not spine(k):
                    continue
                for xx,zz in ((.4,12),(23.6,12),(12,.4),(12,23.6)):
                    self.assertTrue(walkable_at(k,xx,zz),(k,xx,zz))

    def test_superdistrict_spines_connected_across_multiple_regions(self):
        vertices={(x,z) for x in range(-16,16) for z in range(-16,16) if spine((x,0,z))}
        origin=(3,3)
        q=deque([origin]); seen={origin}
        while q:
            x,z=q.popleft()
            for d in ((1,0),(-1,0),(0,1),(0,-1)):
                n=(x+d[0],z+d[1])
                if n in vertices and n not in seen:
                    seen.add(n); q.append(n)
        self.assertEqual(seen,vertices)

    def test_routing_does_not_depend_on_mutable_room_versions(self):
        self.assertNotIn('version', TOP[TOP.index('static func super_key'):TOP.index('## One quadrant of a 10x10m')])
        self.assertIn('ContinuityTopology.continuity_hole(world.seed_value, key)',LAB)
        self.assertIn('ContinuityTopology.continuity_bridge(world.seed_value, key)',LAB)
        self.assertIn('if not ContinuityTopology.is_macro_core(key) and not ContinuityTopology.is_super_spine(key):',LAB)

    def test_periodic_save_and_safe_chunk_rebuild(self):
        self.assertIn('const AUTOSAVE_SECONDS := 12.0',WORLD)
        self.assertIn('if disk_persistence_enabled and _dirty',WORLD)
        # v5 replaced the explicit remove_child with a safe detach: the chunk
        # is hidden and its collision is switched off before the free queue
        # removes it, so a rebuilt chunk never has two overlapping bodies in
        # the same physics frame, and the streamer never removes a child
        # while the tree root is busy.
        self.assertIn('n.visible = false',WORLD)
        self.assertIn('body.collision_layer = 0',WORLD)
        self.assertIn('n.queue_free()',WORLD)
        self.assertIn('NOTIFICATION_WM_CLOSE_REQUEST',WORLD)
        self.assertIn('world.save_to_disk()',LAB)

    def test_actual_interaction_uses_separate_lab_state(self):
        self.assertIn('world.set_change(anchor, "network_online", not active)',LAB)
        self.assertIn('world.change_of(survey_anchor, "network_online", false)',LAB)
        self.assertIn('KEY_F2', LAB)
        self.assertNotIn('SaveService.save_story(', LAB)

    def test_all_six_theme_silhouettes(self):
        for name in ('vertical_foundry','deserted_transit_hub','hanging_city',
                     'great_archive','service_cathedral','silent_cistern','threshold_nexus'):
            self.assertIn('"'+name+'"',LAB)
        self.assertIn('match stype:',LAB)


if __name__=='__main__':
    unittest.main()
