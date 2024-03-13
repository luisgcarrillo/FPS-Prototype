extends Area3D

@onready var sparks = $Sparks
@onready var flash = $Flash
@onready var fire = $Fire
@onready var smoke = $Smoke
@onready var splash_damage = $SplashDamage
@onready var explosion = $"."
@onready var explosion_collision = $ExplosionCollision
@onready var splash_collision = $SplashDamage/SplashCollision
@onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	sparks.emitting = true
	flash.emitting = true
	fire.emitting = true
	smoke.emitting = true
	timer.start()

func dealDamage(value):
	var enemies = get_overlapping_bodies()
	for body in enemies:
		if body.has_method("getHit"):
			body.getHit(value, 500.0)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass





func _on_body_entered(body):
	if body.is_in_group("Enemy"):
		dealDamage(50)


func _on_splash_damage_body_entered(body):
	pass # Replace with function body.


func _on_timer_timeout():
	queue_free()
