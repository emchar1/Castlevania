extends Node

# PROPERTIES

signal health_changed(value: int)

const HEALTH_MAX = 6
var health_current := 6
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
