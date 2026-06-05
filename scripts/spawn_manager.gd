extends Area2D

# PROPERTIES

@export var enemy_scene: PackedScene
@export var enemy_type: Enemy.Type


# FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var enemy = enemy_scene.instantiate()
	add_child(enemy)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
