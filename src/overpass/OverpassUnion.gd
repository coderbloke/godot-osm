@tool
class_name OverpassUnion extends OverpassStatement

@export var input_set: String = ""
@export var intersecting_input_sets: PackedStringArray
@export var statements: Array[OverpassStatement]
@export var output_set: String = ""

func _init():
	pass

func _build_script(script: OverpassQueryBuilder.QLScript):
	script.append(_get_input_set_prefix(input_set, intersecting_input_sets) + "(")
	script.indent()
	for statement in statements:
		if statement != null:
			statement._build_script(script)
	script.unindent()
	script.append_statement(")" + _get_output_set_suffix(output_set))

