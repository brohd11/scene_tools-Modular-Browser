@tool
extends EditorPlugin

const plugin_name := "Scene Tools"

const GuiHandler := preload("res://addons/scene_tools/gui_handler.gd")
const Tool := preload("res://addons/scene_tools/tool.gd")
const PlaceTool := preload("res://addons/scene_tools/tools/place.gd")
var gui := preload("res://addons/scene_tools/gui.tscn")



const ab_lib = preload("res://addons/modular_browser/plugin/script_libs/ab_lib.gd")
func _connect_global_bus():
	var bus_array = ab_lib.ABGlobalSignals.get_global_bus_array(["scene_tools"])
	ab_lib.ABGlobalSignals.connect_send_files_to_bus(bus_array, _on_global)
	pass
func _on_global(items, root):
	if not plugin_enabled:
		plugin_enabled = true
	var scenes = ab_lib.ABTree.Static.get_item_array_paths(items,[],["PackedScene"])
	if scenes.is_empty():
		#update_selected_assets([])
		return
	var path = scenes[0]
	var uid = ab_lib.Stat.ed_util.path_to_uid(path)
	print("uid ", uid)
	update_selected_assets([uid])
	
	if not EditorInterface.get_base_control().get_window().has_focus():
		EditorInterface.get_base_control().get_window().grab_focus()
	pass

static var plugin_instance

var gui_instance: GuiHandler

var root_node: Node
var scene_root: Node

var undo_redo: EditorUndoRedoManager

var plugin_enabled := false

var selected_assets: Array

var side_panel_folded := true

var place_tool := PlaceTool.new(self)
var tools: Array[Tool] = [
	place_tool
]
var current_tool: Tool = place_tool

func _enter_tree() -> void:
	plugin_instance = self
	_connect_global_bus()
	
	scene_changed.connect(_on_scene_changed)
	scene_closed.connect(_on_scene_closed)
	
	undo_redo = get_undo_redo()
	
	current_tool.enter()
	
	EditorInterface.get_selection().selection_changed.connect(_on_editor_selection_changed)

func _exit_tree() -> void:
	
	for tool in tools:
		tool.exit()

#func add_gui():
	#var gui_root := gui.instantiate()
	#gui_instance = gui_root.get_node("SceneTools") as GuiHandler
	#gui_instance.plugin_instance = self
	#
	#gui_instance.version_label.text = plugin_name + " v" + get_plugin_version()
	#
	#gui_instance.owner = null
	#gui_root.remove_child(gui_instance)
	#add_control_to_container(CustomControlContainer.CONTAINER_SPATIAL_EDITOR_MENU, gui_instance)
	#
	#gui_instance.side_panel.owner = null
	#gui_root.remove_child(gui_instance.side_panel)
	#add_control_to_container(CustomControlContainer.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, gui_instance.side_panel)
	#
	#gui_instance.scene_tools_button.pressed.connect(_scene_tools_button_pressed)
	#
	#gui_root.free()
	#pass
#
#func remove_gui():
	#remove_control_from_container(CustomControlContainer.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, gui_instance.side_panel)
	#remove_control_from_container(CustomControlContainer.CONTAINER_SPATIAL_EDITOR_MENU, gui_instance)
	#gui_instance.side_panel.free()
	#gui_instance.free()

#func _make_visible(visible: bool) -> void:
	#if visible:
		#gui_instance.show()
		#gui_instance.side_panel.set_visible(plugin_enabled)
	#else:
		#gui_instance.hide()
		#gui_instance.side_panel.hide()

func _scene_tools_button_pressed() -> void:
	print("YE YE")
	set_plugin_enabled(!plugin_enabled)
	if plugin_enabled:
		if not EditorInterface.get_base_control().get_window().has_focus():
			EditorInterface.get_base_control().get_window().grab_focus()

func _get_plugin_name() -> String:
	return plugin_name

func _edit(object: Object) -> void: # sets root
	current_tool.edit(object)

func _on_editor_selection_changed():
	if not plugin_enabled:
		return
	var selection = EditorInterface.get_selection().get_selected_nodes()
	if selection.is_empty():
		plugin_enabled = false
	


func _on_scene_changed(_scene_root: Node) -> void:
	current_tool._on_scene_changed(_scene_root)

func _on_scene_closed(path: String) -> void:
	current_tool._on_scene_closed(path)

func _handles(object: Object) -> bool:
	return current_tool.handles(object)

func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if not plugin_enabled or not root_node:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	#update_selected_assets()
	
	return current_tool.forward_3d_gui_input(viewport_camera, event)

func _get_window_layout(configuration: ConfigFile) -> void:
	for tool in tools:
		tool.save_state(configuration)

func _set_window_layout(configuration: ConfigFile) -> void:
	for tool in tools:
		tool.load_state(configuration)

func set_plugin_enabled(enabled: bool) -> void:
	plugin_enabled = enabled
	current_tool._on_plugin_enabled(enabled)

func update_selected_assets(new_selected_array=[]) -> void:
	var new_selected:Array
	if new_selected_array.is_empty():
		new_selected = Array(EditorInterface.get_selected_paths())
	else:
		new_selected = new_selected_array

	# Remove directories
	new_selected = new_selected.filter(func(path: String) -> bool:
		return not path.ends_with("/")
	)
	print(plugin_enabled)
	var remove_brush := false
	
	# if the amount of selected files changed
	if new_selected.size() != selected_assets.size():
		# if new_selected is not empty then try instantiating the first asset
		if not new_selected.is_empty():
			var scene := ResourceLoader.load(new_selected[0]) as PackedScene

			if scene:
				place_tool.change_brush(scene)
				if place_tool.snapping_enabled:
					place_tool.set_grid_visible(place_tool.grid_display_enabled)
			else:
				remove_brush = true
		else:
			remove_brush = true
	# if the amount hasn't changed and there is one selected,
	# then compare newly selected with previously selected
	elif new_selected.size() == 1 and selected_assets.size() == 1:
		if new_selected[0] != selected_assets[0]:
			var scene := ResourceLoader.load(new_selected[0]) as PackedScene
			
			if scene:
				place_tool.change_brush(scene)
				if place_tool.snapping_enabled:
					place_tool.set_grid_visible(place_tool.grid_display_enabled)
			else:
				remove_brush = true
	
	if remove_brush:
		place_tool.grid_mesh.hide()
		if place_tool.brush != null:
			place_tool.brush.free()

	selected_assets = new_selected
