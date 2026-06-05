extends Area2D

# PROPERTIES

@export var enemy_scene: PackedScene
@export var enemy_type: Enemy.Type
@export var max_enemies = 1

var enemy_count := 0


# FUNCTIONS

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("spawn_trigger"):
		var body = area.get_parent()
		var player = body as Player
		
		if player:
			call_deferred("_spawn_enemy", player.global_position)


func _spawn_enemy(player_pos: Vector2):
	if enemy_count >= max_enemies:
		return
	
	var enemy = enemy_scene.instantiate()
	enemy.died.connect(_despawn_enemy)
	add_child(enemy)
	
	enemy.set_direction(player_pos)
	
	enemy_count += 1


func _despawn_enemy():
	enemy_count -= 1
