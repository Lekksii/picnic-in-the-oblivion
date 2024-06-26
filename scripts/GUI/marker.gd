class_name Marker extends TextureRect

var id : String
var keys : Dictionary
var _owner: Map


func _on_mouse_entered():
	if _owner is Map:
		# BOTTOM LEFT AREA
		if position.x < 264 and position.y >= 700:
			_owner.hint.set_position(Vector2(164,676))
			_owner.hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		else:
			_owner.hint.set_position(Vector2(20,676))
			_owner.hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			
		_owner.hint.text = Lang.translate(keys["name"])
		_owner.h_line.set_position(Vector2(_owner.h_line.position.x,position.y+21))
		_owner.v_line.set_position(Vector2(position.x+21,_owner.v_line.position.y))
		_owner.h_line.show()
		_owner.v_line.show()

func _on_mouse_exited():
	if _owner is Map:
		_owner.hint.text = ""
		_owner.h_line.hide()
		_owner.v_line.hide()
		_owner.h_line.set_position(Vector2(0,0))
		_owner.v_line.set_position(Vector2(0,0))
	
func _process(delta):
	if _owner.is_on_point:
		var active_markers = 0
		var camp_markers = 0
		for m in _owner.markers:
			if m.keys["type"] == "quest":
				active_markers += 1
			if m.keys["type"] == "camp":
				camp_markers += 1
		if _owner.clicked_marker.keys["type"] == "camp":
			if active_markers > 0:
				GameManager.Gui.pda_icon.show()
				GameManager.ShowPDA(true)
			else:
				GameManager.Gui.pda_icon.hide()
				
			if camp_markers > 1:
				GameManager.ShowPDA(true)
				GameManager.Gui.pda_icon.hide()
				
		if _owner.clicked_marker.keys["type"] == "quest":
			GameManager.ShowPDA(false)
		
		_owner.SetPlayerSpot(_owner.clicked_marker.position.x,_owner.clicked_marker.position.y)
		_owner.hint.text = ""
		GameManager.LoadGameLevel(_owner.clicked_marker.keys["level_id"])
		_owner.is_on_point = false
		_owner.clicked_marker = null
		GameManager.Gui.MapWindow.Close()
		await get_tree().create_timer(0.1).timeout
		GameManager.Gui.PauseWindow.Close()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not _owner.clicked_marker:
			if GameManager.current_level_id != keys["level_id"]:
				GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_map_marker_click"])
				_owner.is_marker_clicked = true
				_owner.clicked_marker = self
			else:
				await get_tree().process_frame
				GameManager.player.can_use = false
				GameManager.pause = false
				GameManager.Gui.MapWindow.Close()
				await get_tree().create_timer(0.3).timeout
				GameManager.player.can_use = true
			#print("CLICKED ON MARKER [%s]" % id)
