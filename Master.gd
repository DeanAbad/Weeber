extends Node

# Request url & api
const base_url : String = "https://gelbooru.com/index.php?"
var request_api : String = "page=dapi&s=post&q=index"
var request_key : String = "&api_key=8ab7ebb52c422eed978168195d24ac54856447855f7676169517683bf7847839&user_id=918696"
var request_list_size : int = 6
var request_options : String = "&limit="+str(request_list_size)+"&pid=0&json=1"
var request_url : String = base_url+request_api+request_key+request_options

# Download queue
var download_list : Array = []
var index : int = 0


func _ready() -> void:
	var signal_connection : int = $HTTPRequest.connect("request_completed", self, "_on_initial_request_completed")
	if signal_connection != OK:
		push_error("An error occurred in signal connection.")
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
		download_list.append(an_index["file_url"])

#	if OS.is_debug_build() == true:
#		var object_string_sample : String = JSON.print(object["post"][0], "\t")
#		print(download_list)
#		print(object_string_sample)

	request_image()


func request_image() -> void:
	# Allow download if item is under the limit
	if index < request_list_size:
		var request_file_status : int = $HTTPRequest.request(
			download_list[index],
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
				$HTTPRequest.set_download_file("user://"+download_list[index].get_extension()+str(index)+"."+download_list[index].get_extension())
	else:
		print("Download queue completed.")
		get_tree().quit()


func _on_file_request_completed(_result, _response_code, headers, _body) -> void:
	var content_length_result : String = headers[3] # Content-Length key-value pair
	content_length_result.erase(0, 16)
	var file_size : int = int(content_length_result)
	var file_size_string : String = String.humanize_size(file_size)

	if OS.is_debug_build() == true:
		print(headers[3])
		print("Removed string: "+content_length_result)
		print("Integer: "+str(file_size))
		print(file_size_string)

	if $HTTPRequest.get_downloaded_bytes() == file_size:
		print("Download size "+file_size_string+" reached.")
		$HTTPRequest.cancel_request()

		if $HTTPRequest.is_connected("request_completed", self, "_on_file_request_completed"):
			$HTTPRequest.disconnect("request_completed", self, "_on_file_request_completed")

			index += 1
			request_image()
