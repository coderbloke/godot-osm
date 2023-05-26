@tool
class_name OSMNode extends OSMElement

@export var location: GeoLocation

func _init(id: int = -1, lat: float = 0.0, lon: float = 0.0):
	super._init(id)
	self.location = GeoLocation.new(lat, lon)
