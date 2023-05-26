@tool
class_name WebMercatorProjection extends Resource

const EARTH_BOUNDS: Rect2 = \
	Rect2(-20037508.34, -20048966.1, 2 * 20037508.34, 2 * 20048966.1)

const min_lat: float = -85.0511288
const max_lat: float = 85.0511288

const min_lon: float = -180
const max_lon: float = 180

@export var bounds: Rect2 = EARTH_BOUNDS

@export var clip_inputs: bool = true

const PI_PER_2 = PI / 2
const PI_PER_4 = PI / 4

func _init(bounds: Rect2 = EARTH_BOUNDS):
	self.bounds = bounds

func clip_lon(lon: float) -> float:
	lon = fmod(lon - min_lon, max_lon - min_lon)
	if lon < 0: lon += (max_lon - min_lon)
	lon += min_lon
	return lon
	
func normalize_lon(lon: float) -> float:
	return (lon - min_lon) / (max_lon - min_lon)

func lon_to_x(lon: float) -> float:
	if clip_inputs:
		lon = clip_lon(lon)
	return bounds.position.x + normalize_lon(lon) * bounds.size.x
	
func clip_x(x: float) -> float:
	x = fmod(x - bounds.position.x, bounds.size.x)
	if x < 0: x += bounds.size.x
	x += bounds.position.x
	return x
	
func normalize_x(x: float) -> float:
	return (x - bounds.position.x) / bounds.size.x
	
func x_to_lon(x: float) -> float:
	if clip_inputs:
		x = clip_x(x)
	return min_lon + normalize_x(x) * (max_lon - min_lon)
	
func lat_to_y(lat: float) -> float:
	if clip_inputs:
		if lat < min_lat:
			return -INF
		if lat > max_lat:
			return INF
	# PI / 4 + deg_to_rad(lat) / 2 
	# -> PI_PER_4 + ((lat / 180) * PI) / 2
	# -> PI_PER_4 + (lat / 90) * PI_PER_4
	# -> (1 + lat / 90) * PI_PER_4
#	var info_slot = DebugInfo.get_slot("WebMercatorProjection.lat_to_y")
#	info_slot.text = str(deg_to_rad(lat)) \
#		+ "\n" + str(log(tan((1 + lat / 90) * PI_PER_4))) \
#		+ "\n" + str(log(tan((1 + lat / 90) * PI_PER_4)) / (2 * PI) + 0.5)
	return bounds.position.y + (log(tan((1 + lat / 90) * PI_PER_4)) / (2 * PI) + 0.5) * bounds.size.y
	
func normalize_y(y: float) -> float:
	return (y - bounds.position.y) / bounds.size.y
	
func y_to_lat(y: float) -> float:
	if clip_inputs:
		if bounds.size.y >= 0:
			if y < bounds.position.y:
				return -INF
			if y > bounds.end.y:
				return INF
		else:
			if y > bounds.position.y:
				return -INF
			if y < bounds.end.y:
				return INF
	# rad_to_deg(2 * atan(exp(y)) - PI / 2.0)
	# -> 2 * (atan(exp(y)) - PI / 4.0) * (180 / PI)
	# -> (360 / PI) * (atan(exp(y)) - PI_PER_4)
	# -> (360 / PI) * atan(exp(y) - 90
#	var info_slot = DebugInfo.get_slot("WebMercatorProjection.y_to_lat")
#	info_slot.text = str(y) \
#		+ "\n" + str(normalize_y(y) * 2 - 1) \
#		+ "\n" + str(atan(exp((normalize_y(y) * 2 - 1) * PI)))
	return (360 / PI) * atan(exp((normalize_y(y) * 2 - 1) * PI)) - 90
	
func project(geo_location: GeoLocation) -> Vector2:
	return Vector2(lon_to_x(geo_location.lon), lat_to_y(geo_location.lat))
	
func reverse(projection: Vector2) -> GeoLocation:
	return GeoLocation.new(y_to_lat(projection.y), x_to_lon(projection.x))
	
