extends Node3D

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
@onready var player = $"../../../.."

@onready var current_weapon = $"../../../../CanvasLayer/VBoxContainer/HBoxContainer/CurrentWeapon"
@onready var current_ammo_count = $"../../../../CanvasLayer/VBoxContainer/HBoxContainer2/CurrentAmmoCount"
@onready var alt_fire_ammo_count = $"../../../../CanvasLayer/VBoxContainer/HBoxContainer3/AltFireAmmoCount"
@onready var alt_fire_label = $"../../../../CanvasLayer/VBoxContainer/HBoxContainer3/AltFireLabel"
@onready var crosshair = $"../../../../CanvasLayer/Crosshair"

@onready var melee_hit = $"../../../../MeleeHit"
@onready var melee_stop = $"../../../../MeleeStop"
@onready var melee_check = $FPSRig/rocketlauncherModern2/MeleeCheck
@onready var melee_hitbox = $FPSRig/rocketlauncherModern2/MeleeCheck/MeleeHitbox

@export var shotgunSpreadX = 2.0
@export var shotgunSpreadY = 2.0

@onready var camera_controller = $"../../.."
@onready var camera_recoil = $"../.."
@onready var camera_3d = $".."

@onready var weapons_manager = $"."
@onready var fps_rig = $FPSRig
@onready var pistol_2 = $FPSRig/pistol2
@onready var pistol_3 = $FPSRig/pistol3
@onready var rocketlauncher_modern_2 = $FPSRig/rocketlauncherModern2
@onready var machinegun_launcher_2 = $FPSRig/machinegunLauncher2
@onready var animation_player = $FPSRig/AnimationPlayer
@onready var rocket_point = $FPSRig/RocketPoint
@onready var grenade_point = $FPSRig/GrenadePoint
@onready var shotgun_rays = $FPSRig/ShotgunRays
@onready var l_pistol_barrel = $FPSRig/LPistolBarrel
@onready var r_pistol_barrel = $FPSRig/RPistolBarrel
@onready var ar_barrel = $FPSRig/ARBarrel
@onready var hit_ray = $"../HitRay"
@onready var hit_ray_end = $"../HitRayEnd"

@onready var above_head_detector = $"../../../../AboveHeadDetector"
@onready var left_side_check = $"../../../../LeftSideCheck"
@onready var right_side_check = $"../../../../RightSideCheck"

#var grenade = preload("res://Scenes/grenade.tscn")
#@onready var machinegun_launcher_2 = $FPSRig/machinegunLauncher2

var pistolToggle = false
var altPistolToggle = false
var altPistolShootToggle = false
var uziADSToggle = false

var rocket = preload("res://Scenes/rocket.tscn")
var altRocketLauncherToggle = false
var altRocketLauncherAnimToggle = false

var decal = preload("res://Scenes/decal.tscn")
#var bulletTrail = preload("res://Scenes/bullettrail.tscn")
var bulletTrailInstance
@onready var uzi_reload_timer = $UziReloadTimer
@onready var pistol_alt_fire_timer = $"../../../../PistolAltFireTimer"

var hitByMelee = []
var slowGravity: float

var rocketMeleeSFX = 0

enum {NULL, HITSCAN, PROJECTILE}

func _ready():
	#make sure game is in real-time in case of reset while in slow-mo
	Engine.time_scale = 1.0
	#randomize for shotgun rays
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
	uziADSToggle = false

	Signals.connect("EnemyDied", ammoRefill)
	
func _process(delta):
	
	current_weapon.text = CurrentWeapon.WeaponName
	current_ammo_count.text = str(CurrentWeapon.CurrentAmmo) + " / " + str(CurrentWeapon.ReserveAmmo)

	if CurrentWeapon.AltFireHasAmmo:
		alt_fire_label.text = CurrentWeapon.AltFireName + ":"
		alt_fire_ammo_count.text = str(CurrentWeapon.CurrentAltFireAmmo) + " / " + str(CurrentWeapon.MaxAltFireAmmo) + " " + CurrentWeapon.AltFireAmmoType
	else:
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
	elif CurrentWeapon.WeaponName == "Uzi" and uziADSToggle:
		uziADSToggle = false
		Signals.StopAimDownSights.emit()
		#camera_3d.fov = 75.0
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
				SoundPlayer.play_sound(SoundPlayer.pistolShot)
				togglePistolAnimations()
				camera_recoil.recoil = Vector3(.2,.1,0)
				camera_recoil.aimRecoil = Vector3(.1,.05,0)
				camera_recoil.returnSpeed = 20
				if altPistolShootToggle:
					camera_recoil.recoilFire(true)
				else:
					camera_recoil.recoilFire()
				
			elif CurrentWeapon.WeaponName == "Assault Rifle":
				SoundPlayer.play_sound(SoundPlayer.arShot)
				camera_recoil.recoil = Vector3(.4,.4,0)
				camera_recoil.returnSpeed = 30
				camera_recoil.recoilFire()
			if CurrentWeapon.WeaponName == "Uzi":
				SoundPlayer.play_sound(SoundPlayer.uziShot)
				camera_recoil.recoil = Vector3(.2,.1,0)
				camera_recoil.aimRecoil = Vector3(.1,.05,0)
				camera_recoil.returnSpeed = 20
				if uziADSToggle:
					camera_recoil.recoilFire(true)
				else:
					camera_recoil.recoilFire()
				
			animation_player.play(CurrentWeapon.ShootAnimation)
			if CurrentWeapon.Type == HITSCAN:
				CurrentWeapon.CurrentAmmo -= 1
				emit_signal("UpdateAmmo", [CurrentWeapon.CurrentAmmo, CurrentWeapon.ReserveAmmo])
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
					if hit_ray.is_colliding() and hit_ray.get_collider().has_method("getHit"):
						if str(hit_ray.get_collider_shape()) == "2":
							hit_ray.get_collider().getHit(CurrentWeapon.Damage * 2.0, CurrentWeapon.KnockbackStrength)
						else:
							hit_ray.get_collider().getHit(CurrentWeapon.Damage, CurrentWeapon.KnockbackStrength)
			elif CurrentWeapon.Type == PROJECTILE:
				if CurrentWeapon.WeaponName == "Rocket Launcher" and !altRocketLauncherToggle:
					camera_recoil.recoil = Vector3(5.0,1.0,0)
					camera_recoil.recoilFire()
					CurrentWeapon.CurrentAmmo -= 1
					emit_signal("UpdateAmmo", [CurrentWeapon.CurrentAmmo, CurrentWeapon.ReserveAmmo])
					SoundPlayer.play_sound(SoundPlayer.rocketShot)
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
				SoundPlayer.play_sound(SoundPlayer.outOfAmmo)
				animation_player.play(CurrentWeapon.OutOfAmmoAnimation)

func reload():
	if CurrentWeapon.CurrentAmmo == CurrentWeapon.MagazineSize:
		return
	elif !animation_player.is_playing():
		if CurrentWeapon.ReserveAmmo != 0:
			if CurrentWeapon.WeaponName == "Uzi":
				handleUziADSReload()
			if CurrentWeapon.WeaponName == "Rocket Launcher" and altRocketLauncherToggle:
				toggleRocketLauncherAnimations()
				
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
				camera_recoil.recoil = Vector3(4.0,1.0,0)
				camera_recoil.recoilFire()
				camera_recoil.returnSpeed = 30
				SoundPlayer.play_sound(SoundPlayer.shotgunShot)
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
						#var collNormal = i.get_collision_normal()
						#var collPoint = i.get_collision_point()
						#var bulletHole = decal.instantiate()
						#i.get_collider().add_child(bulletHole)
						#bulletHole.global_transform.origin = collPoint
						#if collNormal == Vector3.DOWN:
							#bulletHole.rotation_degrees.x = 90
						#elif collNormal != Vector3.UP:
							#bulletHole.look_at(collPoint - collNormal, Vector3(0,1,0))
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
			elif CurrentWeapon.WeaponName  == "Uzi":
				toggleUziAnimations()
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
	#if pistolToggle == false:
		#CurrentWeapon.BarrelNode = "CameraController/Camera3D/WeaponsManager/FPSRig/pistol2/RPistolBarrel"
	#elif pistolToggle == true:
		#CurrentWeapon.BarrelNode =  "CameraController/Camera3D/WeaponsManager/FPSRig/pistol3/LPistolBarrel"
	pistolToggle = !pistolToggle

func toggleRocketLauncherAnimations():
	if altRocketLauncherToggle == false:
		CurrentWeapon.AltFireAnimation = "RocketLauncher AltfireActivate"
		CurrentWeapon.ShootAnimation = "RocketLauncher AltFire"
	elif altRocketLauncherToggle == true:
		CurrentWeapon.AltFireAnimation = "RocketLauncher AltfireDeactivate"
		CurrentWeapon.ShootAnimation = "Rocketlauncher Shoot"
	altRocketLauncherToggle = !altRocketLauncherToggle

func toggleUziAnimations():
	if uziADSToggle == false:
		CurrentWeapon.AltFireAnimation = "Uzi AltFire"
		CurrentWeapon.ShootAnimation = "Uzi AltFire Shoot"
		Signals.AimDownSights.emit()
	elif uziADSToggle == true:
		Signals.StopAimDownSights.emit()
		CurrentWeapon.AltFireAnimation = "Uzi AltFireDeactivate"
		CurrentWeapon.ShootAnimation = "Uzi Shoot"
	uziADSToggle = !uziADSToggle

#handle FOV when reloading Uzi while aiming down sights
func handleUziADSReload():
	if !uziADSToggle:
		CurrentWeapon.ReloadAnimation = "Uzi Reload"
		
	elif uziADSToggle:
		CurrentWeapon.ReloadAnimation = "Uzi ADSReload"
		
	
#Function for decreasing altFire ammo for pistols
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

#Handle melee attacks
func _on_melee_hit_timeout():
	melee_hitbox.monitoring = true
	melee_stop.start()

func _on_melee_stop_timeout():
	melee_hitbox.monitoring = false

func _on_melee_hitbox_body_entered(body):
	if body.has_method("getHit"):
		body.getHit(CurrentWeapon.AltFireDamage, 1000.0)
		if rocketMeleeSFX == 0:
			SoundPlayer.play_sound(SoundPlayer.batHit1)
			rocketMeleeSFX = 1
		elif rocketMeleeSFX == 1:
			SoundPlayer.play_sound(SoundPlayer.batHit2)
			rocketMeleeSFX = 0

#func _on_uzi_reload_timer_timeout():
	#camera_3d.fov = lerp(camera_3d.fov, 30.0,.1)
