@tool
class_name OverpassTestPanel extends VBoxContainer

@export var base_url: String = OverpassClient.DEFAULT_URL:
	set(new_value):
		base_url = new_value
		if overpass_client != null:
			overpass_client.base_url = base_url
			
@export var overpass_query_builder: OverpassQueryBuilder
@export var overpass_query: OverpassQuery

@export var auto_query = true:
	set(new_value):
		auto_query = new_value
		if auto_query_checkbutton != null:
			auto_query_checkbutton.button_pressed = auto_query
@export var print_to_console = true
@export var trigger_query = false

@onready var overpass_client: OverpassClient = $OverpassClient

@onready var query_resource_value_label: RichTextLabel = %ResourceValueLabel
@onready var query_ql_script_label: RichTextLabel = %QLScriptLabel
@onready var query_url_value_label: RichTextLabel = %URLValueLabel
@onready var auto_query_checkbutton: CheckButton = %AutoQueryCheckButton
@onready var query_button: Button = %QueryButton

func _ready():
	overpass_client.base_url = base_url
	auto_query_checkbutton.button_pressed = auto_query

func _on_overpass_query_changed():
	print("_on_overpass_query_changed()")
	
func get_resource_info(resource: Resource) -> String:
	var info: String
	if resource != null:
		info = resource.resource_name
		if info == null:
			info = ""
		if info.length() > 0:
			info += " "
		if resource.resource_path != null and resource.resource_path.length() > 0:
			info += "(" + resource.resource_path + ")"
		else:
			info += "(unsaved)"
	else:
		info = "(null)"
	return info
	
var _ql_script: String
var _query_url: String
var _last_query_url: String

func _update_ql_script():
	if overpass_query_builder != null and overpass_query != null:
		_ql_script = overpass_query_builder.get_overpass_ql_script(overpass_query)
	else:
		_ql_script = ""
		
func _update_query_url():
	if overpass_query_builder != null and overpass_query != null:
		_query_url = overpass_query_builder.get_overpass_ql_script(overpass_query, true)
	else:
		_query_url = ""

func do_query():
	if overpass_query != null:
		_last_query_url = _query_url
		overpass_client.cancel_request()
		if print_to_console:
			print_rich("[color=Lightskyblue][OverpassTestPanel.do_query] TODO[/color]")
			#print_rich("[color=Lightskyblue]" + overpass_client.get_query_url(overpass_query) + "[/color]")
		#overpass_client.query(overpass_query)

func _process(delta):
	query_resource_value_label.text = get_resource_info(overpass_query)
	_update_ql_script()
	_update_query_url()
	query_ql_script_label.text = _ql_script
	query_url_value_label.text = _query_url
	if (auto_query and _query_url != _last_query_url) or trigger_query:
		pass
	trigger_query = false

func _on_query_button_pressed():
	do_query()

func _on_query_completed(result: Array):
	print("[OverpassTestPanel._on_query_completed]")

func _on_auto_query_check_button_toggled(button_pressed):
	auto_query = button_pressed
