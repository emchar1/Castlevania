extends Node

# PROPERTIES

signal health_changed(value: int)
signal coins_changed(value: int)
signal score_changed(value: int)

const HEALTH_MAX = 6
var health_current := 6
var total_coins := 0
var current_score := 0
var checkpoint: Vector2
var screen_size: Vector2

var music_volume := 1.0
var sfx_volume := 1.0


# FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size


func update_health(value: int):
	health_current = clampi(value, 0, HEALTH_MAX)
	health_changed.emit(health_current)


func update_coins(value: int):
	total_coins = max(value, 0)
	coins_changed.emit(total_coins)


func update_score(value: int):
	current_score = max(value, 0)
	score_changed.emit(current_score)


func set_checkpoint(point: Vector2):
	checkpoint = point


# HEALTH CONVENIENCE FUNCTIONS

func increment_health():
	update_health(health_current + 1)


func decrement_health():
	update_health(health_current - 1)


func update_health_by(amount: int):
	update_health(health_current + amount)


func reset_health():
	update_health(HEALTH_MAX)


func is_health_gone() -> bool:
	return health_current <= 0


# COINS CONVENIENCE FUNCTIONS

func increment_coins():
	update_coins(total_coins + 1)

func grant_coins(amount: int):
	update_coins(total_coins + amount)

func spend_coins(amount: int) -> bool:
	if amount > total_coins:
		return false
	
	update_coins(total_coins - amount)
	return true


# SCORE CONVENIENCE FUNCTIONS

func add_score(amount: int):
	update_score(current_score + amount)
