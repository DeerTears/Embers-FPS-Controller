class_name Player
extends KinematicBody

"""
Written by Emberlynn Bland, April 25th 2022.

This KinematicBody uses RayShape to move itself up and down slopes. The camera is
interpolated behind the real body's Y position, making movement appear smooth.

The CylinderShape prevents the player from ascending up walls that are too tall, and gives a cylinder
collider for horizontal interactions. This can be adjusted as needed.

Input Map should include actions for left, right, forward, back, look_up, look_down, look_left, and
look_right.
"""

enum {
	MOUSE_X,
	MOUSE_Y,
	JOY_X,
	JOY_Y,
}

const GRAVITY := Vector3(0.0, -32.0, 0.0)

export (float, 0.0, 20.0, 0.01) var mouse_look_sensitivity = 0.2
export (float, 0.0, 20.0, 0.01) var joy_look_sensitivity = 0.5

export (float, 0.0, 64.0, 0.1) var speed := 8.0
export (float, 0.0, 64.0, 0.1) var horizontal_acceleration := 24.0

# If false, physics and head smoothing will continue to run, but no new inputs will be accepted.
var can_handle_input: bool = true

# Private variables. Keep any access of these variables inside this script.
var _movement := Vector3()
var _direction := Vector3()
var _horizontal_velocity := Vector3()

# Accessed once per frame to invert the camera rotation: Mouse X/Y, Joy X/Y.
var _camera_invert_multipliers := [1.0, 1.0, 1.0, 1.0]

# The actual position for the Camera to reach.
onready var camera_target_position: Position3D = $CameraTargetPosition
# The current position for the Camera, slightly delayed, and set as toplevel.
onready var head_camera: Camera = $HeadCamera


func _ready() -> void:
	head_camera.set_as_toplevel(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if not can_handle_input:
		return
	if event is InputEventMouseMotion:
		# Rotate the body using mouse x movement.
		rotate_y(
			deg2rad(
				(-event.relative.x * mouse_look_sensitivity) * _camera_invert_multipliers[MOUSE_X]
			)
		)
		# Rotate the head using mouse y movement.
		camera_target_position.rotate_x(
			deg2rad(
				(-event.relative.y * mouse_look_sensitivity) * _camera_invert_multipliers[MOUSE_Y]
			)
		)
		camera_target_position.rotation.x = clamp(
			camera_target_position.rotation.x,
			deg2rad(-90),
			deg2rad(90)
		)

func _physics_process(delta):
	_direction = Vector3()
	# Update the x and z of the Camera's target to the Camera directly.
	head_camera.global_transform.basis = camera_target_position.global_transform.basis
	head_camera.global_transform.origin.x = camera_target_position.global_transform.origin.x
	head_camera.global_transform.origin.z = camera_target_position.global_transform.origin.z
	# Lerp the Camera's  y.
	head_camera.global_transform.origin.y = (
		lerp(
			head_camera.global_transform.origin.y,
			camera_target_position.global_transform.origin.y,
			delta * get_smooth_factor()
		)
	)
	if can_handle_input:
		_direction += transform.basis.z * (Input.get_action_strength("back") - Input.get_action_strength("forward"))
		_direction += transform.basis.x * (Input.get_action_strength("right") - Input.get_action_strength("left"))
		process_controller_look()
	# Smooths out horizontal movement.
	_horizontal_velocity = _horizontal_velocity.linear_interpolate(
		_direction * speed,
		horizontal_acceleration * delta
	)
	_movement = _horizontal_velocity + GRAVITY
	move_and_slide(_movement, Vector3.UP, true, 3, 0.01, true)

## Rotates HeadCamera directly based on controller input.
func process_controller_look() -> void:
	var joy_head_horizontal_movement: float = 0.0
	var joy_head_vertical_movement: float = 0.0
	joy_head_vertical_movement = (Input.get_action_strength("look_up") - Input.get_action_strength("look_down")) * _camera_invert_multipliers[JOY_Y]
	joy_head_horizontal_movement = (Input.get_action_strength("look_left") - Input.get_action_strength("look_right"))  * _camera_invert_multipliers[JOY_X]
	camera_target_position.rotate_x(deg2rad(joy_head_vertical_movement * joy_look_sensitivity * 3))
	rotate_y(deg2rad(joy_head_horizontal_movement * joy_look_sensitivity * 3))
	camera_target_position.rotation.x = clamp(camera_target_position.rotation.x, deg2rad(-90), deg2rad(90))

# Returns a value for lerping the camera's y position.
func get_smooth_factor() -> float:
	var current := head_camera.global_transform.origin.y
	var target := camera_target_position.global_transform.origin.y
	# 9.50 seems to be the sweet spot for default speed settings. Add a sprint multiplier to account
	# for a sprinting state. Smoothing should be faster if the player is moving faster.
	var smooth_factor: float = 9.50 + (current - target)
	# We should prevent the player from moving too far upward, this checks if the y distance is at
	# least 4 units in one physics calculation.
	if current < target and current - target < -4:
		# Bug: There is no way to intercept the physics simulation. The best I can do is a warning.
		# The ideal solution is to find out this huge jump in the physics process, not here.
		print_debug("Huge step upwards: %s" % [global_transform.origin])
	return smooth_factor
