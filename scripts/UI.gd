extends Node

var game_font
@onready var GameUI = GameManager.Gui.GUI_GAME
@onready var debug_gui
@onready var Gui = GameManager.Gui

func _ready():
	pass

func reparent_obj_to(obj,to):
	obj.reparent(get_node("/root/Game/CanvasLayer/GUI/GAME/"+to))

func apply_anchors_preset(gui_obj : Control,preset : String):
	match preset:
		"top_left": gui_obj.set_anchors_preset(Control.PRESET_TOP_LEFT)
		"top_right": gui_obj.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		"top_wide": gui_obj.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		"full_screen": gui_obj.set_anchors_preset(Control.PRESET_FULL_RECT)
		"center": gui_obj.set_anchors_preset(Control.PRESET_CENTER)
		"center_bottom": gui_obj.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		"center_top": gui_obj.set_anchors_preset(Control.PRESET_CENTER_TOP)
		"center_left": gui_obj.set_anchors_preset(Control.PRESET_CENTER_LEFT)
		"center_right": gui_obj.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		"bottom_left": gui_obj.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		"bottom_right": gui_obj.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		"bottom_wide": gui_obj.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		"h_center_wide": gui_obj.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
		"v_center_wide": gui_obj.set_anchors_preset(Control.PRESET_VCENTER_WIDE)
		"left_wide": gui_obj.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		"right_wide": gui_obj.set_anchors_preset(Control.PRESET_RIGHT_WIDE)

# UI TEXT
func CreateLabel(text : String ="",pos : Vector2 =Vector2(0,0),size : Vector2=Vector2(128,32),color : Color =Color.WHITE,font : String ="regular",anchor : String="full_screen"):
	
	var label : Label = Label.new()
	apply_anchors_preset(label,anchor)
	label.position = pos
	label.set_deferred("size",size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = text
	label.name = "custom_mod_label"
	label.add_theme_color_override("font_color",color)
	match font:
		"regular": label.theme = load("res://themes/regular_font.tres")
		"bold": label.theme = load("res://themes/bold_font.tres")
	return label
	
	
# UI IMAGE
func CreateImage(path : String = "assets/null.png", pos : Vector2 = Vector2.ZERO, size : Vector2 = Vector2.ZERO, anchor : String = "full_screen"):
	var img : TextureRect = TextureRect.new()
	apply_anchors_preset(img,anchor)
	img.texture = Utility.load_external_texture(path)
	img.position = pos
	img.set_deferred("size",size)
	img.name = "custom_mod_img"
	return img

# UI BUTTON
func CreateButton(text : String = "button", press_function = func():print("pressed"), pos : Vector2 = Vector2.ZERO, size : Vector2 = Vector2.ZERO, anchor : String = "top_left"):
	var btn : Button = preload("res://engine_objects/custom_button.tscn").instantiate()
	apply_anchors_preset(btn,anchor)
	btn.position = pos
	btn.text = text
	btn.set_deferred("size",size)
	btn.name = "custom_mod_btn"
	btn.pressed.connect(press_function)
	return btn
