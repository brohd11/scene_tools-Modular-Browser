extends RefCounted

static func check_terrain_3D_node(node):
	if node is Terrain3D:
		return true
	return false
