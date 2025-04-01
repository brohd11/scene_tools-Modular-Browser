Fork of SceneTools by fstxz

This fork is to integrate with Modular Browser plugin for Godot.
This version will not work without Modular Browser.

Requires 'scene_tools_interface.gd' placed into 'modular_browser/user'.
The layouts can be added to 'modular_browser/plugin/config/layouts'.

Moves all UI to an instance-able scene, that can be removed or added as needed.
Also changes how the plugin functions in regard to enabling and node selection.

Instead of activating the plugin through the toolbar, you just select an asset from the
Modular Browser filter panel. Pressing escape or selecting no nodes will disable it until you
select another asset.

The target node the scenes should be added to can be set by pressing the Node3D button in the UI, 
when the desired node is selected. This will persist between switching scenes.

Can be setup in any way, but the examples I have are bottom panel and a floating window.
