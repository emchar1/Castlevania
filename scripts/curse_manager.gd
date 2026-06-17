extends Node

# PROPERTIES

signal changed(value: int, step_value: int)
signal activated(cursed: bool)

const MAX = 6
const STEP_MAX = 3
const TIMER_SPEED = 2

# Curse values
var current := 0
var step := 0

var timer: Timer
var active := false


# FUNCTIONS

func update_curse(value: int, step_value: int = 0):
	if value < 0 or value > MAX:
		return
	
	if step_value < 0 or step_value > STEP_MAX:
		return
	
	if value >= MAX and step_value > 0:
		return
	
	current = value
	step = step_value
	changed.emit(value, step_value)
	
	if is_curse_full():
		activate_curse()
	
	if is_curse_empty():
		deactivate_curse()


func increment_curse():
	var new_curse = current
	var new_step = step + 1
	
	if new_step >= STEP_MAX:
		new_step = 0
		new_curse += 1
	
	update_curse(new_curse, new_step)


func decrement_curse():
	var new_curse = current
	var new_step = step - 1
	
	if new_step < 0:
		new_step = STEP_MAX - 1
		new_curse -= 1
	
	update_curse(new_curse, new_step)


func reset_curse():
	update_curse(0)


func activate_curse():
	if active:
		return
	
	if timer:
		timer.queue_free()
	
	active = true
	
	timer = Timer.new()
	timer.wait_time = TIMER_SPEED
	timer.one_shot = false
	timer.timeout.connect(_on_timer_tick)
	add_child(timer)
	timer.start()
	
	activated.emit(true)


func deactivate_curse():
	if not active:
		return
	
	if timer:
		timer.queue_free()
	
	active = false
	activated.emit(false)


func is_curse_full() -> bool:
	return current >= MAX


func is_curse_empty() -> bool:
	return current <= 0 and step <= 0


func _on_timer_tick():
	decrement_curse()


func pickup_curse_powerup():
	if not active:
		increment_curse()
