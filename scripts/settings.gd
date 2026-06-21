extends Node


# PROPERTIES

@onready var switch_button = $SwitchHandButton
@onready var instructions = $Bindings/Instructions
@onready var close_button = $CloseButton
@onready var music_slider = $MusicSlider
@onready var sfx_slider = $SFXSlider
@onready var music = $Music
@onready var sound = $Sound

var is_right_handed = true


# FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_slider.value = GameState.music_volume
	sfx_slider.value = GameState.sfx_volume
	music.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_master_slider_value_changed(value: float) -> void:
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	sound.play()


func _on_music_slider_value_changed(value: float) -> void:
	var bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	GameState.music_volume = value


func _on_sfx_slider_value_changed(value: float) -> void:
	var bus = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	GameState.sfx_volume = value
	sound.play()


func _on_close_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")


func _on_switch_hand_button_pressed() -> void:
	sound.play()
	
	is_right_handed = not is_right_handed
	
	_rebind_keys()
	
	if is_right_handed:
		switch_button.text = "RIGHT HANDED"
		instructions.text = "MOVE: WASD / ARROW KEYS\nATTACK: J / NUMPAD 4\nJUMP: K / NUMPAD 5"
	else:
		switch_button.text = "LEFT HANDED"
		instructions.text = "MOVE: IJKL / ARROW KEYS\nATTACK: F / NUMPAD 4\nJUMP: D / NUMPAD 5"


# KEYS RE-BINDING HELPER FUNCTIONS

func _rebind_keys():
	
	# Re-Bind D-Pad
	_rebind_d_pad()
	
	_rebind_key_helper("move_up", KEY_W if is_right_handed else KEY_I, false)
	_rebind_key_helper("move_left", KEY_A if is_right_handed else KEY_J, false)
	_rebind_key_helper("move_down", KEY_S if is_right_handed else KEY_K, false)
	_rebind_key_helper("move_right", KEY_D if is_right_handed else KEY_L, false)
	
	
	# Re-Bind Buttons
	_rebind_buttons()
	
	_rebind_key_helper("attack", KEY_J if is_right_handed else KEY_F, false)
	_rebind_key_helper("jump", KEY_K if is_right_handed else KEY_D, false)


func _rebind_d_pad():
	_rebind_key_helper("move_up", KEY_UP, true)
	_rebind_key_helper("move_left", KEY_LEFT, true)
	_rebind_key_helper("move_down", KEY_DOWN, true)
	_rebind_key_helper("move_right", KEY_RIGHT, true)


func _rebind_buttons():
	_rebind_key_helper("attack", KEY_KP_4, true)
	_rebind_key_helper("jump", KEY_KP_5, true)


func _rebind_key_helper(key_event: StringName, key: Key, should_erase_all: bool):
	if should_erase_all:
		InputMap.action_erase_events(key_event)
	
	var event := InputEventKey.new()
	event.physical_keycode = key
	
	InputMap.action_add_event(key_event, event)
