extends CharacterBody2D
class_name Enemy

# PROPERTIES

enum Type {
	ZOMBIE, SKELETON, FRANKENSTEIN, SLIME, BAT
}

@export var speed = 50.0
@export var hp = 1
@export var attack_dmg = 1
@export var type: Type

@onready var sprite = $AnimatedSprite2D
@onready var ground_ray = $RayCast2D

var dir := 1.0
var is_on_ground := false
var was_on_ground := false


# FUNCTIONS

func _ready() -> void:
	_configure_enemy()


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle movement
	if is_on_floor():
		velocity.x = speed * dir
	
	# Check raycasting
	was_on_ground = is_on_ground
	is_on_ground = ground_ray.is_colliding()
	
	# Update positions
	ground_ray.target_position.x = abs(ground_ray.target_position.x) * dir
	sprite.flip_h = dir < 0
	
	if was_on_ground and not is_on_ground:
		change_directions()
	
	move_and_slide()


func change_directions():
	dir *= -1


# HELPER FUNCTIONS

func _configure_enemy():
	match type:
		Type.ZOMBIE:
			speed = 50
			hp = 1
			attack_dmg = 1
		Type.SKELETON:
			speed = 100
			hp = 2
			attack_dmg = 1
		Type.FRANKENSTEIN:
			speed = 30
			hp = 4
			attack_dmg = 2
		Type.SLIME:
			speed = 10
			hp = 1
			attack_dmg = 1
		Type.BAT:
			speed = 150
			hp = 1
			attack_dmg = 1


# SIGNAL FUNCTIONS

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Enemy touched player.")
