extends Node

class CustomSortTagsList:
	static func ascend_by_id(item_1, item_2) -> bool:
		if item_1["id"] < item_2["id"]: return true
		return false

	static func ascend_by_name(item_1, item_2) -> bool:
		if item_1["name"] < item_2["name"]: return true
		return false

	static func ascend_by_count(item_1, item_2) -> bool:
		if item_1["count"] < item_2["count"]: return true
		return false

	static func ascend_by_type(item_1, item_2) -> bool:
		if item_1["type"] < item_2["type"]: return true
		return false

	static func descend_by_id(item_1, item_2) -> bool:
		if item_1["id"] > item_2["id"]: return true
		return false

	static func descend_by_name(item_1, item_2) -> bool:
		if item_1["name"] > item_2["name"]: return true
		return false

	static func descend_by_count(item_1, item_2) -> bool:
		if item_1["count"] > item_2["count"]: return true
		return false

	static func descend_by_type(item_1, item_2) -> bool:
		if item_1["type"] > item_2["type"]: return true
		return false


# ===================== REQUEST VARIABLES - START ==========================
# Request url & api
const BASE_URL : String = "https://gelbooru.com/index.php?"
var request_api_post : String = "page=dapi&s=post&q=index"
var request_api_tags : String = "page=dapi&s=tag&q=index"
var request_key : String = "&api_key=8ab7ebb52c422eed978168195d24ac54856447855f7676169517683bf7847839&user_id=918696"
var request_tag : String = "&tags=rating:safe -rating:explicit -rating:questionable"
var request_post_size : int = 25
var request_tags_size : int = 100 # 100 is max per request
var request_post_options : String = "&limit="+str(request_post_size)+request_tag+"&pid=0&json=1"
var request_tags_options : String = "&limit="+str(request_tags_size)+"&pid=0&json=1"
var request_url_post : String = BASE_URL+request_api_post+request_key+request_post_options.http_unescape()
var request_url_tags : String = BASE_URL+request_api_tags+request_key+request_tags_options.http_unescape()

# Download queue
var download_path : String = "user://downloads"
var preview_path : String = "user://previews"
var download_list : Array = []
var tags_list : Array = []
var index : int = 0
var size: int = 0
# ====================== REQUEST VARIABLES - END ===========================

# ======================= GUI VARIABLES - START ============================
onready var tooltip : PackedScene = preload("res://CustomToolTip.tscn")
onready var about_popup_weeber : PackedScene = preload("res://Weeber.tscn")
onready var about_popup_tags : PackedScene = preload("res://Tags.tscn")
onready var about_popup_godot : PackedScene = preload("res://Godot.tscn")
onready var menu_bar : HBoxContainer = $GUI/Master/Container/MenuBar
onready var list : VBoxContainer = $GUI/Master/Container/Margin/Content/Info/Margin/File/Tags/Margin/Content/Scroll/List
onready var menu : GridContainer = $GUI/Master/Container/Margin/Content/Post/Object/Margin2/Gallery/Panel1/Margin/Scroll/Menu
onready var about_popup : Control = $GUI/Master/AboutPopup
onready var custom_tooltip : Control = $GUI/Master/CustomTooltip
# ======================== GUI VARIABLES - END =============================


func _ready() -> void:
	on_exit()
	request()
	set_gui()


func open_destination_folder() -> void:
	# Create directory first
	var download_preview_directory : Directory = Directory.new()
	if download_preview_directory.dir_exists(download_path) == true:
		if OS.shell_open(ProjectSettings.globalize_path(download_path)) != OK:
			push_error("An error occurred when opening the directory.")
	else:
		if download_preview_directory.make_dir(download_path) == OK:
			if OS.shell_open(ProjectSettings.globalize_path(download_path)) != OK:
				push_error("An error occurred when opening the directory.")
		else:
			push_error("An error occurred when creating directory.")
			quit_application()


func quit_application() -> void:
	get_tree().quit()


func on_exit() -> void:
	# Connect 'tree_exiting' signal i.e. when the app is about to close
	if connect("tree_exiting", self, "_when_quitting") != OK:
		push_error("An error occurred in signal connection.")


func _when_quitting() -> void:
	if connect("tree_exited", self, "_when_quitted") != OK:
		push_error("An error occurred in signal connection.")


func _when_quitted() -> void:
	# Check the directory and delete the temporary files
	var download_preview_directory : Directory = Directory.new()
	if download_preview_directory.dir_exists(preview_path) == true:
		if download_preview_directory.open(preview_path) == OK:
			if download_preview_directory.list_dir_begin() == OK:
				var file_name = download_preview_directory.get_next()

				while file_name != "":
					# If file_name is a file i.e. not a directory, delete it
					if not download_preview_directory.current_is_dir():
						if download_preview_directory.remove(file_name) != OK:
							push_error("An error occurred on deleting file.")
					file_name = download_preview_directory.get_next()

	queue_free()


func request() -> void:
	# Create directory first
	var download_preview_directory : Directory = Directory.new()
	if download_preview_directory.dir_exists(preview_path) == true:
		initialize_httprequest_signal()
	else:
		if download_preview_directory.make_dir(preview_path) == OK:
			initialize_httprequest_signal()
		else:
			push_error("An error occurred when creating directory.")
			quit_application()


func set_gui() -> void:
	var filebtn_popupmenu : PopupMenu = menu_bar.get_node("FileBtn").get_popup()
	var helpbtn_popupmenu : PopupMenu = menu_bar.get_node("HelpBtn").get_popup()
	var icon : TextureRect = TextureRect.new()
	var key : InputEventKey = InputEventKey.new()

	if menu.connect("resized", self, "_on_when_resized_menu") != OK:
		push_error("An error occurred in signal connection.")

	var tags_list_help_icon : TextureRect = $GUI/Master/Container/Margin/Content/Info/Margin/File/Tags/Margin/Content/Info/Help/Icon
	if tags_list_help_icon.connect("mouse_entered", self, "_on_mouse_entered_tags_list_help_icon") != OK:
		push_error("An error occurred in signal connection.")

	if tags_list_help_icon.connect("mouse_exited", self, "_on_mouse_exited_tags_list_help_icon") != OK:
		push_error("An error occurred in signal connection.")

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

	icon.texture = load("res://gui/icon/tags.png")
	helpbtn_popupmenu.add_icon_item(icon.get_texture(), "  About Tags", 0, 0)

	icon.texture = load("res://gui/icon/about_weeber.png")
	helpbtn_popupmenu.add_icon_item(icon.get_texture(), "  About Weeber", 1, 0)

	helpbtn_popupmenu.add_separator("", 2)

	icon.texture = load("res://gui/icon/about_godot_engine.png")
	helpbtn_popupmenu.add_icon_item(icon.get_texture(), "  About Godot Engine", 3, 0)
# ======================= HELPBTN SETTINGS - END ===========================

	icon.free()

	# After making the buttons, make a connection for their signals
	var filebtn_popupmenu_connection : int = filebtn_popupmenu.connect("index_pressed", self, "_filebtn_popmenu_item_pressed")
	var help_popupmenu_connection : int = helpbtn_popupmenu.connect("index_pressed", self, "_helpbtn_popmenu_item_pressed")

	if filebtn_popupmenu_connection or help_popupmenu_connection != OK: push_error("An error occurred in signal connection.")


func _filebtn_popmenu_item_pressed(an_item: int) -> void:
	match an_item:
		0: open_destination_folder()
		2: quit_application()


func _helpbtn_popmenu_item_pressed(an_item: int) -> void:
		about_popup.visible = !about_popup.visible
		match an_item:
			0:
				if about_popup.get_child_count() > 0:
					if "Tags" in about_popup.get_child(0).name:
						about_popup.get_child(0).free()
					else: pass

				about_popup.add_child(about_popup_tags.instance(), true)
				if about_popup.get_child_count() > 0:
					about_popup.get_node("Tags").visible = !about_popup.get_node("Tags").visible
				else: pass

				if weakref(about_popup_tags) : pass

			1:
				if about_popup.get_child_count() > 0:
					if "Weeber" in about_popup.get_child(0).name:
						about_popup.get_child(0).free()
					else: pass

				about_popup.add_child(about_popup_weeber.instance(), true)
				if about_popup.get_child_count() > 0:
					about_popup.get_node("Weeber").visible = !about_popup.get_node("Weeber").visible

					var link_btn : LinkButton = about_popup.get_node("Weeber/GithubLinkBtn")
					var link_btn_connection : int = link_btn.connect("pressed", self, "_goto_link", ["https://github.com/MumuNiMochii/Weeber"])
					if link_btn_connection != OK: push_error("An error occurred in signal connection.")
				else: pass

				if weakref(about_popup_weeber) : pass

			3:
				if about_popup.get_child_count() > 0:
					if "Godot" in about_popup.get_child(0).name:
						about_popup.get_child(0).free()
					else: pass

				about_popup.add_child(about_popup_godot.instance(), true)
				if about_popup.get_child_count() > 0:
					about_popup.get_node("Godot").visible = !about_popup.get_node("Godot").visible

					var link_btn : LinkButton = about_popup.get_node("Godot/GodotLinkBtn")
					var link_btn_connection : int = link_btn.connect("pressed", self, "_goto_link", ["https://godotengine.org"])
					if link_btn_connection != OK: push_error("An error occurred in signal connection.")
				else: pass

				if weakref(about_popup_godot) : pass


func _goto_link(link : String) -> void:
	if OS.shell_open(link) != OK: push_error("An error occurred while going to link.")


func initialize_httprequest_signal() -> void:
	# Make HTTPRequest function and connect it for signal
	if $HTTPRequest.connect("request_completed", self, "_on_initial_request_completed") != OK: push_error("An error occurred in signal connection.")
	else: $HTTPRequest.set_use_threads(true)

	if $HTTPRequest.request(
		request_url_post,
		PoolStringArray([
			"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"
		]), true, 0
	) != OK: push_error("An error occurred in the HTTP request.")


func _on_initial_request_completed(_result, _response_code, _headers, body) -> void:
	$HTTPRequest.cancel_request()

	var string_body_result : String = body.get_string_from_utf8()
	var json_parse_result : JSONParseResult = JSON.parse(string_body_result)
	var object : Dictionary = json_parse_result.get_result()

	if "post" in object:
		size = object["post"].size()

		# Disconnect to prevent from being emitted when request_image() is used
		if $HTTPRequest.is_connected("request_completed", self, "_on_initial_request_completed"):
			$HTTPRequest.disconnect("request_completed", self, "_on_initial_request_completed")

#		if OS.is_debug_build() == true: print(JSON.print(object["post"][0], "\t"))

		for an_index in object["post"]:
			var item : Dictionary = {
				"id":str(an_index["id"]),
				"url":an_index["file_url"],
				"view":an_index["preview_url"],
				"tags":an_index["tags"],
				"width":str(an_index["width"]),
				"height":str(an_index["height"]),
				"rating":an_index["rating"],
				"date":an_index["created_at"],
				"score":str(an_index["score"])
			}
			download_list.append(item)

#		if OS.is_debug_build() == true:
#			var string = JSON.print(item, "\t")
#			var object_string_sample : String = JSON.print(object["post"][0], "\t")
#			print(string)
#			print(download_list)
#			print(object_string_sample)

		# Remove the text of no results when request was run again
		if menu.get_parent().get_parent().get_child_count() > 1:
			if menu.get_parent().get_parent().get_child(1).get_child_count() > 1:
				menu.get_parent().get_parent().get_child(1).get_child(0).free()
			else: pass

			menu.get_parent().get_parent().get_child(1).free()
		else: pass

		tags_httprequest_signal()

	else:
		var no_result_container : CenterContainer = CenterContainer.new()
		menu.get_parent().get_parent().add_child(no_result_container, true)

		if menu.get_parent().get_parent().get_child_count() > 1:
			var no_result_text : Label = Label.new()
			menu.get_parent().get_parent().get_child(1).set_name("NoResultContainer")
			menu.get_parent().get_parent().get_child(1).add_child(no_result_text, true)

			if menu.get_parent().get_parent().get_child(1).get_child_count() > 0:
				menu.get_parent().get_parent().get_child(1).get_child(0).set_name("NoResultText")
				menu.get_parent().get_parent().get_child(1).get_child(0).set_text("There are no results.")
			else : pass

			if weakref(no_result_text) : pass
		else : pass

		if weakref(no_result_container) : pass


func tags_httprequest_signal() -> void:
	$HTTPRequest.cancel_request()

	if $HTTPRequest.connect("request_completed", self, "_on_tags_httprequest_signal_completed") != OK:
		push_error("An error occurred in signal connection.")
	else:
		$HTTPRequest.set_use_threads(true)

	if $HTTPRequest.request(
		request_url_tags,
		PoolStringArray([
			"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"
		]), true, 0
	) != OK:
		push_error("An error occurred in the HTTP request.")


func _on_tags_httprequest_signal_completed(_result, _response_code, _headers, body) -> void:
	$HTTPRequest.cancel_request()

	var string_body_result : String = body.get_string_from_utf8()
	var json_parse_result : JSONParseResult = JSON.parse(string_body_result)
	var object : Dictionary = json_parse_result.get_result()

	if $HTTPRequest.is_connected("request_completed", self, "_on_tags_httprequest_signal_completed"):
		$HTTPRequest.disconnect("request_completed", self, "_on_tags_httprequest_signal_completed")

#	if OS.is_debug_build() == true: print(JSON.print(object["tag"], "\t"))

	for an_index in object["tag"]:
		var item : Dictionary = {
			"id":str(an_index["id"]),
			"name":an_index["name"],#.erase(an_index["name"].find("&", an_index["name"].length() - 1), 6),
			"count":str(an_index["count"]),
			"type":str(an_index["type"])
		}
		tags_list.append(item)

	tags_list.sort_custom(CustomSortTagsList, "ascend_by_type")
	tags_list.sort_custom(CustomSortTagsList, "ascend_by_name")

#	for an_index in tags_list.size() - 1:
#		print("Type: "+str(tags_list[an_index]["type"])+", Name: "+tags_list[an_index]["name"])

	for an_index in tags_list.size() - 1:
		# Add HboxContainer as containers for LinkButton (name) and Label (count) of a tag
		var list_tag : HBoxContainer = HBoxContainer.new()
		var list_tag_btn : LinkButton = LinkButton.new()
		var list_tag_num : Label = Label.new()

		list.add_child(list_tag, true)

		if list.get_child_count() > 0:
			list.get_child(an_index).set("custom_constants/separation", 8)

			list.get_child(an_index).add_child(list_tag_btn, true)
			list.get_child(an_index).add_child(list_tag_num, true)

			if list.get_child(an_index).get_child_count() > 0:
				list.get_child(an_index).get_child(0).set_text(tags_list[an_index]["name"])
				list.get_child(an_index).get_child(0).set_underline_mode(LinkButton.UNDERLINE_MODE_NEVER)
				list.get_child(an_index).get_child(1).set_text("("+comma_the_number(int(tags_list[an_index]["count"]))+")")
				list.get_child(an_index).get_child(1).set("custom_colors/font_color", Color("#a0a0a0"))

				match int(tags_list[an_index]["type"]): # Set default font color of tag based from its type
					0: list.get_child(an_index).get_child(0).set("custom_colors/font_color", Color("#337ab7")) # General
					1: list.get_child(an_index).get_child(0).set("custom_colors/font_color", Color("#A00"))    # Artist
					3: list.get_child(an_index).get_child(0).set("custom_colors/font_color", Color("#A0A"))    # Copyright e.g. Pokemon 
					4: list.get_child(an_index).get_child(0).set("custom_colors/font_color", Color("#0A0"))    # Character
					5: list.get_child(an_index).get_child(0).set("custom_colors/font_color", Color("#F80"))    # Metadata e.g. animated
					6: list.get_child(an_index).get_child(0).set("custom_colors/font_color", Color("#000"))    # Unofficial/low count tag

				match int(tags_list[an_index]["type"]): # Set hover font color of tag based from its type
					0: list.get_child(an_index).get_child(0).set("custom_colors/font_color_hover", Color("#337ab7")) # General
					1: list.get_child(an_index).get_child(0).set("custom_colors/font_color_hover", Color("#A00"))    # Artist
					3: list.get_child(an_index).get_child(0).set("custom_colors/font_color_hover", Color("#A0A"))    # Copyright e.g. Pokemon 
					4: list.get_child(an_index).get_child(0).set("custom_colors/font_color_hover", Color("#0A0"))    # Character
					5: list.get_child(an_index).get_child(0).set("custom_colors/font_color_hover", Color("#F80"))    # Metadata e.g. animated
					6: list.get_child(an_index).get_child(0).set("custom_colors/font_color_hover", Color("#000"))    # Unofficial/low count tag

				match int(tags_list[an_index]["type"]): # Set pressed font color of tag based from its type
					0: list.get_child(an_index).get_child(0).set("custom_colors/font_color_pressed", Color("#337ab7")) # General
					1: list.get_child(an_index).get_child(0).set("custom_colors/font_color_pressed", Color("#A00"))    # Artist
					3: list.get_child(an_index).get_child(0).set("custom_colors/font_color_pressed", Color("#A0A"))    # Copyright e.g. Pokemon 
					4: list.get_child(an_index).get_child(0).set("custom_colors/font_color_pressed", Color("#0A0"))    # Character
					5: list.get_child(an_index).get_child(0).set("custom_colors/font_color_pressed", Color("#F80"))    # Metadata e.g. animated
					6: list.get_child(an_index).get_child(0).set("custom_colors/font_color_pressed", Color("#000"))    # Unofficial/low count tag

			else: pass
		else: pass

		if weakref(list_tag) : pass
		if weakref(list_tag_btn) : pass
		if weakref(list_tag_num) : pass

	request_image()


func request_image() -> void:
	if index < size:
		# Allow download if item is under the limit
		if index < request_post_size:
			var request_file_status : int = $HTTPRequest.request(
				download_list[index]["view"],
				PoolStringArray([
					"Accept: image/avif,image/webp,*/*",
					"Accept: video/webm,video/ogg,video/*;q=0.9,application/ogg;q=0.7,audio/*;q=0.6,*/*;q=0.5"
				]), true, 0
			)

			if request_file_status == OK:
				# Emit another signal to get the headers
				if $HTTPRequest.connect("request_completed", self, "_on_file_request_completed") == OK:
					$HTTPRequest.set_use_threads(true)
					$HTTPRequest.set_download_file(preview_path+"/"+download_list[index]["id"]+"."+download_list[index]["view"].get_extension())

					_on_when_resized_menu()


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

		var texture : ImageTexture = ImageTexture.new()
		var image : Image = Image.new()
		var view_image_btn : TextureButton = TextureButton.new()

		menu.add_child(view_image_btn, true)
		menu.get_child(index).set_name(download_list[index]["id"])

		view_image_btn.set_expand(true)
		view_image_btn.set_stretch_mode(TextureButton.STRETCH_KEEP_ASPECT_CENTERED)
		view_image_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		view_image_btn.mouse_filter = Control.MOUSE_FILTER_PASS

		if image.load(preview_path+"/"+download_list[index]["id"]+"."+download_list[index]["view"].get_extension()) == OK:
			texture.create_from_image(image)
			view_image_btn.set_normal_texture(texture)

			# Connect signal to the CustomToolTip of the view_image_btn
			if view_image_btn.connect("mouse_entered", self, "_on_mouse_entered_view_image_btn", [view_image_btn.name]) != OK:
				push_error("An error occurred in signal connection.")

			if view_image_btn.connect("mouse_exited", self, "_on_mouse_exited_view_image_btn") != OK:
				push_error("An error occurred in signal connection.")

		if weakref(texture) : pass
		if weakref(image) : pass

		index += 1
		request_image()


func _on_mouse_entered_tags_list_help_icon() -> void:
	custom_tooltip.add_child(tooltip.instance())
	custom_tooltip.visible = !custom_tooltip.visible

	if custom_tooltip.get_child_count() > 0:
		custom_tooltip.get_child(0).rect_min_size.x = 230
		custom_tooltip.get_child(0)._set_global_position($GUI/Master.get_global_mouse_position())
		custom_tooltip.get_child(0).get_node("Margin/Text").set_bbcode(
			"[b]Information[/b]\n" \
			+ "This list consists of the tags that are available from the loaded images." \
			+ "\nIf the tag is colored black, then it must be an unofficial tag or low in count."
		)

	if weakref(tooltip) : pass


func _on_mouse_exited_tags_list_help_icon() -> void:
	custom_tooltip.visible = !custom_tooltip.visible
	custom_tooltip.get_child(0).free()


func _on_mouse_entered_view_image_btn(id : String) -> void:
	custom_tooltip.add_child(tooltip.instance())
	custom_tooltip.visible = !custom_tooltip.visible

	if custom_tooltip.get_child_count() > 0:
		custom_tooltip.get_child(0).rect_min_size.x = 450
		custom_tooltip.get_child(0)._set_global_position($GUI/Master.get_global_mouse_position())

		for an_image in menu.get_children():
			if an_image.name == id:
				var tags = "[b]Tags:[/b] "+download_list[an_image.get_index()]["tags"] \
				+"\n\n[b]ID:[/b] "+download_list[an_image.get_index()]["id"] \
				+"\n[b]Rating:[/b] "+download_list[an_image.get_index()]["rating"] \
				+"\n[b]Score:[/b] "+download_list[an_image.get_index()]["score"] \
				+"\n[b]Size:[/b] "+download_list[an_image.get_index()]["width"]+"x"+download_list[an_image.get_index()]["height"] \
				+"\n[b]Date:[/b] "+download_list[an_image.get_index()]["date"]
				custom_tooltip.get_child(0).get_node("Margin/Text").set_bbcode(tags)

	if weakref(tooltip) : pass


func _on_mouse_exited_view_image_btn() -> void:
	custom_tooltip.visible = !custom_tooltip.visible
	custom_tooltip.get_child(0).free()


func _on_when_resized_menu() -> void:
#	print("menu.x: "+str(menu.rect_size.x)+", image.x: "+str(ceil(menu.rect_size.x / 6)))

	for an_image in menu.get_children():
		an_image.set_custom_minimum_size(Vector2((menu.rect_size.x / 6), 200))

	menu.rect_size.x = menu.get_parent().rect_size.x - 8
# warning-ignore:narrowing_conversion
	menu.add_constant_override("hseparation", (menu.rect_size.x / 6) - (menu.rect_size.x / 6) * 0.8)
	menu.add_constant_override("vseparation", 8)


func comma_the_number(number : int) -> String:
	var text : String = str(number)
	var modulus : int = text.length() % 3
	var result : String = ""

	for an_index in range(0, text.length()):
		if an_index != 0 and an_index % 3 == modulus:
			result += ","
		result += text[an_index]

	return result
