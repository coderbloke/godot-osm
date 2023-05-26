@tool
class_name NominatimClient extends ExtendedHTTPRequest

const DEFAULT_URL = "https://nominatim.openstreetmap.org"

@export var base_url: String = DEFAULT_URL

signal query_completed(result: Array)

func _init():
	request_completed.connect(_on_request_completed)

func get_query_url(parameters: NominatimQueryParameters) -> String:
	var relative_path: String
	var url_parameters = Dictionary()
	match parameters.query_type:
		NominatimQueryParameters.QueryType.FREEFORM_SEARCH, \
		NominatimQueryParameters.QueryType.STRUCTURED_SEARCH:
			relative_path = "search"
			if parameters.query_type == NominatimQueryParameters.QueryType.STRUCTURED_SEARCH:
				url_parameters["street"] = parameters.house_number + " " + parameters.street_name
				url_parameters["city"] = parameters.city
				url_parameters["county"] = parameters.county
				url_parameters["state"] = parameters.state
				url_parameters["country"] = parameters.country
				url_parameters["postalcode"] = parameters.postal_code
			else:
				url_parameters["q"] = parameters.freeform_query
			url_parameters["format"] = "jsonv2"
			url_parameters["addressdetails"] = str(int(parameters.address_details))
			url_parameters["extratags"] = str(int(parameters.extra_tags))
			url_parameters["namedetails"] = str(int(parameters.name_details))
			if parameters.country_codes != null and parameters.country_codes.size() > 0:
				url_parameters["countrycodes"] = ",".join(parameters.country_codes)
			if parameters.exclude_place_ids != null and parameters.exclude_place_ids.size() > 0:
				var exclude_place_id_list
				for id in parameters.exclude_place_ids:
					exclude_place_id_list = (exclude_place_id_list + "," if exclude_place_id_list != null else "") + str(id)
				url_parameters["exclude_place_ids"] = exclude_place_id_list
				
			url_parameters["limit"] = parameters.limit
			if parameters.viewbox != null:
				url_parameters["viewbox"] = ",".join(PackedStringArray([
					parameters.viewbox.from_lat,
					parameters.viewbox.from_lon,
					parameters.viewbox.to_lat,
					parameters.viewbox.to_lon,
					]))
				url_parameters["bounded"] = str(int(parameters.bounded))
		NominatimQueryParameters.QueryType.REVERSE_GEOCODING:
			relative_path = "reverse"
			url_parameters["lat"] = str(parameters.coordinate.lat)
			url_parameters["lon"] = str(parameters.coordinate.lon)
			url_parameters["format"] = "jsonv2"
			url_parameters["addressdetails"] = str(int(parameters.address_details))
			url_parameters["extratags"] = str(int(parameters.extra_tags))
			url_parameters["namedetails"] = str(int(parameters.name_details))
			url_parameters["zoom"] = str(int(parameters.zoom))
		NominatimQueryParameters.QueryType.ADDRESS_LOOKUP:
			relative_path = "lookup"
			url_parameters["osm_ids"] = ','.join(parameters.osm_ids)
			url_parameters["format"] = "jsonv2"
			url_parameters["addressdetails"] = str(int(parameters.address_details))
			url_parameters["extratags"] = str(int(parameters.extra_tags))
			url_parameters["namedetails"] = str(int(parameters.name_details))
	return get_url_with_query(base_url, relative_path, url_parameters)
	
func query(parameters: NominatimQueryParameters) -> Error:
	return request(get_query_url(parameters), [], HTTPClient.Method.METHOD_GET, "")
		
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result == Result.RESULT_SUCCESS and response_code == HTTPClient.RESPONSE_OK:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var query_result = json.get_data()
		if not query_result is Array:
			query_result = [query_result]
		query_completed.emit(query_result)

static func get_result_display_name(result: Dictionary) -> String:
	if not result.has("display_name"):
		return ""
	return result["display_name"]

static func get_result_geo_location(result: Dictionary) -> GeoLocation:
	if not result.has("lat") or not result.has("lon"):
		return null
	return GeoLocation.new(float(result["lat"]), float(result["lon"]))
	
static func get_result_geo_boundary(result: Dictionary) -> GeoBoundary:
	if not result.has("boundingbox"):
		return null
	return GeoBoundary.new(float(result["boundingbox"][0]), float(result["boundingbox"][2]),
		float(result["boundingbox"][1]), float(result["boundingbox"][3]))
	
static func get_result_category(result: Dictionary) -> String:
	if not result.has("category"):
		return ""
	return result["category"]

static func get_result_type(result: Dictionary) -> String:
	if not result.has("type"):
		return ""
	return result["type"]

