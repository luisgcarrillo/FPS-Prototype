extends Area3D

@onready var rocket = $"."
var explosion = preload("res://Scenes/explosion.tscn")
@onready var rocket_particles = $RocketParticles
@export var rocketSpeed = 50.0
# Called when the node enters the scene tree for the first time.
func _ready():
	rocket_particles.emitting = true
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	translate(Vector3.FORWARD * rocketSpeed * delta)

func _on_body_entered(body):
	var explosionInstance = explosion.instantiate()
	#explosionInstance.global_position = rocket.global_position
	#explosionInstance.global_transform = rocket.global_transform
	get_parent().add_child(explosionInstance)
	explosionInstance.global_transform = rocket.global_transform
	#var rocketInstance = rocket.instantiate()
	#rocketInstance.position = rocket_ray.global_position
	queue_free()
	#var rocketInstance = rocket.instantiate()
					#get_parent().add_child(rocketInstance)
					#rocketInstance.global_transform = rocket_point.global_transform
