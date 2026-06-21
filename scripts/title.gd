extends Node


# PROPERTIES

@onready var fade_screen = $FadeScreen
@onready var start_button = $Control/StartButton
@onready var settings_button = $Control/SettingsButton
#@onready var dpad_label = $Bindings/DPad
#@onready var powerups_label = $Bindings/PowerUps
@onready var start_sound = $Audio/StartSound
@onready var switch_sound = $Audio/SwitchHandSound

var is_right_handed = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_button.grab_focus()
	fade_screen.modulate.a = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	start_sound.play()
	
	start_button.disabled = true
	settings_button.disabled = true
	
	var tween = create_tween()
	tween.tween_property(
		fade_screen,
		"modulate:a",
		1.0,
		3.0
	)
	
	await tween.finished
	
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_settings_pressed() -> void:
	start_button.disabled = true
	settings_button.disabled = true
	
	get_tree().change_scene_to_file("res://scenes/settings.tscn")
