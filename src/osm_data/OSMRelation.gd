@tool
class_name OSMRelation extends OSMElement

@export var members: Array[OSMMember]

func _init(id: int = -1, members: Array[OSMMember] = []):
	super._init(id)
