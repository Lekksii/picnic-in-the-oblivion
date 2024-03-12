extends Panel
class_name inv_parameter_bar

@onready var icon : TextureRect = $container/icon
@onready var container = $container
@onready var separator = $container/VSeparator
@onready var parameter_text : Label = $container/parameterText
@onready var parameter_text2 : Label = $container/parameterText2
@onready var parameter_bar : TextureProgressBar = $container/ParameterProgress

func AddIcon(icon_new,pos = 0):
	var new_icon = TextureRect.new()
	new_icon.name = "icon"+str(container.get_child_count())
	new_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	new_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	new_icon.texture = Utility.load_external_texture(icon_new)
	container.add_child(new_icon)
	container.move_child(new_icon,pos)

func AddSeparator(pos_index = 0):
	var new_sep = VSeparator.new()
	new_sep.add_theme_constant_override("separation", 5)
	new_sep.add_theme_stylebox_override("separator",StyleBoxEmpty.new())
	container.add_child(new_sep)
	container.move_child(new_sep,pos_index)
