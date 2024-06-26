extends Node
class_name _GameJolt
# Game Jolt API singleton.


# Signals
signal user_name_changed
signal user_token_changed
signal game_id_changed
signal private_key_changed
signal users_fetch_completed(response)
signal users_auth_completed(response)
signal sessions_open_completed(response)
signal sessions_ping_completed(response)
signal sessions_check_completed(response)
signal sessions_close_completed(response)
signal scores_fetch_completed(response)
signal scores_tables_completed(response)
signal scores_add_completed(response)
signal scores_get_rank_completed(response)
signal trophies_fetch_completed(response)
signal trophies_add_achieved_completed(response)
signal trophies_remove_achieved_completed(response)
signal data_store_set_completed(response)
signal data_store_update_completed(response)
signal data_store_remove_completed(response)
signal data_store_fetch_completed(response)
signal data_store_get_keys_completed(response)
signal friends_completed(response)
signal time_completed(response)
signal batch_completed(response)


# Constants
const BASE_URL := "https://api.gamejolt.com/api/game/v1_2"
const HEADERS := []
const OPERATIONS := {
	"users/fetch": BASE_URL + "/users/" + "?",
	"users/auth": BASE_URL + "/users/auth/" + "?",
	"sessions/open": BASE_URL + "/sessions/open/" + "?",
	"sessions/ping": BASE_URL + "/sessions/ping/" + "?",
	"sessions/check": BASE_URL + "/sessions/check/" + "?",
	"sessions/close": BASE_URL + "/sessions/close/" + "?",
	"scores/fetch": BASE_URL + "/scores/" + "?",
	"scores/tables": BASE_URL + "/scores/tables/" + "?",
	"scores/add": BASE_URL + "/scores/add/" + "?",
	"scores/get-rank": BASE_URL + "/scores/get-rank/" + "?",
	"trophies/fetch": BASE_URL + "/trophies/" + "?",
	"trophies/add-achieved": BASE_URL + "/trophies/add-achieved/" + "?",
	"trophies/remove-achieved": BASE_URL + "/trophies/remove-achieved/" + "?",
	"data-store/set": BASE_URL + "/data-store/set/" + "?",
	"data-store/update": BASE_URL + "/data-store/update/" + "?",
	"data-store/remove": BASE_URL + "/data-store/remove/" + "?",
	"data-store/fetch": BASE_URL + "/data-store/" + "?",
	"data-store/get-keys": BASE_URL + "/data-store/get-keys/" + "?",
	"friends": BASE_URL + "/friends/" + "?",
	"time": BASE_URL + "/time/" + "?",
	"batch": BASE_URL + "/batch/" + "?",
}


# Variables
var user_name := "": set = set_user_name, get = get_user_name
var user_token := "": set = set_user_token, get = get_user_token
var game_id := "": set = set_game_id, get = get_game_id
var private_key := "": set = set_private_key, get = get_private_key

var _submit_requests := true
var _batch_requests := []
var _debug := false


# Built-in overrides
func _ready() -> void:
	_debug = ProjectSettings.get_setting("game_jolt/config/debug/enabled")
	game_id = ProjectSettings.get_setting("game_jolt/config/global/game_id")
	private_key = ProjectSettings.get_setting("game_jolt/config/global/private_key")

	if _debug and OS.is_debug_build():
		user_name = ProjectSettings.get_setting("game_jolt/config/debug/user_name")
		user_token = ProjectSettings.get_setting("game_jolt/config/debug/user_token")


# Setters and getters
# Set the user name for auth and other user scope tasks.
func set_user_name(value: String) -> void:
	if user_name == value:
		return
	user_name = value
	emit_signal("user_name_changed")


# Get current user name.
func get_user_name() -> String:
	return user_name


# Set the user token for auth and other user scope tasks.
func set_user_token(value: String) -> void:
	if user_token == value:
		return
	user_token = value
	emit_signal("user_token_changed")


# Get current user game token.
func get_user_token() -> String:
	return user_token


# Set the game ID needed for all tasks.
func set_game_id(value: String) -> void:
	if game_id == value:
		return
	game_id = value
	emit_signal("game_id_changed")


# Get current game ID.
func get_game_id() -> String:
	return game_id


# Set the private key needed for all tasks.
func set_private_key(value: String) -> void:
	if private_key == value:
		return
	private_key = value
	emit_signal("private_key_changed")


# Get current game private key.
func get_private_key() -> String:
	return private_key


# Public methods
# Users
# Returns a user's data.
func users_fetch(username := "", user_ids := []) -> _GameJolt:
	var data := {
		"game_id": game_id,
	}

	if username.length() and user_ids.size():
		return _dispatch_local_error_response(
			"users/fetch",
			"Values cannot be used together: username, user_ids"
		)

	if username:
		data["username"] = username

	elif user_ids.size():
		for i in user_ids.size():
			user_ids[i] = str(user_ids[i])

		data["user_id"] = ",".join(user_ids)

	else:
		data["username"] = user_name

	return _submit("users/fetch", data)


# Authenticates the user's information.
func users_auth() -> _GameJolt:
	var data := {
		"game_id": game_id,
		"username": user_name,
		"user_token": user_token,
	}

	return _submit("users/auth", data)


# Sessions
# Opens a game session for a particular user and allows you to tell Game Jolt that a user is playing your game.
func sessions_open() -> _GameJolt:
	var data := {
		"game_id": game_id,
		"username": user_name,
		"user_token": user_token,
	}

	return _submit("sessions/open", data)


# Pings an open session to tell the system that it's still active.
func sessions_ping(status := "") -> _GameJolt:
	var data := {
		"game_id": game_id,
		"username": user_name,
		"user_token": user_token,
	}

	if status:
		if not status in ["active", "idle"]:
			return _dispatch_local_error_response(
				"sessions/ping",
				"Ping status must be 'active' or 'idle'"
			)

		data["status"] = status

	return _submit("sessions/ping", data)


# Checks to see if there is an open session for the user.
func sessions_check() -> _GameJolt:
	var data := {
		"game_id": game_id,
		"username": user_name,
		"user_token": user_token,
	}

	return _submit("sessions/check", data)


# Closes the active session.
func sessions_close() -> _GameJolt:
	var data := {
		"game_id": game_id,
		"username": user_name,
		"user_token": user_token,
	}

	return _submit("sessions/close", data)


# Scores
# Returns a list of scores either for a user or globally for a game.
func scores_fetch(limit = null, table_id = null, guest := "", better_than = null, worse_than = null, this_user := false) -> _GameJolt:
	var data := {
		"game_id": game_id,
	}

	var optional_data := {
		"username": user_name if this_user else guest if guest else null,
		"user_token": user_token if this_user else null,
		"limit":  limit if limit else null,
		"table_id":  table_id if table_id else null,
		"guest": guest if guest else null,
		"better_than": better_than if better_than else null,
		"worse_than": worse_than if worse_than else null,
	}

	if optional_data.get("username") and optional_data.get("guest"):
		return _dispatch_local_error_response(
			"scores/fetch",
			"Parameters 'username' and 'guest' are mutually exclusive"
		)

	return _submit("scores/fetch", data, optional_data)


# Returns a list of high score tables for a game.
func scores_tables() -> _GameJolt:
	var data := {
		"game_id": game_id,
	}

	return _submit("scores/tables", data)


# Adds a score for a user or guest.
func scores_add(score: String, sort, table_id = null, guest := "", extra_data = null) -> _GameJolt:
	var data := {
		"game_id": game_id,
		"score": score,
		"sort": sort,
	}

	extra_data = _data_to_string(extra_data)

	var optional_data := {
		"username": guest if guest else user_name,
		"user_token": null if guest else user_token,
		"table_id": table_id if table_id else null,
		"guest": guest if guest else null,
		"extra_data": extra_data if extra_data else null,
	}

	return _submit("scores/add", data, optional_data)


# Returns the rank of a particular score on a score table.
func scores_get_rank(sort, table_id := "") -> _GameJolt:
	var data := {
		"game_id": game_id,
		"sort": sort,
	}

	var optional_data := {
		"table_id": table_id if table_id else null,
	}

	return _submit("scores/get-rank", data, optional_data)


# Trophies
# Returns one trophy or multiple trophies, depending on the parameters passed in.
func trophies_fetch(achieved = null, trophy_ids := []) -> _GameJolt:
	var data := {
		"game_id": game_id,
		"username": user_name,
		"user_token": user_token,
	}

	var optional_data := {
		"achieved": achieved if not trophy_ids.size() else null,
		"trophy_id": ",".join(trophy_ids) if trophy_ids.size() else null,
	}

	return _submit("trophies/fetch", data, optional_data)


# Sets a trophy as achieved for a particular user.
func trophies_add_achieved(trophy_id) -> _GameJolt:
	var data := {
		"game_id": game_id,
		"username": user_name,
		"user_token": user_token,
		"trophy_id": trophy_id,
	}

	return _submit("trophies/add-achieved", data)


# Remove a previously achieved trophy for a particular user.
func trophies_remove_achieved(trophy_id) -> _GameJolt:
	var data := {
		"game_id": game_id,
		"username": user_name,
		"user_token": user_token,
		"trophy_id": trophy_id,
	}

	return _submit("trophies/remove-achieved", data)


# Data Store
# Sets data in the data store.
func data_store_set(key: String, data, global_data := false) -> _GameJolt:
	data = _data_to_string(data)

	var data_ = {
		"game_id" : game_id,
		"key" : key,
		"data" : data,
	}

	var optional_data = {
		"username" : null if global_data else user_name,
		"user_token" : null if global_data else user_token
	}

	return _submit("data-store/set", data_, optional_data)


# Updates data in the data store.
func data_store_update(key: String, operation: String, value, global_data := false) -> _GameJolt:
	var data = {
		"game_id" : game_id,
		"key" : key,
		"operation" : operation,
		"value" : value,
	}

	var optional_data = {
		"username" : null if global_data else user_name,
		"user_token" : null if global_data else user_token
	}

	return _submit("data-store/update", data, optional_data)


# Removes data from the data store.
func data_store_remove(key: String, global_data := false) -> _GameJolt:
	var data = {
		"game_id" : game_id,
		"key" : key,
	}

	var optional_data = {
		"username" : null if global_data else user_name,
		"user_token" : null if global_data else user_token
	}

	return _submit("data-store/remove", data, optional_data)


# Returns data from the data store.
func data_store_fetch(key: String, global_data := false) -> _GameJolt:
	var data = {
		"game_id" : game_id,
		"key" : key,
	}

	var optional_data = {
		"username" : null if global_data else user_name,
		"user_token" : null if global_data else user_token
	}

	return _submit("data-store/fetch", data, optional_data)


# Returns either all the keys in the game's global data store, or all the keys in a user's data store.
func data_store_get_keys(pattern := "", global_data := false) -> _GameJolt:
	var data = {
		"game_id" : game_id,
	}

	var optional_data = {
		"username" : null if global_data else user_name,
		"user_token" : null if global_data else user_token,
		"pattern": pattern,
	}

	return _submit("data-store/get-keys", data, optional_data)


# Friends
# Returns the list of a user's friends.
func friends() -> _GameJolt:
	var data := {
		"game_id": game_id,
		"username": user_name,
		"user_token": user_token,
	}

	return _submit("friends", data)


# Time
# Returns the time of the Game Jolt server.
func time() -> _GameJolt:
	var data := {
		"game_id": game_id,
	}

	return _submit("time", data)


# Batch Calls
# Perform the batch request after gathering requests with batch_begin and batch end.
func batch(parallel := false, break_on_error := false) -> _GameJolt:
	if parallel and break_on_error:
		return _dispatch_local_error_response(
			"batch",
			"Values 'parallel' and 'break_on_error' are mutually exclusive"
		)

	for i in _batch_requests.size():
		var request: String = _batch_requests[i]
		request = request.replace(BASE_URL, "")
		request = request.split("&signature=")[0]
		request += "&signature=" + (request + private_key).md5_text()
		_batch_requests[i] = request

	var data := {
		"game_id": game_id,
		"requests": _batch_requests if _batch_requests.size() else null
	}

	var optional_data := {
		"parallel": parallel if parallel else null,
		"break_on_error": break_on_error if break_on_error else null,
	}

	_batch_requests = []

	return _submit("batch", data, optional_data)


# Begins to gather requests for batch. Methods will not return responses after this call.
func batch_begin() -> void:
	_submit_requests = false
	_batch_requests = []


# Stops gathering requests for batch. Methods will return responses again after this call.
func batch_end() -> void:
	_submit_requests = true


# Private methods
# Submit request and return response data on specific signal.
func _submit(operation: String, data: Dictionary, optional_data := {}) -> _GameJolt:
	var required_data_error := _validate_required_data(data)

	if optional_data.size():
		data.merge(_validate_optional_data(optional_data))

	var final_url := _generate_url(OPERATIONS[operation], data)
	if _debug: prints(final_url)

	if not _submit_requests:
		_batch_requests.push_back(final_url)
		return self

	if required_data_error:
		return _dispatch_local_error_response(operation, required_data_error)

	var http_request := _create_http_request()

	http_request.request(final_url, HEADERS, HTTPClient.METHOD_GET)
	http_request.request_completed.connect(
		_on_HTTPRequest_request_completed.bind(operation, http_request), CONNECT_ONE_SHOT
	)

	return self


# Create and return HTTPRequest node to perform request.
func _create_http_request() -> HTTPRequest:
	var _http_request := HTTPRequest.new()
	add_child(_http_request)
	_http_request.use_threads = OS.get_name() != "HTML5"
	return _http_request


# Await a fraction of a second before emiting an local error response to the user.
func _dispatch_local_error_response(operation: String, message: String, extra_data := {}) -> _GameJolt:
	var data := {"success": "false", "message": message}
	data.merge(extra_data, true)

	get_tree().create_timer(0.1).timeout.connect(
		_on_TimerFailed_timeout.bind(operation, data)
	)
	return self


# Generate request URL from operation and data.
func _generate_url(operation_url: String, data: Dictionary) -> String:
	var is_batch := "batch" in operation_url
	var ordered_data := {}

	var keys_sorted := data.keys()
	keys_sorted.sort()

	for key in keys_sorted:
		ordered_data[key] = data[key]
	data = ordered_data

	var request_urls: Array = data.get("requests", [])
	data.erase("requests")
	var url_params := _params_encode(data, request_urls)

	var signature := (operation_url + url_params + private_key).md5_text()
	return operation_url + url_params + "&signature=" + signature


# Validate if required data of request is provided.
func _validate_required_data(data: Dictionary) -> String:
	for key in data.keys():
		var value = data[key]

		if typeof(value) == TYPE_NIL or typeof(value) == TYPE_STRING and not value.length():
			return "Value is required: " + str(key)

		if typeof(value) == TYPE_BOOL:
			data[key] = str(value).to_lower()

	return ""


# Discard null values from optional data and perform conversions.
func _validate_optional_data(data: Dictionary) -> Dictionary:
	var valid_data := {}

	for key in data.keys():
		var value = data[key]

		if typeof(value) == TYPE_NIL or typeof(value) == TYPE_STRING and not value.length():
			continue

		if typeof(value) == TYPE_BOOL:
			value = str(value).to_lower()

		valid_data[key] = value

	return valid_data


# Encode and join URL params.
func _params_encode(data: Dictionary, requests := []) -> String:
	var params := []

	for key in data.keys():
		params.push_back(key + "=" + str(data[key]).uri_encode())

	for request in requests:
		params.push_back("requests[]=" + request.uri_encode())

	return "&".join(params)


# Convert generic data to string in the best way possible.
func _data_to_string(data) -> String:
	if typeof(data) in [TYPE_ARRAY, TYPE_DICTIONARY]:
		data = JSON.stringify(data)
	elif typeof(data) == TYPE_BOOL:
		data = str(data).to_lower()
	else:
		data = str(data)

	return data


# Formats an operation name to a signal name.
func _operation_to_signal(operation: String) -> String:
	return operation.replace("/", "_").replace("-", "_") + "_completed"


# Event handlers
# Executed when the request is finished.
func _on_HTTPRequest_request_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray,
	operation: String,
	http_request: HTTPRequest
) -> void:
	var signal_name := _operation_to_signal(operation)
	http_request.queue_free()

	if result == HTTPRequest.RESULT_SUCCESS and response_code == HTTPClient.RESPONSE_OK:
		var parsed_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())

		if parsed_body and parsed_body["response"]:
			parsed_body = parsed_body["response"]
		else:
			parsed_body = {"success": "false"}

		emit_signal(signal_name, parsed_body)

		if _debug: prints(JSON.stringify(parsed_body))
		return

	_dispatch_local_error_response(
		operation,
		"Could not complete request: " + operation,
		{"result_code": result}
	)


# Executed when a local error happens and the script must wait to respond.
func _on_TimerFailed_timeout(operation: String, data: Dictionary) -> void:
	if _debug: prints(JSON.stringify(data))
	emit_signal(_operation_to_signal(operation), data)
