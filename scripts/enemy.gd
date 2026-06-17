extends CharacterBody2D
class_name Enemy

# PROPERTIES

enum Type {
	ZOMBIE, SKELETON, SKELETON2, FRANKENSTEIN, SLIME, BAT
}

signal died
signal removed

const JUMP_FORCE = -300.0

@export var speed = 50.0
@export var hp = 1
@export var attack_dmg = 1
@export var type: Type
@export var pickup_scene: PackedScene

@onready var sprite = $AnimatedSprite2D
@onready var player_detector = $PlayerDetector
@onready var ground_ray = $FloorRayCast
@onready var player_ray = $PlayerRayCast
@onready var bat_ray = $BatRayCast

var timer: Timer
var tween: Tween
var movement_type: Callable
var projectile_scene = preload("res://scenes/projectile.tscn")

var orig_speed = 50.0
var dir := 1.0

var is_on_ground := false
var was_on_ground := false
var secondary_movement := false
var should_chase := false
var did_hit_floor := false


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
			movement_type = _movement1
		Type.SKELETON:
			sprite.play("skeleton")
			speed = 75
			hp = 2
			attack_dmg = 1
			movement_type = _movement1
		Type.SKELETON2:
			sprite.play("skeleton2")
			speed = 60
			hp = 3
			attack_dmg = 1
			movement_type = _movement2
		Type.FRANKENSTEIN:
			sprite.play("frankenstein")
			speed = 30
			hp = 4
			attack_dmg = 2
			movement_type = _movement1
		Type.SLIME:
			sprite.play("slime")
			speed = 10
			hp = 1
			attack_dmg = 1
			movement_type = _movement1
		Type.BAT:
			sprite.play("bat_idle")
			speed = 80
			hp = 1
			attack_dmg = 1
			movement_type = _movement3
	
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
	velocity = Vector2.ZERO
	player_detector.monitoring = false
	sprite.stop()
	
	if not AudioManager.is_playing(AudioData.AudioKey.ATTACK_KILL):
		AudioManager.play(AudioData.AudioKey.ATTACK_KILL)
	
	await timer.timeout
	
	spawn_pickup()

	died.emit()
	removed.emit()
	queue_free()


func flee():
	_reset_timers()
	speed = 0
	removed.emit()
	queue_free()


# MOVEMENT FUNCTIONS

func _handle_movement(delta: float):
	if movement_type:
		movement_type.call(delta)
	
	# Update positions
	ground_ray.target_position.x = abs(ground_ray.target_position.x) * dir
	player_ray.target_position.x = abs(player_ray.target_position.x) * dir
	bat_ray.target_position.x = abs(bat_ray.target_position.x) * dir
	sprite.flip_h = dir < 0


func _movement1(delta: float):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle movement
	if is_on_floor():
		velocity.x = speed * dir
	
	# Ground raycasting
	was_on_ground = is_on_ground
	is_on_ground = ground_ray.is_colliding()
	
	if was_on_ground and not is_on_ground:
		change_directions()


func _movement2(delta: float):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle movement
	if is_on_floor():
		velocity.x = speed * dir
	
	# Player raycasting
	if player_ray.is_colliding():
		_player_detection_secondary_movement()
	else:
		secondary_movement = false


func _movement3(delta: float):
	if should_chase:
		velocity.x = speed * dir
		
		if is_on_floor():
			did_hit_floor = true
		
		if did_hit_floor:
			velocity -= get_gravity() * delta * 0.05
		else:
			velocity += get_gravity() * delta * 0.25
	
	# Bat raycasting
	if bat_ray.is_colliding() and not should_chase:
		should_chase = true
		sprite.play("bat")


func _player_detection_secondary_movement():
	if secondary_movement:
		return
	
	secondary_movement = true
	
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


# MISC FUNCTIONS

func _handle_collisions():
	if player_detector.monitoring == false:
		return
	
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


# PICKUP ITEM FUNCTIONS

func spawn_pickup():
	if pickup_scene == null:
		return
	
	var item = pickup_scene.instantiate()
	item.global_position = global_position
	get_tree().current_scene.add_child(item)
	
	item.configure_pickup(randi_range(0, 1))


# SIGNAL FUNCTIONS

func _on_player_detector_body_entered(_body: Node2D) -> void:
	pass


func curse_activated(cursed: bool):
	speed = 0
	await get_tree().create_timer(2.0 if cursed else 1.0).timeout
	speed = orig_speed
