extends CharacterBody3D

@onready var enemy = $"."
@export var health = 5
@export var speed = 15.0
const JUMP_VELOCITY = -50.0
@onready var player = $"../Player"
@onready var animated_sprite_3d = $AnimatedSprite3D
@onready var navigation_agent_3d = $NavigationAgent3D
var isDead = false
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var direction

@onready var collision_shape_3d = $CollisionShape3D
@onready var headshot_collision = $HeadshotCollision

@onready var color_change_timer = $ColorChangeTimer

@onready var despawn_timer = $DespawnTimer
@onready var dead_collision = $DeadCollision




var knockback = Vector3.ZERO
@export var knockbackStrength = 0.0

func _ready():
	collision_shape_3d.disabled = false
	setAliveCollision()
	isDead = false
	health = 5

func _process(delta):
	if health <= 0:
		die()
		
func _physics_process(delta):
	
	#if !navigation_agent_3d.is_target_reachable():
	if not is_on_floor():
		velocity.y -= (gravity * 50) * delta

	navigation_agent_3d.set_target_position(player.global_transform.origin)
	var nextNavPoint = navigation_agent_3d.get_next_path_position()
	#direction = nextNavPoint - global_transform.origin
	if !isDead:
		velocity = (nextNavPoint - global_transform.origin).normalized() * speed + knockback	
	else:
		velocity = lerp(velocity, Vector3.ZERO, 0.1)
	move_and_slide()
	knockback =  lerp(knockback, Vector3.ZERO, 0.1)

#func handleAnimation():
	#if !isDead:
		#animated_sprite_3d.play("idle")
	#else:
		#animated_sprite_3d.play("die")

func jump():
	velocity.y -= 100

func handleKnockback(knockbackStrength):
	var knockbackDirection = -global_position.direction_to(player.global_position)
	var knockbackForce = knockbackDirection * knockbackStrength
	knockback = knockbackForce

func getHit(value, knockbackStrength):
	handleKnockback(knockbackStrength)
	health -= value
	
	#animated_sprite_3d.set_self_modulate("#ff0d0d")
	#color_change_timer.start()
	
	

func die():
	if !isDead:
		Signals.EnemyDied.emit()
		animated_sprite_3d.play("die")
		setDeadCollision()
		isDead = true
		collision_shape_3d.disabled = true
		dead_collision.disabled = false
		despawn_timer.start()


func _on_color_change_timer_timeout():
	pass
	#animated_sprite_3d.set_self_modulate("#ffffff")


func setAliveCollision():
	enemy.set_collision_layer_value(3, true)
	enemy.set_collision_layer_value(7, false)
	
	enemy.set_collision_mask_value(1, true)
	enemy.set_collision_mask_value(2, true)
	enemy.set_collision_mask_value(3, true)
	enemy.set_collision_mask_value(5, true)
	enemy.set_collision_mask_value(6, true)
	headshot_collision.disabled = false
func setDeadCollision():
	enemy.set_collision_layer_value(3, false)
	enemy.set_collision_layer_value(7, true)
	
	enemy.set_collision_mask_value(2, false)
	enemy.set_collision_mask_value(3, false)
	enemy.set_collision_mask_value(5, false)
	enemy.set_collision_mask_value(6, false)
	headshot_collision.disabled = true
func _on_despawn_timer_timeout():
	queue_free()
