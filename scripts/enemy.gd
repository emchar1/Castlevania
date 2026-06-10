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
@onready var player_detector = $PlayerDetector
@onready var ground_ray = $RayCast2D

var orig_speed = 50.0
var dir := 1.0
var is_on_ground := false
var was_on_ground := false
var timer: Timer
var tween: Tween


# FUNCTIONS

func _ready() -> void:
	pass


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
	handle_collisions()


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
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	
	for i in range(20):
		tween.tween_property(self, "modulate", Color.DEEP_PINK, 0.05)
		tween.tween_property(self, "modulate", Color.DARK_CYAN, 0.05)
	
	speed = 0
	AudioManager.play(AudioData.AudioKey.ATTACK_SWING)
	
	if timer:
		timer.stop()
		timer.queue_free()
		timer = null
	
	timer = Timer.new()
	timer.wait_time = 0.6
	timer.one_shot = true
	add_child(timer)
	timer.start()
	
	await timer.timeout
	
	if tween:
		tween.kill()
	
	modulate = Color.WHITE
	speed = orig_speed


func kill_enemy():
	if tween:
		tween.kill()
	
	if timer:
		timer.stop()
		timer.queue_free()
		timer = null
	
	modulate = Color.BLACK
	speed = 0
	sprite.stop()
	AudioManager.play(AudioData.AudioKey.ATTACK_KILL)
	
	timer = Timer.new()
	timer.wait_time = 0.2
	timer.one_shot = true
	add_child(timer)
	timer.start()
	
	await timer.timeout
	
	CurseManager.increment_curse()	
	died.emit()
	queue_free()


func configure_enemy(_type: Type):
	type = _type
	
	match type:
		Type.ZOMBIE:
			sprite.play("zombie")
			speed = 50
			hp = 1
			attack_dmg = 1
		Type.SKELETON:
			sprite.play("skeleton")
			speed = 75
			hp = 2
			attack_dmg = 1
		Type.FRANKENSTEIN:
			sprite.play("frankenstein")
			speed = 30
			hp = 4
			attack_dmg = 2
		Type.SLIME:
			sprite.play("slime")
			speed = 10
			hp = 1
			attack_dmg = 1
		Type.BAT:
			sprite.play("bat")
			speed = 150
			hp = 1
			attack_dmg = 1
	
	orig_speed = speed


# SIGNAL FUNCTIONS

func handle_collisions():
	var bodies = player_detector.get_overlapping_bodies()
	
	for body in bodies:
		if body.is_in_group("player"):
			var player = body as Player
			if player:
				player.hurt_player(attack_dmg, global_position)
				print("Enemy hurt player.")


func _on_player_detector_body_entered(body: Node2D) -> void:
	pass
