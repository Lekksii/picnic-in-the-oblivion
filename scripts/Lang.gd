extends Node

var current_lang = "en"
var language_file

func _ready():
	var opt = Utility.read_json("assets/options.json")
	if "current_language" in opt:
		current_lang = opt["current_language"]
	else:
		current_lang = "en"
	
	_change_lang(current_lang)

func _change_lang(lang):
	language_file = Utility.read_json("assets/texts/lang_"+lang+".json")

func translate_string(input : String):
	var founded_text = input
	var new_regex = RegEx.new()
	var edited_text = new_regex.compile("\\[key_action\\](.*?)\\[/key_action\\]|\\[/version\\]|\\[lang\\](.*?)\\[/lang\\]")
	# after compiling expression in search we'll get two strings:
	# original [lang]test.text[/lang] and only inside text in brackets test.text
	for reg_result in new_regex.search_all(founded_text):
		# Regular expression for finding custom bbcodes
		# Get first string of founded regex element
		var result_bbcode = reg_result.get_string()
		# if this is key_action code
		if result_bbcode.contains("key_action"):
			# make loop through actions
			for action in InputMap.get_actions():
				# if action is match with key_action data
				if action == reg_result.get_string(1):
					var act_keys = []
					# create empty array to collect input keys
					# loop through events of current action
					for k in InputMap.action_get_events(action):
						# split event data at chars where -> ' (' Physical) string
						# just after our key name, and append it to array 
						act_keys.append(k.as_text().split(' (')[0])
					# crop big words such as left mouse button or etc
					founded_text = founded_text.replace('Left Mouse Button','LMB').replace('Right Mouse Button','RMB')
					# make list looks like string separated by comma and will deletes []
					founded_text = founded_text.replace(reg_result.get_string(0),str(act_keys).replace('"','').lstrip('[').rstrip(']'))
					break
		if result_bbcode.contains("version"):
			founded_text = founded_text.replace(reg_result.get_string(0),str(GameManager.game_version))
		if result_bbcode.contains("lang"):
			var cleaned_result = clear_regex_from_empty_string(reg_result.strings)
			founded_text = founded_text.replace(cleaned_result[0],Lang.translate(cleaned_result[1]))
	
	return founded_text
		
# function that translate key_code to value from file
func translate(key):
	if key in language_file.keys():
		var founded_text = language_file[key]
		var new_regex = RegEx.new()
		var edited_text = new_regex.compile("\\[key_action\\](.*?)\\[/key_action\\]|\\[/version\\]|\\[lang\\](.*?)\\[/lang\\]")
		# after compiling expression in search we'll get two strings:
		# original [lang]test.text[/lang] and only inside text in brackets test.text
		for reg_result in new_regex.search_all(founded_text):
			# Regular expression for finding custom bbcodes
			# Get first string of founded regex element
			var result_bbcode = reg_result.get_string()
			# if this is key_action code
			if result_bbcode.contains("key_action"):
				# make loop through actions
				for action in InputMap.get_actions():
					# if action is match with key_action data
					if action == reg_result.get_string(1):
						var act_keys = []
						# create empty array to collect input keys
						# loop through events of current action
						for k in InputMap.action_get_events(action):
							# split event data at chars where -> ' (' Physical) string
							# just after our key name, and append it to array 
							act_keys.append(k.as_text().split(' (')[0])
						# crop big words such as left mouse button or etc
						founded_text = founded_text.replace('Left Mouse Button','LMB').replace('Right Mouse Button','RMB')
						# make list looks like string separated by comma and will deletes []
						founded_text = founded_text.replace(reg_result.get_string(0),str(act_keys).replace('"','').lstrip('[').rstrip(']'))
						break
			if result_bbcode.contains("version"):
				founded_text = founded_text.replace(reg_result.get_string(0),str(GameManager.game_version))
			if result_bbcode.contains("lang"):
				var cleaned_result = clear_regex_from_empty_string(reg_result.strings)
				founded_text = founded_text.replace(cleaned_result[0],Lang.translate(cleaned_result[1]))
		
		return founded_text
	else:
		return key

func clear_regex_from_empty_string(strings_array: Array):
	var str = []
	for string_data in strings_array:
		if string_data.is_empty():
			continue
		else:
			str.append(string_data)
	return str
