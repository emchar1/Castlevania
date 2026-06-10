extends CharacterBody2D
class_name Player

# PROPERTIES

signal dead()

@export var attack_dmg = 1

@onready var sword = $Sword
@onready var sword_sprite = $Sword/SpriteSword
@onready var player_sprite = $SpritePlayer
@onready var animation_player = $AnimationPlayer
@onready var collision_stand = $CollisionStand
@onready var collision_crouch = $CollisionCrouch
@onready var camera = $Camera2D

const SPEED = 60.0
const ATTACK_DURATION = 0.4
const JUMP_VELOCITY = -250.0
const KNOCKBACK_VELOCITY = Vector2(50.0, -150.0)

var tween: Tween
var move_dir := Vector2.ZERO
var speed_multiplier := 1.0
var jump_multiplier := 1.0
var jump_velocity_x := 0.0

var allow_input := true
var is_jumping := false
var is_attacking := false
var is_crouching := false
var is_invincible := false
var is_hurt := false
var is_dead := false


# FUNCTIONS

func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	_process_gravity(delta)
	
	_move_player()
	_player_attack()
	move_and_slide()


func _process_gravity(delta: float):
	if not is_on_floor():
		velocity += get_gravity() * delta


# PLAYER RESET FUNCTIONS

func kill_player(delay: float):
	is_dead = true
	allow_input = false
	turn_on_invincibility(false)
	GameState.update_health(0)
	dead.emit()
	
	await get_tree().create_timer(delay).timeout

	set_process(false)
	set_physics_process(false)
	player_sprite.stop()
	sword_sprite.stop()
	animation_player.stop()


func kill_movement():
	velocity = Vector2.ZERO


# MOVEMENT FUNCTIONS

func _move_player():
	_get_movement_input()
	_process_movement()
	_process_crouching()
	_process_jumping()
	_process_animation()


func _get_movement_input():
	if not allow_input:
		move_dir = Vector2.ZERO
		return
	
	move_dir = Vector2(Input.get_axis("move_left", "move_right"), 0)


func _process_movement():
	if is_on_floor() and not is_crouching:
		velocity.x = move_dir.x * SPEED * speed_multiplier


func _process_crouching():
	is_crouching = (
		is_on_floor()
		and move_dir.x == 0
		and Input.is_action_pressed("move_down")
	)
		
	if is_crouching:
		sword.position.y = 8
		collision_crouch.disabled = false
		collision_stand.disabled = true
	else:
		sword.position.y = 0
		collision_crouch.disabled = true
		collision_stand.disabled = false


func _process_jumping():
	if is_on_floor():
		is_jumping = false
	
	if is_jumping:
		velocity.x = jump_velocity_x
		return
	
	if allow_input and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY * jump_multiplier
		jump_velocity_x = velocity.x
		is_jumping = true


func _process_animation():
	if is_dead:
		if player_sprite.animation != "die":
			player_sprite.play("die")
		return

	if is_hurt:
		player_sprite.play("hurt")
		return

	if is_attacking:
		animation_player.play("crouch_attack" if is_crouching else "attack")
		sword_sprite.play("attack")
		return
	
	if is_jumping:
		player_sprite.play("jump")
		return
	
	if move_dir.x == 0:
		player_sprite.play("crouch" if is_crouching else "idle")
	else:
		if is_on_floor():
			player_sprite.flip_h = move_dir.x > 0
			sword.scale.x = -1 if player_sprite.flip_h else 1
			player_sprite.play("crouch" if is_crouching else "run")


# ATTACK FUNCTIONS

func _player_attack():
	if is_attacking:
		return
		
	if allow_input and Input.is_action_just_pressed("attack"):
		var speed_multiplier_orig = speed_multiplier
		
		is_attacking = true
		speed_multiplier = 0.0
		AudioManager.play(AudioData.AudioKey.ATTACK_MISS)
		
		await get_tree().create_timer(ATTACK_DURATION).timeout
		
		speed_multiplier = speed_multiplier_orig
		is_attacking = false


func _on_sword_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		var enemy = body as Enemy
		
		if enemy:
			print("player hurt enemy!!!!")
			enemy.hurt_enemy(attack_dmg)


func hurt_player(dmg: int, enemy_pos: Vector2):
	if is_hurt or is_dead or is_invincible:
		return
	
	is_hurt = true
	allow_input = false
	turn_on_invincibility(true)
	GameState.update_health_by(-dmg)

	velocity = Vector2(
		(global_position - enemy_pos).normalized().x * KNOCKBACK_VELOCITY.x,
		KNOCKBACK_VELOCITY.y
	)

	if GameState.is_health_gone():
		kill_player(2.0)
		return
	
	await get_tree().create_timer(0.25).timeout
	allow_input = true
	is_hurt = false

	await get_tree().create_timer(0.75).timeout
	turn_on_invincibility(false)


func turn_on_invincibility(on: bool):
	is_invincible = on

	if tween:
		tween.kill()

	if on:
		tween = create_tween()

		for i in range(20):
			tween.tween_property(self, "modulate:a", 0.0, 0.05)
			tween.tween_property(self, "modulate:a", 1.0, 0.05)
	else:
		modulate.a = 1.0