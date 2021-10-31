extends Spatial

var bgm_stage = load("res://assets/audio/bgm/menu.ogg")

func _ready() -> void:
	AudioManager.play_bgm(bgm_stage)
