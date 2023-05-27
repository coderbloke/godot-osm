@tool
class_name OverpassStatementOut extends OverpassStatement

enum Verbosity {
	DEFAULT, IDS, SKELETON, BODY, TAGS, META
}

enum AdditionalGeolocations {
	NONE, FULL_GEOMETRY, BOUNDING_BOXES, CENTERS
}

enum SortOrder {
	DEFAULT, BY_ID, BY_QUADTILE_INDEX
}

@export var input_set: String = ""
@export var intersecting_input_sets: PackedStringArray
@export var verbosity: Verbosity
@export var omit_ids: bool = false
@export var additional_geolocations: AdditionalGeolocations = AdditionalGeolocations.NONE
@export var bounding_box: GeoBoundary
@export var sort_order: SortOrder
@export var max_number_of_features: int = -1

func _init():
	pass

func _build_script(script: OverpassQueryBuilder.QLScript):
	var statement = _get_input_set_prefix(input_set, intersecting_input_sets)
	statement += "out" if statement.length() == 0 else " out"
	match verbosity:
		Verbosity.IDS: statement += " ids"
		Verbosity.SKELETON: statement += " skel"
		Verbosity.BODY: statement += " body"
		Verbosity.TAGS: statement += " tags"
		Verbosity.META: statement += " meta"
	if omit_ids:
		statement += " noids"
	match additional_geolocations:
		AdditionalGeolocations.FULL_GEOMETRY: statement += " geom"
		AdditionalGeolocations.BOUNDING_BOXES: statement += " bb"
		AdditionalGeolocations.CENTERS: statement += " center"
	if bounding_box != null:
		statement += " " + _get_bbox(bounding_box, true)
	match sort_order:
		SortOrder.BY_ID: statement += " asc"
		SortOrder.BY_QUADTILE_INDEX: statement += " qt"
	if max_number_of_features >= 0:
		statement += " " + str(max_number_of_features)
	script.append_statement(statement)

