extends Spatial

"""
Additional script to handle interacting-with and shooting physics bodies.

This template does not include damaging targets or calling functions on interactive elements.
"""

onready var player_body: KinematicBody = $Body
onready var head_camera: Camera = $Body/HeadCamera
onready var cursor_ray: RayCast = $Body/HeadCamera/CursorRay
onready var shoot_ray: RayCast = $Body/HeadCamera/ShootRay

func _unhandled_input(event):
	# Requires "shoot" and "interact" setup in Project Settings -> Input Map.
	if event.is_action_pressed("interact"):
		_interact(true)
	if event.is_action_released("interact"):
		_interact(false)
	if player_body.can_handle_input and event.is_action_pressed("shoot"):
		_shoot()

## Can be called to pause recieving the player's inputs, without pausing physics or the SceneTree.
func set_movement_input(_true: bool) -> void:
	player_body.can_handle_input = _true

# Private functions. Simple games shouldn't need to access these in other scripts. Advanced games
# should move these functions into a new child node/script to handle more complex interactions.

func _interact(is_pressed: bool) -> void:
	if not cursor_ray.is_colliding():
		return
	var body = cursor_ray.get_collider()
	print_debug(body) # replace with code to handle interactable bodies

func _shoot() -> void:
	if shoot_ray.is_colliding():
		var body = shoot_ray.get_collider()
		if body is StaticBody:
			return # or process shooting the world here
		else:
			print_debug(body) # replace with code to handle shootable bodies
