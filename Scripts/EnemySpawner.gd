extends Node3D

var enemy = preload("res://Scenes/enemy.tscn")
var spawnPoints = []
@onready var world = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in get_children():
		if i is Marker3D:
			spawnPoints.append(i)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_enemy_spawn_timer_timeout():
	var spawn = spawnPoints[randi() % spawnPoints.size()]
	var enemyInstance  = enemy.instantiate()
	enemyInstance.position = spawn.position
	if len(get_tree().get_nodes_in_group("Enemy")) <= 19:
		world.add_child(enemyInstance)
	else:
		pass
