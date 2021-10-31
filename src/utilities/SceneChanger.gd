extends CanvasLayer

onready var animation_player = $Control/AnimationPlayer
var scene: String

func change_scene(new_scene, animation) -> void:
	scene = new_scene
	animation_player.play(animation)

func new_scene():
	assert(get_tree().change_scene(scene) == OK)
