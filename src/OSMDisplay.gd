@tool
class_name OSMDisplay extends Control

@export var osm_data: OSMData :
	set(value):
		if osm_data != null:
			osm_data.changed.disconnect(_on_osm_data_changed)
		osm_data = value
		if osm_data != null:
			osm_data.rebuild_hashmaps()
			osm_data.changed.connect(_on_osm_data_changed)

@export var draw_scale: float = 1:
	set(value):
		draw_scale = value
		queue_redraw()
@export var draw_offset: Vector2 = Vector2.ZERO:
	set(value):
		draw_offset = value
		queue_redraw()

@export_category("Debug")
@export var trigger_draw: bool = false:
	set(value):
		if value == true:
			queue_redraw()
@export var center_offset: bool = false:
	set(value):
		if value == true:
			if osm_data != null:
				var map_boundary = osm_data.get_boundary()
				draw_offset = (map_boundary.min_loc().to_vector2() + map_boundary.max_loc().to_vector2()) / 2
@export var way_draw_limit: int = -1:
	set(value):
		way_draw_limit = value
		queue_redraw()
		
func _ready():
	pass
		
func _draw():
	var draw_transform = Transform2D(0, Vector2(draw_scale, -draw_scale), 0, draw_offset)
	var drawn_way_count = 0
	for way in osm_data.ways:
		var sections: Array[PackedVector2Array] = []
		var points: PackedVector2Array
		var prev_node: OSMNode = null
		for i in way.node_ids.size():
			var node: OSMNode = osm_data.get_node_by_id(way.node_ids[i])
			#print("way = " + str(way.id) + ", node = " + str(way.node_ids[i]) + " " + ("(*)" if node == null else str(node.location)))
			if node != null:
				if prev_node == null:
					points = PackedVector2Array()
					sections.append(points)
				points.append(node.location.to_vector2() * draw_transform)
			prev_node = node
		var any_section_drawn = false
		for section in sections:
			if section.size() < 2:
				continue
			#print("section = " + str(section) + ", way = " + str(way.id) + " (#" + str(drawn_way_count + 1) + ")")
			draw_polyline(section, Color.WHITE, 1, true)
			any_section_drawn = true
		if any_section_drawn:
			drawn_way_count += 1
			if way_draw_limit >= 0 and drawn_way_count >= way_draw_limit:
				break
			

func _on_osm_data_changed():
	queue_redraw()
