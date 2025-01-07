extends Node
	
## Run script *.gd file 'from assets/scripts/' folder
func RunOutsideScript(script_name : String):
	# check if game already has holder with this script, if not - load it from file
	if not has_node(script_name):
		var script_holder = Node.new()
		var script = GDScript.new()
		var file_data = ""
		
		if FileAccess.file_exists(GameManager.app_dir+"assets/scripts/%s.gd" % script_name):
			var file = FileAccess.open(GameManager.app_dir+"assets/scripts/%s.gd" % script_name,FileAccess.READ)
			file_data = file.get_as_text()
			file.close()
		else:
			print("[Script Loader]: Failed to load script! File is don't exists!\n")
			return
		
		if file_data.is_empty(): 
			print("[Script Loader]: Failed to load script! Data is empty!\n")
			return
		
		script.source_code = file_data
		script.reload()
		
		add_child(script_holder)
		script_holder.name = script_name
		
		script_holder.set_process(true)
		script_holder.set_process_input(true)
		script_holder.set_process_unhandled_input(true)
		
		script_holder.set_script(script)
		
		print("[Script Loader]: Script \"assets/scripts/%s.gd\" loaded successfuly!\n" % script_name)
		return script_holder
	else: # else we just return already created holder with functions
		return get_node(script_name)
