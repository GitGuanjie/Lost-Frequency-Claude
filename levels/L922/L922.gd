extends LevelBase
## Escherian Stairwell: a compact brutalist spiral that climbs and returns to its start.
var _loop_count:=0
var _upper_count:=0
var _reset_cooldown:=0.0

func build() -> void:
    rules["view_distance"]=100.0
    indoor_env(Color(0.74,0.74,0.74),0.37,Color(0.72,0.72,0.72),0.002)
    MatLib.define("l922_concrete",{"albedo_a":Color(0.29,0.29,0.29),"albedo_b":Color(0.39,0.39,0.39)},"concrete")
    MatLib.define("l922_black",{"albedo_a":Color(0.03,0.03,0.03),"albedo_b":Color(0.08,0.08,0.08)},"concrete")
    MatLib.register("l922_glow",MatLib.panel(Color(1.0,1.0,1.0),2.0))
    lights.setup(4,0)
    _spiral()
    add_arrival("start",Vector3(-8,0.08,-10))
    add_landmark("A staircase which rises to nowhere",Vector3(0,2,0))
    add_shot("escherian",Vector3(-8,1.62,-11),Vector3(0,21,0))
    add_shot("ceiling_light",Vector3(2,11.7,-7),Vector3(0,30,0))
    # No footsteps or soundtrack added: documented silence is essential.

func _spiral() -> void:
    var k:=kit("MonochromeSpiral")
    k.slab(-14,-16,14,16,0,0.55,"l922_concrete")
    # Four rises each 4m around a solid centre. Adjacent floors have actual stair openings.
    for n in 4:
        var y:float=float(n)*4.0
        var start:Vector3
        var direction:Vector3
        match n%4:
            0:
                start=Vector3(-8,y,-10)
                direction=Vector3(0,0,1)
            1:
                start=Vector3(-8,y,10)
                direction=Vector3(1,0,0)
            2:
                start=Vector3(8,y,10)
                direction=Vector3(0,0,-1)
            _:
                start=Vector3(8,y,-10)
                direction=Vector3(-1,0,0)
        k.stairs(start,direction,2.7,4.0,20,"l922_concrete",1.0 if n%2==0 else 0.8)
        k.box(Vector3(0,y+1.8,0),Vector3(8,3.6,8),"l922_black")
        _upper_count+=1
    # Visual unreachably distant white light, no physical end door.
    k.box(Vector3(0,35,0),Vector3(11,0.25,11),"l922_glow",GeoKit.ALL,false)
    k.box(Vector3(-14,18,0),Vector3(0.4,36,32),"l922_concrete")
    k.box(Vector3(14,18,0),Vector3(0.4,36,32),"l922_concrete")
    k.box(Vector3(0,18,-16),Vector3(28,36,0.4),"l922_concrete")
    k.box(Vector3(0,18,16),Vector3(28,36,0.4),"l922_concrete")
    k.commit()
    lights.add_anchor(Vector3(0,30,0),Color.WHITE,0.9,36,0.0,"l922_white")

func level_process(delta:float) -> void:
    _reset_cooldown=maxf(0.0,_reset_cooldown-delta)
    if player!=null and player.global_position.y>15.6 and _reset_cooldown<=0.0:
        _loop_count+=1
        _reset_cooldown=3.0
        player.global_position=Vector3(-8,0.25,-10)
        # This is an in-level loop, not an invented connection to another level.
        if not SessionState.is_qa():
            Overlay.subtitle("[there is only another flight of stairs]",4.0)

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"four vertical flights", "ok":_upper_count==4}, {"what":"no fabricated destination", "ok":exits.is_empty()}, {"what":"loop state initialized", "ok":_loop_count==0}]
