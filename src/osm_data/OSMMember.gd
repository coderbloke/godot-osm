@tool
class_name OSMMember extends Resource

enum Type {
	NODE, WAY, RELATION
}

@export var type: Type
@export var ref_id: int
@export var role: String

func _init(type: Type = 0, ref_id: int = -1, role: String = ""):
	self.ref_id = ref_id
	self.role = role
