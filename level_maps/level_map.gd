extends Node2D

# PROPERTIES

signal zone_trans_started
signal zone_trans_ended

@onready var fade_rect = $Transition/FadeRect


# FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		var zone = child as Zone
		
		if zone:
			zone.zone_entered.connect(zone_entered)


# Returns the absolute Zone given the type and number.
func get_zone(zone_type: Zone.ZoneType, zone_number: int) -> Zone:
	var check_id = Zone.get_zone_id(zone_type, zone_number)
	
	for child in get_children():
		var zone = child as Zone
		
		if zone and \
		Zone.get_zone_id(zone.zone_type, zone.zone_number) == check_id:
			return zone
	
	return null


func zone_entered(_zone: Zone, _direction: Zone.Direction):
	zone_trans_started.emit()
	
	_fade_zone()


func _fade_zone():
	#var fade_steps = [1.0, 0.75, 0.5, 0.25, 0.0]
	
	fade_rect.modulate.a = 1.0
	
	await get_tree().create_timer(0.5).timeout
	fade_rect.modulate.a = 0.0
	zone_trans_ended.emit()
	
	#for alpha in fade_steps:
		#await get_tree().create_timer(0.07).timeout
		#fade_rect.modulate.a = alpha
		#
		#if alpha == fade_steps[fade_steps.size() - 1]:
			#zone_trans_ended.emit()
