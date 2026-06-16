extends Area2D

# PROPERTIES

@export var enemy_type: Enemy.Type
@export var max_enemies = 1

var enemy_scene = preload("res://scenes/enemy.tscn")
var enemy_count := 0


# FUNCTIONS

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("spawn_trigger"):
		var body = area.get_parent()
		var player = body as Player
		
		if player:
			call_deferred("_spawn_enemy", player.global_position)


# Spawns an enemy if the spawner is not at max capacity.
# Called when the player enters the spawner's area.
func _spawn_enemy(player_pos: Vector2):
	if enemy_count >= max_enemies:
		return
	
	var enemy = enemy_scene.instantiate()
	enemy.died.connect(_despawn_enemy)
	add_child(enemy)
	
	enemy.set_direction(player_pos)
	enemy.configure_enemy(enemy_type)
	
	enemy_count += 1


# Despawns an enemy by reducing the count. Called when an enemy dies.
func _despawn_enemy():
	enemy_count -= 1


# Resets the spawner by despawning all enemies it has spawned.
# Called when the player enters a new zone.
func reset_spawn():
	for child in get_children():
		var enemy = child as Enemy
		
		if enemy:
			enemy.queue_free()
			_despawn_enemy()
