extends Area2D
class_name Pickup

# PROPERTIES

enum Type {
	CURSE_GEM, HEART, GOLD
}

@export var type: Type
@onready var sprite = $AnimatedSprite2D

var sfx: AudioData.AudioKey
var action: Callable


# FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func configure_pickup(_type: Type):
	type = _type
	
	match type:
		Type.CURSE_GEM:
			sprite.play("curse_gem")
			sfx = AudioData.AudioKey.CURSE_PICKUP
			action = CurseManager.pickup_curse_powerup
		Type.HEART:
			sprite.play("heart")
			sfx = AudioData.AudioKey.HEALTH_PICKUP
			action = GameState.increment_health
		Type.GOLD:
			pass


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not AudioManager.is_playing(sfx):
			AudioManager.play(sfx)
		
		action.call()
		queue_free()


func _on_timer_timeout() -> void:
	queue_free()
