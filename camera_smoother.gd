extends Camera3D

@export var follow_target : NodePath
var target: Node3D
var update = false
var get_prev : Transform3D
var get_current : Transform3D

# Called when the node enters the scene tree for the first time.
func _ready():
	set_as_top_level(true)
	target = get_node_or_null(follow_target)
	if target == null:
		target = get_parent()
	global_transform = target.global_transform

func update_transform():
	get_prev = get_current
	get_current = target.global_transform

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if update:
		update_transform()
		update = false
	var f = clamp(Engine.get_physics_interpolation_fraction(),0,1)
	global_transform = get_prev.interpolate_with(get_current,f)
	
func _physics_process(_delta):
	update = true
