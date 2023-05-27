@tool
class_name OverpassClient extends ExtendedHTTPRequest

const DEFAULT_URL = "https://overpass.openstreetmap.ru/api/interpreter"
@export var base_url: String = DEFAULT_URL

@export var query_builder: OverpassQueryBuilder = OverpassQueryBuilder.new()
@export var compact_query: bool = true

signal query_completed(result: Dictionary)

func _init():
	request_completed.connect(_on_request_completed)
	
func get_query_url(query: OverpassQuery) -> String:
	var script := query_builder.get_overpass_ql_script(query, compact_query)
	return get_url_with_query(base_url, "", { "data" : script })

static func _print_log(message: String):
	print("[OverpassClient] (%.3f) %s" % [float(Time.get_ticks_msec()) / 1000.0, message])
	
func query(query: OverpassQuery) -> Error:
	_print_log("Requesting data...")
	return request(get_query_url(query), [], HTTPClient.Method.METHOD_GET, "")
		
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result == Result.RESULT_SUCCESS and response_code == HTTPClient.RESPONSE_OK:
		_print_log("Response arrived. Parsing...")
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		_print_log("Response parsed")
		var query_result = json.get_data()
		query_completed.emit(query_result)
	else:
		_print_log("Response error")
		printerr("[OverpassClient._on_request_completed] result = %d, response_code= %d" % [result, response_code])
		
static func update_osm_data_from_query_result(osm_data: OSMData, result: Dictionary):
	_print_log("Updating OSM data...")
	var progress_print_cycle_ms = 300

	var current_tick_ms = Time.get_ticks_msec()
	var next_progress_print_tick_msec = current_tick_ms + progress_print_cycle_ms
	
	osm_data.rebuild_hashmaps()
	
	var elements = result.get("elements", [ ])
	for i in elements.size():
		var element: Dictionary = elements[i]
		var osm_element: OSMElement
		match element["type"]:
			"node":
				var osm_node: OSMNode = osm_data.get_node_by_id(element["id"], true)
				if element.has("lat") and element.has("lon"):
					osm_node.location = GeoLocation.new(element["lat"], element["lon"])
				osm_element = osm_node
			"way":
				var osm_way: OSMWay = osm_data.get_way_by_id(element["id"], true)
				var node_ids: PackedInt64Array = element.get("nodes", [ ])
				if node_ids.size() > 0:
					if osm_way.node_ids == null or osm_way.node_ids.size() == 0:
						osm_way._section_start_indices = [0]
						osm_way.node_ids = node_ids.duplicate()
						osm_way._section_end_indices = [osm_way.node_ids.size() - 1]
					else:
						print("[OverpassClient] Warning. The way #%d already has nodes." % osm_way.id \
							+ " Nodes from the new result is added to the node list as a new section." \
							+ " But in this case the full node list can contain duplicate nodes and the order of sections also cannot be determined.")
						osm_way._section_start_indices.append(osm_way.node_ids.size())
						osm_way.node_ids.append_array(node_ids)
						osm_way._section_end_indices.append(osm_way.node_ids.size() - 1)
				osm_element = osm_way
			"relation":
				var osm_relation: OSMRelation = osm_data.get_relation_by_id(element["id"], true)
				var members = element["members"]
				for j in members.size():
					var member: Dictionary = members[j]
					var member_type: OSMMember.Type
					match member["type"]:
						"node": member_type = OSMMember.Type.NODE
						"way": member_type = OSMMember.Type.WAY
						"relation": member_type = OSMMember.Type.RELATION
					var osm_member := OSMMember.new(member_type, member["ref"], member["role"])
					osm_relation.members.append(osm_member)
				osm_element = osm_relation
		if osm_element != null:
			var tags: Dictionary = element.get("tags", { }) 
			for key in tags:
				osm_element.tags[key] = tags[key]
		current_tick_ms = Time.get_ticks_msec()
		if current_tick_ms > next_progress_print_tick_msec:
			#print("[OverpassClient.update_osm_data_from_query_result] %.2f (%s)" % [float(i) / float(elements.size()), current_tick_ms])
			next_progress_print_tick_msec = current_tick_ms + progress_print_cycle_ms
	_print_log("OSM data updated")
	
