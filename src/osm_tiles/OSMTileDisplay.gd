@tool
class_name OSMTileDisplay extends Control

@export var tile_manager: OSMTileManager:
	set(new_value):
		if tile_manager != null:
			tile_manager.tile_request_completed.disconnect(_on_tile_request_completed)
		tile_manager = new_value
		if tile_manager != null:
			tile_manager.tile_request_completed.connect(_on_tile_request_completed)
		update_tiles()

@export var geo_center: GeoLocation = GeoLocation.new():
	set(new_value):
		if new_value == geo_center:
			return
		if new_value == null:
			new_value = GeoLocation.new()
		if geo_center != null:
			geo_center.changed.disconnect(update_viewport)
		geo_center = new_value
		if geo_center != null:
			geo_center.changed.connect(update_viewport)
		update_viewport()

@export_range(0, 19) var zoom: float = 0:
	set(new_value):
		if new_value != zoom:
			zoom = clampf(new_value, 0, 19)
			update_viewport()
			
@export var highlighted_boundary: GeoBoundary:
	set(new_value):
		if highlighted_boundary != null:
			highlighted_boundary.changed.disconnect(queue_redraw)
		highlighted_boundary = new_value
		if highlighted_boundary != null:
			highlighted_boundary.changed.connect(queue_redraw)
		queue_redraw()
			
enum GizmoOption {
	OFF, ON, ON_WITH_LABEL
}

@export_group("Labels", "label_")
@export var label_offset: Vector2 = Vector2(4, 4):
	set(new_value): label_offset = new_value; queue_redraw()
@export var label_text_margin: Vector2 = Vector2(2, 0):
	set(new_value): label_text_margin = new_value; queue_redraw()

@export_group("Gizmos", "gizmo_option_")
@export var gizmo_option_grid: GizmoOption = GizmoOption.ON_WITH_LABEL:
	set(new_value): gizmo_option_grid = new_value; queue_redraw()
@export var gizmo_option_center: GizmoOption = GizmoOption.ON_WITH_LABEL:
	set(new_value): gizmo_option_center = new_value; queue_redraw()
@export var gizmo_option_cursor: GizmoOption = GizmoOption.OFF:
	set(new_value): gizmo_option_cursor = new_value; queue_redraw()
@export var gizmo_option_location_highlight: GizmoOption = GizmoOption.OFF:
	set(new_value): gizmo_option_location_highlight = new_value; queue_redraw()
@export var gizmo_option_boundary_higlight: GizmoOption = GizmoOption.OFF:
	set(new_value): gizmo_option_boundary_higlight = new_value; queue_redraw()
@export var gizmo_option_tiles: GizmoOption = GizmoOption.OFF:
	set(new_value): gizmo_option_tiles = new_value; queue_redraw()
@export_subgroup("Color", "gizmo_color_")
@export var gizmo_color_grid: Color = Color.BLACK:
	set(new_value): gizmo_color_grid = new_value; queue_redraw()
@export var gizmo_color_center: Color = Color.DARK_SLATE_GRAY:
	set(new_value): gizmo_color_center = new_value; queue_redraw()
@export var gizmo_color_cursor: Color = Color.DARK_SLATE_BLUE:
	set(new_value): gizmo_color_cursor = new_value; queue_redraw()
@export var gizmo_color_location_highlight: Color = Color.BLACK:
	set(new_value): gizmo_color_location_highlight = new_value; queue_redraw()
@export var gizmo_color_boundary_higlight: Color = Color.BROWN:
	set(new_value): gizmo_color_boundary_higlight = new_value; queue_redraw()
@export var gizmo_color_tiles: Color = Color(0, 0, 0, 0.25):
	set(new_value): gizmo_color_tiles = new_value; queue_redraw()

@export_group("Other")
@export var draw_center_offset: Vector2 = Vector2(0, 0):
	set(new_value):
		if new_value != draw_center_offset:
			draw_center_offset = new_value
			update_viewport()
@export var loading_texture: Texture2D:
	set(new_value):
		if new_value != loading_texture:
			loading_texture = new_value
			update_viewport()

@export_group("Debug")
@export var trigger_redraw: bool = false:
	set(new_value): if new_value == true: queue_redraw()
	
func _init():
	if geo_center != null:
		geo_center.changed.connect(update_viewport)
	resized.connect(update_viewport)
	
func _ready():
	update_viewport()
	
var dragging := false
	
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom -= 0.1 #zoom *= 0.95
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom += 0.1 #zoom /= 0.95
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
			else:
				dragging = false
	if event is InputEventMouseMotion:
#		var info := DebugInfo.get_slot("_gui_input / InputEventMouseMotion")
#		info.add_line("local_mouse_position = " + str(get_local_mouse_position()))
#		info.add_line("geo_location = " + str(geo_to_gui.reverse(get_local_mouse_position())))
		if gizmo_option_cursor != GizmoOption.OFF:
			queue_redraw()
		if dragging:
			var gui_center := geo_to_gui.project(geo_center)
			#print("[drag from] " + str(geo_center) + " -> " + str(gui_center))
			gui_center -= event.relative
			geo_center.update_from(geo_to_gui.reverse(gui_center))
			#print("[drag to] " + str(gui_center) + " -> " + str(geo_center))

func highlight_boundary(boundary: GeoBoundary):
	highlighted_boundary = boundary.duplicate()
	
func zoom_to_region(region: GeoBoundary):
	var p_from := geo_to_gui.project(region.from_loc())
	var p_to := geo_to_gui.project(region.to_loc())
	var p_center := (p_from + p_to) / 2
	geo_center = geo_to_gui.reverse(p_center)
	var p_min := Vector2(min(p_from.x, p_to.x), min(p_from.y, p_to.y))
	var p_max := Vector2(max(p_from.x, p_to.x), max(p_from.y, p_to.y))
	var current_rect_size = p_max - p_min
	var needed_rect_size_y = 0.8 * size.y
	var needed_rect_size_x = 0.8 * size.x
	var needed_scale = needed_rect_size_y / current_rect_size.y
	if (current_rect_size * needed_scale).x > needed_rect_size_x:
		needed_scale = needed_rect_size_x / current_rect_size.x
	var needed_zoom = _log_n(2, needed_scale)
	print("needed_scale = %0.7f, needed_zoom = %0.7f" % [needed_scale, needed_zoom])
	#zoom = floor(zoom + needed_zoom)
	zoom += needed_zoom
	
func _log_n(n: float, x: float):
	return log(x) / log(n)

class LabelRequest:
	var text: String
	var color: Color
	var background: bool
	var anchors: PackedVector2Array
	var horizontal_aligments: Array[HorizontalAlignment]
	var vertical_aligments: Array[VerticalAlignment]
	var text_aligments: Array[HorizontalAlignment]
	var label_offsets: PackedVector2Array
	var _bounds: Array[Rect2]
	var _possible: Array[bool]
	func _init(text: String, color: Color, background = true):
		self.text = text
		self.color = color
		self.background = background
	func add_anchor(anchor: Vector2, horizontal_aligment: HorizontalAlignment, vertical_aligment: VerticalAlignment, label_offset: Vector2 = Vector2(1, 1), text_aligment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT):
		anchors.append(anchor)
		horizontal_aligments.append(horizontal_aligment)
		vertical_aligments.append(vertical_aligment)
		label_offsets.append(label_offset)
		text_aligments.append(text_aligment)
	
func _draw_gizmo_center() -> Array[LabelRequest]:
	var gizmo_color := gizmo_color_center
	draw_line(Vector2(draw_center.x, 0), Vector2(draw_center.x, size.y), gizmo_color, -1, false)
	draw_line(Vector2(0, draw_center.y), Vector2(size.x, draw_center.y), gizmo_color, -1, false)
	
	var label_text := "%.7f°, %.7f°" % [ geo_center.lat, geo_center.lon ]
	var label_request := LabelRequest.new(label_text, gizmo_color)
	label_request.add_anchor(Vector2(draw_center.x, 0), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP)
	return [label_request]
	
func _draw_gizmo_cursor() -> Array[LabelRequest]:
	var gizmo_color := gizmo_color_cursor
	var cursor_position_gui = get_local_mouse_position()
	draw_line(Vector2(cursor_position_gui.x, 0), Vector2(cursor_position_gui.x, size.y), gizmo_color, -1, false)
	draw_line(Vector2(0, cursor_position_gui.y), Vector2(size.x, cursor_position_gui.y), gizmo_color, -1, false)
	
	var cursor_position_geo = geo_to_gui.reverse(cursor_position_gui)
	var label_text := "%.7f°, %.7f°" % [ cursor_position_geo.lat, cursor_position_geo.lon ]
	var label_request := LabelRequest.new(label_text, gizmo_color)
	label_request.add_anchor(cursor_position_gui, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_BOTTOM)
	return [label_request]

func _draw_gizmo_boundary_highlight() -> Array[LabelRequest]:
	if highlighted_boundary == null:
		return []
	var gizmo_color := gizmo_color_boundary_higlight
	var min_geo = highlighted_boundary.min_loc()
	var max_geo = highlighted_boundary.max_loc()
	var bottom_left_gui = geo_to_gui.project(min_geo)
	var top_right_gui = geo_to_gui.project(max_geo)
	var p: PackedVector2Array = [
		Vector2(bottom_left_gui.x, bottom_left_gui.y),
		Vector2(bottom_left_gui.x, top_right_gui.y),
		Vector2(top_right_gui.x, top_right_gui.y),
		Vector2(top_right_gui.x, bottom_left_gui.y),
		Vector2(bottom_left_gui.x, bottom_left_gui.y),
	]
	draw_polyline(p, gizmo_color, -1, false)

	var label_requests: Array[LabelRequest] = []
		
	var label_text := "%.7f°, %.7f°x" % [ min_geo.lat, min_geo.lon ]
	var label_request := LabelRequest.new(label_text, gizmo_color)
	label_request.add_anchor(bottom_left_gui, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, Vector2(0, 1))
	label_requests.append(label_request)
	
	label_text = "%.7f°, %.7f°" % [ max_geo.lat, max_geo.lon ]
	label_request = LabelRequest.new(label_text, gizmo_color)
	label_request.add_anchor(top_right_gui, HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_BOTTOM, Vector2(0, 1))
	label_requests.append(label_request)
	
	return label_requests

func _draw_gizmo_tiles() -> Array[LabelRequest]:
	var tile_rect := Rect2(Vector2.ZERO, tile_size_px * draw_scale)
	var gizmo_color = gizmo_color_tiles
	var label_requests: Array[LabelRequest] = []
	for i in tile_viewport.size.x:
		for j in tile_viewport.size.y: 
			tile_rect.position = (draw_center - draw_offset) + tile_rect.size * Vector2(tile_viewport.position.x + i, tile_viewport.position.y + j)
			draw_rect(tile_rect, gizmo_color, false, -1)
			var label_text = "%d, %d\n(x%d)" \
				% [tile_viewport.position.x + i, tile_viewport.position.y + j, zoom_level]
			var label_request := LabelRequest.new(label_text, gizmo_color_tiles, false)
			label_request.add_anchor(tile_rect.position + tile_rect.size / 2, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, Vector2(1, 1), HORIZONTAL_ALIGNMENT_CENTER)
			label_requests.append(label_request)
	return label_requests

func _draw_gizmos() -> Array[LabelRequest]:
	var label_requests: Array[LabelRequest] = []
	if gizmo_option_center != GizmoOption.OFF:
		var gizmo_label_requests = _draw_gizmo_center()
		if gizmo_option_center == GizmoOption.ON_WITH_LABEL:
			label_requests.append_array(gizmo_label_requests)
	if gizmo_option_cursor != GizmoOption.OFF:
		var gizmo_label_requests = _draw_gizmo_cursor()
		if gizmo_option_cursor == GizmoOption.ON_WITH_LABEL:
			label_requests.append_array(gizmo_label_requests)
	if gizmo_option_boundary_higlight != GizmoOption.OFF:
		var gizmo_label_requests = _draw_gizmo_boundary_highlight()
		if gizmo_option_boundary_higlight == GizmoOption.ON_WITH_LABEL:
			label_requests.append_array(gizmo_label_requests)
	if gizmo_option_tiles != GizmoOption.OFF:
		var gizmo_label_requests = _draw_gizmo_tiles()
		if gizmo_option_tiles == GizmoOption.ON_WITH_LABEL:
			label_requests.append_array(gizmo_label_requests)
	return label_requests

func _draw_labels(label_requests: Array[LabelRequest]):
	var font := get_theme_font("font", "Label")
	var font_size := get_theme_font_size("font_size", "Label")
	
	for r in label_requests:
		var text_size := font.get_multiline_string_size(r.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		text_size.y = text_size.y - font.get_height(font_size) + font.get_ascent(font_size) + font.get_descent(font_size)
		r._bounds.resize(r.anchors.size())
		for i in r.anchors.size():
			r._bounds[i] = Rect2(Vector2(), text_size + 2 * label_text_margin)
			match r.horizontal_aligments[i]:
				HORIZONTAL_ALIGNMENT_CENTER, HORIZONTAL_ALIGNMENT_FILL:
					r._bounds[i].position.x = r.anchors[i].x - text_size.x / 2
				HORIZONTAL_ALIGNMENT_RIGHT:
					r._bounds[i].position.x = r.anchors[i].x - text_size.x - label_offset.x * r.label_offsets[i].x - 2 * label_text_margin.x
				HORIZONTAL_ALIGNMENT_LEFT, _:
					r._bounds[i].position.x = r.anchors[i].x + label_offset.x * r.label_offsets[i].x
			match r.vertical_aligments[i]:
				VERTICAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_FILL:
					r._bounds[i].position.y = r.anchors[i].y - text_size.y / 2
				VERTICAL_ALIGNMENT_BOTTOM:
					r._bounds[i].position.y = r.anchors[i].y - text_size.y - label_offset.y * r.label_offsets[i].y - 2 * label_text_margin.y
				VERTICAL_ALIGNMENT_TOP, _:
					r._bounds[i].position.y = r.anchors[i].y + label_offset.y * r.label_offsets[i].y
	for r in label_requests:
		r._possible.resize(r.anchors.size())
		r._possible.fill(true)
	# Here a mechanism can be implemented to:
	# - choose from possible positioning to avoid lable overlap
	# - modify bound to keep on screen
	# (Later can be extended:
	# - for any other labels label (not just gizmos)
	# - importance can be introduced to labels to high low prio oes if screen is too crowded)
	# - possibility to define polyline and area also for possible positioning
	# Following cycle chooses the first possible anchor (if any) for each label
	var line_height := font.get_height(font_size)
	for r in label_requests:
		for i in r.anchors.size():
			if r._possible[i]:
				if r.background:
					var background_color = Color(r.color)
					background_color.a /= 3
					draw_rect(r._bounds[i], background_color) 
				var text_size := font.get_multiline_string_size(r.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
				draw_multiline_string(font, r._bounds[i].position + label_text_margin + Vector2(0, font.get_ascent(font_size)),
					r.text, r.text_aligments[i], text_size.x, font_size, -1, r.color) 
				break

func _draw():
	#print("[_draw] tile_textures.size = " + str(tile_textures.size()))
	var tile_rect := Rect2(Vector2.ZERO, tile_size_px * draw_scale)
	for j in tile_viewport.size.y: 
		#print("[_draw] tile_textures[" + str(j) +"].size = " + str(tile_textures[j].size()))
		for i in tile_viewport.size.x:
			tile_rect.position = (draw_center - draw_offset) + tile_rect.size * Vector2(tile_viewport.position.x + i, tile_viewport.position.y + j)
			var texture = tile_textures[j][i]
			if texture == null:
				texture = loading_texture
			var draw_rect := Rect2(tile_rect.position, tile_rect.size)
			var src_rect := Rect2(0, 0, 256, 256)
			if texture != null:
#				draw_lcd_texture_rect_region(texture, draw_rect, src_rect)
				draw_texture_rect(texture, draw_rect, false)
	var label_requests := _draw_gizmos()
	_draw_labels(label_requests)

var tile_size_px := Vector2(256, 256)

var zoom_level: int

var draw_center: Vector2 = Vector2()
var draw_offset: Vector2 = Vector2()
var draw_scale: float
	
var tile_viewport: Rect2i

var geo_to_gui: WebMercatorProjection = WebMercatorProjection.new()

func str_rect(rect: Rect2) -> String:
	return str(rect.position) + "..." + str(rect.end)

func _calc_viewport():
	var info: DebugInfoSlot # DEBUG
	
	if geo_center.lat < WebMercatorProjection.min_lat:
		geo_center.lat = WebMercatorProjection.min_lat
	if geo_center.lat > WebMercatorProjection.max_lat:
		geo_center.lat = WebMercatorProjection.max_lat
		
	zoom_level = int(ceil(zoom))
	var grid_size := int(pow(2, zoom_level))
	draw_scale = pow(2, zoom - zoom_level)
	
#	info = DebugInfo.get_slot("OSMTileDisplay._calc_viewport / Zoom") # DEBUG
#	info.add_line("zoom = " + str(zoom)) # DEBUG
#	info.add_line(" -> zoom_level = " + str(zoom_level) + " (grid_size = " + str(grid_size) + ")") # DEBUG
#	info.add_line(" -> draw_scale = " + str(draw_scale)) # DEBUG
		
	draw_center = size / 2 + draw_center_offset

	var bounds_normalized := Rect2(Vector2.ZERO, Vector2.ONE)
	var bounds_normalized_flipped := Rect2(
		Vector2(bounds_normalized.position.x, bounds_normalized.end.y),
		Vector2(bounds_normalized.size.x, -bounds_normalized.size.y))
	var q = pow(2, zoom)
	var bounds_tiles := Rect2(bounds_normalized_flipped.position * q, bounds_normalized_flipped.size * q)
	var bounds_px := Rect2(bounds_tiles.position * tile_size_px, bounds_tiles.size * tile_size_px)

	var projection := WebMercatorProjection.new()
	projection.bounds = bounds_px
	draw_offset = projection.project(geo_center)
	
	var bounds_gui := Rect2(bounds_px.position + draw_center - bounds_px.size.abs() / 2, bounds_px.size)
	bounds_gui = Rect2(bounds_px.position + draw_center - draw_offset, bounds_px.size)
	geo_to_gui.bounds = bounds_gui
	
#	info = DebugInfo.get_slot("OSMTileDisplay._calc_viewport / Projection bounds", true, 0) # DEBUG
#	info.add_line("bounds_normalized = " + str_rect(bounds_normalized)) # DEBUG
#	info.add_line("bounds_normalized_flipped = " + str_rect(bounds_normalized_flipped)) # DEBUG
#	info.add_line("bounds_tiles = " + str_rect(bounds_tiles)) # DEBUG
#	info.add_line("bounds_px = " + str_rect(bounds_px)) # DEBUG
#	info.add_line("draw_center = " + str(draw_center)) # DEBUG
#	info.add_line("draw_offset = " + str(draw_offset)) # DEBUG
#	info.add_line("bounds_gui = " + str_rect(bounds_gui)) # DEBUG

#	projection.bounds = bounds_normalized # DEBUG
#	var projected_center_normalized := projection.project(geo_center) # DEBUG
#	projection.bounds = bounds_normalized_flipped # DEBUG
#	var projected_center_normalized_flipped := projection.project(geo_center) # DEBUG
#	projection.bounds = bounds_tiles # DEBUG
#	var projected_center_tile := projection.project(geo_center) # DEBUG
#	projection.bounds = bounds_px
#	var projected_center_px := projection.project(geo_center)
#	projection.bounds = bounds_gui # DEBUG
#	var projected_center_gui := projection.project(geo_center) # DEBUG
	
#	info = DebugInfo.get_slot("OSMTileDisplay._calc_viewport / Center projection") # DEBUG
#	info.add_line("projected_center_normalized = " + str(projected_center_normalized)) # DEBUG
#	info.add_line("projected_center_normalized_flipped = " + str(projected_center_normalized_flipped)) # DEBUG
#	info.add_line("projected_center_tile = " + str(projected_center_tile)) # DEBUG
#	info.add_line("projected_center_px = " + str(projected_center_px)) # DEBUG
#	info.add_line("projected_center_gui = " + str(projected_center_gui)) # DEBUG
		
	var draw_rect_px := Rect2(Vector2.ZERO, size)
	var viewport_rect_px := Rect2(draw_rect_px.position - draw_center + draw_offset, draw_rect_px.size)
	var viewport_rect_tile := Rect2(viewport_rect_px.position / (tile_size_px * draw_scale), viewport_rect_px.size / (tile_size_px * draw_scale))
	var tile_from := Vector2i(floor(viewport_rect_tile.position.x), floor(viewport_rect_tile.position.y))
	var tile_until := Vector2i(ceil(viewport_rect_tile.end.x), ceil(viewport_rect_tile.end.y))
	var viewport_rect_tile_int := Rect2i(tile_from, tile_until - tile_from)
	tile_from = Vector2i(max(tile_from.x, 0), max(tile_from.y, 0))
	tile_until = Vector2i(min(tile_until.x, grid_size), min(tile_until.y, grid_size))
	var viewport_rect_tile_clamped := Rect2i(tile_from, tile_until - tile_from)
	
	tile_viewport = viewport_rect_tile_clamped
	
#	info = DebugInfo.get_slot("OSMTileDisplay._calc_viewport / View") # DEBUG
#	info.add_line("draw_rect_px = " + str_rect(draw_rect_px)) # DEBUG
#	info.add_line("draw_center_px = " + str(draw_center_px)) # DEBUG
#	info.add_line("viewport_rect_px = " + str_rect(viewport_rect_px)) # DEBUG
#	info.add_line("viewport_rect_tile = " + str_rect(viewport_rect_tile)) # DEBUG
#	info.add_line("viewport_rect_tile_int = " + str(viewport_rect_tile_int)) # DEBUG
#	info.add_line("viewport_rect_tile_clamped = " + str(viewport_rect_tile_clamped)) # DEBUG

var work_tile_image := Image.new()
var tile_textures := Array()
var tile_requests := Dictionary()

func _update_tile_textures():
	var max_tile_count = Vector2i(int(size.x / (tile_size_px.x * 0.5)) + 2, int(size.y / (0.5 * tile_size_px.y)) + 2)
	#print("[_update_tile_textures] max_tile_count = " + str(max_tile_count))
	tile_textures.resize(max_tile_count.y)
	for j in tile_textures.size():
		if tile_textures[j] == null:
			tile_textures[j] = Array()
		tile_textures[j].resize(max_tile_count.x)
	if tile_manager != null:
		for request_id in tile_requests:
			tile_manager.cancel_tile_request(request_id)
		tile_requests.clear()
		for j in tile_viewport.size.y:
			for i in tile_viewport.size.x:
				var tile_x = tile_viewport.position.x + i
				var tile_y = tile_viewport.position.y + j
				#print("[_update_tile_textures] i,j = %d,%d - x,y = %d,%d" % [i, j, tile_x, tile_y])
				if tile_manager.load_tile(work_tile_image, zoom_level, tile_x, tile_y) == OK:
					#print("[_update_tile_textures] load OK")
					if tile_textures[j][i] == null:
						tile_textures[j][i] = ImageTexture.create_from_image(work_tile_image)
					else:
						tile_textures[j][i].update(work_tile_image)
				else:
					#print("[_update_tile_textures] request needed")
					var request_id = tile_manager.request_tile(zoom_level, tile_x, tile_y)
					tile_textures[j][i] = null
					tile_requests[request_id] = Vector2i(i, j)
	pass

func _on_tile_request_completed(id: int, error: Error):
	if not tile_requests.has(id):
		return
	var tile_index = tile_requests[id]
	var tile_x = tile_viewport.position.x + tile_index.x
	var tile_y = tile_viewport.position.y + tile_index.y
	if tile_manager.load_tile(work_tile_image, zoom_level, tile_x, tile_y) == OK:
		if tile_textures[tile_index.y][tile_index.x] == null:
			tile_textures[tile_index.y][tile_index.x] = ImageTexture.create_from_image(work_tile_image)
		else:
			tile_textures[tile_index.y][tile_index.x].update(work_tile_image)
	tile_requests.erase(id)
	queue_redraw()

func update_viewport():
	_calc_viewport()
	update_tiles()
	
func update_tiles():
	_update_tile_textures()
	queue_redraw()
	
func _process(delta):
	if Engine.is_editor_hint():
		var tile_manager = get_node_or_null(get_meta("_editor_prop_ptr_tile_manager"))
		if tile_manager != self.tile_manager:
			self.tile_manager = tile_manager
