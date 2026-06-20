extends Area2D
class_name Checkpoint

# PROPERTIES

@onready var spawn_point = $Marker2D
@export var is_left_checkpoint: bool = false


# FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var player = body as Player
		
		if player:
			GameState.set_checkpoint(spawn_point.global_position)
			
			if is_left_checkpoint:
				player.set_direction(true)
			
			print("Checkpoint set at ", spawn_point.global_position)
