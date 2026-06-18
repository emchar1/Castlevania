extends CanvasLayer

# PROPERTIES

@onready var health := $Health/Container.get_children()
@onready var curse := $Curse/Container.get_children()
@onready var score := $Score/Total
@onready var coins := $Coins/Total

var curse_meter_is_flashing := false


# FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_current_health(GameState.health_current)
	update_current_curse(CurseManager.current, CurseManager.step)
	set_flash_cursed_meter(false)
	
	GameState.health_changed.connect(update_current_health)
	GameState.coins_changed.connect(update_coins)
	GameState.score_changed.connect(update_score)
	CurseManager.changed.connect(update_current_curse)


func _process(_delta: float) -> void:
	if CurseManager.active:
		toggle_flash_cursed_meter()


# HEALTH/CURSE FUNCTIONS

func set_health_filled(index: int, filled: bool):
	var sprite = health[index] as Sprite2D
	var atlas = sprite.texture as AtlasTexture
	atlas.region.position.x = 0.0 if filled else 8.0


func set_curse_filled(index: int, step_value: int):
	var sprite = curse[index] as Sprite2D
	var atlas = sprite.texture as AtlasTexture
	
	var region_pos_x
	match step_value:
		0: region_pos_x = 8.0
		1: region_pos_x = 16.0
		2: region_pos_x = 24.0
		3: region_pos_x = 0.0
	
	atlas.region.position.x = region_pos_x


func toggle_flash_cursed_meter(speed: float = 0.1):
	if curse_meter_is_flashing:
		return
	
	curse_meter_is_flashing = true
	
	set_flash_cursed_meter(true)
	await get_tree().create_timer(speed).timeout
	
	set_flash_cursed_meter(false)
	await get_tree().create_timer(speed).timeout
	
	curse_meter_is_flashing = false


func set_flash_cursed_meter(flash: bool):
	for i in curse.size():
		var sprite = curse[i] as Sprite2D
		var atlas = sprite.texture as AtlasTexture
		
		await get_tree().create_timer(0.03).timeout
		atlas.region.position.y = 16.0 if flash else 8.0


# SIGNAL CONNECTION FUNCTIONS

func update_current_health(value: int):
	for i in health.size():
		set_health_filled(i, i < value)


func update_coins(_value: int):
	coins.text = "%03d" % GameState.total_coins


func update_score(_value: int):
	score.text = "%06d" % GameState.current_score


func update_current_curse(value: int, step_value: int):
	for i in curse.size():
		var curse_step
		
		if i < value:
			curse_step = 3
		elif i == value:
			curse_step = step_value
		else:
			curse_step = 0
		
		set_curse_filled(i, curse_step)
