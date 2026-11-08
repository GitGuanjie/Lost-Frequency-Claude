extends RefCounted
## Level 263 hallway geometry: one repeating 6 m bay (pilaster, tall segmented
## window of static, pilaster) on both sides of a 9 m wide pink corridor whose
## walls rise into a pitch-black ceiling at 17 m. Streamed along -Z in 24 m
## chunks (four bays). Also builds the static door assembly and the abandoned
## backpack and laptop. Materials and the static shader live here too.

const HALF_W := 4.5          # corridor half width (wall faces at x = +-4.5)
const CEIL := 17.0           # ~55 ft, pitch black
const BAY := 6.0
const WIN_W := 3.6
const SILL := 0.9
const WIN_TOP := 8.7
const CHUNK := 24.0

var lvl


func _init(level) -> void:
	lvl = level


static func define_materials() -> void:
	MatLib.define("l263_wall", {"albedo_a": Color(0.93, 0.42, 0.62), "albedo_b": Color(0.88, 0.38, 0.58),
		"noise_scale": 0.8, "roughness_a": 0.82, "roughness_b": 0.92, "bump_strength": 0.25,
		"stain_amount": 0.0, "grime_height": 0.0}, "plaster")
	MatLib.define("l263_trim", {"albedo_a": Color(0.97, 0.62, 0.76), "albedo_b": Color(0.94, 0.58, 0.72),
		"roughness_a": 0.45, "roughness_b": 0.6, "noise_scale": 0.5, "bump_strength": 0.1}, "trim_white")
	MatLib.define("l263_carpet", {"albedo_a": Color(0.66, 0.2, 0.38), "albedo_b": Color(0.6, 0.17, 0.34),
		"pattern": 6, "pattern_scale": Vector2(1, 1), "pattern_strength": 0.0, "wetness": 0.0,
		"stain_amount": 0.0, "roughness_a": 0.95, "roughness_b": 1.0, "noise_scale": 0.5, "bump_strength": 0.5}, "l0_carpet")
	MatLib.define("l263_border", {"albedo_a": Color(0.52, 0.13, 0.29), "albedo_b": Color(0.48, 0.12, 0.27),
		"pattern": 6, "roughness_a": 0.95, "roughness_b": 1.0, "noise_scale": 0.5}, "l0_carpet")
	MatLib.define("l263_black", {"albedo_a": Color(0.0, 0.0, 0.0), "albedo_b": Color(0.0, 0.0, 0.0),
		"roughness_a": 1.0, "roughness_b": 1.0, "bump_strength": 0.0}, "void_black")
	MatLib.define("l263_pack", {"albedo_a": Color(0.16, 0.2, 0.24), "albedo_b": Color(0.12, 0.15, 0.18),
		"noise_scale": 6.0, "roughness_a": 0.9, "roughness_b": 1.0, "bump_strength": 0.6, "stain_amount": 0.3,
		"stain_color": Color(0.2, 0.18, 0.16)}, "concrete")
	MatLib.define("l263_plastic", {"albedo_a": Color(0.2, 0.2, 0.21), "albedo_b": Color(0.17, 0.17, 0.18),
		"roughness_a": 0.4, "roughness_b": 0.5, "noise_scale": 2.0}, "trim_white")
	var sh := Shader.new()
	sh.code = STATIC
	var m := ShaderMaterial.new()
	m.shader = sh
	MatLib.register("l263_static", m)
	var ds := ShaderMaterial.new()
	ds.shader = sh
	ds.set_shader_parameter("energy", 2.2)
	ds.set_shader_parameter("pinkness", 0.7)
	ds.set_shader_parameter("cells", Vector2(90.0, 120.0))
	MatLib.register("l263_door", ds)


## Animated TV static. `pinkness` blends towards Pink's own colour, `energy`
## sets the glow; each pane flickers on its own.
const STATIC := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float energy = 1.25;
uniform float pinkness = 0.15;
uniform vec2 cells = vec2(150.0, 320.0);
uniform float fps = 24.0;
float hsh(vec3 p) { p = fract(p * vec3(0.1031, 0.1030, 0.0973)); p += dot(p, p.yxz + 33.33); return fract((p.x + p.y) * p.z); }
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float t = floor(TIME * fps);
	vec2 c = floor(UV * cells);
	float n = hsh(vec3(c, t));
	float line = hsh(vec3(0.0, c.y, t * 0.37));
	n = mix(n, line, 0.18);
	float pane = hsh(vec3(floor(wp.xz * 0.5), floor(wp.y * 0.5) + floor(TIME * 0.7)));
	float b = (0.25 + 0.75 * n) * (0.82 + 0.25 * pane);
	vec3 col = mix(vec3(0.82, 0.82, 0.86), vec3(1.0, 0.5, 0.74), pinkness);
	ALBEDO = col * b * energy;
}
"""


## One 24 m chunk of the corridor at chunk index cz (z from cz*24 to +24).
func chunk(k: GeoKit, node: Node3D, cz: int) -> Array:
	var z0 := cz * CHUNK
	var z1 := z0 + CHUNK
	var anchors: Array = []
	k.slab(-HALF_W, z0, HALF_W, z1, 0.0, 0.5, "l263_carpet")
	# a darker border along both walls, the carpet "slightly darker" than the walls
	for s in [-1.0, 1.0]:
		k.box(Vector3(s * (HALF_W - 0.35), 0.004, z0 + CHUNK * 0.5), Vector3(0.7, 0.008, CHUNK), "l263_border", GeoKit.PY, false)
	k.box(Vector3(0, CEIL + 0.25, z0 + CHUNK * 0.5), Vector3(HALF_W * 2.0 + 2.0, 0.5, CHUNK), "l263_black", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		var x: float = s * HALF_W
		for b in 4:
			var zc := z0 + BAY * (b + 0.5)
			_bay(k, node, x, s, zc)
			anchors.append(Vector3(x - s * 1.6, 4.2, zc))
	return anchors


func _bay(k: GeoKit, node: Node3D, x: float, s: float, zc: float) -> void:
	var t := 0.6
	var wx := x + s * t * 0.5
	var zw0 := zc - WIN_W * 0.5
	var zw1 := zc + WIN_W * 0.5
	var bz0 := zc - BAY * 0.5
	var bz1 := zc + BAY * 0.5
	# solid wall either side of the window, full height
	k.box_mm(Vector3(minf(wx - t * 0.5, wx + t * 0.5), 0.0, bz0), Vector3(maxf(wx - t * 0.5, wx + t * 0.5), CEIL, zw0), "l263_wall")
	k.box_mm(Vector3(minf(wx - t * 0.5, wx + t * 0.5), 0.0, zw1), Vector3(maxf(wx - t * 0.5, wx + t * 0.5), CEIL, bz1), "l263_wall")
	k.box_mm(Vector3(minf(wx - t * 0.5, wx + t * 0.5), 0.0, zw0), Vector3(maxf(wx - t * 0.5, wx + t * 0.5), SILL, zw1), "l263_wall")
	k.box_mm(Vector3(minf(wx - t * 0.5, wx + t * 0.5), WIN_TOP, zw0), Vector3(maxf(wx - t * 0.5, wx + t * 0.5), CEIL, zw1), "l263_wall")
	# shallow pilasters with base and capital between the windows
	var px := x - s * 0.09
	k.box(Vector3(px, 4.9, bz0), Vector3(0.18, 9.8, 0.9), "l263_wall", GeoKit.ALL, false)
	k.box(Vector3(x - s * 0.12, 0.09, bz0), Vector3(0.24, 0.18, 1.0), "l263_trim", GeoKit.ALL, false)
	k.box(Vector3(x - s * 0.14, 9.85, bz0), Vector3(0.28, 0.22, 1.05), "l263_trim", GeoKit.ALL, false)
	# baseboard and the cornice band that runs above the windows
	k.box(Vector3(x - s * 0.02, 0.08, zc), Vector3(0.04, 0.16, BAY), "l263_trim", GeoKit.ALL, false)
	k.box(Vector3(x - s * 0.05, 9.85, zc), Vector3(0.1, 0.16, BAY), "l263_trim", GeoKit.ALL, false)
	# the window: deep reveal, a solid static surface, a mullion grid (2 x 4 panes)
	var sx := x + s * 0.42
	k.box(Vector3(x + s * 0.21, SILL + 0.03, zc), Vector3(0.42, 0.06, WIN_W), "l263_trim", GeoKit.ALL, false)
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(WIN_W, WIN_TOP - SILL)
	q.mesh = qm
	q.material_override = MatLib.get_mat("l263_static")
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	q.position = Vector3(sx, (SILL + WIN_TOP) * 0.5, zc)
	q.rotation.y = -s * PI * 0.5
	node.add_child(q)
	var fx := x + s * 0.36
	for i in 3:
		var zz := zw0 + WIN_W * i / 2.0
		k.box(Vector3(fx, (SILL + WIN_TOP) * 0.5, clampf(zz, zw0 + 0.05, zw1 - 0.05)), Vector3(0.1, WIN_TOP - SILL, 0.1), "l263_trim", GeoKit.ALL, false)
	for j in 5:
		var yy := SILL + (WIN_TOP - SILL) * j / 4.0
		k.box(Vector3(fx, clampf(yy, SILL + 0.05, WIN_TOP - 0.05), zc), Vector3(0.1, 0.1, WIN_W), "l263_trim", GeoKit.ALL, false)


## The static door in a full-height end wall; returns the trigger centre.
## The assembly is one node so it can be moved as a whole.
func door_assembly(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "StaticDoor"
	parent.add_child(root)
	var k := GeoKit.new(root, "EndWall")
	var dw := 2.6
	var dh := 3.6
	# the end wall faces -Z (into the hall); the door opens through it
	k.wall(Vector3(-HALF_W - 0.6, 0, 0), Vector3(HALF_W + 0.6, 0, 0), CEIL, 0.6, "l263_wall", [{"at": HALF_W + 0.6, "w": dw, "h": dh, "sill": 0.0}])
	k.box(Vector3(0, dh + 0.12, -0.32), Vector3(dw + 0.5, 0.24, 0.1), "l263_trim", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box(Vector3(s * (dw * 0.5 + 0.12), dh * 0.5, -0.32), Vector3(0.24, dh, 0.1), "l263_trim", GeoKit.ALL, false)
	k.box(Vector3(0, 0.08, -0.32), Vector3(HALF_W * 2.0, 0.16, 0.04), "l263_trim", GeoKit.ALL, false)
	# behind the opening: a shallow box of static you walk into
	k.box(Vector3(0, dh * 0.5, 1.6), Vector3(dw + 0.4, dh + 0.4, 0.2), "l263_black")
	k.box(Vector3(0, -0.1, 0.9), Vector3(dw + 0.4, 0.2, 1.6), "l263_carpet")
	k.commit()
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(dw, dh)
	q.mesh = qm
	q.material_override = MatLib.get_mat("l263_door")
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	q.position = Vector3(0, dh * 0.5, 0.05)
	root.add_child(q)
	return root


## What is left of the visitor Pink describes: a backpack and an open laptop.
## Returns the laptop screen node so the level can write on it.
func visitor_things(parent: Node3D, at: Vector3) -> Label3D:
	var root := Node3D.new()
	root.name = "VisitorThings"
	root.position = at
	parent.add_child(root)
	var k := GeoKit.new(root, "Backpack")
	# backpack lying on its back: body, front pocket, lid flap, loose straps
	k.box(Vector3(-0.72, 0.1, 0.12), Vector3(0.36, 0.2, 0.52), "l263_pack", GeoKit.ALL, false)
	k.box(Vector3(-0.72, 0.13, 0.4), Vector3(0.34, 0.16, 0.08), "l263_pack", GeoKit.ALL, false)
	k.box(Vector3(-0.72, 0.235, 0.06), Vector3(0.27, 0.07, 0.24), "l263_pack", GeoKit.ALL, false)
	k.box(Vector3(-0.72, 0.215, 0.36), Vector3(0.37, 0.03, 0.17), "l263_pack", GeoKit.ALL, false)
	k.box(Vector3(-0.72, 0.03, -0.17), Vector3(0.3, 0.06, 0.1), "l263_pack", GeoKit.ALL, false)
	for sx in [-0.1, 0.1]:
		k.box(Vector3(-0.72 + sx, 0.012, -0.32), Vector3(0.045, 0.012, 0.34), "l263_plastic", GeoKit.ALL, false)
	k.box(Vector3(-0.72, 0.25, 0.06), Vector3(0.2, 0.012, 0.012), "l263_plastic", GeoKit.ALL, false)
	# the laptop, open, its screen turned towards whoever walks up the hall (+Z)
	k.box(Vector3(0.1, 0.012, 0.0), Vector3(0.34, 0.024, 0.24), "l263_plastic", GeoKit.ALL, false)
	var lid := Basis(Vector3.RIGHT, deg_to_rad(-12.0))
	k.box_xf(Transform3D(lid, Vector3(0.1, 0.135, -0.14)), Vector3(0.34, 0.23, 0.014), "l263_plastic", GeoKit.ALL, false)
	k.commit()
	var scr := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.3, 0.19)
	scr.mesh = qm
	scr.material_override = MatLib.panel(Color(0.85, 0.82, 0.9), 0.55)
	scr.position = Vector3(0.1, 0.135, -0.131)
	scr.rotation_degrees = Vector3(-12.0, 0.0, 0.0)
	root.add_child(scr)
	var lab := Label3D.new()
	lab.name = "Screen"
	lab.text = ""
	lab.font_size = 32
	lab.pixel_size = 0.0005
	lab.modulate = Color(0.25, 0.08, 0.16)
	lab.outline_size = 0
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.double_sided = false
	lab.position = Vector3(0.1, 0.135, -0.126)
	lab.rotation_degrees = Vector3(-12.0, 0.0, 0.0)
	root.add_child(lab)
	Props.place(lvl, root, "ph/plastic_bottle_gallon", Vector3(-1.05, 0.0, 0.55), 30.0, 0.0, false)
	var fl := Props.place(lvl, root, "ph/vintage_flashlight", Vector3(-0.35, 0.05, 0.62), 70.0, 0.0, false)
	if fl:
		fl.rotation.z = PI * 0.5
	var light := OmniLight3D.new()
	light.position = Vector3(0.1, 0.2, 0.1)
	light.light_color = Color(0.85, 0.8, 0.95)
	light.light_energy = 0.12
	light.omni_range = 1.4
	root.add_child(light)
	return lab


## Laptop screens are small: wrap Pink's words to short lines, keep the tail.
static func screen_text(text: String) -> String:
	var lines: Array = []
	var cur := ""
	for w in text.split(" "):
		if cur.length() + w.length() + 1 > 24 and cur != "":
			lines.append(cur)
			cur = w
		else:
			cur = w if cur == "" else cur + " " + w
	if cur != "":
		lines.append(cur)
	if lines.size() > 7:
		lines = lines.slice(lines.size() - 7)
	return "\n".join(lines)
