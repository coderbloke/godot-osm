@tool
class_name ExtendedHTTPRequest extends HTTPRequest

static func get_url_with_query(base_url: String, relative_path: String, parameters: Dictionary):
	var url = base_url
	var parameter_names = parameters.keys()
	if relative_path != null and relative_path.length() > 0:
		url += "/" + relative_path
	else:
		if parameter_names.size() > 0:
			url += "/"
	for i in parameter_names.size():
		var parameter_name = parameter_names[i]
		url += ("?" if i == 0 else "&") + str(parameter_name).uri_encode() + "=" + str(parameters[parameter_name]).uri_encode()
	return url
