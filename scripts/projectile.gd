extends Area2D
class_name Projectile

# PROPERTIES

var tween: Tween
var attack_dmg := 1


# FUNCTIONS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func launch_at(target: Vector2):
	var speed := 0.5
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "position", target, speed)
	tween.parallel().tween_property(self, "rotation", 3 * PI, speed)
	
	await tween.finished
	
	remove_projectile(false)


func remove_projectile(did_hit: bool):
	if tween:
		tween.kill()
	
	var color = Color.DEEP_PINK if did_hit else Color.BLACK
	
	tween = create_tween()
	tween.tween_property(self, "modulate", color, 0.25)
	
	await tween.finished
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var player = body as Player
		if player:
			player.hurt_player(attack_dmg, global_position)
			
			if not (player.is_dead or player.is_hurt):
				remove_projectile(true)
