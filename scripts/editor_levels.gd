@tool
extends Node

@onready var World = $LEVEL
var app_dir = "res://"
@onready var outsky_color = $outsky
@onready var level_sky : MeshInstance3D
var editor_level_objects = []
var js = JSON.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint():
		editor_level_objects.clear()
	
		for children in World.get_children():
			children.queue_free()
			
		await get_tree().create_timer(0.1).timeout
		if World.get_child_count() == 0:
			load_level("svistun_collectors")
			
		for obj in editor_level_objects:
			#print("TOOL: "+obj.name)
			obj.set_owner(get_tree().edited_scene_root)
			
		#print("TOOL EDITOR: Level loaded!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func load_level(id):
	var level_path = app_dir+"assets/levels/"+id+"/"
	
	if DirAccess.dir_exists_absolute(level_path):
		var level_data = read_json("assets/levels/"+id+"/level.json")	
		outsky_color.get_material().albedo_color = Color(level_data["weather_color"])
		
		#if "rotation_range" in level_data:
			#player.rotation_range_y[0] = level_data["rotation_range"][0]
			#player.rotation_range_y[1] = level_data["rotation_range"][1]
		#ProjectSettings.set_setting("rendering/environment/defaults/default_clear_color")
		
		if "light" in level_data:
			for light in level_data["light"]:
				if light["type"] == "point":
					var color = []			
					color = light["color"]
					var l = add_point_light(Color(color[0]/255,color[1]/255,color[2]/255,255),light["distance"],light["shadows"],light["energy"],Vector3(light["position"][0],light["position"][1],light["position"][2]),Vector3(light["rotation"][0],light["rotation"][1],light["rotation"][2]))
					l.name = light["name"]
					
					editor_level_objects.append(l)
		for obj in level_data["level_data"]:
			if "uid" in obj and "id" not in obj:
				if obj["uid"] == "skybox":
					var sky_model : MeshInstance3D = load_model(obj["model"]+".obj","assets/textures/"+obj["texture"],Vector3(obj["position"][0],obj["position"][1],obj["position"][2]),Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2]),Vector3(obj["scale"][0],obj["scale"][1],obj["scale"][2]) if typeof(obj["scale"]) == TYPE_ARRAY else Vector3(obj["scale"],obj["scale"],obj["scale"]))
					sky_model.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					level_sky = sky_model
			if "id" in obj:
				if obj["id"] == "sprite3d":
					var sprite_3d = Sprite3D.new()
					sprite_3d.name = obj["name"] if "name" in obj else "game_object_"+str(sprite_3d.get_instance_id())
					sprite_3d.texture = load_external_texture("assets/textures/"+obj["texture"])
					sprite_3d.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
					sprite_3d.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					sprite_3d.position = Vector3(obj["position"][0],obj["position"][1],obj["position"][2])
					sprite_3d.rotation = Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2])
					sprite_3d.scale = Vector3(obj["scale"][0],obj["scale"][1],obj["scale"][2]) if typeof(obj["scale"]) == TYPE_ARRAY else Vector3(obj["scale"],obj["scale"],obj["scale"])
					sprite_3d.name = obj["name"] if "name" in obj else "sprite3d"
					World.add_child(sprite_3d)
					editor_level_objects.append(sprite_3d)
					
				#if obj["id"] == "spawn_point":
				#	player.position = Vector3(obj["position"][0],obj["position"][1],obj["position"][2])
				#	player.rotation_degrees = Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2])
				
				if obj["id"] == "animated3dsprite":
					var anim3dsprite : AnimatedSprite3D = preload("res://engine_objects/animated_sprite.tscn").instantiate()
					anim3dsprite.name = obj["name"] if "name" in obj else "game_object_"+str(anim3dsprite.get_instance_id())
					anim3dsprite.animation = obj["sequence"] if "sequence" in obj else "Default"
					anim3dsprite.play(obj["sequence"])
					anim3dsprite.pixel_size = 0.04
					anim3dsprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
					anim3dsprite.position = Vector3(obj["position"][0],obj["position"][1],obj["position"][2])
					anim3dsprite.rotation = Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2])
					anim3dsprite.scale = Vector3(obj["scale"][0],obj["scale"][1],obj["scale"][2]) if typeof(obj["scale"]) == TYPE_ARRAY else Vector3(obj["scale"],obj["scale"],obj["scale"])
					World.add_child(anim3dsprite)
					editor_level_objects.append(anim3dsprite)
				
				if obj["id"] == "spawn_point":
					var spawn_point = Sprite3D.new()
					spawn_point.name = "SpawnPoint"
					spawn_point.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					spawn_point.texture = load_external_texture("assets/ui/editor/spawn.pngs")
					spawn_point.position = Vector3(obj["position"][0],obj["position"][1],obj["position"][2])
					spawn_point.rotation_degrees = Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2])
					#player.ChangePosition(Vector3(obj["position"][0],obj["position"][1],obj["position"][2]))
					#player.ChangeRotation(Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2]))
					World.add_child(spawn_point)
					editor_level_objects.append(spawn_point)
						
				if obj["id"] == "radiation":
					var rad_trigger = preload("res://engine_objects/rad_trigger.tscn").instantiate()
					rad_trigger.name = obj["name"] if "name" in obj else "rad_trigger_"+str(rad_trigger.get_instance_id())
					rad_trigger.get_child(0).shape.size = Vector3(obj["size"][0],obj["size"][1],obj["size"][2])
					rad_trigger.position = Vector3(obj["position"][0],obj["position"][1],obj["position"][2])
					rad_trigger.rotation_degrees = Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2])
				#	if "scale" in obj:
				#		rad_trigger.scale = Vector3(obj["scale"][0],obj["scale"][1],obj["scale"][2]) if typeof(obj["scale"]) == TYPE_ARRAY else Vector3(obj["scale"],obj["scale"],obj["scale"])
					World.add_child(rad_trigger)
					editor_level_objects.append(rad_trigger)
				
				if obj["id"] == "loot_money":
					var lootmoney_obj : MeshInstance3D = MeshInstance3D.new()
					lootmoney_obj.name = obj["name"] if "name" in obj else "loot_money_obj"
					if obj["model"] == "cube":
						lootmoney_obj.mesh = BoxMesh.new()
						lootmoney_obj.material_override = StandardMaterial3D.new()
					lootmoney_obj.position = Vector3(obj["position"][0],obj["position"][1],obj["position"][2])
					lootmoney_obj.rotation = Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2])
					lootmoney_obj.scale = Vector3(obj["scale"][0],obj["scale"][1],obj["scale"][2]) if typeof(obj["scale"]) == TYPE_ARRAY else Vector3(obj["scale"],obj["scale"],obj["scale"])
					World.add_child(lootmoney_obj)
					editor_level_objects.append(lootmoney_obj)
					
			if "id" not in obj:
				var new_obj : MeshInstance3D = load_model(obj["model"]+".obj","assets/textures/"+obj["texture"],Vector3(obj["position"][0],obj["position"][1],obj["position"][2]),Vector3(obj["rotation"][0],obj["rotation"][1],obj["rotation"][2]),Vector3(obj["scale"][0],obj["scale"][1],obj["scale"][2]) if typeof(obj["scale"]) == TYPE_ARRAY else Vector3(obj["scale"],obj["scale"],obj["scale"]),false,true if "double_sided" in obj and obj["double_sided"] else false)
				new_obj.name = obj["name"] if "name" in obj else "game_object"
				if "collider" in obj:
					var sbody = StaticBody3D.new()
					sbody.name = "static_body"
					new_obj.add_child(sbody)
					if obj["collider"] == "mesh":
						var collider = CollisionShape3D.new()
						collider.shape = new_obj.mesh.create_trimesh_shape()
						collider.name = "collider_trimesh"
						sbody.add_child(collider)
				
				if "alpha" in obj and obj["alpha"]:
					new_obj.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					
				if "lit" in obj and obj["lit"]:
					new_obj.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					
				if "billboard" in obj and obj["billboard"]:
					new_obj.material_override.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
				editor_level_objects.append(new_obj)



# ---------------- UTILITY ----------------------
# Load Texture2D from extrenal path
func load_external_texture(path):
	if !FileAccess.file_exists(app_dir+path):
		BugTrap.Crash("File "+path+" doesn't exist!","File "+path+" doesn't exist!")
		return
	var tex_file = FileAccess.open(app_dir+path,FileAccess.READ)
	var buffer = tex_file.get_buffer(tex_file.get_length())
	var img = Image.new()
	img.load_png_from_buffer(buffer)
	var img_tex = ImageTexture.create_from_image(img)
	tex_file.close()
	return img_tex
	
func set_texture_to_object(texture,two_sided=false,emission=false):	
	var new_mat : StandardMaterial3D = StandardMaterial3D.new()
	
	new_mat.albedo_texture = load_external_texture(texture)
	
	if two_sided:
		new_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission:
		new_mat.emission_enabled = true
		new_mat.emission_texture = new_mat.albedo_texture
		
	#new_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	#new_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	#new_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	new_mat.metallic = 0
	new_mat.metallic_specular = 0
	new_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return new_mat
	
# Load *.obj model from file in assets/models/ folder
func load_model(path, texture="",position=Vector3(0,0,0),rotation=Vector3(0,0,0),scale=Vector3(0,0,0),emission=false,two_sided=false):
	if !FileAccess.file_exists(app_dir+path):
		BugTrap.Crash("File "+path+" doesn't exist!","File "+path+" doesn't exist!")
		return
	var mesh_file = load_obj(app_dir+path)
	var mesh = MeshInstance3D.new()
	var mat = set_texture_to_object(texture,two_sided,emission)
	
	mesh.mesh = mesh_file
	mesh.name = "model_"+str(mesh.get_instance_id())
	# DONT WORK, NEED TO FIX 14.04.23
	mesh.material_override = mat
	mesh.position = position
	mesh.rotation = rotation
	mesh.set_scale(scale)
	World.add_child(mesh)
	#World.set_owner(get_tree().edited_scene_root)
	return mesh
	
func add_point_light(color,l_range,shadows,energy,pos,rot):
	var light_point = OmniLight3D.new()
	light_point.omni_range = l_range
	light_point.shadow_enabled = shadows
	light_point.light_indirect_energy = energy
	light_point.light_color = color
	light_point.position = pos
	light_point.rotation = rot
	World.add_child(light_point)
	return light_point
	
# run code from string
func run_script(input):
	var script = GDScript.new()
	script.set_source_code("func eval():" + input)
	script.reload()

	#var obj = Reference.new()
	var obj = Node.new() #So we can call get_node
	obj.set_script(script)
	add_child(obj)
	var ret_val = obj.eval()
	remove_child(obj)

	return ret_val

# compare two values and return boolean
func compare_bool(a, b):
	if a == b:
		return true
	else:
		return false

# read json data from file
func read_json(json_data):
	if not FileAccess.file_exists(app_dir+json_data):
		BugTrap.Crash("File "+str(json_data)+" doesn't exist!","File "+str(json_data)+" doesn't exist!")
		return
		
	var target = FileAccess.get_file_as_string(app_dir+json_data)
	var parse_result = js.parse(target)
	if parse_result != OK:
		BugTrap.Crash("Error %s reading json file." % parse_result,"Error %s reading json file." % parse_result)
		return
	return js.data

# Save object data to json
func write_json(object,path):
	var target = FileAccess.open(path, FileAccess.WRITE)
	target.store_string(beautify_json(str(object)))
	target.close()
	
# beautify json to human read format
func beautify_json(json: String, spaces := 0) -> String:
	var indentation := ""
	if spaces > 0:
		for i in spaces:
			indentation += " "
	else:
		indentation = "\t"

	var quotation_start := -1
	var char_position := 0
	for i in json:
		# Workaround a Godot quirk, as it allows JSON strings to end with a
		# trailing comma.
		if i == "," and char_position + 1 == json.length():
			break
	
		# Avoid formating inside strings.
		if i == "\"":
			if quotation_start == -1:
				quotation_start = char_position
			elif json[char_position - 1] != "\\":
				quotation_start = -1

			char_position += 1

			continue
		elif quotation_start != -1:
			char_position += 1

			continue

		match i:
			# Remove pre-existing formatting.
			" ", "\n", "\t":
				json[char_position] = ""
				char_position -= 1
			"{", "[", ",":
				if json[char_position + 1] != "}" and\
						json[char_position + 1] != "]":
					json = json.insert(char_position + 1, "\n")
					char_position += 1
			"}", "]":
				if json[char_position - 1] != "{" and\
						json[char_position - 1] != "[":
					json = json.insert(char_position, "\n")
					char_position += 1
			":":
				json = json.insert(char_position + 1, " ")
				char_position += 1
		
		char_position += 1

	for i in [["{", "}"], ["[", "]"]]:
		var bracket_start: int = json.find(i[0])
		while bracket_start != -1:
			var bracket_end: int = json.find("\n", bracket_start)
			var bracket_count := 0
			while bracket_end != - 1:
				if json[bracket_end - 1] == i[0]:
					bracket_count += 1
				elif json[bracket_end + 1] == i[1]:
					bracket_count -= 1

				# Move through the indentation to see if there is a match.
				while json[bracket_end + 1] == indentation[0]:
					bracket_end += 1

					if json[bracket_end + 1] == i[1]:
						bracket_count -= 1

				if bracket_count <= 0:
					break

				bracket_end = json.find("\n", bracket_end + 1)

			# Skip one newline so the end bracket doesn't get indented.
			bracket_end = json.rfind("\n", json.rfind("\n", bracket_end) - 1)
			while bracket_end > bracket_start:
				json = json.insert(bracket_end + 1, indentation)
				bracket_end = json.rfind("\n", bracket_end - 1)

			bracket_start = json.find(i[0], bracket_start + 1)

	return json

# gd-obj
#
# Created on 7/11/2018
#
# Originally made by Ezcha
# Contributors: deakcor, kb173, jeffgamedev
#
# https://ezcha.net
# https://github.com/Ezcha/gd-obj
#
# MIT License
# https://github.com/Ezcha/gd-obj/blob/master/LICENSE
const debug: bool = false

# Create mesh from obj and mtl paths
func load_obj(obj_path: String, mtl_path: String = "") -> Mesh:
	var obj_str: String = _read_file_str(obj_path)
	if (mtl_path == ""):
		var mtl_filename: String = _get_mtl_filename(obj_str)
		mtl_path = "%s/%s" % [obj_path.get_base_dir(), mtl_filename]
	var mats: Dictionary = {}
	if (mtl_path != ""):
		mats = _create_mtl(_read_file_str(mtl_path), _get_mtl_tex(mtl_path))
	if (obj_str.is_empty()): return null
	return _create_obj(obj_str, mats)

# Create mesh from obj, materials. Materials should be { "matname": data }
func load_obj_from_buffer(obj_data: String, materials: Dictionary) -> Mesh:
	return _create_obj(obj_data,materials)

# Create materials
func load_mtl_from_buffer(mtl_data: String, textures: Dictionary) -> Dictionary:
	return _create_mtl(mtl_data,textures)
	
# Get data from file path
func _read_file_str(path: String) -> String:
	if (path == ""):
		return ""
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if (file == null):
		return ""
	return file.get_as_text()

# Internal functions

# Get textures from mtl path (returns { "tex_path": data })
func _get_mtl_tex(mtl_path: String) -> Dictionary:
	var file_paths: Array[String] = _get_mtl_tex_paths(mtl_path)
	var textures: Dictionary = {}
	for k in file_paths:
		textures[k] = _get_image(mtl_path, k).save_png_to_buffer()
	return textures

# Get textures paths from mtl path
func _get_mtl_tex_paths(mtl_path: String) -> Array[String]:
	var file: FileAccess = FileAccess.open(mtl_path, FileAccess.READ)
	if (file == null):
		return []
	
	var paths: Array[String] = []
	var lines: PackedStringArray = file.get_as_text().split("\n", false)
	for line in lines:
		var parts: PackedStringArray = line.split(" ", false, 1)
		if (["map_Kd", "map_Ks", "map_Ka"].has(parts[0])):
			if (!paths.has(parts[1])):
				paths.push_back(parts[1])
	return paths

func _get_mtl_filename(obj: String) -> String:
	var lines: PackedStringArray = obj.split("\n")
	for line in lines:
		var split: PackedStringArray = line.split(" ", false)
		if (split.size() < 2): continue
		if (split[0] != "mtllib"): continue
		return split[1].strip_edges()
	return ""

func _create_mtl(obj: String, textures: Dictionary) -> Dictionary:
	var mats: Dictionary = {}
	var currentMat: StandardMaterial3D = null

	var lines: PackedStringArray = obj.split("\n", false)
	for line in lines:
		var parts: PackedStringArray = line.split(" ", false)
		match parts[0]:
			"#":
				# Comment
				pass
			"newmtl":
				# Create a new material
				if debug:
					prints("Adding new material", parts[1])
				currentMat = StandardMaterial3D.new()
				mats[parts[1]] = currentMat
			"Ka":
				# Ambient color
				#currentMat.albedo_color = Color(float(parts[1]), float(parts[2]), float(parts[3]))
				pass
			"Kd":
				# Diffuse color
				currentMat.albedo_color = Color(parts[1].to_float(), parts[2].to_float(), parts[3].to_float())
				if debug:
					prints("Setting material color", str(currentMat.albedo_color))
				pass
			_:
				if parts[0] in ["map_Kd","map_Ks","map_Ka"]:
					var path: String = line.split(" ", false,1)[1]
					if textures.has(path):
						currentMat.albedo_texture = _create_texture(textures[path])
	return mats

func _parse_mtl_file(path) -> Dictionary:
	return _create_mtl(_read_file_str(path), _get_mtl_tex(path))

func _get_image(mtl_filepath: String, tex_filename: String) -> Image:
	if debug:
		prints("Debug: Mapping texture file", tex_filename)
	var tex_filepath: String = tex_filename
	if tex_filename.is_relative_path():
		tex_filepath = "%s/%s" % [mtl_filepath.get_base_dir(), tex_filename]
	var file_type: String = tex_filepath.get_extension()
	if debug:
		prints("Debug: texture file path:", tex_filepath, "of type", file_type)
	
	var img: Image = Image.new()
	img.load(tex_filepath)
	return img

func _create_texture(data: PackedByteArray) -> ImageTexture:
	var img: Image = Image.new()
	img.load_png_from_buffer(data)
	return ImageTexture.create_from_image(img)

func _get_texture(mtl_filepath, tex_filename) -> ImageTexture:
	var tex = ImageTexture.create_from_image(_get_image(mtl_filepath, tex_filename))
	if debug:
		prints("Debug: texture is", str(tex))
	return tex

func _create_obj(obj: String, mats: Dictionary) -> Mesh:
	# Setup
	var mesh: ArrayMesh = ArrayMesh.new()
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var faces: Dictionary = {}

	var mat_name: String = "default"
	var count_mtl: int =0
	
	# Parse
	var lines: PackedStringArray = obj.split("\n", false)
	for line in lines:
		var parts: PackedStringArray = line.split(" ", false)
		match parts[0]:
			"#":
				# Comment
				pass
			"v":
				# Vertice
				var n_v: Vector3 = Vector3(parts[1].to_float(), parts[2].to_float(), parts[3].to_float())
				vertices.append(n_v)
			"vn":
				# Normal
				var n_vn: Vector3 = Vector3(parts[1].to_float(), parts[2].to_float(), parts[3].to_float())
				normals.append(n_vn)
			"vt":
				# UV
				var n_uv: Vector2 = Vector2(parts[1].to_float(), 1 - parts[2].to_float())
				uvs.append(n_uv)
			"usemtl":
				# Material group
				count_mtl += 1
				mat_name = parts[1].strip_edges()
				if (!faces.has(mat_name)):
					var mats_keys: Array = mats.keys()
					if (!mats.has(mat_name)):
						if (mats_keys.size() > count_mtl):
							mat_name = mats_keys[count_mtl]
					faces[mat_name] = []
			"f":
				if (!faces.has(mat_name)):
					var mats_keys: Array = mats.keys()
					if (mats_keys.size() > count_mtl):
						mat_name = mats_keys[count_mtl]
					faces[mat_name] = []
				# Face
				if (parts.size() == 4):
					# Tri
					var face: Dictionary = { "v": [], "vt": [], "vn": [] }
					for map in parts:
						var vertices_index: PackedStringArray = map.split("/")
						if (vertices_index[0] != "f"):
							face["v"].append(vertices_index[0].to_int() - 1)
							face["vt"].append(vertices_index[1].to_int() - 1)
							if (vertices_index.size() > 2):
								face["vn"].append(vertices_index[2].to_int() - 1)
					if (faces.has(mat_name)):
						faces[mat_name].append(face)
				elif (parts.size() > 4):
					# Triangulate
					var points: Array[Array] = []
					for map in parts:
						var vertices_index: PackedStringArray = map.split("/")
						if (vertices_index[0] != "f"):
							var point: Array[int] = []
							point.append(vertices_index[0].to_int() - 1)
							point.append(vertices_index[1].to_int() - 1)
							if (vertices_index.size() > 2):
								point.append(vertices_index[2].to_int()-1)
							points.append(point)
					for i in (points.size()):
						if (i != 0):
							var face = { "v":[], "vt":[], "vn":[] }
							var point0: Array[int] = points[0]
							var point1: Array[int] = points[i]
							var point2: Array[int] = points[i-1]
							face["v"].append(point0[0])
							face["v"].append(point2[0])
							face["v"].append(point1[0])
							face["vt"].append(point0[1])
							face["vt"].append(point2[1])
							face["vt"].append(point1[1])
							if (point0.size() > 2):
								face["vn"].append(point0[2])
							if (point2.size() > 2):
								face["vn"].append(point2[2])
							if (point1.size() > 2):
								face["vn"].append(point1[2])
							faces[mat_name].append(face)
	
	# Make tri
	for matgroup in faces.keys():
		if debug:
			prints("Creating surface for matgroup", matgroup, "with", str(faces[matgroup].size()), "faces")
		
		# Mesh Assembler
		var st: SurfaceTool = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		if (!mats.has(matgroup)):
			mats[matgroup] = StandardMaterial3D.new()
		st.set_material(mats[matgroup])
		for face in faces[matgroup]:
			if (face["v"].size() == 3):
				# Vertices
				var fan_v: PackedVector3Array = PackedVector3Array()
				fan_v.append(vertices[face["v"][0]])
				fan_v.append(vertices[face["v"][2]])
				fan_v.append(vertices[face["v"][1]])
				
				# Normals
				var fan_vn: PackedVector3Array = PackedVector3Array()
				if (face["vn"].size() > 0):
					fan_vn.append(normals[face["vn"][0]])
					fan_vn.append(normals[face["vn"][2]])
					fan_vn.append(normals[face["vn"][1]])
				
				# Textures
				var fan_vt: PackedVector2Array = PackedVector2Array()
				if (face["vt"].size() > 0):
					for k in [0,2,1]:
						var f = face["vt"][k]
						if (f > -1):
							var uv = uvs[f]
							fan_vt.append(uv)
				st.add_triangle_fan(fan_v, fan_vt, PackedColorArray(), PackedVector2Array(), fan_vn, [])
		mesh = st.commit(mesh)
	
	for k in mesh.get_surface_count():
		var mat: Material = mesh.surface_get_material(k)
		mat_name = ""
		for m in mats:
			if (mats[m] == mat):
				mat_name = m
		mesh.surface_set_name(k, mat_name)
	
	# Finish
	return mesh
