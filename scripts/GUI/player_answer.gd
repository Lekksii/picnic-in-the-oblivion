extends Label
class_name PlayerAnswer 
var keys : Dictionary
var colors : Dictionary = {
	"orange" : "ee9d31",
	"gray" : "66625f"
}


func _on_mouse_entered():
	add_theme_color_override("font_color",colors["orange"])


func _on_mouse_exited():
	add_theme_color_override("font_color",colors["gray"])


func answer_pressed():
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_dialogue_replic_click"])
	GameManager.Gui.DialogueWindow._player_answer_clicked(keys)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				answer_pressed()
