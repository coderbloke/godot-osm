@tool
class_name OverpassStatement extends Resource

func _init():
	push_warning("This class on its does nothing. Use one of its sublasses.")

func _build_script(script: OverpassQueryBuilder.QLScript):
	push_warning("This class on its does nothing. Use one of its sublasses, which implements _build.")

func _get_input_set_prefix(input_set: String, intersecting_input_sets: PackedStringArray = []) -> String:
	var filtered_intersecting_input_sets := PackedStringArray()
	if intersecting_input_sets != null:
		for intersecting_set in intersecting_input_sets:
			if intersecting_set != null and intersecting_set.length() > 0:
				filtered_intersecting_input_sets.append(intersecting_set)
	if input_set == null or input_set.length() == 0:
		if filtered_intersecting_input_sets.size() > 0:
			input_set = "_"
		else:
			return ""
	return "." + input_set + ("." + ".".join(filtered_intersecting_input_sets) if filtered_intersecting_input_sets.size() > 0 else "")

func _get_loop_variable_prefix(loop_variable: String) -> String:
	return "->." + loop_variable if loop_variable != null and loop_variable.length() > 0 else ""
	
func _get_output_set_suffix(output_set: String) -> String:
	return "->." + output_set if output_set != null and output_set.length() > 0 else ""

func _get_bbox(bounds: GeoBoundary, in_brackets: bool = true):
	return ("(" if in_brackets else "") \
		+ "%f,%f,%f,%f" % [bounds.from_lat, bounds.from_lon, bounds.to_lat, bounds.to_lon] \
		+ (")" if in_brackets else "")
