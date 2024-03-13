extends RigidBody3D


@onready var explode_timer = $ExplodeTimer
@onready var grenade = $"."
var explosion = preload("res://Scenes/explosion.tscn")
@export var grenadeSpeed = 40.0
var gravity = 9.8
# Called when the node enters the scene tree for the first time.
func _ready():
	explode_timer.start()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	translate(Vector3.FORWARD * grenadeSpeed * delta)

func _on_body_entered(body):
	if body.is_in_group("Enemy"):
		var explosionInstance = explosion.instantiate()
		get_parent().add_child(explosionInstance)
		explosionInstance.global_transform = grenade.global_transform
		queue_free()

func _on_explode_timer_timeout():
	var explosionInstance = explosion.instantiate()
	get_parent().add_child(explosionInstance)
	explosionInstance.global_transform = grenade.global_transform
	queue_free()
