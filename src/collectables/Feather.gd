extends Area

onready var collision_shape = $CollisionShape
onready var animation_player = $feather/AnimationPlayer

var sfx_collect = load("res://assets/audio/sfx/collect_feather.ogg")

func _ready() -> void:
	animation_player.play("Idle")

func destroy() -> void:
	queue_free()

func _on_Feather_body_entered(body: Node) -> void:
	if body.name == "Player":
		collision_shape.disabled = true
		body.add_collectable()
		animation_player.play("Dissolve")
		AudioManager.play_sfx(sfx_collect, -5, rand_range(1.0, 1.2))
