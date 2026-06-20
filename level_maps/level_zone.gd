extends Node2D
class_name Zone

# PROPERTIES

signal zone_entered(zone: Zone, direction: Direction)
signal zone_dead()

enum ZoneType {
	FOREST, GRAVEYARD, CATACOMBS, MOUNTAINS, TOWN
}

enum Direction {
	LEFT, RIGHT, TOP_LEFT, TOP_RIGHT, TOP
}

@export var music: AudioData.Music
@export var zone_type: ZoneType
@export var zone_number: int
var zone_id: String

@onready var camera_bounds_tl = $CameraBounds/TopLeft
@onready var camera_bounds_br = $CameraBounds/BottomRight
@onready var spawn_left = $SpawnPoints/SpawnLeft
@onready var spawn_right = $SpawnPoints/SpawnRight
@onready var spawn_top_left = get_node_or_null("SpawnPoints/SpawnTopLeft")
@onready var spawn_top_right = get_node_or_null("SpawnPoints/SpawnTopRight")
@onready var cursed_spawners = get_node_or_null("CursedSpawners")
@onready var cursed_spawners2 = get_node_or_null("CursedSpawners2")

@onready var floor_tiles = $TileMapLayers/Floor
@onready var bg_tiles = $TileMapLayers/Background
@onready var decor_tiles = $TileMapLayers/Decor

var all_tilemaps: Array
var original_coords: Dictionary

var energia_tween: Tween
var energia_bpm_interval: float = 60 / 133.6
var energia_length: float = 40 * 4


# FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	all_tilemaps = [floor_tiles, bg_tiles, decor_tiles]
	zone_id = Zone.get_zone_id(zone_type, zone_number)
	CurseManager.activated.connect(curse_activated)
	
	# Populate original coordinates
	for tilemap in all_tilemaps:
		original_coords[tilemap.name] = {}
		
		for cell in tilemap.get_used_cells():
			var tiles = tilemap.get_cell_atlas_coords(cell)
			original_coords[tilemap.name][cell] = tiles


# Sets camera bounds with player's camera.
func set_camera_bounds(player: Player, spawn_pos: Vector2):
	# Set camera bounds (limits)
	player.camera.limit_left = camera_bounds_tl.global_position.x
	player.camera.limit_top = camera_bounds_tl.global_position.y
	player.camera.limit_right = camera_bounds_br.global_position.x
	player.camera.limit_bottom = camera_bounds_br.global_position.y
	
	# Set player spawn point
	player.position = spawn_pos


# Sets bgm based on music property set in Inspector.
func set_music():
	if CurseManager.active:
		return
	
	if not AudioManager.is_music_playing(music):
		AudioManager.stop_music(AudioManager.current_music)
		AudioManager.play_music(music)


# Checks if a point is within the bounds of this zone.
func is_point_in_bounds(point: Vector2) -> bool:
	var point_x_is_bigger = point.x >= camera_bounds_tl.global_position.x
	var point_x_is_smaller = point.x <= camera_bounds_br.global_position.x
	var point_y_is_bigger = point.y >= camera_bounds_tl.global_position.y
	var point_y_is_smaller = point.y <= camera_bounds_br.global_position.y
	var x_in_bounds = point_x_is_bigger and point_x_is_smaller
	var y_in_bounds = point_y_is_bigger and point_y_is_smaller
	
	return x_in_bounds and y_in_bounds


# Gets zone id format using type and number formula, e.g. 0-1 = forest-1
# (See ZoneType enum above for type cases)
static func get_zone_id(type: ZoneType, number: int) -> String:
	return str(type) + "-" + str(number)


# ZONE ENTRANCE SIGNALS

func _on_exit_left_body_entered(body: Node2D) -> void:
	_on_zone_entered(body, Direction.LEFT)


func _on_exit_right_body_entered(body: Node2D) -> void:
	_on_zone_entered(body, Direction.RIGHT)


func _on_exit_top_left_body_entered(body: Node2D) -> void:
	_on_zone_entered(body, Direction.TOP_LEFT)


func _on_exit_top_right_body_entered(body: Node2D) -> void:
	_on_zone_entered(body, Direction.TOP_RIGHT)


func _on_exit_top_body_entered(body: Node2D) -> void:
	_on_zone_entered(body, Direction.TOP)


func _on_dead_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		zone_dead.emit()
		
		var player = body as Player
		
		if player:
			player.kill_player(0.25)


func _on_zone_entered(body: Node2D, direction: Direction):
	if body.is_in_group("player"):
		for spawner in get_tree().get_nodes_in_group("spawner"):
			spawner.reset_spawn()
		
		zone_entered.emit(self, direction)
		
		var player = body as Player
		
		if player:
			var spawn_pos := Vector2.ZERO
			
			match direction:
				Direction.LEFT:
					spawn_pos = spawn_left.global_position
				Direction.RIGHT:
					spawn_pos = spawn_right.global_position
				Direction.TOP_LEFT:
					spawn_pos = spawn_top_left.global_position
				Direction.TOP_RIGHT:
					spawn_pos = spawn_top_right.global_position
				Direction.TOP:
					spawn_pos = spawn_right.global_position
			
			player.kill_movement()
			set_camera_bounds(player, spawn_pos)
			set_music()
	
	if body.is_in_group("enemy"):
		var enemy = body as Enemy
		
		if enemy:
			if direction == Direction.TOP:
				enemy.flee()
			else:
				enemy.change_directions()


func curse_activated(cursed: bool):
	set_textures(cursed)
	
	if cursed:
		await get_tree().create_timer(1.0 + 2 * energia_bpm_interval).timeout
		
		var energia_range_last = energia_length - 1
		var color_index := 0
		var rhythm_index := 0
		
		var colors = [
			Color.RED,
			Color.GREEN,
			Color.CYAN,
			Color.MAGENTA
		]
		
		var rhythm = [
			{ "note_length": 4.0, "count": 1 * 1, "should_fade": true },
			{ "note_length": 1.0, "count": 11 * 4, "should_fade": false },
			{ "note_length": 4.0, "count": 2 * 1, "should_fade": true },
			{ "note_length": 2.0, "count": 2 * 2, "should_fade": true },
			{ "note_length": 1.0, "count": 1 * 4, "should_fade": false },
			{ "note_length": 0.5, "count": 1 * 8, "should_fade": false },
			{ "note_length": 0.25, "count": 1 * 16, "should_fade": false },
			{ "note_length": 0.125, "count": 1 * 32, "should_fade": false },
			{ "note_length": 1.0, "count": 20 * 4, "should_fade": true },
		]
		
		for i in range(energia_length):
			var note_length = rhythm[rhythm_index]["note_length"]
			var note_count = rhythm[rhythm_index]["count"]
			var should_fade = rhythm[rhythm_index]["should_fade"]
			var timer_duration = energia_bpm_interval * note_length
			
			for _j in range(note_count):
				# Revert to orginal color at end of curse sequence
				if not CurseManager.active:
					color_textures(Color.WHITE)
					break
				
				# Last index also gets original color
				var flash_color = colors[color_index]
				
				color_textures(
					flash_color if i < energia_range_last else Color.WHITE,
					should_fade,
					note_length
				)
				
				await get_tree().create_timer(timer_duration).timeout
				
				# Cycle through colors, resetting at end
				color_index += 1
				if color_index >= colors.size():
					color_index = 0
			
			# Same with rhythm...
			rhythm_index += 1
			if rhythm_index >= rhythm.size():
				rhythm_index = 0
	else:
		color_textures(Color.WHITE)
		
		if cursed_spawners:
			cursed_spawners.reset_spawners()
		
		if cursed_spawners2:
			cursed_spawners2.reset_spawners()


# TEXTURE FUNCTIONS

func set_textures(cursed: bool):
	await fade_textures([0.75, 0.5, 0.25, 0.0])
	
	for tilemap in all_tilemaps:
		for cell in original_coords[tilemap.name]:
			var coords: Vector2i = original_coords[tilemap.name][cell]
			var y_offset: int = 3 if cursed else 0
			tilemap.set_cell(cell, 0, coords + Vector2i(0, y_offset))
	
	if cursed:
		await get_tree().create_timer(0.3).timeout
	
	fade_textures([0.25, 0.5, 0.75, 1.0])


func fade_textures(values: Array):
	for value in values:
		for tilemap in all_tilemaps:
			tilemap.modulate = Color(value, value, value)
			await get_tree().create_timer(0.05).timeout


func color_textures(
	color: Color,
	should_fade: bool = false,
	fade_out: float = 0.0
):
	for tilemap in all_tilemaps:
		tilemap.modulate = color
		
		if energia_tween:
			energia_tween.kill()
		
		if should_fade:
			energia_tween = create_tween()
			energia_tween.tween_property(
				tilemap,
				"modulate",
				Color.WHITE,
				fade_out
			)
