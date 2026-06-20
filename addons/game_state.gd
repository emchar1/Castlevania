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


# FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size


func update_health(value: int):
	if value < 0 or value > HEALTH_MAX:
		return
	
	health_current = value
	health_changed.emit(value)


func update_coins(value: int):
	if value < 0:
		return
	
	total_coins = value
	coins_changed.emit(value)


func update_score(value: int):
	if value < 0:
		return
	
	current_score = value
	score_changed.emit(value)


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
