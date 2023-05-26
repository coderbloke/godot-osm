@tool
class_name OverpassQueryStatement extends OverpassStatement

enum Type {
	NODE, WAY, RELATION, NWR, NW, NR, WR, DERIVED, AREA
}

@export var type: Type

func _init():
	pass

func _build_script(script: OverpassQueryBuilder.QLScript):
	var specifier
	match type:
		Type.NODE: specifier = "node"
		Type.WAY: specifier = "way"
		Type.RELATION: specifier = "rel"
		Type.NWR: specifier = "nwr"
		Type.NW: specifier = "nw"
		Type.NR: specifier = "nr"
		Type.WR: specifier = "wr"
		Type.DERIVED: specifier = "derived"
		Type.AREA: specifier = "area"
	script.append_statement(specifier + "()")

