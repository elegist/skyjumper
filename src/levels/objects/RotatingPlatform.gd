extends KinematicBody

export(float, 0, 1) var speed_modifier = 1

func _physics_process(delta: float) -> void:
	rotate_object_local(Vector3(1,0,0), PI * speed_modifier * delta)
