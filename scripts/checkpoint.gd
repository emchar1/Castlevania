extends Area2D
class_name Checkpoint

# PROPERTIES

@onready var spawn_point = $Marker2D


# FUNCTIONS

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var player = body as Player
		
		if player:
			GameState.set_checkpoint(spawn_point.global_position)
