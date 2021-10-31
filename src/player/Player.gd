extends KinematicBody

var velocity: Vector3 = Vector3.ZERO

var is_alive: bool = true
var has_won: bool = false

var is_dashing: bool = false
var is_wall_running: bool = false

var can_dash: bool = false
var can_wall_run: bool = false

var wallrun_started_once: bool = false

export var gravity: float = -25.0

export var max_speed: float = 9.0
export var acceleration: float = 90.0
export var friction: float = 100.0
export var jump_height: float = 10.5
export var max_gravity_drag: float = 18.0
export var dash_factor: int = 25

var max_jump_count: int = 2
var jump_count: int = 0

var dash_direction: Vector3 = Vector3.ZERO
var wall_normal: Vector3 = Vector3.ZERO

export var mouse_sensitivity: Vector2 = Vector2(0.0025, 0.0025)
export var right_stick_sensitivity: Vector2 = Vector2(0.07, 0.035)

var min_vertical_camera_rotation: float = -50.0
var max_vertical_camera_rotation: float = 50.0
var camera_x_rotation: float = 0.0

var rotation_interpolation = 10.0

var origin_basis = Basis()
var orientation = Transform()

var snap_vector: Vector3 = Vector3.ZERO

var count = 0

onready var mesh = $Mesh

onready var camera_root = $CameraRoot
onready var camera_pivot = $CameraRoot/CameraPivot
onready var camera = $CameraRoot/CameraPivot/CameraSpringArm/Camera
onready var animation_tree = $Mesh/AnimationTree

onready var wall_check_left = $Mesh/WallChecks/Left
onready var wall_check_right = $Mesh/WallChecks/Right
onready var wall_check_forward = $Mesh/WallChecks/Forward

onready var timer_wall_run = $WallRunTimer

onready var feathers_total_amount = $CanvasLayer/Control/Total
onready var feathers_count = $CanvasLayer/Control/Amount

onready var origin_parent = get_parent()

var pushed_dust: PackedScene = preload("res://src/particles/PushedDust.tscn")
onready var move_dust = $MoveDust

onready var ui_animation_player = $CanvasLayer/AnimationPlayer

func _ready() -> void:
	orientation = mesh.global_transform
	origin_basis = global_transform.basis
	
	feathers_total_amount.text = get_parent().get_node("Feathers").get_child_count() as String

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_root.rotate_y(event.relative.x * -mouse_sensitivity.x)
		camera_root.orthonormalize()
		camera_x_rotation = clamp(camera_x_rotation + event.relative.y * mouse_sensitivity.y, deg2rad(min_vertical_camera_rotation), deg2rad(max_vertical_camera_rotation))
		camera_pivot.rotation.x = -camera_x_rotation
	if event.is_action_pressed("reset"):
		assert(get_tree().reload_current_scene() == OK)

func _process(_delta: float) -> void:
	var camera_target: Vector2 = Vector2.ZERO
	camera_target = Vector2(
		Input.get_action_strength("camera_left") - Input.get_action_strength("camera_right"), 
		Input.get_action_strength("camera_down") - Input.get_action_strength("camera_up")
		)
	
	camera_root.rotate_y(camera_target.x * right_stick_sensitivity.x)
	camera_root.orthonormalize()
	camera_x_rotation = clamp(camera_x_rotation + camera_target.y * right_stick_sensitivity.y, deg2rad(min_vertical_camera_rotation), deg2rad(max_vertical_camera_rotation))
	camera_pivot.rotation.x = -camera_x_rotation
	
	

func _physics_process(delta: float) -> void:
	if is_alive:
		var input_vector = _get_input_vector()
		var move_direction = dash_direction if is_wall_running else _get_move_direction(input_vector)
		
		_update_snap_vector()
		
		apply_gravity(delta)
		
		apply_movement(move_direction, delta)
		
		if velocity.x == 0.0 && velocity.z == 0:
			move_dust.emitting = false
		else:
			if is_on_floor() || is_wall_running:
				move_dust.emitting = true
			else:
				move_dust.emitting = false
		
		if is_on_floor():
			jump_count = max_jump_count
			is_dashing = false
			is_wall_running = false
			can_dash = true
			wallrun_started_once = false
		
		if Input.is_action_just_pressed("jump") && jump_count > 0 && !is_wall_running:
			apply_jump()
		elif Input.is_action_just_released("jump") && velocity.y > jump_height / 2:
			velocity.y = jump_height / 2
		
		if Input.is_action_just_pressed("dash") && !is_on_floor() && can_dash:
			apply_dash(move_direction, delta)
			dash_direction = move_direction
			can_dash = false
		
		if is_on_wall() && !is_on_floor():
			can_wall_run = true
			if is_wall_running:
				jump_count = max_jump_count
		else:
			can_wall_run = false
		
		if can_wall_run:
			can_dash = true
			wall_normal = get_slide_collision(0).normal
			if Input.is_action_pressed("dash"):
				if timer_wall_run.is_stopped() && !wallrun_started_once:
					timer_wall_run.start()
					wallrun_started_once = true
				if !timer_wall_run.is_stopped():
					wall_check_left.enabled = true
					wall_check_right.enabled = true
					wall_check_forward.enabled = true
					apply_wall_run(delta)
				if Input.is_action_just_pressed("jump"):
					apply_wall_jump()
					wallrun_started_once = false
			else:
				is_wall_running = false
		else:
			wall_check_left.enabled = false
			wall_check_right.enabled = false
			wall_check_forward.enabled = false
			is_wall_running = false
		
		velocity = move_and_slide_with_snap(velocity, snap_vector, Vector3.UP, true)
		
	apply_animations()

func _get_input_vector() -> Vector3:
	var input_vector = Vector3.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.z = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return input_vector.normalized() if input_vector.length() > 1 else input_vector

func _get_move_direction(input_vector: Vector3) -> Vector3:
	var move_direction = (input_vector.x * camera_root.transform.basis.x) + (input_vector.z * camera_root.transform.basis.z)
	return move_direction

func _update_snap_vector() -> void:
	snap_vector = -get_floor_normal() if is_on_floor() else Vector3.DOWN

func apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, gravity, max_gravity_drag)

func apply_movement(move_direction: Vector3, delta: float) -> void:
	if move_direction != Vector3.ZERO:
		velocity.x = velocity.move_toward(move_direction * max_speed, acceleration * delta).x
		velocity.z = velocity.move_toward(move_direction * max_speed, acceleration * delta).z
		mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(move_direction.x, move_direction.z), 10 * delta)
	else:
		velocity.x = velocity.move_toward(Vector3.ZERO, friction * delta).x
		velocity.z = velocity.move_toward(Vector3.ZERO, friction * delta).z

func apply_jump() -> void:
	snap_vector = Vector3.ZERO
	jump_count -= 1
	velocity.y = jump_height
	
	var pushed_dust_instance = pushed_dust.instance()
	pushed_dust_instance.emitting = true
	add_child(pushed_dust_instance)

func apply_dash(move_direction: Vector3, delta: float) -> void:
	is_dashing = true
	velocity.x = velocity.move_toward(move_direction * max_speed * dash_factor, acceleration * dash_factor * delta).x
	velocity.z = velocity.move_toward(move_direction * max_speed * dash_factor, acceleration * dash_factor * delta).z
	velocity.y = velocity.move_toward(Vector3.ZERO, friction * dash_factor * delta).y
	var pushed_dust_instance = pushed_dust.instance()
	pushed_dust_instance.emitting = true
	add_child(pushed_dust_instance)
	yield(get_tree().create_timer(0.25), "timeout")
	velocity.x = velocity.move_toward(Vector3.ZERO, friction * dash_factor * delta).x
	velocity.z = velocity.move_toward(Vector3.ZERO, friction * dash_factor * delta).z
	is_dashing = false
	

func apply_wall_run(_delta: float) -> void:
	is_wall_running = true
	if wall_check_left.is_colliding() || wall_check_right.is_colliding():
		wall_check_forward.enabled = false
		velocity.y = 0.0
		velocity.x = sign(dash_direction.x) * max_speed
		velocity.z = sign(dash_direction.z) * max_speed
	if wall_check_forward.is_colliding():
		wall_check_left.enabled = false
		wall_check_right.enabled = false
		velocity.y = max_speed
		velocity.x = -wall_normal.x * max_speed
		velocity.z = -wall_normal.z * max_speed

func apply_wall_jump() -> void:
	is_wall_running = false
	velocity.y = jump_height * 0.5
	velocity.x = wall_normal.x * 30
	velocity.z = wall_normal.z * 30
	if round(wall_normal.x) != 0:
		dash_direction.x *= -1
	elif round(wall_normal.z) != 0:
		dash_direction.z *= -1
	jump_count -= 1

func apply_animations() -> void:
	if !is_alive && !has_won:
		animation_tree.set("parameters/location/current", 3)
	elif !is_alive && has_won:
		animation_tree.set("parameters/location/current", 0)
		animation_tree.set("parameters/ground_state/current", 0)
	else:
		if is_wall_running && Input.is_action_pressed("dash"):
			animation_tree.set("parameters/location/current", 2)
			animation_tree.set("parameters/TimeScale/scale", 2.0)
			if wall_check_left.is_colliding():
				animation_tree.set("parameters/wall/current", 0)
			if wall_check_right.is_colliding():
				animation_tree.set("parameters/wall/current", 1)
			if wall_check_forward.is_colliding():
				animation_tree.set("parameters/wall/current", 2)
		else:
			if !is_on_floor():
				animation_tree.set("parameters/location/current", 1)
				if velocity.y < 0:
					animation_tree.set("parameters/air_state/current", 1)
				elif velocity.y > 0 && !is_dashing:
					animation_tree.set("parameters/air_state/current", 0)
				if is_dashing:
					animation_tree.set("parameters/air_state/current", 2)
			else:
				animation_tree.set("parameters/location/current", 0)
				if velocity.x != 0 || velocity.z != 0:
					animation_tree.set("parameters/ground_state/current", 1)
					animation_tree.set("parameters/run_speed/scale", abs(velocity.length() / max_speed))
				else:
					animation_tree.set("parameters/ground_state/current", 0)
					animation_tree.set("parameters/run_speed/scale", 1.0)

func _on_WallRunTimer_timeout() -> void:
	timer_wall_run.stop()
	can_wall_run = false

func add_collectable() -> void:
	count += 1
	feathers_count.text = count as String

func die() -> void:
	is_alive = false
	yield(get_tree().create_timer(2.5), "timeout")
	assert(get_tree().reload_current_scene() == OK)

func win() -> void:
	has_won = true
	is_alive = false
	ui_animation_player.play("result")
	yield(ui_animation_player, "animation_finished")
	yield(get_tree().create_timer(2.5), "timeout")
	SceneChanger.change_scene("res://src/levels/TitleScreenStage.tscn", "Fade")
