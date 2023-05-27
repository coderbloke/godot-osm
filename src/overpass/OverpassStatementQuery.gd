@tool
class_name OverpassStatementQuery extends OverpassStatement

enum ElementType {
	NODE, WAY, RELATION, NODE_WAY_RELATION, NODE_WAY, NODE_RELATION, WAY_RELATION, DERIVED, AREA
}

@export var input_set: String = ""
@export var intersecting_input_sets: PackedStringArray
@export var element_type: ElementType
@export var output_set: String = ""

func _init():
	pass

func _build_script(script: OverpassQueryBuilder.QLScript):
	var specifier
	match element_type:
		ElementType.NODE: specifier = "node"
		ElementType.WAY: specifier = "way"
		ElementType.RELATION: specifier = "rel"
		ElementType.NODE_WAY_RELATION: specifier = "nwr"
		ElementType.NODE_WAY: specifier = "nw"
		ElementType.NODE_RELATION: specifier = "nr"
		ElementType.WAY_RELATION: specifier = "wr"
		ElementType.DERIVED: specifier = "derived"
		ElementType.AREA: specifier = "area"
	if specifier != null:
		script.append_statement(
			specifier + _get_input_set_prefix(input_set, intersecting_input_sets)
			+ _get_output_set_suffix(output_set)
		)
	else:
		script.error("The query statement here has no 'element_type' defined.")

