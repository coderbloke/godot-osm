@tool
class_name ExtendedWindow extends Window

var button_hiding_texture := PlaceholderTexture2D.new()

@export var close_button_visible := true:
	set(new_value):
		close_button_visible = new_value
		if close_button_visible:
			remove_theme_icon_override("close")
			remove_theme_icon_override("close_pressed")
		else:
			add_theme_icon_override("close", button_hiding_texture)
			add_theme_icon_override("close_pressed", button_hiding_texture)

@export var follow_parent_visibility := true:
	set(new_value):
		follow_parent_visibility = new_value
		process_parent_visibility()

func process_parent_visibility():
	if follow_parent_visibility:
		var parent := get_parent()
		var parent_visible := true
		while parent != null and parent is CanvasItem:
			if not parent.visible:
				parent_visible = false
				break
			parent = parent.get_parent()
		visible = parent_visible

func _enter_tree():
	process_parent_visibility()
	var parent := get_parent()
	while parent != null and parent is CanvasItem:
		parent.visibility_changed.connect(_on_parent_visibility_changed)
		parent = parent.get_parent()
	
func _exit_tree():
	var parent := get_parent()
	while parent != null and parent is CanvasItem:
		parent.visibility_changed.disconnect(_on_parent_visibility_changed)
		parent = parent.get_parent()
	
func _on_parent_visibility_changed():
	process_parent_visibility()
