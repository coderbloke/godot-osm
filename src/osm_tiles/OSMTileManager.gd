@tool
class_name OSMTileManager extends HTTPRequest

@export var base_url: String = "https://tile.openstreetmap.org"
@export var url_suffix: String = ""

@export var max_cache_size_mb: int = 64
@export_global_dir var cache_path: String = "res://osm_tile_cache"
@export var cache_update_time_days: float = 1
@export var cache_remove_time_days: float = 30

class TileRequest:
	var id: int
	var zoom_level: int
	var x: int
	var y: int
	func _init(id: int, zoom_level: int, x: int, y: int):
		self.id = id
		self.zoom_level = zoom_level
		self.x = x
		self.y = y
	
var next_tile_request_id: int = 0
var tile_request_queue: Array[TileRequest] = []
var tile_request_in_progress: TileRequest

signal tile_request_completed(id: int, error: Error)

func _init():
	request_completed.connect(_http_request_completed)
	
func get_tile_id(zoom_level: int, x: int, y: int) -> String:
	return "%d_%d_%d" % [zoom_level, x, y]

func get_cache_file_name(zoom_level: int, x: int, y: int) -> String:
	return get_tile_id(zoom_level, x, y) + ".png"

func get_cache_file_path(zoom_level: int, x: int, y: int) -> String:
	return cache_path + "/" + get_cache_file_name(zoom_level, x, y)

func get_tile_url(zoom_level: int, x: int, y: int) -> String:
	return "%s/%d/%d/%d.png" % [base_url, zoom_level, x, y]
	
func is_tile_available(zoom_level: int, x: int, y: int) -> bool:
	var cache_file_name := get_cache_file_path(zoom_level, x, y)
	var cache_file_path := get_cache_file_path(zoom_level, x, y)
	if not FileAccess.file_exists(cache_file_path):
		print("[is_tile_available] No such file (%s)" % cache_file_name)
		return false
	var current_time := Time.get_unix_time_from_system() + float(Time.get_time_zone_from_system()["bias"] * 60)
	var last_update_time := FileAccess.get_modified_time(cache_file_path)
	var file_age := current_time - last_update_time
	var cache_update_time_sec = cache_update_time_days * 24 * 60 * 60
	if file_age >= cache_update_time_sec:
		print("[is_tile_available] Out-of-date file (%s, cached = %s, current = %s)" \
			% [cache_file_name, Time.get_datetime_string_from_unix_time(last_update_time), \
			Time.get_datetime_string_from_unix_time(current_time)])
		return false
	return true
	
func load_cached_tile(image: Image, zoom_level: int, x: int, y: int) -> Error:
	var cache_file_path := get_cache_file_path(zoom_level, x, y)
	var buffer := FileAccess.get_file_as_bytes(cache_file_path)
	return image.load_png_from_buffer(buffer)
	
func load_tile(image: Image, zoom_level: int, x: int, y: int) -> Error:
	if is_tile_available(zoom_level, x, y):
		return load_cached_tile(image, zoom_level, x, y)
	else:
		return ERR_UNAVAILABLE
		
func request_matches(request: TileRequest, zoom_level: int, x: int, y: int) -> bool:
	return request.zoom_level == zoom_level and request.x == x and request.y == y
		
func request_tile(zoom_level: int, x: int, y: int) -> int:
	var new_request := TileRequest.new(next_tile_request_id, zoom_level, x, y)
	tile_request_queue.append(new_request)
	next_tile_request_id += 1
	try_next_request()
	return new_request.id
	
func cancel_tile_request(request_id: int):
	var request
	if tile_request_in_progress != null and tile_request_in_progress.id == request_id:
		request = tile_request_in_progress
	else:
		for r in tile_request_queue:
			if r.id == request_id:
				request = r
				break
#	if request != null:
#		print("[cancel_tile_request] " + str(get_cache_file_name(request.zoom_level, request.x, request.y))
#		+ (" (already in progress)" if request == tile_request_in_progress else ""))
#	else:
#		print("[cancel_tile_request] ??? (" + str(request_id) + ")")
	tile_request_queue.erase(request)
	
func _process(delta):
	try_next_request() # For sure, for the case, something broke the cycle
	
func try_next_request():
	if tile_request_queue.size() == 0: return
	# Uncomment below check, if it stucked in for some reason (e.g. aborted functions due to error during dev)
	if tile_request_in_progress != null: return
	var next_request := tile_request_queue[0]
	var client_busy := (get_http_client_status() == HTTPClient.STATUS_RESOLVING \
		or get_http_client_status() == HTTPClient.STATUS_CONNECTING \
		or get_http_client_status() == HTTPClient.STATUS_REQUESTING) \
		or get_http_client_status() == HTTPClient.STATUS_BODY
	if client_busy:
		return
	var url := get_tile_url(next_request.zoom_level, next_request.x, next_request.y)
	print(url)
	if request(url) == OK:
		if tile_request_in_progress != null:
			tile_request_completed.emit(tile_request_in_progress, FAILED)
		tile_request_in_progress = next_request
		tile_request_queue.remove_at(0)
		
func _http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != RESULT_SUCCESS:
		tile_request_completed.emit(tile_request_in_progress.id, FAILED)
	if response_code != HTTPClient.RESPONSE_OK:
		tile_request_completed.emit(tile_request_in_progress.id, FAILED)
	var file_path = get_cache_file_path(tile_request_in_progress.zoom_level,
		tile_request_in_progress.x, tile_request_in_progress.y)
	var folder_path = file_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(folder_path)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	file.store_buffer(body)
	file.close()
	tile_request_completed.emit(tile_request_in_progress.id, OK)
	var same_requests_in_queue: Array[TileRequest] = []
	for request_in_queue in tile_request_queue:
		if request_matches(request_in_queue, tile_request_in_progress.zoom_level, tile_request_in_progress.x, tile_request_in_progress.y):
			same_requests_in_queue.append(request_in_queue)
	for same_request in same_requests_in_queue:
		tile_request_completed.emit(same_request.id, OK)
		tile_request_queue.erase(same_request)
	tile_request_in_progress = null
	try_next_request()
