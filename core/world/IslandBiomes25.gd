extends RefCounted
## DEV25: extra natural island chains for the weak-gravity Level 149. Geometry
## remains deliberately irregular and separate; no invented roads or level exits.
const DATA := "res://data/dev25_coconut_island_variants.json"
const Dress := preload("res://core/world/ModelDress.gd")
const Observation := preload("res://core/world/IslandObservation25.gd")

static func install(owner: LevelBase) -> Dictionary:
    var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
    if not raw is Dictionary or str(raw.get("level","")) != owner.stable_id:
        push_error("DEV25 missing or invalid island blueprint")
        return {}
    var k := owner.kit("DEV25_Coconut_Island_Variation")
    var island_list: Array = raw["islands"]
    var discovered := Observation.new()
    discovered.name="DEV25_WindObservation"
    owner.add_child(discovered)
    discovered.setup(owner)
    var glb_owner := Node3D.new()
    glb_owner.name="DEV25_Coconut_Rock_GLB"
    owner.add_child(glb_owner)
    var rocks := 0
    var palms := 0
    for rec in island_list:
        var xyz: Array = rec["pos"]
        var at := Vector3(float(xyz[0]),float(xyz[1]),float(xyz[2]))
        var radius := float(rec["radius"])
        # One coarse irregular 12-gon cylinder: real collision, not a floating visual.
        k.cylinder(at+Vector3(0,-1.0,0),radius,2.0,"l149_sand",12)
        k.cylinder(at+Vector3(-radius*.12,-2.0,radius*.08),radius*.78,1.9,"l149_sand",9,false)
        for j in range(int(rec["palms"])):
            var angle := TAU*float(j)/float(rec["palms"])+float(rec["id"])*.41
            var tx := at.x+cos(angle)*radius*.43
            var tz := at.z+sin(angle)*radius*.43
            var height := 2.8+float((j+int(rec["id"]))%3)*.55
            k.cylinder(Vector3(tx,at.y+height*.5,tz),.16,height,"l149_wood",6,false)
            # Uneven frond crowns, deliberately not modern geometric light fixtures.
            for arm in 3:
                var spread := TAU*float(arm)/3.0+angle
                k.box(Vector3(tx+cos(spread)*1.15,at.y+height,tz+sin(spread)*1.15),
                    Vector3(2.8,.20,1.25),"l149_palm",GeoKit.ALL,false)
            palms+=1
        for item in rec["props"]:
            var prop := {"pack":"nature-kit","model":str(item["model"]),
                "pos":[float(item["x"]),float(item["y"]),float(item["z"])],
                "height":float(item["height"]),"yaw":float(item["yaw"]),"solid":false}
            if Dress._place(owner,glb_owner,prop): rocks+=1
        if int(rec["id"]) in [3,8,12]:
            var index := 0 if int(rec["id"])==3 else (1 if int(rec["id"])==8 else 2)
            var examine := at+Vector3(0,1.1,0)
            owner.add_interactable(examine,Vector3(2,1.7,2),
                "Listen to the coconut-island wind",Callable(discovered,"observe").bind(index))
    k.commit()
    owner.add_landmark("Low-gravity western island chain",Vector3(-93,2.0,7))
    owner.add_landmark("The fork reconnecting near the outer palms",Vector3(-150,3.0,13))
    return {"new_islands":island_list.size(),"extra_palms":palms,"rock_props":rocks}
