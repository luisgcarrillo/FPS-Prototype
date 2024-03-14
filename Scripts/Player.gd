extends CharacterBody3D
@onready var player = $"."

#var bullet = load("res://Scenes/bullet.tscn")

@export var health = 5


@export_range(5, 10, 0.1) var crouchAnimSpeed : float = 7.0
@export var MOUSE_SENSITIVITY  = 0.5
var ORIGINAL_SENSITIVITY: float
@export var ADS_SLOWDOWN = .5
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Node3D
@export var animationPlayer : AnimationPlayer
@export var AboveHeadDetector : ShapeCast3D
var isCrouched = false
var isWallrunning = false
var isWallJumping = false
var wallrunDrop = false

@onready var left_side_check = $LeftSideCheck
@onready var right_side_check = $RightSideCheck
@onready var wallrun_timer = $WallrunTimer

@export_category("Movement")
@export var jumpPeakTime = .5
@export var jumpFallTime = .5
@export var jumpHeight = 2.0
@export var jumpDistance = 4.0
@export var speed = 20.0
@export var jumpVelocity = 7.0

@export var acceleration = 800
@export var friction = .85
@export var wallJumpHorizontal = 1.0
@export var wallJumpVertical = .5
@export var wallFriction = .8

# Get the gravity from the project settings to be synced with RigidBody nodes.
var jumpGravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var fallGravity = 5.0

var _mouse_input = false
var _mouse_rotation : Vector3
var _rotation_input : float
var _tilt_input : float
var _player_rotation : Vector3
var _camera_rotation : Vector3

@onready var current_weapon = $CanvasLayer/VBoxContainer/HBoxContainer/CurrentWeapon
@onready var current_ammo_count = $CanvasLayer/VBoxContainer/HBoxContainer2/CurrentAmmoCount
@onready var weapon_inventory = $CanvasLayer/VBoxContainer/HBoxContainer3/WeaponInventory
@onready var hit_ray = $CameraController/Camera3D/HitRay


var slowGravity: float
var originalFallGravity: float
var slowGravityToggle = false
var isDead = false

func _input(event):
	if isDead:
		return
	if event.is_action_pressed("Crouch"):
		toggle_crouch()


func _unhandled_input(event):
	#get mouse input
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY

func _update_camera(delta):
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)
	
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	global_transform.basis = Basis.from_euler(_player_rotation)
	CAMERA_CONTROLLER.rotation.z = 0.0
	
	_rotation_input = 0.0
	_tilt_input = 0.0

func _ready():
	ORIGINAL_SENSITIVITY = MOUSE_SENSITIVITY
	
	#calculate movement variables and gravity needed for slowmo
	calculateMovement()
	originalFallGravity = fallGravity
	slowGravity = fallGravity * .1
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	Signals.connect("AimDownSights", ADSSensitivity)
	Signals.connect("StopAimDownSights", originalSensitivity)

func _process(delta):
	#no input allowed if dead, not fully implemented yet
	if isDead:
		return

func _physics_process(delta):
	if isDead:
		return
	
	if Engine.time_scale == .5:
		fallGravity = slowGravity
	else:
		fallGravity = originalFallGravity
	
	if is_on_floor():
		isWallrunning = false
		isWallJumping = false
	
	if not is_on_floor():
		if velocity.y > 0:
			velocity.y -= jumpGravity * delta
		else:
			velocity.y -= fallGravity * delta
		
	_update_camera(delta)
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x += direction.x * acceleration * delta
		velocity.z += direction.z * acceleration * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jumpVelocity
	
	#if Input.is_action_just_pressed("Jump") and is_on_wall_only():
		#velocity.y = jumpVelocity
		#gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	
	#make player to wallrun, not fully implemented yet
	if is_on_wall_only() or (left_side_check.is_colliding() and !is_on_floor()) or(right_side_check.is_colliding() and !is_on_floor()):
		handle_wallrun(delta)
		isWallrunning = true
	else:
		isWallrunning = false
		
	handle_walljump(direction)
	move_and_slide()
	velocity.x *= friction
	velocity.z *= friction

func calculateMovement():
	jumpGravity = (2*jumpHeight)/pow(jumpPeakTime,2)
	fallGravity = (2*jumpHeight)/pow(jumpFallTime,2)
	jumpVelocity = jumpGravity * jumpPeakTime
	speed = jumpDistance/(jumpPeakTime+jumpFallTime)

func toggleGravity():
	#toggle gravity for slowmotion time and real time
	if !slowGravityToggle:
		fallGravity = slowGravity
	elif slowGravityToggle:
		fallGravity = fallGravity
	slowGravityToggle = !slowGravityToggle

func toggle_crouch():
	if isCrouched == true and !AboveHeadDetector.is_colliding() and is_on_floor():
		animationPlayer.play("Crouch", -1, -crouchAnimSpeed, true)
		speed = 20.0
	elif isCrouched == false and is_on_floor():
		animationPlayer.play("Crouch", -1, crouchAnimSpeed)
		speed = 8.0
	isCrouched = !isCrouched

func handle_wallrun(delta):
	if isWallrunning:
		velocity.y -= wallFriction * delta

func handle_walljump(direction):
	#var wallRunJumpDirection = Vector3.ZERO
	if Input.is_action_just_pressed("Jump") and isWallrunning:
		isWallrunning = false
		isWallJumping = true
		
		velocity.y = jumpVelocity * 1.1
		velocity = lerp(velocity, velocity + (get_wall_normal() * 100), 1.5)
		

		#if left_side_check.is_colliding() and !is_on_floor():
			#animationPlayer.play("LeftWallrun")
		#elif right_side_check.is_colliding() and !is_on_floor():
			#animationPlayer.play("RightWallrun")


func _on_wallrun_timer_timeout():
	wallrunDrop = true

#func slowDown():
	#pass
#
#func speedUp():
	#gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	#acceleration = 800


func ADSSensitivity():
	MOUSE_SENSITIVITY = MOUSE_SENSITIVITY * ADS_SLOWDOWN

func originalSensitivity():
	MOUSE_SENSITIVITY = ORIGINAL_SENSITIVITY



