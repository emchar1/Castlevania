extends Area2D

# PROPERTIES

enum EnemyType {
	ZOMBIE, SKELETON, FRANKENSTEIN, SPIDER, BAT
}

@export var enemy_scene: PackedScene
@export var enemy_type: EnemyType


# FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
