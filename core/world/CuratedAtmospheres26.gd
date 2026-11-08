extends Node3D
## DEV26: curated, data-driven ambient micro-scenes for ten *existing* levels.
## All props are GLB assets owned by this node, have NO collision, and remain
## outside the authored main corridor. No exits/arrivals/manifest flags changed.
const Dress = preload("res://core/world/ModelDress.gd")
var level: LevelBase
var site: Dictionary = {}
var found: Dictionary = {}
var lamps: Array = []
var panels: Array = []
var _last_used: int = -1

func setup(owner: LevelBase, record: Dictionary) -> void:
    level = owner
    site = record
    var c: Array = site.get("tint", [0.8, 0.8, 0.8])
    var tint := Color(float(c[0]), float(c[1]), float(c[2]))
    var cues: Array = site.get("cues", [])
    for i in cues.size():
        var cue: Dictionary = cues[i]
        var raw: Array = cue["pos"]
        var at := Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
        # Only the small vertical marker glows, never place new walls in a
        # canonical corridor; tiny objects use original imported mesh materials.
        var panel := MeshInstance3D.new()
        panel.name = "DEV26_Signal_%d" % i
        var shape := BoxMesh.new()
        shape.size = Vector3(0.16, 0.35, 0.09)
        panel.mesh = shape
        panel.position = at + Vector3(0.0, 1.13, 0.0)
        panel.material_override = MatLib.panel(tint, 0.08)
        panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(panel)
        panels.append(panel)
        var lamp := OmniLight3D.new()
        lamp.name = "DEV26_ClueLamp_%d" % i
        lamp.position = panel.position + Vector3(0.0, 0.3, 0.0)
        lamp.omni_range = 6.5
        lamp.light_energy = 0.03
        lamp.light_color = tint
        lamp.shadow_enabled = false
        add_child(lamp)
        lamps.append(lamp)
        for prop in cue.get("props", []):
            Dress._place(owner, self, prop)
        # This uses the SAME E-interaction path used by the existing player.
        # The interaction is owned by the annex and leaves with the level.
        var hit := owner.add_interactable(at + Vector3(0, 1.0, 0),
            Vector3(1.8, 2.1, 2.0), str(cue["prompt"]), Callable(self, "inspect").bind(i))
        hit.reparent(self)
    owner.add_landmark(str(site["title"]), _v(cues[0]["pos"]) + Vector3.UP)
    # Ambient proximity sound and visual information are independent from E.
    # Existing cooldown + vertical-height gating prevents repeated or
    # through-the-floor events. Quiet levels deliberately omit extra sound.
    var ambient_records: Array = []
    for cue in cues:
        var pos: Array = cue["pos"]
        var ambient_sound := ""
        match owner.stable_id:
            "L060": ambient_sound = "wind"
            "L071": ambient_sound = "creak"
            "L079": ambient_sound = "fluorescent_hum"
            "L083": ambient_sound = "water_bed"
            "L090": ambient_sound = "creak"
            "L101": ambient_sound = "room_tone"
            "L160": ambient_sound = "whisper"
            "L197": ambient_sound = "drip"
        ambient_records.append({"id": "dev26:approach:" + str(cue["id"]),
            "pos": [pos[0], float(pos[1])+1.0, pos[2]], "height": 2.5,
            "radius": 4.0, "caption": "[a detail of the place draws your attention]",
            "sound": ambient_sound, "source": "ADAPTATION"})
    var atmosphere := preload("res://core/world/AmbientDiscovery.gd").new()
    atmosphere.name = "DEV26_ProximityAmbience"
    add_child(atmosphere)
    atmosphere.setup(owner, ambient_records)

static func _v(raw: Array) -> Vector3:
    return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))

func inspect(_player: Player, index: int) -> void:
    var cue: Dictionary = site["cues"][index]
    var cid := str(cue["id"])
    if found.has(cid):
        Overlay.subtitle("[you have already recorded this detail]", 2.0)
        return
    found[cid] = true
    var tint: Array = site["tint"]
    var color := Color(float(tint[0]), float(tint[1]), float(tint[2]))
    (lamps[index] as OmniLight3D).light_energy = 0.75
    (panels[index] as MeshInstance3D).material_override = MatLib.panel(color, 1.1)
    SaveService.record_discovery(level.stable_id, "dev26:" + cid,
        str(cue["description"]), "ADAPTATION")
    Overlay.subtitle(str(cue["description"]), 4.0)
    if not SessionState.is_qa():
        var p: Array = cue["pos"]
        var sound_name := "drip" if level.stable_id == "L197" else (
            "static" if level.stable_id == "L263" else "creak")
        level.sound.play_at(sound_name, {}, _v(p) + Vector3.UP, -23.0)
    # Localized progress: completing all observations improves the guide lamps,
    # but no gate is imposed on any original exit.
    if found.size() == (site["cues"] as Array).size():
        for lamp in lamps:
            (lamp as OmniLight3D).light_energy = 1.0
        SaveService.record_discovery(level.stable_id, "dev26:complete",
            "All environmental details in this area were investigated.", "ADAPTATION")

func inspection_count() -> int:
    return found.size()
