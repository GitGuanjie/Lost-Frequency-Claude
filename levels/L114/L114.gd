extends LevelBase
## Level 114 "Sweet Dreams" (Backrooms Wikidot rev 108, accessed 2026-11-04; Kai4C and
## Xylense, CC BY-SA 3.0). Dossier: docs/canon/levels/L114.md.
##
## PLAN (read -> design):
## - SOURCE: a childhood bedroom (age 9-12) with an infinite black void behind the doorway;
##   arrival in the doorway facing in, the door behind slightly ajar. Seeded room size,
##   furniture and (70%) a second childhood room fused in erratically at another floor
##   height ("several rooms fused together") -> natural split level of 2-3 steps.
## - SOURCE: the bed is always the same single bed (wooden frame, blue floral sheet) with
##   bed bugs. Lying down bites you; sleeping there wakes you on a Level 9 street (exit 1).
## - SOURCE: appliances are dead (TV, lamps, radio, clock); the light switch is the only
##   working one, on by default, dim sterile white. Off -> the Smilers under the bed and in
##   the closet gap show, slide out and attack until the light is back on.
## - SOURCE: the void is enterable, breathable, low gravity, no swimming up; a ~137 m M.E.G.
##   rope tied to the doorknob lets you climb back. Below its end you are lost (fail state).
## - SOURCE: Stress Mould patches grow over the stay; past ~8 h it becomes hazardous.
##   ADAPTATION: one in-room hour = 45 s of play.
## - SOURCE: windows (only if the room had one; seeded) are occasionally replaced by a
##   malevolent counterpart. Saying "I'm so bored..." in a dull voice leads to Level 25.
## - Interview details (pink stool, poster, duck lamp) are testimony and are not used.

const Room := preload("res://levels/L114/L114_room.gd")
const HOUR := 45.0
const COLD := Color(0.86, 0.92, 1.0)
const GRIN_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float reveal = 0.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.y = -p.y;
	float eyes = 0.0;
	eyes += 1.0 - smoothstep(0.10, 0.13, length((p - vec2(-0.38, 0.42)) * vec2(1.0, 1.5)));
	eyes += 1.0 - smoothstep(0.10, 0.13, length((p - vec2(0.38, 0.42)) * vec2(1.0, 1.5)));
	float outer = 1.0 - smoothstep(0.80, 0.84, length(p - vec2(0.0, 0.55)));
	float inner = 1.0 - smoothstep(0.80, 0.84, length(p - vec2(0.0, 0.80)));
	float grin = clamp(outer - inner, 0.0, 1.0) * step(p.y, 0.2);
	float teeth = step(0.16, fract(p.x * 6.0 + 0.5));
	float m = clamp(eyes + grin * mix(0.35, 1.0, teeth), 0.0, 1.0);
	ALBEDO = vec3(0.95, 0.95, 0.9);
	ALPHA = m * reveal;
}
"""

var R
var light_on := true
var hours := 0.0
var qa_fixture := false
var bed_center := Vector3.ZERO
var knob := Vector3.ZERO
var _knob_local := Vector3.ZERO
var _door_pivot: Node3D
var _door_angle := 16.0
var _door_target := 16.0
var _rope: LadderVolume
var _haul := -1.0
var _was_deep := false
var ceiling_lights: Array = []
var grins: Array = []            # [{node, home, mat}]
var mould: Array = []            # [Node3D]
var _dark_t := 0.0
var _attack_t := 0.0
var _dozing := false
var _doze_t := 0.0
var _asleep := false
var _bed_exit: ExitTrigger
var _in_void := false
var _lost := false
var _lost_t := 0.0
var _said := {}
var _hum: AudioStreamPlayer3D
var _heart: AudioStreamPlayer
var _void_pad: AudioStreamPlayer
var _under: AudioStreamPlayer3D
var _window_bad := false
var _window_t := 120.0
var _glass: MeshInstance3D
var _bitten := 0.0


class BedTrigger extends ExitTrigger:
	var on_use: Callable
	func interact(p: Player) -> void:
		if is_instance_valid(p) and _inside == p and enabled and on_use.is_valid():
			on_use.call(p)


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 60.0
	rules["reverb_room"] = 0.12
	rules["reverb_wet"] = 0.05
	rules["kill_y"] = -400.0
	indoor_env(Color(0.62, 0.68, 0.76), 0.09, Color(0.0, 0.0, 0.0), 0.03)
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.78
	environment.adjustment_contrast = 1.05
	environment.glow_intensity = 0.2
	Room.materials(level_seed)
	R = Room.new(self, kit("Bedroom"))
	R.plan(rng)
	R.shell()
	R.fragment()
	var b: Array = R.bed()
	bed_center = b[0]
	var closet_gap: Vector3 = R.closet(rng)
	_curtains()
	_faded_patches()
	R.k.box(Vector3(R.door_x - 0.75, 0.98, -0.005), Vector3(0.15, 0.2, 0.004), "paper", GeoKit.ALL, false)
	R.k.box(Vector3(R.door_x + 0.47, 1.3, -0.034), Vector3(0.08, 0.12, 0.004), "paper", GeoKit.ALL, false)
	R.k.commit()
	# The door, slightly ajar onto the void; it swings wide when you step onto the
	# threshold. The M.E.G. rope is tied to its outer knob and hangs ~137 m down.
	_door_pivot = Node3D.new()
	_door_pivot.name = "DoorPivot"
	_door_pivot.position = Vector3(R.door_x + 0.43, 0.0, Room.T + 0.02)
	_door_pivot.rotation.y = deg_to_rad(_door_angle)
	add_child(_door_pivot)
	var dk := GeoKit.new(_door_pivot, "DoorLeaf")
	_knob_local = Room.door_leaf(dk)
	dk.commit()
	_rope = LadderVolume.new()
	_rope.name = "MEG_Rope"
	add_child(_rope)
	_rope.setup(Vector3.ZERO, Vector3.ONE)
	_update_rope()
	_furnish()
	_mould()
	_smilers(closet_gap)
	_lights()
	_sounds()
	_interactions()
	var arrive := Vector3(R.door_x, 0.02, -0.12)
	add_arrival("start", arrive, 0.0)
	add_arrival("from_L013", arrive, 0.0)
	add_arrival("from_L029", arrive, 0.0)
	add_landmark("The blue floral bed", bed_center)
	add_landmark("Doorway onto the void", Vector3(R.door_x, 0, 0.1))
	_shots()


func _curtains() -> void:
	if not R.has_window:
		return
	var wz: float = -R.D + 1.15
	for dz in [-0.62, 0.62]:
		R.k.box(Vector3(-R.hx + 0.1, 1.6, wz + dz), Vector3(0.05, 1.15, 0.26), "l114_cloth_c", GeoKit.ALL, false)


## Sun-faded rectangles where posters and frames used to hang: the room has been lived in.
func _faded_patches() -> void:
	MatLib.define("l114_fade", {"albedo_a": Color(0.76, 0.73, 0.66), "albedo_b": Color(0.73, 0.70, 0.62), "stain_amount": 0.1}, "plaster")
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "fade"])
	for i in 3:
		var w := r.randf_range(0.35, 0.7)
		var h := r.randf_range(0.45, 0.9)
		match i:
			0: R.k.box(Vector3(R.hx - 0.004, 1.65, -R.D + 2.6 if not R.frag else -0.5), Vector3(0.006, h, w), "l114_fade", GeoKit.ALL, false)
			1: R.k.box(Vector3(R.closet_x0 - 0.7, 1.6, -R.D + 0.004), Vector3(w * 0.7, h * 0.7, 0.006), "l114_fade", GeoKit.ALL, false)
			2: R.k.box(Vector3(-R.hx + 0.004, 1.5, -R.D + 3.1), Vector3(0.006, h, w), "l114_fade", GeoKit.ALL, false)


func _p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	return Props.place(self, _props_root(), id, pos, yaw, h, collide)


var _props_node: Node3D
func _props_root() -> Node3D:
	if _props_node == null:
		_props_node = Node3D.new()
		_props_node.name = "Furnishings"
		add_child(_props_node)
	return _props_node


func _furnish() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "furnish"])
	var hx: float = R.hx
	var D: float = R.D
	# bedside
	_p("ph/ClassicNightstand_01", Vector3(-hx + 1.32, 0, -D + 0.24), 0.0, 0.0, true)
	_p("kenney/furniture-kit/lamproundfloor", Vector3(-hx + 1.22, 0.7, -D + 0.22), 0.0, 0.42)
	_p("kenney/furniture-kit/books", Vector3(-hx + 1.45, 0.7, -D + 0.27), r.randf_range(-30, 30), 0.07)
	# desk corner: a school desk, its chair, homework
	_p("ph/SchoolDesk_01", Vector3(hx - 0.3, 0, -D + 0.62), -90.0, 0.0, true)
	_p("ph/SchoolChair_01", Vector3(hx - 0.86, 0, -D + 0.7), 90.0 + r.randf_range(-25, 15))
	_p("ph/binder_notebook", Vector3(hx - 0.3, 0.76, -D + 0.5), r.randf_range(-100, -80))
	_p("ph/stationery_supplies", Vector3(hx - 0.2, 0.76, -D + 0.85), -90.0)
	_p("kenney/furniture-kit/radio", Vector3(hx - 0.22, 0.76, -D + 0.4), -90.0, 0.17)
	_p("ph/wall_clock", Vector3(hx - 0.03, 1.85, -D + 0.62), -90.0)
	# bookshelf by the door
	var shelf_z: float = -1.05 if not R.frag else (R.frag_z1 - 0.02) * 0.5
	_p("ph/wooden_bookshelf_worn", Vector3(hx - 0.2, 0, shelf_z), -90.0, 1.4, true)
	for i in 4:
		_p("kenney/furniture-kit/books", Vector3(hx - 0.22, 0.42 + 0.33 * float(i % 3), shelf_z + r.randf_range(-0.3, 0.3)), -90.0, r.randf_range(0.1, 0.14))
	# dresser and the dead television: in the fused room if there is one
	if not R.frag:
		_p("ph/drawer_cabinet", Vector3(hx - 0.17, 0, -D + 2.45), -90.0, 1.1, true)
		_p("ph/Television_01", Vector3(hx - 0.25, 1.1, -D + 2.45), -90.0)
	# west side, toward the door: floor lamp, toy crates, a box of old things
	_p("kenney/furniture-kit/lamproundfloor", Vector3(-hx + 0.25, 0, -D + 2.35), 0.0, 1.45)
	_p("ph/plastic_crate_01", Vector3(-hx + 0.28, 0, -0.55), 90.0, 0.0, true)
	_p("ph/plastic_crate_01", Vector3(-hx + 0.28, 0.26, -0.58), 84.0)
	_p("ph/cardboard_box_01", Vector3(-hx + 0.3, 0, -1.15), r.randf_range(70, 110), 0.0, true)
	# floor clutter on the rug
	var rug := kit("Rug")
	rug.box(Vector3(-0.1, 0.006, -D * 0.5 - 0.1), Vector3(1.7, 0.012, 1.25), "l114_rug", GeoKit.ALL, false)
	rug.commit()
	_p("ph/rubber_duck_toy", Vector3(r.randf_range(-0.6, 0.3), 0.012, -D * 0.5 + r.randf_range(-0.4, 0.3)), r.randf_range(0, 360))
	_p("kenney/furniture-kit/books", Vector3(-0.5, 0.012, -D * 0.5 + 0.35), r.randf_range(0, 360), 0.09)
	_p("kenney/furniture-kit/cardboardboxopen", Vector3(-hx + 0.32, 0, -D + 2.85), r.randf_range(-20, 20), 0.3)
	if R.frag:
		_furnish_fragment(r)


func _furnish_fragment(r: RandomNumberGenerator) -> void:
	var y: float = R.frag_y
	var x0: float = R.hx + Room.T
	var x1: float = x0 + R.frag_w
	var z0: float = R.frag_z0 - 1.1
	var z1: float = R.frag_z1 + 0.7
	_p("ph/drawer_cabinet", Vector3(x1 - 0.17, y, (z0 + z1) * 0.5 + 0.2), -90.0, 1.1, true)
	_p("ph/Television_01", Vector3(x1 - 0.25, y + 1.1, (z0 + z1) * 0.5 + 0.2), -90.0)
	_p("ph/ArmChair_01", Vector3(x0 + 0.55, y, z0 + 0.5), 25.0, 0.0, true)
	_p("ph/Shelf_01", Vector3(x0 + 1.5, y, z0 + 0.14), 0.0, 1.6, true)
	for i in 3:
		_p("kenney/furniture-kit/books", Vector3(x0 + 1.25 + 0.25 * float(i), y + 0.62 + 0.4 * float(i % 2), z0 + 0.14), 0.0, 0.12)
	_p("ph/plastic_crate_01", Vector3(x1 - 0.3, y, z1 - 0.3), r.randf_range(0, 90), 0.0, true)
	_p("ph/cardboard_box_01", Vector3(x0 + 1.4, y, z1 - 0.3), r.randf_range(0, 40), 0.0, true)
	_p("kenney/furniture-kit/lamproundfloor", Vector3(x1 - 0.3, y, z0 + 0.3), 0.0, 1.45)
	_p("ph/vintage_suitcase", Vector3(x0 + 2.1, y, z0 + 0.2), 0.0, 0.0)


## Stress Mould: dark blotches on walls and ceiling that grow with the hours spent here.
func _mould() -> void:
	var mat := MatLib.standard(Color(0.06, 0.08, 0.05), 0.95)
	var mat2 := MatLib.standard(Color(0.18, 0.2, 0.12), 1.0)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "mould"])
	var hx: float = R.hx
	var D: float = R.D
	var H: float = R.H
	var spots := [
		[Vector3(-hx + 0.35, H - 0.001, -D + 0.3), Vector3.DOWN], [Vector3(hx - 0.3, H - 0.001, -D + 0.35), Vector3.DOWN],
		[Vector3(-hx + 0.001, H - 0.3, -D + 0.5), Vector3.RIGHT], [Vector3(R.closet_x0 + 1.9, H - 0.25, -D + 0.001), Vector3.BACK],
		[Vector3(hx - 0.001, H - 0.35, -0.4), Vector3.LEFT], [Vector3(-hx + 0.4, H - 0.001, -0.5), Vector3.DOWN],
		[Vector3(0.6, H - 0.001, -D * 0.5 + 0.9), Vector3.DOWN], [Vector3(-hx + 0.001, 0.25, -0.3), Vector3.RIGHT]]
	if R.has_window:
		spots.append([Vector3(-hx + 0.001, 2.25, -D + 1.55), Vector3.RIGHT])
	if R.frag:
		spots.append([Vector3(R.hx + Room.T + R.frag_w - 0.4, R.frag_y + 2.379, R.frag_z1 + 0.3), Vector3.DOWN])
	for s in spots:
		var n: Vector3 = s[1]
		var y := n
		var x := Vector3.UP.cross(n).normalized() if absf(n.y) < 0.9 else Vector3.RIGHT
		var z := x.cross(y)
		var patch := Node3D.new()
		patch.name = "StressMould"
		patch.transform = Transform3D(Basis(x, y, z), s[0])
		add_child(patch)
		for i in r.randi_range(4, 7):
			var mi := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 1.0
			sm.height = 2.0
			sm.radial_segments = 10
			sm.rings = 5
			mi.mesh = sm
			mi.material_override = mat if i % 3 != 2 else mat2
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var rad := r.randf_range(0.04, 0.13)
			mi.scale = Vector3(rad, 0.006, rad * r.randf_range(0.6, 1.3))
			mi.position = Vector3(r.randf_range(-0.16, 0.16), 0.0, r.randf_range(-0.16, 0.16))
			patch.add_child(mi)
		patch.scale = Vector3.ONE * 0.35
		mould.append(patch)


## Smilers: grins in the dark gap under the bed and in the closet; hidden while lit.
func _smilers(closet_gap: Vector3) -> void:
	var sh := Shader.new()
	sh.code = GRIN_SHADER
	var spots := [[Vector3(-R.hx + 0.62, 0.15, bed_center.z - 0.45), 90.0, 0.34],
		[Vector3(-R.hx + 0.55, 0.16, bed_center.z + 0.5), 90.0, 0.3],
		[closet_gap, 0.0, 0.42]]
	if R.frag:
		spots.append([Vector3(R.hx + Room.T + 0.2, R.frag_y + 0.3, R.frag_z0 - 0.95), 120.0, 0.3])
	for s in spots:
		var mat := ShaderMaterial.new()
		mat.shader = sh
		var mi := MeshInstance3D.new()
		mi.name = "SmilerGrin"
		var q := QuadMesh.new()
		q.size = Vector2(float(s[2]), float(s[2]) * 0.62)
		mi.mesh = q
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = s[0]
		mi.rotation.y = deg_to_rad(float(s[1]))
		add_child(mi)
		grins.append({"node": mi, "home": s[0], "mat": mat})


func _lights() -> void:
	lights.setup(2, 1)
	var c := OmniLight3D.new()
	c.name = "CeilingLight"
	c.position = Vector3(0, R.H - 0.25, -R.D * 0.5)
	c.light_color = COLD
	c.light_energy = 0.85
	c.omni_range = 7.0
	c.omni_attenuation = 1.3
	c.shadow_enabled = true
	add_child(c)
	ceiling_lights.append(c)
	if R.frag:
		var f := OmniLight3D.new()
		f.name = "FusedRoomLight"
		f.position = Vector3(R.hx + Room.T + R.frag_w * 0.5, R.frag_y + 2.1, (R.frag_z0 + R.frag_z1) * 0.5 - 0.2)
		f.light_color = COLD
		f.light_energy = 0.55
		f.omni_range = 4.2
		f.omni_attenuation = 1.4
		f.shadow_enabled = true
		add_child(f)
		ceiling_lights.append(f)


func _sounds() -> void:
	sound.bed("room_tone", {"cutoff": 240.0, "rumble": 0.25, "seconds": 6.0}, -31.0)
	_hum = sound.emitter("fluorescent_hum", Vector3(0, R.H - 0.1, -R.D * 0.5), {"base": 100.0, "rasp": 0.12, "seconds": 3.0}, -31.0, 6.0)
	_heart = sound.bed("heartbeat", {}, -80.0)
	_void_pad = sound.bed("pad", {"root": 49.0, "chord": [0, 7, 15], "bright": 0.05, "seconds": 10.0}, -80.0)
	_under = sound.emitter("whisper", Vector3(-R.hx + 0.5, 0.15, bed_center.z), {"seconds": 3.0}, -80.0, 5.0)


func _interactions() -> void:
	var hx: float = R.hx
	var D: float = R.D
	# Exit 1 (QA's walker target): fall asleep on the bed -> a street on Level 9.
	_bed_exit = BedTrigger.new()
	_bed_exit.name = "Exit_L114_to_L009_1"
	add_child(_bed_exit)
	_bed_exit.setup("L114>L009#1", "interact", Vector3(-hx + 1.25, 1.0, bed_center.z + 0.15), Vector3(1.3, 2.0, 1.9), "Lie down on the blue floral bed")
	(_bed_exit as BedTrigger).on_use = _lie_down
	_bed_exit.condition = func() -> bool: return _asleep
	exits.append(_bed_exit)
	# Exit 2: say it, in a dull voice -> Level 25.
	var bored := add_exit("L114>L025#2", "interact", Vector3(hx - 0.85, 1.0, -D + 0.75), Vector3(1.2, 2.0, 1.2), "Slump at the desk and say, dully: \"I'm so bored...\"")
	if bored:
		bored.fired.connect(func(_e: String) -> void: Overlay.subtitle("\"I'm so bored...\" [your own voice, flat in the dead air]", 3.5))
	add_interactable(Vector3(R.door_x - 0.75, 1.2, -0.05), Vector3(0.25, 0.3, 0.12), "Flip the light switch", func(_p: Player) -> void: set_light(not light_on))
	var dead := "[click. Nothing happens. The cable is plugged in and looks fine.]"
	add_interactable(Vector3(-hx + 1.22, 0.85, -D + 0.22), Vector3(0.3, 0.35, 0.3), "Switch on the bedside lamp", func(_p: Player) -> void: Overlay.subtitle(dead, 3.0))
	add_interactable(Vector3(-hx + 0.25, 1.3, -D + 2.35), Vector3(0.4, 0.5, 0.4), "Switch on the floor lamp", func(_p: Player) -> void: Overlay.subtitle(dead, 3.0))
	add_interactable(Vector3(hx - 0.22, 0.86, -D + 0.4), Vector3(0.3, 0.25, 0.25), "Turn on the radio", func(_p: Player) -> void: Overlay.subtitle("[the dial turns; the radio stays silent. Fresh batteries would not help either.]", 3.5))
	var tv := Vector3(hx - 0.25, 1.33, -D + 2.45) if not R.frag else Vector3(R.hx + Room.T + R.frag_w - 0.25, R.frag_y + 1.33, (R.frag_z0 + R.frag_z1) * 0.5 - 0.2)
	add_interactable(tv, Vector3(0.5, 0.45, 0.6), "Turn on the television", func(_p: Player) -> void: Overlay.subtitle("[the button clicks; the screen stays grey and dead]", 3.0))
	add_interactable(Vector3(hx - 0.06, 2.0, -D + 0.62), Vector3(0.15, 0.4, 0.4), "Look at the clock", func(_p: Player) -> void: Overlay.subtitle("[the hands do not move. You have been here about %d hours.]" % int(hours), 3.0))
	if R.has_window:
		add_interactable(Vector3(-hx + 0.15, 1.55, -D + 1.15), Vector3(0.3, 1.0, 1.0), "Try the window", _try_window)
		_glass = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.02, 1.0, 1.0)
		_glass.mesh = bm
		_glass.material_override = MatLib.get_mat("l114_glass")
		_glass.position = Vector3(-hx - 0.06, 1.55, -D + 1.15)
		add_child(_glass)
	add_note("advisory", "M.E.G. ADVISORY (taped by the switch)",
		"Leave this switch ON. The light is the only thing here that works. Things that smile live under the bed and in the dark corners; they stay put while it is lit.",
		Vector3(R.door_x - 0.75, 1.0, -0.04), Vector3(0.25, 0.2, 0.06), false)
	add_note("rope", "TAG ON THE ROPE (M.E.G.)",
		"About 150 yards of line, tied to the knob. The dark past the door has air and pulls you down slowly; you cannot swim up. If you fall, swim to the rope and climb.",
		Vector3(R.door_x + 0.47, 1.3, -0.04), Vector3(0.12, 0.2, 0.06), false)
	add_note("mould", "NOTE ON THE DESK",
		"The dark patches on the ceiling grow while you stay and smell of soggy dirt. They make you anxious. After about eight hours they are dangerous to breathe. Don't linger.",
		Vector3(hx - 0.3, 0.79, -D + 0.75))


func _shots() -> void:
	var hx: float = R.hx
	var D: float = R.D
	add_shot("doorway", Vector3(R.door_x + 0.1, 1.62, -0.2), Vector3(-hx + 0.6, 0.7, -D + 0.9))
	add_shot("bed", Vector3(0.9, 1.35, -D + 3.3), Vector3(-hx + 0.4, 0.35, bed_center.z - 0.2))
	add_shot("void", Vector3(R.door_x - 0.35, 1.55, -1.3), Vector3(R.door_x + 0.4, -0.8, 2.5), {"prepare": _prep_open})
	add_shot("below", Vector3(R.door_x + 0.7, -0.9, 3.8), Vector3(R.door_x - 0.2, 1.0, -1.5), {"prepare": _prep_open})
	add_shot("lights_out", Vector3(0.2, 0.75, bed_center.z + 1.3), Vector3(-hx + 0.4, 0.15, bed_center.z - 0.1), {"prepare": _prep_dark})
	if R.frag:
		add_shot("fused", Vector3(-0.6, 1.55, R.frag_z1 + 0.3), Vector3(R.hx + Room.T + R.frag_w, R.frag_y + 1.0, (R.frag_z0 + R.frag_z1) * 0.5 - 0.4), {"prepare": _prep_light})
	add_shot("closet", Vector3(-0.3, 1.5, -1.0), Vector3(R.closet_x0 + 1.0, 1.1, -D), {"prepare": _prep_light})


func _prep_open() -> void:
	_prep_light()
	_door_angle = 96.0
	_door_target = 96.0
	_door_pivot.rotation.y = deg_to_rad(_door_angle)
	_update_rope()
	await get_tree().process_frame


func _prep_dark() -> void:
	set_light(false)
	_dark_t = 2.0
	for g in grins:
		if (g["home"] as Vector3).y < 0.5:
			(g["node"] as Node3D).position = (g["home"] as Vector3) + Vector3(0.32, 0.0, 0.0)
		g["v"] = 1.0
		(g["mat"] as ShaderMaterial).set_shader_parameter("reveal", 1.0)
	await get_tree().process_frame


func _prep_light() -> void:
	set_light(true)
	_dark_t = 0.0
	for g in grins:
		g["v"] = 0.0
		(g["node"] as Node3D).position = g["home"]
		(g["mat"] as ShaderMaterial).set_shader_parameter("reveal", 0.0)
	await get_tree().process_frame


func on_player_ready() -> void:
	_relocate_overlay()
	if not qa_fixture:
		Overlay.subtitle("[a dim, sterile light; the door behind you stands ajar onto nothing]", 4.5)


## The shared DEV26 annex places its two cues at fixed coordinates; move them onto the desk
## and the toy crates of this seeded room and shrink its oversized book stacks to real size.
func _relocate_overlay() -> void:
	var annex := get_node_or_null("DEV26_CuratedAtmospheres") as Node3D
	if annex == null:
		return
	var hx: float = R.hx
	var D: float = R.D
	var src := [Vector3(4.5, 0, -4), Vector3(4.5, 0, 3)]
	var dst := [Vector3(hx - 0.95, 0, -D + 1.7), Vector3(-hx + 1.0, 0, -0.75)]
	# per cue: [books spot, other prop spot]; books are shrunk to a real stack
	var spots := [[Vector3(hx - 0.36, 0.76, -D + 0.98), Vector3(hx - 0.4, 0.0, -D + 0.66)],
		[Vector3(-hx + 1.15, 0.0, -0.95), Vector3(-hx + 0.82, 0.0, -0.42)]]
	var used := [0, 0]
	var walls := [Vector3(hx - 0.05, 1.25, -D + 1.25), Vector3(-hx + 0.05, 1.1, -1.75)]
	for c in annex.get_children():
		if not (c is Node3D) or str(c.name).begins_with("DEV26_Proximity"):
			continue
		var n := c as Node3D
		var gp := n.global_position
		var i := 0 if Vector2(gp.x - 4.5, gp.z + 4.0).length() < Vector2(gp.x - 4.5, gp.z - 3.0).length() else 1
		if n.get_node_or_null("Visual") != null:
			# ModelDress renames a second "GLB_books" in the same annex, so go by data order
			var books: bool = int(used[i]) == (0 if i == 0 else 1)
			n.global_position = spots[i][0] if books else spots[i][1]
			n.rotation.y = deg_to_rad(-90.0 if i == 0 else 30.0)
			n.scale = Vector3.ONE * (0.2 if books else 0.75)
			used[i] += 1
		elif str(n.name).begins_with("DEV26_Signal"):
			n.global_position = walls[i]
		elif str(n.name).begins_with("DEV26_ClueLamp"):
			n.global_position = walls[i] + (Vector3(-0.4, 0.3, 0) if i == 0 else Vector3(0.4, 0.3, 0))
		else:
			n.global_position = gp - src[i] + dst[i]


# --------------------------------------------------------------- mechanics

func set_light(on: bool) -> void:
	light_on = on
	for l in ceiling_lights:
		(l as OmniLight3D).visible = on
	(MatLib.get_mat("l114_lamp_panel") as ShaderMaterial).set_shader_parameter("energy", 1.7 if on else 0.0)
	environment.ambient_light_energy = 0.09 if on else 0.012
	if _hum:
		_hum.volume_db = -31.0 if on else -80.0
	if is_instance_valid(player) and built:
		sound.play_at("ui", {"kind": "click"}, Vector3(R.door_x - 0.75, 1.2, -0.05), -10.0, "[click]")
		if not on:
			Overlay.subtitle("[the room goes black. Under the bed, something stirs.]", 3.0)
	if on:
		_dark_t = 0.0
		_attack_t = 0.0


func _lie_down(p: Player) -> void:
	if _dozing:
		return
	_dozing = true
	_doze_t = 0.0
	p.frozen = true
	p.velocity = Vector3.ZERO
	if not qa_fixture:
		p.global_position = Vector3(bed_center.x + 0.1, 0.58, bed_center.z + 0.3)
		p.rotation.y = 0.0
		p.look_pitch = deg_to_rad(65.0)
		p.head.rotation.x = p.look_pitch
	Overlay.subtitle("[the blue floral sheet is damp and smells of old wood. Your eyes grow heavy.]", 4.0)


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	hours += delta / HOUR
	_grow_mould()
	_light_rules(delta)
	_void_rules(delta)
	_window_rules(delta)
	if _bitten > 0.0:
		_bitten = maxf(0.0, _bitten - delta * 0.1)
		Overlay.set_screen_effect("red_tint", _bitten)
	if _dozing and not _asleep:
		_doze_t += delta
		if _doze_t > 1.6 and _bitten == 0.0 and not qa_fixture:
			_bitten = 0.12
			Overlay.subtitle("[small bites itch along your forearm: bed bugs in the sheets]", 3.5)
		var need := 1.2 if qa_fixture else 7.0
		if not qa_fixture:
			Overlay.set_screen_effect("blackout", clampf((_doze_t - 3.0) / 4.0, 0.0, 1.0))
		if _doze_t >= need:
			_asleep = true
			Overlay.subtitle("[you doze off ... and wake to a street]", 3.0)
			_bed_exit.fire()
			if qa_fixture:
				player.frozen = false


func _grow_mould() -> void:
	var g := clampf(hours / 8.0, 0.0, 1.4)
	var s := 0.35 + g * 1.1
	for m in mould:
		(m as Node3D).scale = Vector3(s, 1.0, s)
	if not qa_fixture:
		var marks := {2: "[a soggy-dirt smell from the ceiling patches]", 5: "[your pulse is up; the dark patches have spread]",
			8: "[the mould is everywhere now. Breathing it hurts. You should not stay.]"}
		for h in marks.keys():
			if hours >= float(h) and not _said.has(h):
				_said[h] = true
				Overlay.subtitle(marks[h], 4.0)
	var stress := clampf((hours - 3.0) / 5.0, 0.0, 1.0)
	_heart.volume_db = lerpf(-60.0, -18.0, stress) if stress > 0.0 else -80.0
	Overlay.set_screen_effect("vignette", 0.25 + stress * 0.35)
	if hours > 8.0 and not qa_fixture:
		player.hurt(delta_hurt(), "Stress Mould exposure past about eight hours in Level 114")


func delta_hurt() -> float:
	return get_process_delta_time() * 0.6


func _light_rules(delta: float) -> void:
	var target := 0.0 if light_on else 1.0
	for g in grins:
		var m := g["mat"] as ShaderMaterial
		var v := move_toward(float(g.get("v", 0.0)), target, delta * (0.8 if not light_on else 2.0))
		g["v"] = v
		m.set_shader_parameter("reveal", v)
		var node := g["node"] as Node3D
		if light_on:
			node.position = node.position.move_toward(g["home"], delta * 2.0)
		elif _dark_t > 3.0:
			var to := player.global_position + Vector3(0, 1.0, 0)
			node.position = node.position.move_toward(to, delta * 0.9)
			node.look_at(player.camera.global_position, Vector3.UP, true)
	if light_on:
		_under.volume_db = move_toward(_under.volume_db, -80.0, delta * 30.0)
		return
	_dark_t += delta
	_under.volume_db = move_toward(_under.volume_db, -14.0, delta * 20.0)
	if _dark_t > 6.5 and not qa_fixture:
		_attack_t -= delta
		if _attack_t <= 0.0:
			_attack_t = 3.0
			Overlay.glitch(0.6)
			Overlay.subtitle("[grinning shapes pour out of the dark under the bed. Turn the light back on.]", 3.0)
			player.hurt(30.0, "Smilers emerged after the lights in Level 114 went out")


func _update_rope() -> void:
	knob = _door_pivot.transform * _knob_local
	if _door_angle < 90.0:
		_rope.aabb = AABB(Vector3(knob.x, -2000.0, knob.z), Vector3(0.1, 0.1, 0.1))
	else:
		_rope.aabb = AABB(Vector3(knob.x - 0.42, -137.0, knob.z - 0.38), Vector3(0.84, 137.0 + knob.y + 0.25, 0.8))


func _void_rules(delta: float) -> void:
	var p := player.global_position
	if _door_target < 90.0 and p.z > -0.02 and absf(p.x - R.door_x) < 0.7 and p.y > -0.5:
		_door_target = 96.0
		sound.play_at("creak", {"freq": 120.0}, _door_pivot.global_position + Vector3(0, 1, 0), -12.0, "[the door creaks open onto black]")
	if absf(_door_angle - _door_target) > 0.01:
		_door_angle = move_toward(_door_angle, _door_target, delta * 140.0)
		_door_pivot.rotation.y = deg_to_rad(_door_angle)
		_update_rope()
	# at the top of the rope, haul yourself back over the threshold
	if p.y < -1.0:
		_was_deep = true
	if _haul < 0.0 and _was_deep and player.on_ladder and p.y > -0.15:
		_was_deep = false
		_haul = 0.0
		player.frozen = true
		Overlay.subtitle("[you haul yourself up the rope and over the threshold]", 3.0)
	if _haul >= 0.0:
		_haul += delta
		player.global_position = p.lerp(Vector3(R.door_x, 0.05, -0.35), clampf(_haul * 3.0, 0.0, 1.0))
		if _haul > 0.6:
			_haul = -1.0
			player.frozen = false
			player.velocity = Vector3.ZERO
		return
	var inside := p.z > Room.T + 0.06 or p.y < -0.4
	if inside != _in_void:
		_in_void = inside
		player.gravity = 1.9 if inside else float(rules["gravity"])
		if inside and not qa_fixture:
			Overlay.subtitle("[you sink slowly, as if through water. Kicking does not lift you.]", 4.0)
	if _in_void:
		if player.velocity.y > 0.3 and not player.on_ladder:
			player.velocity.y = 0.3
		player.velocity.y = maxf(player.velocity.y, -1.5)
		_void_pad.volume_db = lerpf(_void_pad.volume_db, clampf(-34.0 - p.y * 0.1, -34.0, -16.0), delta)
	else:
		_void_pad.volume_db = move_toward(_void_pad.volume_db, -80.0, delta * 30.0)
	if p.y < -139.5 and not _lost:
		_lost = true
		Overlay.subtitle("[the end of the rope is above you now. Nothing below. Nothing anywhere.]", 6.0)
	if _lost:
		_lost_t += delta
		Overlay.set_screen_effect("blackout", clampf(_lost_t / 8.0, 0.0, 1.0))
		if _lost_t > 9.0 and not player.dead:
			player.hurt(1000.0, "Drifted past the end of the M.E.G. rope into the void below Level 114")


func _window_rules(delta: float) -> void:
	if not R.has_window or _glass == null:
		return
	_window_t -= delta
	if _window_t > 0.0:
		return
	_window_bad = not _window_bad and rng.randf() < 0.45
	_window_t = rng.randf_range(25.0, 45.0) if _window_bad else rng.randf_range(90.0, 160.0)
	_glass.scale = Vector3(1.0, 1.06, 0.97) if _window_bad else Vector3.ONE
	(_glass.material_override as StandardMaterial3D).emission_energy_multiplier = 0.0 if _window_bad else 0.4
	if _window_bad:
		sound.play_at("creak", {"freq": 90.0}, _glass.global_position, -14.0, "[the window frame creaks, as if something leaned on it]")


func _try_window(p: Player) -> void:
	if _window_bad:
		Overlay.glitch(0.5)
		Overlay.subtitle("[the glass is warm and gives like skin. This is not your window.]", 3.5)
		p.hurt(25.0, "Touched the malevolent counterpart that replaced the window in Level 114")
	else:
		Overlay.subtitle("[the latch will not move. The glass is cold and black.]", 3.0)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out := []
	out.append({"what": "two in-room exits (sleep, bored); the void is a fail state", "ok": exits.size() == 2})
	out.append({"what": "light switch is on by default", "ok": light_on})
	set_light(false)
	out.append({"what": "switching off hides every ceiling light", "ok": ceiling_lights.all(func(l): return not l.visible)})
	set_light(true)
	out.append({"what": "smiler grins exist under the bed and in the closet", "ok": grins.size() >= 3})
	_door_angle = 96.0
	_door_pivot.rotation.y = deg_to_rad(_door_angle)
	_update_rope()
	out.append({"what": "M.E.G. rope climbable to ~137 m", "ok": get_node_or_null("MEG_Rope") != null and (get_node("MEG_Rope") as LadderVolume).aabb.size.y > 130.0})
	var before: float = (mould[0] as Node3D).scale.x
	hours += 8.0
	_grow_mould()
	out.append({"what": "stress mould grows with time", "ok": (mould[0] as Node3D).scale.x > before + 0.5, "detail": [before, (mould[0] as Node3D).scale.x]})
	hours -= 8.0
	_grow_mould()
	return out
