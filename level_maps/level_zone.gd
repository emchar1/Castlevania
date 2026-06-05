extends Node2D
class_name Zone

# PROPERTIES

signal zone_entered(zone: Zone, direction: Direction)
signal zone_dead()

enum ZoneType {
	FOREST, GRAVEYARD, CATACOMBS, MOUNTAINS, TOWN
}

enum Direction {
	LEFT, RIGHT, TOP_LEFT, TOP_RIGHT
}

@export var music: AudioData.Music
@export var cursed_texture: Texture2D
@export var normal_texture: Texture2D
@export var zone_type: ZoneType
@export var zone_number: int
var zone_id: String

@onready var camera_bounds_tl = $CameraBounds/TopLeft
@onready var camera_bounds_br = $CameraBounds/BottomRight
@onready var spawn_left = $SpawnPoints/SpawnLeft
@onready var spawn_right = $SpawnPoints/SpawnRight
@onready var spawn_top_left = get_node_or_null("SpawnPoints/SpawnTopLeft")
@onready var spawn_top_right = get_node_or_null("SpawnPoints/SpawnTopRight")

@onready var floor_tiles = $TileMapLayers/Floor
@onready var bg_tiles = $TileMapLayers/Background
@onready var decor_tiles = $TileMapLayers/Decor


# FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	zone_id = Zone.get_zone_id(zone_type, zone_number)
	CurseManager.activated.connect(curse_activated)


# Sets camera bounds with player's camera.
func set_camera_bounds(player: Player, spawn_pos: Vector2):
	# Set camera bounds (limits)
	player.camera.limit_left = camera_bounds_tl.global_position.x
	player.camera.limit_top = camera_bounds_tl.global_position.y
	player.camera.limit_right = camera_bounds_br.global_position.x
	player.camera.limit_bottom = camera_bounds_br.global_position.y
	
	# Set player spawn point
	player.position = spawn_pos


func set_music():
	if CurseManager.active:
		return
	
	if not AudioManager.is_music_playing(music):
		AudioManager.stop_music(AudioManager.current_music)
		AudioManager.play_music(music)


static func get_zone_id(type: ZoneType, number: int) -> String:
	return str(type) + str(number)


# ZONE ENTRANCE SIGNALS

func _on_exit_left_body_entered(body: Node2D) -> void:
	_on_zone_entered(body, Direction.LEFT)


func _on_exit_right_body_entered(body: Node2D) -> void:
	_on_zone_entered(body, Direction.RIGHT)


func _on_exit_top_left_body_entered(body: Node2D) -> void:
	_on_zone_entered(body, Direction.TOP_LEFT)


func _on_exit_top_right_body_entered(body: Node2D) -> void:
	_on_zone_entered(body, Direction.TOP_RIGHT)


func _on_dead_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		zone_dead.emit()
		
		var player = body as Player
		
		if player:
			player.kill_player()


func _on_zone_entered(body: Node2D, direction: Direction):
	if body.is_in_group("player"):
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
			
			player.kill_movement()
			set_camera_bounds(player, spawn_pos)
			set_music()
	
	if body.is_in_group("enemy"):
		var enemy = body as Enemy
		
		if enemy:
			print("reached zone end.")
			enemy.change_directions()



func curse_activated(cursed: bool):
	set_textures(cursed)


func set_textures(cursed: bool):
	for tilemap in [bg_tiles, decor_tiles, floor_tiles]:
		var source = tilemap.tile_set.get_source(0) as TileSetAtlasSource
		if source:
			source.texture = cursed_texture if cursed else normal_texture
