extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	set_disable_scale(1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_timer_timeout():
	queue_free()
