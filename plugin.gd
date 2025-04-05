@tool
extends EditorPlugin

const plugin_name := "Scene Tools"

const GuiHandler := preload("res://addons/scene_tools/gui_handler.gd")
const Tool := preload("res://addons/scene_tools/tool.gd")
const PlaceTool := preload("res://addons/scene_tools/tools/place.gd")


## ModBrowser Start
const TERRAIN3D_CHECK_PATH = "res://addons/scene_tools/config/hidden/terrain_3D_check.gd"
const CONFIG_PATH = "res://addons/scene_tools/config/scene_tools.cfg"

const ab_lib = preload("res://addons/modular_browser/plugin/script_libs/ab_lib.gd")
func _connect_global_bus():
	if not ab_lib.ABGlobalSignals:
		print("Re-enable Scene Tools plugin once Modular Browser is enabled.")
		return
	var bus_array = ab_lib.ABGlobalSignals.get_global_bus_array(["scene_tools_send"])
	ab_lib.ABGlobalSignals.connect_send_files_to_bus(bus_array, _on_data_items_sent)


func _on_data_items_sent(items, root):
	if not plugin_enabled:
		set_plugin_enabled(true)
		
	var scenes = ab_lib.ABTree.Static.get_item_array_paths(items,[],["PackedScene"])
	if scenes.is_empty():
		#update_selected_assets([])
		return
	var path = scenes[0]
	var uid = ab_lib.Stat.ed_util.path_to_uid(path)
	
	update_selected_assets(scenes)
	editor_grab_focus()

static var plugin_instance
## /

var gui_instance: GuiHandler

var root_node: Node: # scene added to here
	set(val):
		root_node = val
		_get_state()
var terrain3D_node:
	set(val):
		terrain3D_node = val
		_get_state()



var scene_root: Node
var undo_redo: EditorUndoRedoManager
var plugin_enabled := false
var selected_assets: Array

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
	
	EditorInterface.get_selection().selection_changed.connect(_on_editor_selection_changed, 1)


func _exit_tree() -> void:
	save_config()
	for tool in tools: # doesn't seem to cause issues, but may be unnecessary?
		tool.exit()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and plugin_enabled:
		if event.keycode == KEY_ESCAPE:
			set_plugin_enabled(false)

func _get_plugin_name() -> String:
	return plugin_name

func _edit(object: Object) -> void: # sets root
	current_tool.edit(object)

func _on_editor_selection_changed():
	if not plugin_enabled:
		return
	var selection = EditorInterface.get_selection().get_selected_nodes()
	if selection.is_empty():
		set_plugin_enabled(false)


func _on_scene_changed(_scene_root: Node) -> void:
	current_tool._on_scene_changed(_scene_root)
func _on_scene_closed(path: String) -> void:
	current_tool._on_scene_closed(path)

func _handles(object: Object) -> bool:
	return current_tool.handles(object)

func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if not plugin_enabled or not root_node:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	return current_tool.forward_3d_gui_input(viewport_camera, event)

func get_config_file():
	var config = ConfigFile.new()
	if not FileAccess.file_exists(CONFIG_PATH):
		var c = ConfigFile.new()
		c.save(CONFIG_PATH)
		await get_tree().process_frame
	
	var err = config.load(CONFIG_PATH)
	if err != OK:
		print("Error loading SceneTools config: ", err)
	return config

func save_config():
	var configuration = await get_config_file()
	for tool in tools:
		tool.save_state(configuration)
	
	configuration.save(CONFIG_PATH)

func load_config():
	var configuration = await get_config_file()
	for tool in tools:
		tool.load_state(configuration)

func set_plugin_enabled(enabled: bool) -> void:
	plugin_enabled = enabled
	current_tool._on_plugin_enabled(enabled)
	if enabled:
		var selected = EditorInterface.get_selection().get_selected_nodes()
		if not selected.is_empty():
			return
		# prefer neither root_node or ed_scene_root to avoid bounding box
		var ed_scene_root = EditorInterface.get_edited_scene_root()
		if ed_scene_root is not Node3D:
			print("Can't use in non-3D scenes.")
			set_plugin_enabled(false)
			return
		
		if ed_scene_root.get_child_count() == 0:
			EditorInterface.edit_node(ed_scene_root)
		else:
			var children = ed_scene_root.get_children()
			
			for c in children:
				if c != root_node and not check_terrain_3D_node(c) and c.owner == ed_scene_root:
					EditorInterface.edit_node(c)
					return
			if root_node:
				EditorInterface.edit_node(root_node)
			else:
				EditorInterface.edit_node(ed_scene_root.get_child(0))
			

func update_selected_assets(new_selected:Array) -> void:
	# Remove directories
	new_selected = new_selected.filter(func(path: String) -> bool:
		return not path.ends_with("/")
	)
	
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


func _set_state(state: Dictionary) -> void:
	var root_path = state.get("SceneToolsRootPath")
	var terrain_3d_path = state.get("SceneToolsTerrainPath")
	var editor_scene_root = EditorInterface.get_edited_scene_root()
	if root_path:
		var node_path = NodePath(root_path)
		var last_root
		if not editor_scene_root.has_node(node_path):
			last_root = editor_scene_root
		else:
			last_root = editor_scene_root.get_node(node_path)
		set_root_node(last_root)
	if terrain_3d_path:
		var node_path = NodePath(terrain_3d_path)
		if editor_scene_root.has_node(node_path):
			var terrain = editor_scene_root.get_node(node_path)
			set_terrain_3D_node(terrain)
		else:
			set_terrain_3D_node(null)
	else:
		set_terrain_3D_node(null)

func _get_state():
	var state = {}
	var editor_scene_root = EditorInterface.get_edited_scene_root()
	if root_node:
		if root_node == editor_scene_root or root_node.owner == editor_scene_root:
			var path:NodePath = editor_scene_root.get_path_to(root_node)
			state["SceneToolsRootPath"] = path
	if terrain3D_node:
		if terrain3D_node == editor_scene_root or terrain3D_node.owner == editor_scene_root:
			var path:NodePath = editor_scene_root.get_path_to(terrain3D_node)
			state["SceneToolsTerrainPath"] = path
	
	return state

func set_root_node(node):
	root_node = node
	for tool in tools:
		tool.set_root_node(root_node)
	if is_instance_valid(gui_instance):
		gui_instance.set_root_node_name(root_node)

func set_terrain_3D_node(node):
	terrain3D_node = node
	for tool in tools:
		if tool.has_method("set_terrain_3D_node"):
			tool.set_terrain_3D_node(node)
	if is_instance_valid(gui_instance):
		gui_instance.set_terrain_3D_node_name(node)

func editor_grab_focus():
	if not EditorInterface.get_base_control().get_window().has_focus():
		EditorInterface.get_base_control().get_window().grab_focus()

static func check_terrain_3D_node(node):
	var check_script = load(TERRAIN3D_CHECK_PATH)
	var is_terrain = check_script.check_terrain_3D_node(node)
	if not is_terrain:
		return false
	return true
