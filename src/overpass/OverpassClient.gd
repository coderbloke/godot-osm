@tool
class_name OverpassClient extends ExtendedHTTPRequest

const DEFAULT_URL = "https://overpass.openstreetmap.ru/api/interpreter"
@export var base_url: String = DEFAULT_URL

@export var query_builder: OverpassQueryBuilder = OverpassQueryBuilder.new()

signal query_completed(result: Dictionary)

func _init():
	request_completed.connect(_on_request_completed)
	
func get_overpass_ql_query(parameters: OldOverpassQueryParameters) -> PackedStringArray:
	var query_bounds = ",".join(PackedStringArray([
		min(parameters.bounding_box.from_lat, parameters.bounding_box.to_lat),
		min(parameters.bounding_box.from_lon, parameters.bounding_box.to_lon),
		max(parameters.bounding_box.from_lat, parameters.bounding_box.to_lat),
		max(parameters.bounding_box.from_lon, parameters.bounding_box.to_lon),
		])) if parameters.bounding_box != null else ""
	var query: PackedStringArray = PackedStringArray()
	var settings = "[out:json]"
	if parameters.timeout >= 0:
		settings += "[timeout:" + str(parameters.timeout) + "]" 
	if parameters.max_size >= 0:
		settings += "[maxsize:" + str(parameters.max_size) + "]" 
	query.append(settings + ";")
	query.append("(")
	if parameters.query_nodes:
		query.append("node(" + query_bounds + ");")
	if parameters.query_ways:
		query.append("way(" + query_bounds + ");")
	if parameters.query_relations:
		query.append("rel(" + query_bounds + ");")
	if parameters.query_derived:
		query.append("derived(" + query_bounds + ");")
	if parameters.query_areas:
		query.append("area(" + query_bounds + ");")
	query.append(");")
	var output_verbosity = ""
	match parameters.output_verbosity:
		OldOverpassQueryParameters.OutputVerbosity.IDS:
			output_verbosity = "ids"
		OldOverpassQueryParameters.OutputVerbosity.SKELETON:
			output_verbosity = "skel"
		OldOverpassQueryParameters.OutputVerbosity.BODY:
			output_verbosity = "body"
		OldOverpassQueryParameters.OutputVerbosity.TAGS:
			output_verbosity = "tags"
		OldOverpassQueryParameters.OutputVerbosity.META:
			output_verbosity = "meta"
	query.append("out " + output_verbosity + ";")
	return query

func get_query_url(parameters: OldOverpassQueryParameters) -> String:
	var query = get_overpass_ql_query(parameters)
	return get_url_with_query(base_url, "", { "data" : "".join(query) })
	
func query(parameters: OldOverpassQueryParameters) -> Error:
	return request(get_query_url(parameters), [], HTTPClient.Method.METHOD_GET, "")
		
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result == Result.RESULT_SUCCESS and response_code == HTTPClient.RESPONSE_OK:
		var json = JSON.new()
		print(body.get_string_from_utf8())
		json.parse(body.get_string_from_utf8())
		var query_result = json.get_data()
		query_completed.emit(query_result)
		
static func update_osm_data_from_query_result(osm_data: OSMData, result: Dictionary):
	osm_data.rebuild_hashmaps()
	
	var elements = result["elements"]
	for i in elements.size():
		var element: Dictionary = elements[i]
		match element["type"]:
			"node":
				var n : OSMNode = osm_data.get_node_by_id(element["id"], true)
				n.location = GeoLocation.new(element["lat"], element["lon"])
			"way":
				var w : OSMWay = osm_data.get_way_by_id(element["id"], true)
				w.node_ids = element["nodes"]
	
