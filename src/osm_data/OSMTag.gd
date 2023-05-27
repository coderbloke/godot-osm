@tool
class_name OSMTag extends Resource

@export var key: String
@export var value: String

func _init(key: String = "", value: String = ""):
	self.key = key
	self.value = value
