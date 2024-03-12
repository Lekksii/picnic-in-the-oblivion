extends Control
class_name UI_TEXT
var text_id : String
@export var blink = false
@export var blink_speed : float = 0.5
@export var uppercase_text : bool = false
@export var lowercase_text : bool = false
@export var show_anim_icon: bool = true

var timer_blink = blink_speed

func _enter_tree():
	text_id = self.text
	#print(text_id)

# Called when the node enters the scene tree for the first time.
func _ready():
	if has_node("AnimIcon"):
		self.connect("mouse_entered",_on_mouse_entered)
		self.connect("mouse_exited", _on_mouse_exited)
		
	self.text = Lang.translate(text_id)	
	
	if uppercase_text:
		self.text = self.text.to_upper()
		
	if lowercase_text:
		self.text = self.text.to_lower()
		
func UpdateLanguage():
	if not text_id.is_empty():
		self.text = Lang.translate(text_id)
	
func _process(delta):
	if blink:
		timer_blink -= delta
		if timer_blink <= 0:
			timer_blink = blink_speed
			self.visible = !self.visible

func SetIconAnimation(state : bool):
	if state:
		if has_node("AnimIcon"):
			var a : AnimatedSprite2D = get_node("AnimIcon") as AnimatedSprite2D
			a.show()
			a.play("default")
	else:
		if has_node("AnimIcon"):
			var a : AnimatedSprite2D = get_node("AnimIcon") as AnimatedSprite2D
			a.hide()
			a.stop()

func _on_mouse_entered():
	if show_anim_icon:
		SetIconAnimation(true)
	else:
		add_theme_color_override("font_color",Color("66625f"))

func _on_mouse_exited():
	if show_anim_icon:
		SetIconAnimation(false)
	else:
		add_theme_color_override("font_color",Color("ee9d31"))
