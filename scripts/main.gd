extends Node

# PROPERTIES

@onready var player = $Player
@onready var forest_map = $ForestMap
@onready var graveyard_map = $GraveyardMap

# TODO: - Build map looping logic
@onready var spawn_left = $MapLoop/LoopRight/SpawnLeft
@onready var spawn_right = $MapLoop/LoopLeft/SpawnRight


# FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_checkpoint_if_exists()
	set_camera_bounds_to_player_global_position()
	
	CurseManager.activated.connect(curse_activated)
	
	# Connect all map types here!
	forest_map.zone_trans_started.connect(zone_trans_started)
	forest_map.zone_trans_ended.connect(zone_trans_ended)
	graveyard_map.zone_trans_started.connect(zone_trans_started)
	graveyard_map.zone_trans_ended.connect(zone_trans_ended)
	
	player.dead.connect(kill_player)
	
	await get_tree().create_timer(0.5).timeout
	forest_map.get_zone(0, 0).set_music()


# SIGNAL CONNECT FUNCTIONS

func zone_trans_started():
	player.allow_input = false


func zone_trans_ended():
	player.allow_input = true


func kill_player():
	AudioManager.stop_all_music()
	
	await get_tree().create_timer(2.0).timeout
	
	GameState.reset_health()
	#CurseManager.reset_curse()
	get_tree().call_deferred("reload_current_scene")




# FIXME: - You have to "guess" the zone_type and number :(
func _on_loop_left_body_entered(body: Node2D) -> void:
	loop_zone(body, spawn_right, Zone.ZoneType.GRAVEYARD, 3)


func _on_loop_right_body_entered(body: Node2D) -> void:
	loop_zone(body, spawn_left, Zone.ZoneType.FOREST, 3)




func loop_zone(
	body: Node2D, 
	spawn_point: Marker2D,
	zone_type: Zone.ZoneType,
	zone_number: int
) -> void:
	if body.is_in_group("player"):
		var zone_map: Node2D
		
		match zone_type:
			0: zone_map = forest_map
			1: zone_map = graveyard_map
			2: pass # catacombs
			3: pass # mountains
			4: pass # town
		
		zone_trans_started()
		zone_map._fade_zone()
		player.kill_movement()
		player.position = spawn_point.global_position
		
		var zone = zone_map.get_zone(zone_type, zone_number)
		
		if zone:
			var zone_id = Zone.get_zone_id(zone.zone_type, zone.zone_number)
			var check_id = Zone.get_zone_id(zone_type, zone_number)
			
			if zone_id == check_id:
				zone.set_camera_bounds(player, spawn_point.global_position)
				zone.set_music()
		else:
			print("Invalid zone")


func curse_activated(active: bool):
	AudioManager.stop_music(AudioManager.current_music)
	
	if active:
		await get_tree().create_timer(1.0).timeout
		AudioManager.play_music(AudioData.Music.ENERGIA)
	else:
		AudioManager.play_music(AudioData.Music.SWITCHWITHME)


func set_checkpoint_if_exists():
	if GameState.checkpoint:
		player.global_position = GameState.checkpoint


func set_camera_bounds_to_player_global_position():
	var global_position = player.global_position
	var checkpoint_left = false
	
	for node in get_tree().get_nodes_in_group("zone"):
		var zone = node as Zone
		
		if zone and zone.is_point_in_bounds(global_position):
			var checkpoint_pos = global_position.x - zone.position.x
			checkpoint_left = checkpoint_pos < GameState.screen_size.x / 2
			
			zone.set_camera_bounds(player, global_position)
			
			# FIXME: - this doesn't work (for graveyard)
			print("global_position.x: ", global_position.x)
			print("   zone.position.x: ", zone.position.x)
			if checkpoint_left:
				player.set_direction(checkpoint_left)
