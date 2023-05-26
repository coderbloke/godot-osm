@tool
class_name GeoBoundary extends Resource

var _disable_change_notifications: bool = false

var from_lat: float:
	set(new_value):
		if new_value != from_lat:
			from_lat = new_value
			if not _disable_change_notifications:
				changed.emit()
var from_lon: float:
	set(new_value):
		if new_value != from_lon:
			from_lon = new_value
			if not _disable_change_notifications:
				changed.emit()
var to_lat: float:
	set(new_value):
		if new_value != to_lat:
			to_lat = new_value
			if not _disable_change_notifications:
				changed.emit()
var to_lon: float:
	set(new_value):
		if new_value != to_lon:
			to_lon = new_value
			if not _disable_change_notifications:
				changed.emit()

func _init(from_lat: float = 0.0, from_lon: float = 0.0, to_lat: float = 0.0, to_lon: float = 0.0):
	self.from_lat = from_lat
	self.from_lon = from_lon
	self.to_lat = to_lat
	self.to_lon = to_lon

func _get_property_list() -> Array[Dictionary]:
	return [
		{ "name": "from_lat", "type": TYPE_FLOAT, "usage": PROPERTY_USAGE_DEFAULT & (~ PROPERTY_USAGE_STORAGE),
			"hint": PROPERTY_HINT_RANGE, "hint_string" : "-90,90,0.0000001,degrees" },
		{ "name": "from_lon", "type": TYPE_FLOAT, "usage": PROPERTY_USAGE_DEFAULT & (~ PROPERTY_USAGE_STORAGE),
			"hint": PROPERTY_HINT_RANGE, "hint_string" : "-180,180,0.0000001,degrees" },
		{ "name": "to_lat", "type": TYPE_FLOAT, "usage": PROPERTY_USAGE_DEFAULT & (~ PROPERTY_USAGE_STORAGE),
			"hint": PROPERTY_HINT_RANGE, "hint_string" : "-90,90,0.0000001,degrees" },
		{ "name": "to_lon", "type": TYPE_FLOAT, "usage": PROPERTY_USAGE_DEFAULT & (~ PROPERTY_USAGE_STORAGE),
			"hint": PROPERTY_HINT_RANGE, "hint_string" : "-180,180,0.0000001,degrees" },
		{ "name": "from_lat_raw", "type": TYPE_PACKED_BYTE_ARRAY, "usage": PROPERTY_USAGE_NO_EDITOR },
		{ "name": "from_lon_raw", "type": TYPE_PACKED_BYTE_ARRAY, "usage": PROPERTY_USAGE_NO_EDITOR },
		{ "name": "to_lat_raw", "type": TYPE_PACKED_BYTE_ARRAY, "usage": PROPERTY_USAGE_NO_EDITOR },
		{ "name": "to_lon_raw", "type": TYPE_PACKED_BYTE_ARRAY, "usage": PROPERTY_USAGE_NO_EDITOR },
	]
	
func _get(property: StringName) -> Variant:
	match property:
		"from_lat_raw":
			return var_to_bytes(from_lat)
		"from_lon_raw":
			return var_to_bytes(from_lon)
		"to_lat_raw":
			return var_to_bytes(to_lat)
		"to_lon_raw":
			return var_to_bytes(to_lon)
	return null

func _set(property: StringName, value: Variant):
	match property:
		"from_lat_raw":
			from_lat = bytes_to_var(value)
			return true
		"from_lon_raw":
			from_lon = bytes_to_var(value)
			return true
		"to_lat_raw":
			to_lat = bytes_to_var(value)
			return true
		"to_lon_raw":
			to_lon = bytes_to_var(value)
			return true
	return false

func extend(location: GeoLocation):
	if from_lat < to_lat:
		from_lat = min(from_lat, location.lat)
		to_lat = max(to_lat, location.lat)
	else:
		from_lat = max(from_lat, location.lat)
		to_lat = min(to_lat, location.lat)
	if from_lon < to_lon:
		from_lon = min(from_lon, location.lon)
		to_lon = max(to_lon, location.lon)
	else:
		from_lon = max(from_lon, location.lon)
		to_lon = min(to_lon, location.lon)

func from_loc() -> GeoLocation:
	return GeoLocation.new(from_lat, from_lon)

func to_loc() -> GeoLocation:
	return GeoLocation.new(to_lat, to_lon)

func min_loc() -> GeoLocation:
	return GeoLocation.new(min(from_lat, to_lat), min(from_lon, to_lon))

func max_loc() -> GeoLocation:
	return GeoLocation.new(max(from_lat, to_lat), max(from_lon, to_lon))

func _to_string():
	return "(" + str(from_lat) + ", " + str(from_lon) + ") (" + str(to_lat) + ", " + str(to_lon) + ")"

func to_rect2():
	var min = Vector2(min(from_lat, to_lat), min(from_lon, to_lon))
	var max = Vector2(max(from_lat, to_lat), max(from_lon, to_lon))
	return Rect2(min, max - min)
