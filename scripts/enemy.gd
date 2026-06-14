extends CharacterBody2D
class_name Enemy

# PROPERTIES

enum Type {
	ZOMBIE, SKELETON, SKELETON2, FRANKENSTEIN, SLIME, BAT
}

signal died

const JUMP_FORCE = -300.0

@export var speed = 50.0
@export var hp = 1
@export var attack_dmg = 1
@export var type: Type

@onready var sprite = $AnimatedSprite2D
@onready var player_detector = $PlayerDetector
@onready var ground_ray = $FloorRayCast
@onready var player_ray = $PlayerRayCast

var timer: Timer
var tween: Tween
var projectile_scene = preload("res://scenes/projectile.tscn")

var orig_speed = 50.0
var dir := 1.0
var is_on_ground := false
var was_on_ground := false
var secondary_movement := false


# INIT FUNCTIONS

func _ready() -> void:
	CurseManager.activated.connect(curse_activated)


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_collisions()

	move_and_slide()


# CONFIG FUNCTIONS

func set_direction(player_pos: Vector2):
	dir = -1 if global_position > player_pos else 1


func change_directions():
	dir *= -1


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
		Type.SKELETON2:
			sprite.play("skeleton2")
			speed = 60
			hp = 3
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


# DAMAGE FUNCTIONS

func hurt_enemy(dmg: int):
	hp -= dmg
	if hp <= 0:
		kill_enemy()
		return
	
	_reset_timers()
	_setup_timer(0.6, true)

	speed = 0

	if not AudioManager.is_playing(AudioData.AudioKey.ATTACK_SWING):
		AudioManager.play(AudioData.AudioKey.ATTACK_SWING)

	tween = create_tween()
	for i in range(20):
		tween.tween_property(self, "modulate", Color.DEEP_PINK, 0.05)
		tween.tween_property(self, "modulate", Color.DARK_CYAN, 0.05)
	
	await timer.timeout
	
	if tween:
		tween.kill()
	
	modulate = Color.WHITE
	speed = orig_speed


func kill_enemy():
	_reset_timers()
	_setup_timer(0.2, true)

	modulate = Color.BLACK
	speed = 0
	sprite.stop()

	if not AudioManager.is_playing(AudioData.AudioKey.ATTACK_KILL):
		AudioManager.play(AudioData.AudioKey.ATTACK_KILL)
	
	await timer.timeout
	
	if not CurseManager.active:
		CurseManager.increment_curse()	
	
	died.emit()
	queue_free()


# HELPER FUNCTIONS

func _handle_movement(delta: float):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle movement
	if is_on_floor():
		velocity.x = speed * dir
	
	# Ground raycasting
	was_on_ground = is_on_ground
	is_on_ground = ground_ray.is_colliding()

	if was_on_ground and not is_on_ground and type != Type.SKELETON2:
		change_directions()

	# Player raycasting
	if player_ray.is_colliding():
		_player_detection_secondary_movement()
	else:
		secondary_movement = false

	# Update positions
	ground_ray.target_position.x = abs(ground_ray.target_position.x) * dir
	player_ray.target_position.x = abs(player_ray.target_position.x) * dir
	sprite.flip_h = dir < 0


func _player_detection_secondary_movement():
	if secondary_movement:
		return

	secondary_movement = true

	if type == Type.SKELETON2:
		if not is_on_floor():
			return

		var target = position + Vector2(randf_range(50.0, 100.0) * dir, 0.0)
		
		velocity.x = -speed * dir
		velocity.y = JUMP_FORCE
		
		await get_tree().create_timer(0.25).timeout
		
		var projectile = projectile_scene.instantiate()
		projectile.position = position
		get_parent().add_child(projectile)
		projectile.launch_at(target)


func _handle_collisions():
	var bodies = player_detector.get_overlapping_bodies()
	
	for body in bodies:
		if body.is_in_group("player"):
			var player = body as Player
			if player:
				player.hurt_player(attack_dmg, global_position)


func _reset_timers():
	if timer:
		timer.stop()
		timer.queue_free()
		timer = null
	
	if tween:
		tween.kill()
		tween = null


func _setup_timer(wait_time: float, one_shot: bool):
	timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = one_shot
	add_child(timer)
	timer.start()


# SIGNAL FUNCTIONS

func _on_player_detector_body_entered(_body: Node2D) -> void:
	pass


func curse_activated(cursed: bool):
	speed = 0

	await get_tree().create_timer(2.0 if cursed else 1.0).timeout

	speed = orig_speed