extends Node3D

var maxDistance: float
var trailMeshHeight: float
@export var bulletTrailSpeed = 100.0
#@onready var bullet_trail = $"."



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += transform.basis * Vector3.FORWARD * delta
	


func _on_timer_timeout():
	queue_free()
