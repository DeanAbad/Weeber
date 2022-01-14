extends Node

# ===================== REQUEST VARIABLES - START ==========================
# Request url & api
const BASE_URL : String = "https://gelbooru.com/index.php?"
var request_api : String = "page=dapi&s=post&q=index"
var request_key : String = "&api_key=8ab7ebb52c422eed978168195d24ac54856447855f7676169517683bf7847839&user_id=918696"
var request_list_size : int = 10
var request_options : String = "&limit="+str(request_list_size)+"&pid=0&json=1"
var request_url : String = BASE_URL+request_api+request_key+request_options
# Download queue
var download_path : String = "user://downloaded_files"
var download_list : Array = []
var index : int = 0
# ====================== REQUEST VARIABLES - END ===========================

# ======================= GUI VARIABLES - START ============================
onready var menu_bar : HBoxContainer = $GUI/Master/Container/MenuBar
#onready var content_post : VBoxContainer = $GUI/Master/Container/Content/Post
onready var about_popup : Control = $GUI/Master/AboutPopup
# ======================== GUI VARIABLES - END =============================


func _ready() -> void:
	request()
	set_gui()


func open_destination_folder() -> void:
	var open_destination_folder : int = OS.shell_open(ProjectSettings.globalize_path(download_path))
	if open_destination_folder != OK:
		push_error("Error occurred in attempt to open the folder.")
	else:
		return


func quit_application() -> void:
	get_tree().quit()


func request() -> void:
	# Create directory first
	var download_directory : Directory = Directory.new()
	if download_directory.dir_exists(download_path) == true:
		initialize_httprequest_signal()
	else:
		if download_directory.make_dir(download_path) == OK:
			initialize_httprequest_signal()
		else:
			push_error("Creating directory failed.")
			quit_application()


func set_gui() -> void:
	var filebtn_popupmenu : PopupMenu = menu_bar.get_node("FileBtn").get_popup()
	var helpbtn_popupmenu : PopupMenu = menu_bar.get_node("HelpBtn").get_popup()
	var icon : TextureRect = TextureRect.new()
	var key : InputEventKey = InputEventKey.new()

# ====================== FILEBTN SETTINGS - START ==========================
	filebtn_popupmenu.set_custom_minimum_size(
		Vector2(
			260,
			filebtn_popupmenu.get_size().y
		)
	)

	icon.texture = load("res://gui/icon/destination_folder.png")
	key.set_control(true)   # CTRL key
	key.set_scancode(KEY_O) # O key
	filebtn_popupmenu.add_icon_item(icon.get_texture(), "  Open Destination Folder", 0, key.get_scancode_with_modifiers())

	filebtn_popupmenu.add_separator("", 1)

	icon.texture = load("res://gui/icon/quit.png")
	key.set_control(true)
	key.set_scancode(KEY_Q)
	filebtn_popupmenu.add_icon_item(icon.get_texture(), "  Quit Weeber", 2, key.get_scancode_with_modifiers())
# ======================= FILEBTN SETTINGS - END ===========================

# ====================== HELPBTN SETTINGS - START ==========================
	helpbtn_popupmenu.set_custom_minimum_size(
		Vector2(
			260,
			helpbtn_popupmenu.get_size().y
		)
	)

	key.set_control(false) # Since there are no shortcuts in help popup menu,
	key.set_scancode(0)    # just revert its properties with default values

	icon.texture = load("res://gui/icon/about_weeber.png")
	helpbtn_popupmenu.add_icon_item(icon.get_texture(), "  About Weeber", 0, 0)

	helpbtn_popupmenu.add_separator("", 1)

	icon.texture = load("res://gui/icon/about_godot_engine.png")
	helpbtn_popupmenu.add_icon_item(icon.get_texture(), "  About Godot Engine", 2, 0)
# ======================= HELPBTN SETTINGS - END ===========================

	# After making the buttons, make a connection for their signals
	var filebtn_popupmenu_connection : int = filebtn_popupmenu.connect("index_pressed", self, "_filebtn_popmenu_item_pressed")
	var help_popupmenu_connection : int = helpbtn_popupmenu.connect("index_pressed", self, "_helpbtn_popmenu_item_pressed")

	# Make connection for link buttons
	var about_popup_weeber_github_link_btn : LinkButton = about_popup.get_node("Weeber/GithubLinkBtn")
	var github_link_btn_connection : int = about_popup_weeber_github_link_btn.connect("pressed", self, "_goto_link", ["https://github.com/MumuNiMochii/Weeber"])

	if filebtn_popupmenu_connection != OK:
		push_error("Error occurred in signal connection.")
	else:
		return

	if help_popupmenu_connection != OK:
		push_error("Error occurred in signal connection.")
	else:
		return

	if github_link_btn_connection != OK:
		push_error("Error occurred in signal connection.")
	else:
		return


func _filebtn_popmenu_item_pressed(an_item: int) -> void:
	match an_item:
		0:
			open_destination_folder()
		2:
			quit_application()


func _helpbtn_popmenu_item_pressed(an_item: int) -> void:
	match an_item:
		0:
			$GUI/Master/AboutPopup/Weeber.visible = !$GUI/Master/AboutPopup/Weeber.visible
		2:
			print("ABOUT GODOT ENGINE")


func _goto_link(link : String) -> void:
	var open_link : int = OS.shell_open(link)
	if open_link != OK:
		push_error("Error occurred while going to link.")
	else:
		return


func initialize_httprequest_signal() -> void:
	# Make HTTPRequest function and connect it for signal
	var signal_connection : int = $HTTPRequest.connect("request_completed", self, "_on_initial_request_completed")
	if signal_connection != OK:
		push_error("Error occurred in signal connection.")
	else:
		$HTTPRequest.set_use_threads(true)

	var request_json_status : int = $HTTPRequest.request(
		request_url,
		PoolStringArray([
			"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"
		]), true, 0
	)

	if request_json_status != OK:
		push_error("An error occurred in the HTTP request.")


func _on_initial_request_completed(_result, _response_code, _headers, body) -> void:
	$HTTPRequest.cancel_request()

	var string_body_result : String = body.get_string_from_utf8()
	var json_parse_result : JSONParseResult = JSON.parse(string_body_result)
	var object : Dictionary = json_parse_result.get_result()

	# Disconnect to prevent from being emitted when request_image() is used
	if $HTTPRequest.is_connected("request_completed", self, "_on_initial_request_completed"):
		$HTTPRequest.disconnect("request_completed", self, "_on_initial_request_completed")

	for an_index in object["post"]:
		var item : Dictionary = {
			"id":str(an_index["id"]),
			"url":an_index["file_url"],
			"view":an_index["preview_url"]
		}
		download_list.append(item)

#	if OS.is_debug_build() == true:
#		var string = JSON.print(item, "\t")
#		var object_string_sample : String = JSON.print(object["post"][0], "\t")
#		print(string)
#		print(download_list)
#		print(object_string_sample)

	request_image()


func request_image() -> void:
	# Allow download if item is under the limit
	if index < request_list_size:
		var request_file_status : int = $HTTPRequest.request(
			download_list[index]["url"],
			PoolStringArray([
				"Accept: image/avif,image/webp,*/*",
				"Accept: video/webm,video/ogg,video/*;q=0.9,application/ogg;q=0.7,audio/*;q=0.6,*/*;q=0.5"
			]), true, 0
		)

		if request_file_status != OK:
			push_error("An error occurred in the HTTP request.")
		elif request_file_status == OK:
			# Emit another signal to get the headers
			var signal_connection : int = $HTTPRequest.connect("request_completed", self, "_on_file_request_completed")
			if signal_connection != OK:
				push_error("An error occurred in signal connection.")
			else:
				$HTTPRequest.set_use_threads(true)
				$HTTPRequest.set_download_file(download_path+"/"+download_list[index]["id"]+"."+download_list[index]["view"].get_extension())
	else:
		print("Download queue completed.")
		quit_application()


func _on_file_request_completed(_result, _response_code, headers, _body) -> void:
	var content_length_result : String = headers[3] # Content-Length key-value pair
	content_length_result.erase(0, 16)
	var file_size : int = int(content_length_result)
	var _file_size_string : String = String.humanize_size(file_size)

#	if OS.is_debug_build() == true:
#		print(headers[3])
#		print("Removed string: "+content_length_result)
#		print("Integer: "+str(file_size))
#		print(file_size_string)

	if $HTTPRequest.get_downloaded_bytes() == file_size:
#		if OS.is_debug_build() == true:
#			print("Download size "+file_size_string+" reached.")

		$HTTPRequest.cancel_request()

		if $HTTPRequest.is_connected("request_completed", self, "_on_file_request_completed"):
			$HTTPRequest.disconnect("request_completed", self, "_on_file_request_completed")

			index += 1
			request_image()


func _process(_delta) -> void:
	$GUI/Master/Container/Content/Post/PostSize.set_text("Post size: " + str($GUI/Master/Container/Content/Post.get_rect().size.x) + " x " + str($GUI/Master/Container/Content/Post.get_rect().size.y))
