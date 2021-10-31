extends Particles

func _ready() -> void:
	yield(get_tree().create_timer(2), "timeout")
	queue_free()
