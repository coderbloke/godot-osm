@tool
class_name GeoLocation extends Resource

var _disable_change_notifications: bool = false

var lat: float:
	set(new_value):
		if new_value != lat:
			lat = new_value
			if not _disable_change_notifications:
				changed.emit()
var lon: float:
	set(new_value):
		if new_value != lon:
			lon = new_value
			if not _disable_change_notifications:
				changed.emit()

func _init(lat: float = 0.0, lon: float = 0.0):
	self.lat = lat
	self.lon = lon
	
func _get_property_list() -> Array[Dictionary]:
	return [
		{ "name": "lat", "type": TYPE_FLOAT, "usage": PROPERTY_USAGE_DEFAULT & (~ PROPERTY_USAGE_STORAGE),
			"hint": PROPERTY_HINT_RANGE, "hint_string" : "-90,90,0.0000001,degrees" },
		{ "name": "lon", "type": TYPE_FLOAT, "usage": PROPERTY_USAGE_DEFAULT & (~ PROPERTY_USAGE_STORAGE),
			"hint": PROPERTY_HINT_RANGE, "hint_string" : "-180,180,0.0000001,degrees" },
		{ "name": "lat_raw", "type": TYPE_PACKED_BYTE_ARRAY, "usage": PROPERTY_USAGE_NO_EDITOR },
		{ "name": "lon_raw", "type": TYPE_PACKED_BYTE_ARRAY, "usage": PROPERTY_USAGE_NO_EDITOR },
	]
	
func _get(property: StringName) -> Variant:
	match property:
		"lat_raw":
			return var_to_bytes(lat)
		"lon_raw":
			return var_to_bytes(lon)
	return null

func _set(property: StringName, value: Variant):
	match property:
		"lat_raw":
			lat = bytes_to_var(value)
			return true
		"lon_raw":
			lon = bytes_to_var(value)
			return true
	return false

func _to_string():
	return "(" + str(lat) + ", " + str(lon) + ")"

func to_vector2():
	var x = fmod(lon, 180)
	if x < 0:
		x = x + 180
	var y = fmod(lat, 180)
	if y < 0:
		y = y + 180
	return Vector2(x, y)
	
func update_from(geo_location: GeoLocation):
	_disable_change_notifications = true
	lat = geo_location.lat
	lon = geo_location.lon
	_disable_change_notifications = false
	changed.emit()
