extends Area



func _on_Goal_body_entered(body: Node) -> void:
	if body.name == "Player":
		body.win()
