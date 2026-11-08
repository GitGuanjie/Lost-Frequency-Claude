extends Node3D
## Quiet, optional journal discoveries in a world of low gravity and wind.
var owner_level: LevelBase
var observed := [false,false,false]
var tones: Array = []

func setup(level: LevelBase) -> void:
    owner_level=level

func observe(_player: Player,index: int) -> void:
    if observed[index]:
        Overlay.subtitle("The wind returns to the same note.",2.5)
        return
    observed[index]=true
    var descriptions: Array[String] = [
        "The warm island sands feel weightless; the palms bend toward the same evening sun.",
        "Far below the floating sand, the current keeps the islands suspended.",
        "The island fork rejoins its own tracks, but the distant Barrier still looks unstable.",
    ]
    var text: String = descriptions[index]
    SaveService.record_discovery("L149","dev25:wind:%d"%index,text,"ADAPTATION")
    Overlay.subtitle(text,3.6)
    if owner_level!=null and owner_level.sound!=null:
        owner_level.sound.play_at("wind",{"seconds":4.0},owner_level.player.global_position,-35.0)
