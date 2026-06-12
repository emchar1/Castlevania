extends CharacterBody2D
class_name Player

# PROPERTIES

signal dead()

@export var attack_dmg = 1

# Player
@onready var sword = $Sword
@onready var sword_sprite = $Sword/SpriteSword
@onready var player_sprite = $SpritePlayer
@onready var animation_player = $AnimationPlayer
@onready var collision_stand = $CollisionStand
@onready var collision_crouch = $CollisionCrouch

# Werewolf
@onready var werewolf_sprite = $SpriteWerewolf
@onready var collision_ww_stand = $CollisionWWStand

@onready var camera = $Camera2D

const SPEED_HUMAN = 60.0
const SPEED_WEREWOLF = 90.0
const ATTACK_DURATION_HUMAN = 0.4
const ATTACK_DURATION_WEREWOLF = 0.4
const JUMP_VELOCITY_HUMAN = -250.0
const JUMP_VELOCITY_WEREWOLF = -300.0
const KNOCKBACK_VELOCITY_HUMAN = Vector2(50.0, -150.0)
const KNOCKBACK_VELOCITY_WEREWOLF = Vector2(0.0, 0.0)

var speed := 1.0
var attack_duration := 1.0
var jump_velocity := 1.0
var knockback_velocity := Vector2(100.0, -200.0)
var jump_velocity_x := 0.0

var tween: Tween
var move_dir := Vector2.ZERO
var allow_input := true
var is_jumping := false
var is_attacking := false
var is_crouching := false
var is_invincible := false
var is_hurt := false
var is_dead := false


# INIT FUNCTIONS

func _ready() -> void:
	# Order matters here! Connect first, then sync state.
	CurseManager.activated.connect(_on_curse_activated)
	_on_curse_activated(CurseManager.active)


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
		velocity.x = move_dir.x * speed


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
		velocity.y = jump_velocity
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


# ATTACK/HURT FUNCTIONS

func _player_attack():
	if is_attacking:
		return
		
	if allow_input and Input.is_action_just_pressed("attack"):
		var speed_orig = speed
		
		is_attacking = true
		speed = 0.0
		AudioManager.play(AudioData.AudioKey.ATTACK_MISS)
		
		await get_tree().create_timer(attack_duration).timeout
		
		speed = speed_orig
		is_attacking = false


func _on_sword_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		var enemy = body as Enemy
		
		if enemy:
			enemy.hurt_enemy(attack_dmg)


func hurt_player(dmg: int, enemy_pos: Vector2):
	if is_hurt or is_dead or is_invincible:
		return
	
	is_hurt = true
	allow_input = false
	turn_on_invincibility(true)
	GameState.update_health_by(-dmg)
	
	velocity = Vector2(
		(global_position - enemy_pos).normalized().x * knockback_velocity.x,
		knockback_velocity.y
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


# SIGNAL CALLBACK FUNCTIONS

func _on_curse_activated(cursed: bool):
	if cursed:
		speed = SPEED_WEREWOLF
		attack_duration = ATTACK_DURATION_WEREWOLF
		jump_velocity = JUMP_VELOCITY_WEREWOLF
		knockback_velocity = KNOCKBACK_VELOCITY_WEREWOLF

		sword.visible = false
		sword_sprite.visible = false
		player_sprite.visible = false
		collision_stand.disabled = true
		collision_crouch.disabled = true
		werewolf_sprite.visible = true
		collision_ww_stand.disabled = false
	else:
		speed = SPEED_HUMAN
		attack_duration = ATTACK_DURATION_HUMAN
		jump_velocity = JUMP_VELOCITY_HUMAN
		knockback_velocity = KNOCKBACK_VELOCITY_HUMAN

		sword.visible = true
		sword_sprite.visible = true
		player_sprite.visible = true
		collision_stand.disabled = false
		collision_crouch.disabled = false
		werewolf_sprite.visible = false
		collision_ww_stand.disabled = true