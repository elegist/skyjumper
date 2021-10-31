extends Area



func _on_Death_body_entered(body: Node) -> void:
	if body.name == "Player":
		body.die()
