@tool
class_name OverpassQuery extends Resource

@export var settings: OverpassQuerySettings
@export var statements: Array[OverpassStatement]

func _build_script(script: OverpassQueryBuilder.QLScript):
	for statement in statements:
		if statement != null:
			statement._build_script(script)


