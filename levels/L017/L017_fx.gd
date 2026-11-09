extends RefCounted
## Level 17 scripted presences and sector effects: occupants who turn to watch,
## the uniformed man of sector 12, the skinless man of sector 165, the whispering
## closet (47), the bridge door (185), the thermometers (200-206), and the machine
## and fused crew of sector 217. Records carry their sector so they unload with it.

const Anchors := preload("res://levels/L017/L017_anchors.gd")
const S := preload("res://levels/L017/L017_sector.gd")
const FUSED := """
shader_type spatial;
uniform vec3 col : source_color = vec3(0.33, 0.31, 0.28);
void vertex() {
	float b = sin(TIME * 1.1 + float(INSTANCE_ID) * 1.7);
	VERTEX += NORMAL * 0.014 * b;
}
void fragment() {
	ALBEDO = col;
	ROUGHNESS = 0.62;
}
"""
const TUBES := """
shader_type spatial;
render_mode unshaded;
void fragment() {
	float id = COLOR.r * 97.0;
	float f = 0.75 + 0.25 * sin(TIME * (3.0 + fract(id) * 9.0) + id * 13.0);
	ALBEDO = vec3(1.0, 0.5, 0.16) * f * 1.6;
}
"""

var lv
var said := {}
var knock_t := 2.0


func _init(level) -> void:
	lv = level


func _emit(parent: Node3D, recipe: String, pos: Vector3, params: Dictionary, db: float, dist: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = AudioSynth.get_stream(recipe, params)
	p.volume_db = db
	p.max_distance = dist
	p.unit_size = 3.0
	p.bus = "Ambience"
	parent.add_child(p)
	p.global_position = pos
	p.autoplay = true
	if p.is_inside_tree():
		p.play()
	return p


func figure(f: Dictionary, parent: Node3D, n: int) -> Dictionary:
	var node := Anchors.mannequin(str(f["kind"]))
	parent.add_child(node)
	node.global_position = f["pos"]
	node.rotation_degrees.y = float(f["yaw"])
	if f["kind"] != "remains":
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(0.5, 1.8, 0.4)
		cs.shape = sh
		cs.position = Vector3(0, 0.9, 0)
		body.add_child(cs)
		node.add_child(body)
	var rec := f.duplicate()
	rec["node"] = node
	rec["sector"] = n
	return rec


func setup(e: Dictionary, parent: Node3D, n: int) -> Dictionary:
	var rec := e.duplicate()
	rec["sector"] = n
	match str(e["kind"]):
		"whisper_closet":
			rec["snd"] = _emit(parent, "whisper", e["pos"], {"seconds": 3.2}, -14.0, 11.0)
			rec["open"] = false
			var it: Interactable = lv.make_interactable(e["pos"] + Vector3(0, 0, -0.3), Vector3(1.2, 2.0, 0.8), "Open the storage closet", Callable(), parent)
			it.action = _open_closet.bind(rec)
			rec["it"] = it
		"bridge":
			rec["snd"] = _emit(parent, "pad", e["pos"], {"root": 523.0, "chord": [0, 1, 6, 13], "bright": 0.9, "seconds": 6.0}, -20.0, 16.0)
			rec["snd2"] = _emit(parent, "whisper", e["pos"], {"seconds": 2.6}, -16.0, 14.0)
		"thermometer":
			var it2: Interactable = lv.make_interactable(e["pos"], Vector3(0.6, 0.8, 0.6), "Read the thermometer", Callable(), parent)
			it2.action = _thermo.bind(n)
		"machine":
			var omni := OmniLight3D.new()
			omni.light_color = Color(0.35, 0.55, 1.0)
			omni.omni_range = 11.0
			omni.light_energy = 2.2
			omni.shadow_enabled = false
			parent.add_child(omni)
			omni.global_position = e["pos"] + Vector3(0, 0.6, 1.4)
			rec["omni"] = omni
			rec["tone"] = _emit(parent, "fluorescent_hum", e["pos"], {"base": 1450.0, "rasp": 0.05, "seconds": 2.0}, -18.0, 22.0)
			_tubes(parent, e["tubes"])
		"fused":
			_fused(parent, n)
	return rec


func _open_closet(rec: Dictionary) -> void:
	rec["open"] = true
	var s: AudioStreamPlayer3D = rec["snd"]
	if is_instance_valid(s):
		s.volume_db = -80.0
	lv.sound.play_at("creak", {"freq": 180.0}, rec["pos"], -8.0, "[the closet is empty: bare shelves. The whispering stopped the moment the door opened]")


func _thermo(n: int) -> void:
	var t: float = sin(lv.elapsed * 0.23 + n) * 8.0 + 2.0
	Overlay.subtitle("[the thermometer reads %d degrees C, and the needle will not settle]" % int(round(t)), 3.5)


## Vacuum tubes on the machine's shelves, one instanced mesh.
func _tubes(parent: Node3D, span: Array) -> void:
	var a: Vector3 = span[0]
	var b: Vector3 = span[1]
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cm := CylinderMesh.new()
	cm.top_radius = 0.034
	cm.bottom_radius = 0.04
	cm.height = 0.17
	cm.radial_segments = 6
	cm.rings = 1
	mm.mesh = cm
	var cols := 44
	var rows := 6
	mm.instance_count = cols * rows
	var i := 0
	for r in rows:
		for c in cols:
			var p := Vector3(lerpf(a.x, b.x, float(c) / (cols - 1)), a.y + r * 0.36 + 0.07, a.z)
			mm.set_instance_transform(i, Transform3D(Basis(), p))
			mm.set_instance_color(i, Color(fmod(i * 0.6180339, 1.0), 0, 0))
			i += 1
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var sh := Shader.new()
	sh.code = TUBES
	var m := ShaderMaterial.new()
	m.shader = sh
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


## 216 crew fused into bulkhead, deck and deckhead: body-shaped swellings in the
## plating that rise and fall as they breathe. Implied, never detailed.
func _fused(parent: Node3D, n: int) -> void:
	var z0: float = S.z_of(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 217216
	var spots: Array = []
	for i in 216:
		var r := rng.randf()
		var p: Vector3
		var nrm: Vector3
		if r < 0.3:
			var s := -1.0 if rng.randf() < 0.5 else 1.0
			p = Vector3(s * 10.98, rng.randf_range(0.3, 2.3), z0 - rng.randf_range(0.6, 11.4))
			nrm = Vector3(-s, 0, 0)
		elif r < 0.5:
			var s2 := -1.0 if rng.randf() < 0.5 else 1.0
			p = Vector3(s2 * 9.25, rng.randf_range(0.3, 2.3), z0 - rng.randf_range(0.6, 11.4))
			if absf(z0 - p.z - 6.0) < 1.3:
				p.z -= 2.5
			nrm = Vector3(s2, 0, 0)
		elif r < 0.7:
			p = Vector3(rng.randf_range(-9.0, 9.0), 2.69, z0 - rng.randf_range(0.6, 11.4))
			nrm = Vector3.DOWN
		elif r < 0.85:
			p = Vector3(rng.randf_range(-8.8, 8.8), rng.randf_range(0.3, 2.3), z0 - 5.06)
			nrm = Vector3(0, 0, -1)
		else:
			var s3 := -1.0 if rng.randf() < 0.5 else 1.0
			p = Vector3(s3 * rng.randf_range(9.5, 10.8), 0.0, z0 - rng.randf_range(0.6, 11.4))
			nrm = Vector3.UP
		spots.append([p, nrm, rng.randf() * TAU])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var cm := CapsuleMesh.new()
	cm.radius = 0.17
	cm.height = 1.55
	cm.radial_segments = 10
	cm.rings = 4
	mm.mesh = cm
	mm.instance_count = spots.size()
	for i in spots.size():
		var nrm: Vector3 = spots[i][1]
		var t := nrm.cross(Vector3.UP if absf(nrm.y) < 0.9 else Vector3.RIGHT).normalized()
		var ax := t.rotated(nrm, spots[i][2])
		var bz := nrm
		var bx := ax.cross(bz).normalized()
		var bas := Basis(bx, ax, bz * 0.75)
		mm.set_instance_transform(i, Transform3D(bas, spots[i][0] - nrm * 0.05))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var sh := Shader.new()
	sh.code = FUSED
	var m := ShaderMaterial.new()
	m.shader = sh
	mi.material_override = m
	parent.add_child(mi)


func update(delta: float, pp: Vector3) -> void:
	var cam: Camera3D = lv.get_viewport().get_camera_3d()
	for f in lv.figures:
		var nd: Node3D = f["node"]
		if not is_instance_valid(nd) or f["kind"] == "remains":
			continue
		var d := pp.distance_to(nd.global_position)
		if f.get("watch", false) and d < 7.0:
			var to := pp - nd.global_position
			var want := atan2(to.x, to.z)
			nd.rotation.y = lerp_angle(nd.rotation.y, want, minf(1.0, delta * 1.5))
		match str(f["kind"]):
			"sailor":
				if d < 4.5 and not f.get("spoke", false):
					f["spoke"] = true
					if not SessionState.is_qa():
						Overlay.subtitle("[a man in a stained 1940s Navy uniform] \"Civilians are not allowed on this ship.\"", 4.0)
				elif d > 9.0:
					f["spoke"] = false
			"skinless":
				if d < 4.0 and not said.has("skinless") and not SessionState.is_qa():
					said["skinless"] = true
					Overlay.subtitle("[a man with no skin stands in the barracks doorway. He will not let you in]", 4.0)
			"dungarees":
				if d < 5.0 and not said.has("occupant") and not SessionState.is_qa():
					said["occupant"] = true
					Overlay.subtitle("[someone stands in the compartment, not moving. Better not to speak to them]", 4.0)
	for e in lv.fxs:
		match str(e.get("kind", "")):
			"whisper_closet":
				var d2 := pp.distance_to(e["pos"])
				if not e["open"] and d2 < 6.0 and not said.has("whisper") and not SessionState.is_qa():
					said["whisper"] = true
					Overlay.subtitle("[whispering from the storage closet: the Lord's Prayer, over and over]", 4.0)
				if e["open"] and d2 > 12.0:
					e["open"] = false
					var s: AudioStreamPlayer3D = e["snd"]
					if is_instance_valid(s):
						s.volume_db = -14.0
			"bridge":
				if pp.distance_to(e["pos"]) < 8.0 and not said.has("bridge") and not SessionState.is_qa():
					said["bridge"] = true
					Overlay.subtitle("[behind the door marked BRIDGE: infants crying, hundreds of them. The smell is unbearable]", 4.5)
			"machine":
				var om: OmniLight3D = e.get("omni")
				if is_instance_valid(om):
					om.light_energy = 2.0 + sin(lv.elapsed * 17.0) * 0.3 + (0.8 if fmod(lv.elapsed, 2.3) < 0.08 else 0.0)
				var d3 := pp.distance_to(e["pos"])
				if d3 < 26.0:
					knock_t -= delta
					if knock_t <= 0.0:
						knock_t = randf_range(1.2, 2.8)
						lv.sound.play_at("knock", {"hits": 2 + randi() % 3}, e["pos"], -10.0, "" if said.has("knock") else "[knocking from inside the machine]")
						said["knock"] = true
				if d3 < 12.0 and not said.has("machine") and not SessionState.is_qa():
					said["machine"] = true
					Overlay.subtitle("[a high, thin tone and a blue light. The walls here are not only steel. They are breathing]", 5.0)
	if cam == null:
		return
