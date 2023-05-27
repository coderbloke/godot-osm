@tool
class_name OSMElement extends Resource

@export var id: int
@export var tags = { }

func _init(id: int = -1):
	self.id = id
