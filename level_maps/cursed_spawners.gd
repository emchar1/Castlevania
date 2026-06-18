extends Node2D
class_name CursedSpawners

# PROPERTIES

@export var a_spawners_type: Enemy.Type = Enemy.Type.ZOMBIE
@export var b_spawners_type: Enemy.Type = Enemy.Type.ZOMBIE
@export var c_spawners_type: Enemy.Type = Enemy.Type.ZOMBIE
@export var d_spawners_type: Enemy.Type = Enemy.Type.ZOMBIE

@onready var spawners_a: Array = [
	$SpawnManager3, $SpawnManager11, $SpawnManager19, $SpawnManager27
]

@onready var spawners_b: Array = [
	$SpawnManager4, $SpawnManager12, $SpawnManager20, $SpawnManager28
]

@onready var spawners_c: Array = [
	$SpawnManager5, $SpawnManager13, $SpawnManager21, $SpawnManager29
]

@onready var spawners_d: Array = [
	$SpawnManager6, $SpawnManager14, $SpawnManager22, $SpawnManager30
]


# INIT FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_setup_spawners()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _setup_spawners():
	if a_spawners_type != Enemy.Type.ZOMBIE:
		for spawner in spawners_a:
			spawner.enemy_type = a_spawners_type
	
	if b_spawners_type != Enemy.Type.ZOMBIE:
		for spawner in spawners_b:
			spawner.enemy_type = b_spawners_type
	
	if c_spawners_type != Enemy.Type.ZOMBIE:
		for spawner in spawners_c:
			spawner.enemy_type = c_spawners_type
	
	if d_spawners_type != Enemy.Type.ZOMBIE:
		for spawner in spawners_d:
			spawner.enemy_type = d_spawners_type


# FUNCTIONS

func reset_spawners():
	for spawner in get_children():
		spawner.reset_spawn()
