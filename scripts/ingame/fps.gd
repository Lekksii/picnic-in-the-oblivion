extends Label

func _ready():
	text = ""

func _process(_delta):
	if GameManager.show_fps:
		text = str(Engine.get_frames_per_second())
	else:
		if not text.is_empty():
			text = ""
