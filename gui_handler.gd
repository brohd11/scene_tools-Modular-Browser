@tool
extends Control

const SceneTools = preload("res://addons/scene_tools/plugin.gd")



var plugin_instance: SceneTools

@export var snapping_button: CheckBox
@export var snapping_step: LineEdit
@export var snapping_offset: LineEdit
@export var align_to_surface_button: CheckBox
@export var help_dialog: AcceptDialog
@export var version_label: Label
@export var random_rotation_button: CheckBox
@export var random_scale_button: CheckBox
@export var random_rotation_axis: OptionButton
@export var random_rotation: LineEdit
@export var scale_x: LineEdit
@export var scale_y: LineEdit
@export var scale_z: LineEdit
@export var rotation_x: LineEdit
@export var rotation_y: LineEdit
@export var rotation_z: LineEdit
@export var position_x: LineEdit
@export var position_y: LineEdit
@export var position_z: LineEdit
@export var scale_link_button: Button
@export var random_scale: LineEdit
@export var plane_option: OptionButton
@export var display_grid_checkbox: CheckBox
@export var mode_option: OptionButton
@export var surface_container: Control
@export var plane_container: Control
@export var chance_to_spawn_container: Control
@export var chance_to_spawn: LineEdit
@export var plane_level: LineEdit
@export var rotation_step: LineEdit
#@export var force_readable_name_checkbox: CheckBox

@export var side_panel: Control

@onready var settings_button = %SettingsButton
@onready var set_root_button = %SetRootButton
@onready var root_name_label = %RootNameLabel
@onready var terrain_3D_container = %TerrainH
@onready var terrain_3D_button = %Terrain3DButton
@onready var terrain_3D_node_lab = %Terrain3DNodeLab
@onready var terrain_3D_snap_container = %TerrainSnapHeightContainer
@onready var terrain_3D_snap_check = %TerrainSnapHeightCheck
@onready var terrain_3D_all_col_container = %TerrainAllCollisionsContainer
@onready var terrain_3D_all_collisions_check: CheckBox = %TerrainAllCollisionsCheck



func _ready() -> void:
	plugin_instance = SceneTools.plugin_instance
	if not plugin_instance:
		push_error("Scene Tools plugin not found.")
		return
	
	root_name_label.text = "Set parent node"
	terrain_3D_node_lab.text = "Set Terrain3D Node"
	
	plugin_instance.gui_instance = self
	
	if plugin_instance.root_node:
		_set_root_node(plugin_instance.root_node)
	if plugin_instance.terrain3D_node:
		_set_terrain_3D_node(plugin_instance.terrain3D_node)
	
	snapping_button.toggled.connect(_on_snapping_toggled)
	plane_level.text_changed.connect(_on_plane_level_text_changed)
	snapping_step.text_changed.connect(_on_snapping_step_text_changed)
	snapping_offset.text_changed.connect(_on_snapping_offset_text_changed)
	align_to_surface_button.toggled.connect(_on_align_to_surface_toggled)
	random_scale.text_changed.connect(_on_random_scale_text_changed)
	plane_option.item_selected.connect(_on_plane_option_button_item_selected)
	display_grid_checkbox.toggled.connect(_on_display_grid_checkbox_toggled)
	mode_option.item_selected.connect(_on_mode_option_button_item_selected)
	chance_to_spawn.text_changed.connect(_on_chance_to_spawn_text_changed)
	scale_link_button.toggled.connect(_on_scale_link_toggled)
	random_rotation_button.toggled.connect(_on_random_rotation_button_toggled)
	random_scale_button.toggled.connect(_on_random_scale_button_toggled)
	random_rotation_axis.item_selected.connect(_on_random_rotation_axis_item_selected)
	random_rotation.text_changed.connect(_on_random_rotation_text_changed)
	#force_readable_name_checkbox.toggled.connect(_on_force_readable_name_checkbox_toggled)
	
	rotation_x.text_changed.connect(_on_rotation_x_text_changed)
	rotation_y.text_changed.connect(_on_rotation_y_text_changed)
	rotation_z.text_changed.connect(_on_rotation_z_text_changed)
	rotation_step.text_changed.connect(_on_rotation_step_text_changed)

	scale_x.text_changed.connect(_on_scale_x_text_changed)
	scale_y.text_changed.connect(_on_scale_y_text_changed)
	scale_z.text_changed.connect(_on_scale_z_text_changed)
	
	position_x.text_changed.connect(_on_position_x_text_changed)
	position_y.text_changed.connect(_on_position_y_text_changed)
	position_z.text_changed.connect(_on_position_z_text_changed)
	
	set_root_button.pressed.connect(_on_set_root_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	terrain_3D_button.pressed.connect(_on_set_terrain_3D_button_pressed)
	terrain_3D_snap_check.toggled.connect(_on_terrain_3D_snap_check_toggled)
	terrain_3D_all_collisions_check.toggled.connect(_on_terrain_all_collisions_check_toggled)
	
	# Hide mode specific containers
	surface_container.hide()
	plane_container.hide()
	chance_to_spawn_container.hide()
	
	plugin_instance.load_config()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(plugin_instance):
			plugin_instance.save_config()
			plugin_instance.plugin_enabled = false
			plugin_instance.gui_instance = null

#region Settings

func _on_mode_option_button_item_selected(index: int) -> void:
	if not EditorInterface.is_plugin_enabled("terrain_3d"):
		index = 0
	plugin_instance.place_tool.change_mode(index)
	plugin_instance.editor_grab_focus()

func _on_display_grid_checkbox_toggled(toggled: bool) -> void:
	plugin_instance.place_tool.set_grid_display_enabled(toggled)

func _on_plane_option_button_item_selected(index: int) -> void:
	plugin_instance.place_tool.set_plane_normal(index)

func _on_random_scale_text_changed(text: String) -> void:
	plugin_instance.place_tool.set_random_scale(float(text))

func _on_scene_tools_menu_pressed(id: int) -> void:
	match id:
		0:
			help_dialog.visible = true

func _on_align_to_surface_toggled(toggled: bool) -> void:
	plugin_instance.place_tool.set_align_to_surface(toggled)

func _on_snapping_toggled(toggled: bool) -> void:
	plugin_instance.place_tool.set_snapping_enabled(toggled)

func _on_plane_level_text_changed(text: String) -> void:
	plugin_instance.place_tool.set_plane_level(float(text))

func _on_snapping_step_text_changed(text: String) -> void:
	plugin_instance.place_tool.set_snapping_step(float(text))

func _on_snapping_offset_text_changed(text: String) -> void:
	plugin_instance.place_tool.set_snapping_offset(float(text))

func _on_chance_to_spawn_text_changed(text: String) -> void:
	plugin_instance.place_tool.set_chance_to_spawn(int(text))

# _ because it clashes with the base class
func _set_rotation(value: Vector3) -> void:
	rotation_x.text = str(value.x)
	rotation_y.text = str(value.y)
	rotation_z.text = str(value.z)

func _set_scale(value: Vector3) -> void:
	scale_x.text = str(value.x)
	scale_y.text = str(value.y)
	scale_z.text = str(value.z)

func _on_scale_link_toggled(toggled: bool) -> void:
	plugin_instance.place_tool.set_scale_link_toggled(toggled)

func _on_random_rotation_button_toggled(toggled: bool) -> void:
	plugin_instance.place_tool.set_random_rotation_enabled(toggled)

func _on_random_scale_button_toggled(toggled: bool) -> void:
	plugin_instance.place_tool.set_random_scale_enabled(toggled)

func _on_random_rotation_axis_item_selected(index: int) -> void:
	plugin_instance.place_tool.set_random_rotation_axis(index)

func _on_rotation_x_text_changed(text: String) -> void:
	plugin_instance.place_tool.set_rotation(Vector3(
		deg_to_rad(float(text)),
		plugin_instance.place_tool.rotation.y,
		plugin_instance.place_tool.rotation.z
		))

func _on_rotation_y_text_changed(text: String) -> void:
	plugin_instance.place_tool.set_rotation(Vector3(
		plugin_instance.place_tool.rotation.x,
		deg_to_rad(float(text)),
		plugin_instance.place_tool.rotation.z
		))

func _on_rotation_z_text_changed(text: String) -> void:
	plugin_instance.place_tool.set_rotation(Vector3(
		plugin_instance.place_tool.rotation.x,
		plugin_instance.place_tool.rotation.y,
		deg_to_rad(float(text))
		))

func _on_random_rotation_text_changed(text: String) -> void:
	plugin_instance.place_tool.set_random_rotation(deg_to_rad(float(text)))

func _on_scale_x_text_changed(text: String) -> void:
	if plugin_instance.place_tool.scale_linked:
		plugin_instance.place_tool.set_base_scale(Vector3(float(text), float(text), float(text)))
		_set_scale(plugin_instance.place_tool.base_scale)
	else:
		plugin_instance.place_tool.set_base_scale(Vector3(
			float(text),
			plugin_instance.place_tool.base_scale.y,
			plugin_instance.place_tool.base_scale.z
			))

func _on_scale_y_text_changed(text: String) -> void:
	if plugin_instance.place_tool.scale_linked:
		plugin_instance.place_tool.set_base_scale(Vector3(float(text), float(text), float(text)))
		_set_scale(plugin_instance.place_tool.base_scale)
	else:
		plugin_instance.place_tool.set_base_scale(Vector3(
			plugin_instance.place_tool.base_scale.x,
			float(text),
			plugin_instance.place_tool.base_scale.z
			))

func _on_scale_z_text_changed(text: String) -> void:
	if plugin_instance.place_tool.scale_linked:
		plugin_instance.place_tool.set_base_scale(Vector3(float(text), float(text), float(text)))
		_set_scale(plugin_instance.place_tool.base_scale)
	else:
		plugin_instance.place_tool.set_base_scale(Vector3(
			plugin_instance.place_tool.base_scale.x,
			plugin_instance.place_tool.base_scale.y,
			float(text)
			))

func _on_rotation_step_text_changed(text: String) -> void:
	plugin_instance.place_tool.set_rotation_step(deg_to_rad(float(text)))

func _on_position_x_text_changed(text: String) -> void:
	plugin_instance.place_tool.set_position(Vector3(
		float(text),
		plugin_instance.place_tool.position.y,
		plugin_instance.place_tool.position.z
		))

func _on_position_y_text_changed(text: String) -> void:
	plugin_instance.place_tool.set_position(Vector3(
		plugin_instance.place_tool.position.x,
		float(text),
		plugin_instance.place_tool.position.z
		))

func _on_position_z_text_changed(text: String) -> void:
	plugin_instance.place_tool.set_position(Vector3(
		plugin_instance.place_tool.position.x,
		plugin_instance.place_tool.position.y,
		float(text)
		))

#func _on_force_readable_name_checkbox_toggled(toggled: bool) -> void:
	#plugin_instance.place_tool.force_readable_name = toggled

func _on_terrain_3D_snap_check_toggled(toggled:bool) -> void:
	plugin_instance.place_tool.set_terrain_3D_height_snap(toggled)

func _on_terrain_all_collisions_check_toggled(toggled:bool) -> void:
	plugin_instance.place_tool.set_terrain_3D_allow_all_col(toggled)

#endregion


func _on_settings_button_pressed():
	help_dialog.show()


func _on_set_root_button_pressed():
	var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
	if selected_nodes.is_empty():
		print("No node selected.")
		return
	var node = selected_nodes[0]
	_set_root_node(node)

func _set_root_node(node:Node):
	if node is not Node3D and node is not Node:
		print("Select Node or Node3D.")
		return
	#plugin_instance.root_node = node
	SceneTools.plugin_instance.set_root_node(node)

func set_root_node_name(node):
	root_name_label.text = node.name
	root_name_label.tooltip_text = node.name


func _on_set_terrain_3D_button_pressed():
	var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
	if selected_nodes.is_empty():
		print("No node selected.")
		return
	var node = selected_nodes[0]
	_set_terrain_3D_node(node)

func _set_terrain_3D_node(node):
	if not SceneTools.check_terrain_3D_node(node):
		print("Must be Terrain3D")
		return
	SceneTools.plugin_instance.set_terrain_3D_node(node)

func set_terrain_3D_node_name(node):
	if node:
		terrain_3D_node_lab.text = node.name
		terrain_3D_node_lab.tooltip_text = node.name
	else:
		terrain_3D_node_lab.text = "null"
		terrain_3D_node_lab.tooltip_text = "null"
