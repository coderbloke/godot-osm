@icon("RichTextButton.svg")

@tool
class_name RichTextButton extends RichTextLabel

var button = Button.new()

@export var flat: bool:
	set(new_value): button.flat = new_value; flat = button.flat
	get: return button.flat
@export var disabled: bool:
	set(new_value): button.disabled = new_value; disabled = button.disabled
	get: return button.disabled
@export var toggle_mode: bool:
	set(new_value): button.toggle_mode = new_value; toggle_mode = button.toggle_mode
	get: return button.toggle_mode
@export var button_group: ButtonGroup:
	set(new_value): button.button_group = new_value; button_group = button.button_group
	get: return button.button_group
@export_group("Shortcut")
@export var shortcut: Shortcut:
	set(new_value): button.shortcut = new_value; shortcut = button.shortcut
	get: return button.shortcut
@export var shortcut_feedback: bool:
	set(new_value): button.shortcut_feedback = new_value; shortcut_feedback = button.shortcut_feedback
	get: return button.shortcut_feedback
@export var shortcut_in_tooltip: bool:
	set(new_value): button.shortcut_in_tooltip = new_value; shortcut_in_tooltip = button.shortcut_in_tooltip
	get: return button.shortcut_in_tooltip
	
var meta

signal button_down
signal button_up
signal pressed
signal toggled(button_pressed: bool)

signal meta_pressed(meta)

func _init():
	button.show_behind_parent = true
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.set_meta("rich_text_button", get_instance_id())
	add_child(button, false, Node.INTERNAL_MODE_FRONT)
	button.button_down.connect(_on_button_down)
	button.button_up.connect(_on_button_up)
	button.pressed.connect(_on_pressed)
	button.toggled.connect(_on_toggled)
	
func _ready():
	# If this label was duplicated, the previous button is also duplicated
	# That is not reused, beacuse in that was bridging the button properties would be more complicated
	# The old button is not yet available at _init, but the set methods for the label called before _ready
	var duplicate_children = []
	for c in get_children(true):
		var reference = c.get_meta("rich_text_button", 0)
		if reference > 0 and reference != get_instance_id():
			duplicate_children.append(c)
	for c in duplicate_children:
		remove_child(c)

func _on_button_down():
	button_down.emit()
	
func _on_button_up():
	button_up.emit()

func _on_pressed():
	pressed.emit()
	meta_pressed.emit(meta)
	
func _on_toggled(button_pressed: bool):
	toggled.emit()
