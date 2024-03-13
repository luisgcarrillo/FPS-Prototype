extends Node3D

@onready var animation_player = $FPSRig/AnimationPlayer

signal WeaponChanged
signal UpdateAmmo
signal UpdateWeaponInventory

var CurrentWeapon = null
var WeaponInventory = []
var WeaponIndicator = 0
var NextWeapon : String
var WeaponList = {}

@export var _weapon_resources: Array[WeaponsResource]
@export var StartingWeapons: Array[String]

@onready var enemies = get_tree().get_nodes_in_group("Enemy")
@onready var players = get_tree().get_nodes_in_group("Player")

@onready var current_ammo_count = $"../../../CanvasLayer/VBoxContainer/HBoxContainer2/CurrentAmmoCount"
@onready var current_weapon = $"../../../CanvasLayer/VBoxContainer/HBoxContainer/CurrentWeapon"
@onready var weapon_inventory = $"../../../CanvasLayer/VBoxContainer/HBoxContainer3/WeaponInventory"
@onready var hit_ray = $"../HitRay"

@onready var melee_hit = $"../../../MeleeHit"
@onready var melee_stop = $"../../../MeleeStop"
@onready var melee_check = $FPSRig/MeleeCheck

@onready var rocket_point = $FPSRig/RocketPoint
@onready var crosshair = $"../../../CanvasLayer/Crosshair"
@onready var alt_fire_ammo_count = $"../../../CanvasLayer/VBoxContainer/HBoxContainer3/AltFireAmmoCount"
@onready var grenade_point = $FPSRig/GrenadePoint
@onready var shotgun_rays = $FPSRig/ShotgunRays

@export var shotgunSpreadX = 2.0
@export var shotgunSpreadY = 2.0

#var grenade = preload("res://Scenes/grenade.tscn")
@onready var machinegun_launcher_2 = $FPSRig/machinegunLauncher2

var pistolToggle = false
var altPistolToggle = false
var altPistolShootToggle = false

var rocket = preload("res://Scenes/rocket.tscn")
var altRocketLauncherToggle = false
var altRocketLauncherAnimToggle = false
#var pistolSlowTimeToggle = false

var decal = preload("res://Scenes/decal.tscn")

@onready var pistol_alt_fire_timer = $"../../../PistolAltFireTimer"
@onready var alt_fire_label = $"../../../CanvasLayer/VBoxContainer/HBoxContainer3/AltFireLabel"
@onready var camera_3d = $Player/CameraController/Camera3D

var hitByMelee = []
var slowGravity: float

enum {NULL, HITSCAN, PROJECTILE}

func _ready():
	Engine.time_scale = 1.0
	randomize()
	for i in shotgun_rays.get_children():
		i.target_position.x = randi_range(shotgunSpreadX, -shotgunSpreadX)
		i.target_position.y = randi_range(shotgunSpreadY, -shotgunSpreadY)
		
	Initialize(StartingWeapons)
	machinegun_launcher_2.visible = false
	
	if altRocketLauncherToggle:
		toggleRocketLauncherAnimations()
	
	pistolToggle = false 
	altPistolToggle = false
	altPistolShootToggle = false
	altRocketLauncherToggle = false

	melee_check.enabled = false
	
	Signals.connect("EnemyDied", ammoRefill)
	
func _process(delta):
	current_weapon.text = CurrentWeapon.WeaponName
	current_ammo_count.text = str(CurrentWeapon.CurrentAmmo) + " / " + str(CurrentWeapon.ReserveAmmo)

	if CurrentWeapon.WeaponName != "Rocket Launcher":
		alt_fire_label.text = CurrentWeapon.AltFireName + ":"
		alt_fire_ammo_count.text = str(CurrentWeapon.CurrentAltFireAmmo) + " / " + str(CurrentWeapon.MaxAltFireAmmo)
	elif CurrentWeapon.WeaponName == "Rocket Launcher":
		alt_fire_label.text = CurrentWeapon.AltFireName
		alt_fire_ammo_count.text = ""

	
	if hit_ray.is_colliding() and hit_ray.get_collider().has_method("getHit"):
		crosshair.set_self_modulate("#ca0600")
	else:
		crosshair.set_self_modulate("#ffffff")
	
	if altPistolToggle and CurrentWeapon.WeaponName == "Pistols":
		Engine.time_scale = .5
	else:
		Engine.time_scale = 1
	
	
	if melee_check.is_colliding():
		for i in melee_check.get_collision_count():
			if melee_check.get_collider(i).has_method("getHit"):
				melee_check.get_collider(i).getHit(CurrentWeapon.AltFireDamage, 500.0)
			else:
				pass


func _input(event):
	if event.is_action_pressed("WeaponUp"):
		WeaponIndicator = min(WeaponIndicator+1, WeaponInventory.size()-1)
		exit(WeaponInventory[WeaponIndicator])
	
	if event.is_action_pressed("WeaponDown"):
		WeaponIndicator = max(WeaponIndicator-1, 0)
		exit(WeaponInventory[WeaponIndicator])
	
	if event.is_action_pressed("Shoot"):
		shoot()
	
	if event.is_action_pressed("Reload"):
		reload()
	
	if event.is_action_pressed("AltFire"):
		altFire()

func Initialize(_starting_weapons: Array):
	for Weapons in _weapon_resources:
		WeaponList[Weapons.WeaponName] = Weapons
		Weapons.CurrentAmmo = Weapons.StartingAmmo
		Weapons.ReserveAmmo = Weapons.StartingReserveAmmo
		Weapons.CurrentAltFireAmmo = Weapons.StartingAltFireAmmo
		Weapons.ShootAnimation = Weapons.StartingShootAnimation
	for i in _starting_weapons:
		WeaponInventory.push_back(i)
		
	CurrentWeapon = WeaponList[WeaponInventory[0]]
	UpdateWeaponInventory.emit(WeaponInventory[0])
	change_weapon(CurrentWeapon.WeaponName)
	

func enter():
	#function for activating/equipping a weapon
	animation_player.play(CurrentWeapon.ActivateAnimation)
	emit_signal("WeaponChanged", CurrentWeapon.WeaponName)
	emit_signal("UpdateAmmo", [CurrentWeapon.CurrentAmmo, CurrentWeapon.ReserveAmmo])

func exit(_next_weapon: String):
	#unequipping a weapon
	if _next_weapon != CurrentWeapon.WeaponName:
		if animation_player.get_current_animation() != CurrentWeapon.DeactivateAnimation:
			animation_player.play(CurrentWeapon.DeactivateAnimation)
			NextWeapon = _next_weapon

func change_weapon(weapon_name: String):
	#changing weapons
	if CurrentWeapon.WeaponName == "Pistols" and altPistolToggle:
		altPistolToggle = false
		pistol_alt_fire_timer.stop()
	elif CurrentWeapon.WeaponName == "Rocket Launcher" and altRocketLauncherToggle:
		altRocketLauncherToggle = !altRocketLauncherToggle
		CurrentWeapon.ShootAnimation = CurrentWeapon.StartingShootAnimation
	CurrentWeapon = WeaponList[weapon_name]
	NextWeapon = ""
	enter()


func _on_animation_player_animation_finished(anim_name):
	if anim_name == CurrentWeapon.DeactivateAnimation:
		change_weapon(NextWeapon)
	if anim_name == CurrentWeapon.ShootAnimation and CurrentWeapon.Autofire:
		if Input.is_action_pressed("Shoot"):
			shoot()

func shoot():
	if CurrentWeapon.CurrentAmmo != 0:
		if !animation_player.is_playing():
			if CurrentWeapon.WeaponName == "Pistols":
				togglePistolAnimations()
			animation_player.play(CurrentWeapon.ShootAnimation)
			if CurrentWeapon.Type == HITSCAN:
				CurrentWeapon.CurrentAmmo -= 1
				emit_signal("UpdateAmmo", [CurrentWeapon.CurrentAmmo, CurrentWeapon.ReserveAmmo])
				if hit_ray.is_colliding() and hit_ray.get_collider().has_method("getHit"):
					if str(hit_ray.get_collider_shape()) == "2":
						hit_ray.get_collider().getHit(CurrentWeapon.Damage * 2.0, CurrentWeapon.KnockbackStrength)
					else:
						hit_ray.get_collider().getHit(CurrentWeapon.Damage, CurrentWeapon.KnockbackStrength)
				if hit_ray.is_colliding():
					var collNormal = hit_ray.get_collision_normal()
					var collPoint = hit_ray.get_collision_point()
					var bulletHole = decal.instantiate()
					hit_ray.get_collider().add_child(bulletHole)
					bulletHole.global_transform.origin = collPoint
					if collNormal == Vector3.DOWN:
						bulletHole.rotation_degrees.x = 90
					elif collNormal != Vector3.UP:
						bulletHole.look_at(collPoint - collNormal, Vector3(0,1,0))
			elif CurrentWeapon.Type == PROJECTILE:
				if CurrentWeapon.WeaponName == "Rocket Launcher" and !altRocketLauncherToggle:
					CurrentWeapon.CurrentAmmo -= 1
					emit_signal("UpdateAmmo", [CurrentWeapon.CurrentAmmo, CurrentWeapon.ReserveAmmo])
					var rocketInstance = rocket.instantiate()
					get_tree().get_root().add_child(rocketInstance)
					rocketInstance.global_transform = rocket_point.global_transform
				elif CurrentWeapon.WeaponName == "Rocket Launcher" and altRocketLauncherToggle:
					melee_hit.start()
					
	else:
		if !animation_player.is_playing():
			if CurrentWeapon.ReserveAmmo > 0:
				if CurrentWeapon.WeaponName == "Rocket Launcher" and altRocketLauncherToggle:
					if !animation_player.is_playing():
						animation_player.play(CurrentWeapon.ShootAnimation)
						melee_hit.start()
				else:
					reload()
			else:
				animation_player.play(CurrentWeapon.OutOfAmmoAnimation)

func reload():
	if CurrentWeapon.CurrentAmmo == CurrentWeapon.MagazineSize:
		return
	elif !animation_player.is_playing():
		if CurrentWeapon.ReserveAmmo != 0:
			animation_player.play(CurrentWeapon.ReloadAnimation)
			var ReloadAmount = min(CurrentWeapon.MagazineSize - CurrentWeapon.CurrentAmmo,CurrentWeapon.ReserveAmmo)
			CurrentWeapon.CurrentAmmo = CurrentWeapon.CurrentAmmo + ReloadAmount
			CurrentWeapon.ReserveAmmo = CurrentWeapon.ReserveAmmo - ReloadAmount
			
			emit_signal("UpdateAmmo", [CurrentWeapon.CurrentAmmo, CurrentWeapon.ReserveAmmo])
		else:
			if !animation_player.is_playing():
				animation_player.play(CurrentWeapon.OutOfAmmoAnimation)
			


func altFire():
	if CurrentWeapon.CurrentAltFireAmmo != 0:
		if !animation_player.is_playing():
			if CurrentWeapon.WeaponName == "Pistols":
				altPistolShootToggle = !altPistolShootToggle
				togglePistolAltFireAnimations()
				#togglePistolSlowTime()
			elif CurrentWeapon.WeaponName == "Assault Rifle":
				for i in shotgun_rays.get_children():
					if i.name == "StaticShotgunRay":
						pass
					else:
						i.target_position.x = randi_range(shotgunSpreadX, -shotgunSpreadX)
						i.target_position.y = randi_range(shotgunSpreadY, -shotgunSpreadY)
					if i.is_colliding():
						var collNormal = i.get_collision_normal()
						var collPoint = i.get_collision_point()
						var bulletHole = decal.instantiate()
						i.get_collider().add_child(bulletHole)
						bulletHole.global_transform.origin = collPoint
						if collNormal == Vector3.DOWN:
							bulletHole.rotation_degrees.x = 90
						elif collNormal != Vector3.UP:
							bulletHole.look_at(collPoint - collNormal, Vector3(0,1,0))
					if i.is_colliding() and i.get_collider().has_method("getHit"):
						if str(hit_ray.get_collider_shape()) == "2":
							i.get_collider().getHit(CurrentWeapon.AltFireDamage * 2.0, 300.0)
						else:
							i.get_collider().getHit(CurrentWeapon.AltFireDamage, 300.0)
				#var grenadeInstance = grenade.instantiate()
				#get_tree().get_root().add_child(grenadeInstance)
				#grenadeInstance.global_transform = grenade_point.global_transform
				CurrentWeapon.CurrentAltFireAmmo -= 1
				emit_signal("UpdateAmmo", [CurrentWeapon.CurrentAltFireAmmo, CurrentWeapon.MaxAltFireAmmo])
			elif CurrentWeapon.WeaponName  == "Rocket Launcher":
				toggleRocketLauncherAnimations()
			animation_player.play(CurrentWeapon.AltFireAnimation)
	else:
		if !animation_player.is_playing():
			animation_player.play(CurrentWeapon.OutOfAmmoAnimation)




func togglePistolAltFireAnimations():
	if altPistolToggle == false:
		pistol_alt_fire_timer.start()
		CurrentWeapon.AltFireAnimation = "Pistol AltfireActivate"
		CurrentWeapon.ReloadAnimation = "Pistol AltfireReload"
	elif altPistolToggle == true:
		pistol_alt_fire_timer.stop()
		CurrentWeapon.AltFireAnimation = "Pistol AltfireDeactivate"
		CurrentWeapon.ReloadAnimation = "Pistol Reload"
	altPistolToggle = !altPistolToggle

func togglePistolAnimations():
	if altPistolShootToggle == true:
		if pistolToggle == false:
			CurrentWeapon.ShootAnimation = "Pistol AltfireShootRight"
		elif pistolToggle == true:
			CurrentWeapon.ShootAnimation = "Pistol AltfireShootLeft"
	elif altPistolShootToggle == false:
		if pistolToggle == false:
			CurrentWeapon.ShootAnimation = "Pistol ShootRight"
		elif pistolToggle == true:
			CurrentWeapon.ShootAnimation = "Pistol ShootLeft"
	pistolToggle = !pistolToggle

func toggleRocketLauncherAnimations():
	if altRocketLauncherToggle == false:
		CurrentWeapon.AltFireAnimation = "RocketLauncher AltfireActivate"
		CurrentWeapon.ShootAnimation = "RocketLauncher AltFire"
	elif altRocketLauncherToggle == true:
		CurrentWeapon.AltFireAnimation = "RocketLauncher AltfireDeactivate"
		CurrentWeapon.ShootAnimation = "Rocketlauncher Shoot"
	altRocketLauncherToggle = !altRocketLauncherToggle
	

func _on_pistol_alt_fire_timer_timeout():
	if CurrentWeapon.WeaponName == "Pistols":
		CurrentWeapon.CurrentAltFireAmmo -= 1
		if CurrentWeapon.CurrentAltFireAmmo == 0:
			togglePistolAltFireAnimations()
			togglePistolAnimations()
			altPistolShootToggle = !altPistolShootToggle
			animation_player.queue(CurrentWeapon.AltFireAnimation)
			pistol_alt_fire_timer.stop()
	else:
		pass

func ammoRefill():
	for Weapons in _weapon_resources:
		if Weapons.WeaponName == CurrentWeapon.WeaponName:
			pass
		else:
			if Weapons.ReserveAmmo != Weapons.MaxAmmoAmount:
				Weapons.ReserveAmmo += Weapons.AmmoRefillAmount
			else:
				pass
			if  Weapons.CurrentAltFireAmmo != Weapons.MaxAltFireAmmo:
				Weapons.CurrentAltFireAmmo += Weapons.AltRefillAmount
			else:
				pass




func _on_melee_hit_timeout():
	melee_check.enabled = true
	melee_stop.start()
	
func meleeHit(array):
	for i in array:
		print(str(array[i]))
		#if array[i].has_method("getHit"):
			#array[i].getHit(CurrentWeapon.AltFireDamage, 500.0)
	#melee_check.get_collider(i).knockbackStrength = 1000

func _on_melee_stop_timeout():
	melee_check.enabled = false
