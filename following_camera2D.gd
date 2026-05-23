extends Camera2D
class_name FollowingCamera2D

@export var target : Node2D;
@export_enum("IMMEDIATE", "SMOOTH") var mode : int = 0;
@export var lerp_speed : float = 7;
@export_range(0, 2) var zoom_near_target : float = 1; ## 1 = no zoom, 2 = zoom out, 0 = zoom in
@export var smooth_zooming : bool = true; ## Lerps to the targetted zoom

var mover : SmoothMovement;
var target_zoom : float;oo
var current_zoom : Vector2 = Vector2.ONE;

func _ready() -> void:
	target_zoom = zoom_near_target;
	current_zoom = zoom;
	
	if mode == 1:
		mover = SmoothMovement.init(self);
		mover.speed = lerp_speed;
		mover.rotation_on = false;
		mover.tilt_on = false;

func _process(delta: float) -> void:
	# Handle camera movement
	match mode:
		0:
			# Immediate mode
			if target:
				global_position = target.global_position;
		1:
			# Smooth mode
			if target and mover:
				mover.global_target_position = target.global_position;
	
	# Handle zooming
	_update_zoom(delta);

func _update_zoom(delta: float) -> void:
	if not target:
		return;
	
	# Calculate target zoom based on distance to target
	var distance_to_target = global_position.distance_to(target.global_position);
	var calculated_zoom = zoom_near_target;
	
	target_zoom = calculated_zoom;
	
	# Apply zoom
	if smooth_zooming:
		# Smooth zoom using lerp
		var target_zoom_vec = Vector2(target_zoom, target_zoom);
		current_zoom = current_zoom.lerp(target_zoom_vec, lerp_speed * delta);
		zoom = current_zoom;
	else:
		# Immediate zoom
		zoom = Vector2(target_zoom, target_zoom);
		current_zoom = zoom;

# Public API methods
func set_target(new_target: Node2D) -> void:
	## Change the camera's target
	target = new_target;
	if mover and mode == 1:
		mover.global_target_position = target.global_position;

func set_zoom_immediate(new_zoom: float) -> void:
	## Instantly set camera zoom
	zoom_near_target = clamp(new_zoom, 0, 2);
	zoom = Vector2(zoom_near_target, zoom_near_target);
	current_zoom = zoom;
	target_zoom = zoom_near_target;

func set_zoom_smooth(new_zoom: float) -> void:
	## Smoothly zoom to target value
	zoom_near_target = clamp(new_zoom, 0, 2);
	target_zoom = zoom_near_target;

func shake(intensity: float = 10.0, duration: float = 0.2) -> void:
	## Camera shake effect
	if not target:
		return;
	
	var shake_tween = create_tween();
	var original_offset = offset;
	var shake_intensity = intensity;
	
	# Simplified shake using tween property
	shake_tween.tween_property(self, "offset", 
		Vector2(randf_range(-shake_intensity, shake_intensity), 
		randf_range(-shake_intensity, shake_intensity)), duration * 0.1);
	
	for i in range(10):
		shake_tween.tween_property(self, "offset",
			Vector2(randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)), duration * 0.1);
	
	shake_tween.tween_property(self, "offset", original_offset, duration * 0.1);

func focus_on_point(point: Vector2, duration: float = 0.5) -> void:
	## Temporarily focus camera on a specific point
	if not target:
		return;
	
	var original_target = target;
	var original_mode = mode;
	var focus_tween = create_tween();
	
	# Switch to smooth mode temporarily
	mode = 1;
	
	# Create temporary mover if needed
	if not mover:
		mover = SmoothMovement.init(self);
		mover.speed = lerp_speed;
		mover.rotation_on = false;
		mover.tilt_on = false;
	
	# Store original position
	var original_position = global_position;
	
	# Animate to point
	focus_tween.tween_property(self, "global_position", point, duration);
	
	# Return to original target
	focus_tween.tween_callback(func():
		mode = original_mode;
		if mover and target:
			mover.global_target_position = target.global_position;
	);

func set_bounds(limit_left: int, limit_top: int, limit_right: int, limit_bottom: int) -> void:
	## Set camera movement boundaries
	limit_left = limit_left;
	limit_top = limit_top;
	limit_right = limit_right;
	limit_bottom = limit_bottom;

func center_on_target() -> void:
	## Instantly center camera on target
	if target:
		global_position = target.global_position;
		if mover and mode == 1:
			mover.global_target_position = target.global_position;