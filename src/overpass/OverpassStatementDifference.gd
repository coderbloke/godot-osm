@tool
class_name OverpassStatementDifference extends OverpassStatement

@export var base: OverpassStatement
@export var exclusion: OverpassStatement
@export var output_set: String = ""

func _build_script(script: OverpassQueryBuilder.QLScript):
	if base != null and exclusion != null:
		script.append("(")
		script.indent()
		base._build_script(script)
		script.push_statement_prefix("- " if not script.compact else "-")
		exclusion._build_script(script)
		script.pop_statement_prefix()
		script.unindent()
		script.append_statement(")" + _get_output_set_suffix(output_set))
	elif base != null and exclusion == null:
		script.error("The difference statement here has no 'exclusion' defined.")
	elif exclusion != null and base == null:
		script.error("The difference statement here has no 'base' defined.")
	else:
		script.error("The difference statement here has no 'base' neither 'exclusion' defined.")
	
