extends Node3D



func _input(event):
	if Input.is_action_just_pressed("Reset"):
		get_tree().reload_current_scene()
	#	Engine.time_scale = 1
# Called every frame. 'delta' is the elapsed time since the previous frame.


func _on_out_of_bounds_body_entered(body):
	get_tree().reload_current_scene()

