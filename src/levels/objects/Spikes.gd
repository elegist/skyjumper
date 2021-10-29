extends Area



func _on_Spikes_body_entered(body: Node) -> void:
	if body.name == "Player":
		body.die()
