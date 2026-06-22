extends CharacterBody2D
class_name Enemy

# PROPERTIES

enum Type {
	ZOMBIE, SKELETON, SKELETON2, FRANKENSTEIN, GREEN_SLIME, ORANGE_SLIME, BAT
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

# Collision boxes
@onready var collision_floor_s = $CollisionFloorS
@onready var collision_floor_m = $CollisionFloorM
@onready var collision_floor_l = $CollisionFloorL
@onready var collision_shape_s = $PlayerDetector/CollisionShapeS
@onready var collision_shape_m = $PlayerDetector/CollisionShapeM
@onready var collision_shape_l = $PlayerDetector/CollisionShapeL

var timer: Timer
var tween: Tween
var movement_type: Callable
var projectile_scene = preload("res://scenes/projectile.tscn")

var orig_speed = 50.0
var dir := 1.0
var score := 0
var pickup_chance: float
var pickup_items: Array[Pickup.Type]

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
	var gem = Pickup.Type.CURSE_GEM
	var heart = Pickup.Type.HEART
	var gold = Pickup.Type.GOLD
		
	match type:
		Type.ZOMBIE:
			sprite.play("zombie")
			speed = 50
			hp = 1
			attack_dmg = 1
			score = 10
			pickup_chance = 0.5
			pickup_items = [gem, heart, heart, heart]
			movement_type = _movement1
			_set_collisions(false, true, false)
		Type.SKELETON:
			sprite.play("skeleton")
			speed = 75
			hp = 2
			attack_dmg = 1
			score = 20
			pickup_chance = 0.75
			pickup_items = [gem, gem, gem, heart]
			movement_type = _movement1
			_set_collisions(false, true, false)
		Type.SKELETON2:
			sprite.play("skeleton2")
			speed = 60
			hp = 3
			attack_dmg = 1
			score = 30
			pickup_chance = 1.0
			pickup_items = [heart]
			movement_type = _movement2
			_set_collisions(false, true, false)
		Type.FRANKENSTEIN:
			sprite.play("frankenstein")
			speed = 30
			hp = 6
			attack_dmg = 2
			score = 100
			pickup_chance = 1.0
			pickup_items = [gold]
			movement_type = _movement1b
			sprite.offset.y = -16
			_set_collisions(false, false, true)
		Type.GREEN_SLIME:
			sprite.play("green_slime")
			speed = 12
			hp = 1
			attack_dmg = 1
			score = 5
			pickup_chance = 1.0
			pickup_items = [gem]
			movement_type = _movement1
			_set_collisions(true, false, false)
		Type.ORANGE_SLIME:
			sprite.play("orange_slime")
			speed = 20
			hp = 1
			attack_dmg = 1
			score = 25
			pickup_chance = 1.0
			pickup_items = [gem]
			movement_type = _movement1
			_set_collisions(true, false, false)
		Type.BAT:
			sprite.play("bat_idle")
			speed = 80
			hp = 1
			attack_dmg = 1
			score = 15
			pickup_chance = 1.0
			pickup_items = [gem]
			movement_type = _movement3
			_set_collisions(true, false, false)
	
	orig_speed = speed


func _set_collisions(small: bool, medium: bool, large: bool):
	collision_floor_s.visible = small
	collision_floor_s.disabled = not small
	collision_floor_m.visible = medium
	collision_floor_m.disabled = not medium
	collision_floor_l.visible = large
	collision_floor_l.disabled = not large
	
	collision_shape_s.visible = small
	collision_shape_s.disabled = not small
	collision_shape_m.visible = medium
	collision_shape_m.disabled = not medium
	collision_shape_l.visible = large
	collision_shape_l.disabled = not large


# DAMAGE FUNCTIONS

func hurt_enemy(dmg: int, attack_dir: float):
	hp -= dmg
	if hp <= 0:
		kill_enemy()
		return
	
	var stun_duration := 0.6
	var did_change_dir := false
	
	if type == Type.FRANKENSTEIN:
		speed = orig_speed * 2
		sprite.speed_scale = 2
		stun_duration = 1.2
		
		# Only change directions if attack frankenstein from behind.
		if attack_dir != dir:
			change_directions()
			did_change_dir = true
	else:
		speed = 0
	
	_reset_timers()
	_setup_timer(stun_duration, true)
	
	if not AudioManager.is_playing(AudioData.AudioKey.ATTACK_SWING):
		AudioManager.play(AudioData.AudioKey.ATTACK_SWING)
	elif not AudioManager.is_playing(AudioData.AudioKey.ATTACK_SWING2):
		AudioManager.play(AudioData.AudioKey.ATTACK_SWING2)
	
	tween = create_tween()
	for i in range(20):
		tween.tween_property(self, "modulate", Color.DEEP_PINK, 0.05)
		tween.tween_property(self, "modulate", Color.DARK_CYAN, 0.05)
	
	await timer.timeout
	
	if tween:
		tween.kill()
	
	if did_change_dir:
		change_directions()
	
	modulate = Color.WHITE
	speed = orig_speed
	sprite.speed_scale = 1


func kill_enemy():
	_reset_timers()
	_setup_timer(0.2, true)
	
	modulate = Color.BLACK
	speed = 0
	velocity = Vector2.ZERO
	player_detector.monitoring = false
	sprite.stop()
	
	GameState.add_score(score)
	
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


func _movement1b(delta: float):
	_movement1(delta)
	
	if is_on_floor():
		if sprite.frame % 2 == 0:
			velocity.x = speed * dir
		else:
			velocity.x = 0


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
	
	var random_chance = randf_range(0, 1)
	if random_chance > pickup_chance:
		return
	
	var item = pickup_scene.instantiate()
	item.global_position = global_position
	get_tree().current_scene.add_child(item)
	
	var random_item = pickup_items.pick_random()
	if random_item != null:
		item.configure_pickup(random_item)


# SIGNAL FUNCTIONS

func _on_player_detector_body_entered(_body: Node2D) -> void:
	pass


func curse_activated(cursed: bool):
	speed = 0
	await get_tree().create_timer(2.0 if cursed else 1.0).timeout
	speed = orig_speed
