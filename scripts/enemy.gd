extends CharacterBody2D
class_name Enemy

# PROPERTIES

enum Type {
	ZOMBIE, SKELETON, FRANKENSTEIN, SLIME, BAT
}

signal died

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


func set_direction(player_pos: Vector2):
	dir = -1 if global_position > player_pos else 1


func change_directions():
	dir *= -1


# TODO: - build this out, add hurt animation, death, etc.
func hurt_enemy(dmg: int):
	hp -= dmg
	if hp <= 0:
		kill_enemy()
		return
	
	var orig_speed = speed
	
	modulate = Color.RED
	speed = 0
	
	await get_tree().create_timer(0.6).timeout
	
	modulate = Color.WHITE
	speed = orig_speed


func kill_enemy():
	CurseManager.increment_curse()
	died.emit()
	queue_free()


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
		var player = body as Player
		if player:
			player.hurt_player(attack_dmg, global_position)
			print("Enemy hurt player.")
