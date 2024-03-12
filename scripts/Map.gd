extends ColorRect
class_name Map 
@export var map_node : Control
@export var hint : Label
@export var h_line : Control
@export var v_line : Control
@export var player_spot : Control
var marker_template = preload("res://engine_objects/marker.tscn")
var is_open_from_pause : bool = false
var is_marker_clicked = false
var is_on_point = false
var clicked_marker = null

var markers = []

func _ready():
	pass
	#await get_tree().create_timer(1).timeout
	#SetPlayerSpot(231,663)
	#AddMarker("village_marker")
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func AddMarker(id):
	#print("Start marker adding")
	for m in markers:
		if m.id == id:
			return
			
	if GameManager.map_json:
		#print("Found map.json")
		if id in GameManager.map_json:
			#print("Found %s" % id)
			var new_marker = marker_template.instantiate() as Marker
			map_node.add_child(new_marker)
			map_node.move_child(new_marker,0)
			new_marker.name = "%s_%s" % [id,str(new_marker.get_instance_id())]
			new_marker.id = id
			new_marker.keys = GameManager.map_json[id]
			new_marker._owner = self
			new_marker.texture = Utility.load_external_texture("assets/ui/pda/%s" % new_marker.keys["spot"])
			new_marker.set_position(Vector2(new_marker.keys["position"][0],new_marker.keys["position"][1]))
			markers.append(new_marker)
		map_node.move_child(h_line,0)
		map_node.move_child(v_line,0)
		map_node.move_child(player_spot,0)
			#print("Marker created %s" % new_marker)
		#else:
			#print("[MAP]: Некорректне ID маркеру!\n[MAP]: Incorrect marker ID")
	
func GetAllMarkersIDs():
	var _list = []
	for m in markers:
		_list.append(m.id)
	return _list
	
func WipeAllMarkers():
	for m in markers:
		m.queue_free()
	await get_tree().process_frame
	markers.clear()
	
func _process(delta):
	if is_marker_clicked:
		#print(player_spot.position)
		var destination = clicked_marker.position
		if not player_spot.position.is_equal_approx(destination):
			player_spot.show()
			player_spot.position = player_spot.position.move_toward(destination,delta*70)
		else:
			is_marker_clicked = false
			player_spot.hide()
			#clicked_marker = null
			is_on_point = true

func SetPlayerSpot(x,y):
	player_spot.position = Vector2(x,y)
	
func SetPlayerSpotbyLevelId(id:String):
	#print("Player's spot is on %s" % str(player_spot.position))
	#print("Search for marker with level ID: %s" % id)
	if markers.size() > 0:
		for m in markers:
			if m.keys["level_id"] == id:
				#print("Found marker with level ID [%s]" % m.keys["level_id"])
				SetPlayerSpot(m.position.x,m.position.y)
				#print("Now player's spot is on %s" % str(player_spot.position))
	else:
		for map in GameManager.map_json:
			if GameManager.map_json[map]["level_id"] == id:
				SetPlayerSpot(GameManager.map_json[map]["position"][0],GameManager.map_json[map]["position"][1])
				break

func DeleteMarker(id):
	for marker in markers:
		if id == marker.id:
			markers.erase(marker)
			marker.queue_free()
			break
			
func GetMarker(id):
	for marker in markers:
		if id == marker.id:
			return marker
			
func Open():
	#print("MAP is opened! Is opened from pause: %s" % is_open_from_pause)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	self.show()
	
# Close inventory func
func Close():
	if is_marker_clicked:
		return 
		
	if is_open_from_pause == false:
		if not GameManager.Gui.death_screen.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		GameManager.pause = false
		self.hide()
	else:
		self.hide()
		is_open_from_pause = false
		
		GameManager.Gui.PauseWindow.show()
	if GameManager.level_is_safe:
		GameManager.SaveGame()
# Check if inventory is opened
func IsOpened():
	if self.visible:
		return true
	else:
		return false


func _on_back_pressed():
	if IsOpened():
		await get_tree().process_frame
		Close()
