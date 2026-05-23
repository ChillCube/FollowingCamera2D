extends Camera2D
class_name FollowingCamera2D

@export var targets : Array[Node2D] = []
@export_enum("IMMEDIATE", "SMOOTH") var mode : int = 0
@export var lerp_speed : float = 7
@export var smooth_zooming : bool = true
@export_range(-1, 1) var target_zoom : float = 0
@export var zoom_to_fit : bool = true  ## Zoom out to keep all targets in view
@export var multi_target_margin : float = 100.0  ## World-unit padding when fitting multiple targets
@export var min_zoom : float = 0.1  ## Minimum zoom level when fitting multiple targets

var mover : SmoothMovement
var current_zoom : Vector2 = Vector2.ONE
var original_zoom : Vector2 = Vector2.ONE

func _ready() -> void:
	if mode == 1:
		mover = SmoothMovement.init(self)
		mover.speed = lerp_speed
		mover.rotation_on = false
		mover.tilt_on = false

	original_zoom = zoom
	current_zoom = zoom

func _process(delta: float) -> void:
	var active := _get_active_targets()
	if active.is_empty():
		return

	var center := _get_center(active)
	var target_zoom_value : float

	if zoom_to_fit and active.size() > 1:
		target_zoom_value = _get_fit_zoom(active)
	else:
		target_zoom_value = original_zoom.x * (1.0 + target_zoom)

	match mode:
		0:
			global_position = center
		1:
			mover.global_target_position = center

	if smooth_zooming:
		current_zoom = current_zoom.lerp(Vector2(target_zoom_value, target_zoom_value), lerp_speed * delta)
		zoom = current_zoom
	else:
		zoom = Vector2(target_zoom_value, target_zoom_value)
		current_zoom = zoom

func _get_active_targets() -> Array[Node2D]:
	if not targets.is_empty():
		var valid : Array[Node2D] = []
		for t in targets:
			if is_instance_valid(t):
				valid.append(t)
		return valid
	return []

func _get_center(active : Array[Node2D]) -> Vector2:
	var sum := Vector2.ZERO
	for t in active:
		sum += t.global_position
	return sum / active.size()

func _get_fit_zoom(active : Array[Node2D]) -> float:
	# Find min and max positions
	var min_x = active[0].global_position.x
	var max_x = active[0].global_position.x
	var min_y = active[0].global_position.y
	var max_y = active[0].global_position.y
	
	for t in active:
		min_x = min(min_x, t.global_position.x)
		max_x = max(max_x, t.global_position.x)
		min_y = min(min_y, t.global_position.y)
		max_y = max(max_y, t.global_position.y)
	
	var bbox_width = max_x - min_x
	var bbox_height = max_y - min_y
	
	# Add margin
	bbox_width += multi_target_margin * 2
	bbox_height += multi_target_margin * 2
	
	var viewport_size = get_viewport_rect().size
	
	# Calculate zoom needed to fit width and height
	var zoom_x = viewport_size.x / bbox_width if bbox_width > 0 else INF
	var zoom_y = viewport_size.y / bbox_height if bbox_height > 0 else INF
	
	# Use the smaller zoom to ensure both dimensions fit
	var fit_zoom = min(zoom_x, zoom_y)
	
	# Clamp to min_zoom and don't exceed original zoom (don't zoom in, only out)
	return clamp(fit_zoom, min_zoom, original_zoom.x)
