extends Spatial

"""
Optional script to handle shooting physics bodies and toggling fullscreen.

This template does not include how to damage targets, just how to recognize them.

All player movement (the meat of this template) is on the KinematicBody child.
"""

onready var player_body: KinematicBody = $Body
onready var head_camera: Camera = $Body/HeadCamera
onready var cursor_ray: RayCast = $Body/HeadCamera/CursorRay
onready var shoot_ray: RayCast = $Body/HeadCamera/ShootRay

func _unhandled_input(event: InputEvent) -> void:
	if player_body.can_handle_input and event.is_action_pressed("shoot"):
		shoot()
	if event.is_action_released("toggle_fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen

## Pauses the player's ability to recieve inputs. Doesn't pause physics or the SceneTree.
func set_movement_input(_true: bool) -> void:
	player_body.can_handle_input = _true

func shoot() -> void:
	if shoot_ray.is_colliding():
		var body: PhysicsBody = shoot_ray.get_collider()
		if body is StaticBody:
			return # handle shooting the world
		else:
			print_debug(body) # handle shooting moving bodies
