@tool
class_name OverpassStatementUnion extends OverpassStatement

@export var statements: Array[OverpassStatement]

func _build_script(script: OverpassQueryBuilder.QLScript):
	script.append("(")
	script.indent()
	for statement in statements:
		if statement != null:
			statement._build_script(script)
	script.unindent()
	script.append_statement(")")

