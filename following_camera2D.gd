extends Camera2D
class_name FollowingCamera2D

@export var target : Node2D;
@export_enum("IMMEDIATE", "SMOOTH") var mode : int = 0;
@export var lerp_speed : float = 7;
@export var smooth_zooming : bool = true; ## Lerps to the targetted zoom
@export_range(-1, 1) var target_zoom : float = 0; ## 0 = no zoom, -1 = 100% less zoom (half size), 1 = 100% more zoom (double size)

var mover : SmoothMovement;
var current_zoom : Vector2 = Vector2.ONE;
var original_zoom : Vector2 = Vector2.ONE;

func _ready() -> void:
	if mode == 1:
		mover = SmoothMovement.init(self);
		mover.speed = lerp_speed;
		mover.rotation_on = false;
		mover.tilt_on = false;
	
	original_zoom = zoom;
	current_zoom = zoom;

func _process(delta: float) -> void:
	match mode:
		0:
			global_position = target.global_position;
		1:
			mover.global_target_position = target.global_position;
	
	# Handle zooming
	var target_zoom_value = original_zoom.x * (1 + target_zoom)
	
	if smooth_zooming:
		current_zoom = current_zoom.lerp(Vector2(target_zoom_value, target_zoom_value), lerp_speed * delta);
		zoom = current_zoom;
	else:
		zoom = Vector2(target_zoom_value, target_zoom_value);
		current_zoom = zoom;
