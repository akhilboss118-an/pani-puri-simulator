## Instantiates user-imported GLB models dropped into
## res://assets/environment/props/. Placements live in placements.json next to
## it; each entry is:
##   { "file": "res://assets/environment/props/chair.glb", "anchor": "terrace_left",
##     "offset": [0, 0, 0], "rotation_deg": [0, 0, 0], "scale": 1.0, "enabled": false }
## See ART_PIPELINE.md for the manual Sketchfab/Mixamo import workflow.

extends Node

const PLACEMENTS_PATH := "res://assets/environment/placements.json"
const PROPS_DIR := "res://assets/environment/props"

var root: Node3D
var loaded: int = 0


func apply(world: Node3D) -> void:
	root = Node3D.new()
	root.name = "ImportedProps"
	world.add_child(root)
	var parsed := _read_manifest()
	if parsed.is_empty():
		return
	var entries: Array = parsed.get("props", [])
	for entry in entries:
		if not _spawn(entry):
			continue
	loaded = loaded
	print("EnvironmentLoader: loaded ", loaded, " imported prop(s)")


func anchor_position(anchor: String) -> Vector3:
	match anchor:
		"entrance":
			return Vector3(-8.0, 0.14, 10.2)
		"terrace_left":
			return Vector3(-6.2, 0.13, 11.2)
		"terrace_right":
			return Vector3(6.2, 0.13, 11.2)
		"counter_left":
			return Vector3(-3.4, 0.0, 9.4)
		"counter_right":
			return Vector3(3.5, 0.0, 9.3)
		"balcony":
			return Vector3(0.0, 3.2, 11.6)
		"street_far":
			return Vector3(-20.0, 0.1, 0.5)
		"road_far":
			return Vector3(-14.0, 0.1, -6.0)
		_:
			return Vector3.ZERO


func _spawn(entry: Dictionary) -> bool:
	if not bool(entry.get("enabled", false)):
		return false
	var path := String(entry.get("file", ""))
	if path == "":
		return false
	if not ResourceLoader.exists(path):
		push_warning("EnvironmentLoader: missing " + path)
		return false
	var scene: Resource = load(path)
	var packed := scene as PackedScene
	if packed == null:
		return false
	var node3d := packed.instantiate() as Node3D
	if node3d == null:
		return false
	node3d.position = anchor_position(String(entry.get("anchor", "entrance")))
	node3d.position += _vec3_from(entry.get("offset", [0, 0, 0]))
	node3d.rotation_degrees = _vec3_from(entry.get("rotation_deg", [0, 0, 0]))
	var scale := float(entry.get("scale", 1.0))
	if scale != 1.0:
		node3d.scale = Vector3(scale, scale, scale)
	for mesh in node3d.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(node3d)
	loaded += 1
	return true


func _read_manifest() -> Dictionary:
	if not FileAccess.file_exists(PLACEMENTS_PATH):
		return Dictionary()
	var file := FileAccess.open(PLACEMENTS_PATH, FileAccess.READ)
	if file == null:
		return Dictionary()
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return Dictionary()
	return parsed as Dictionary


static func _vec3_from(data: Variant, default: Vector3 = Vector3.ZERO) -> Vector3:
	if typeof(data) != TYPE_ARRAY or data.size() < 3:
		return default
	return Vector3(float(data[0]), float(data[1]), float(data[2]))
