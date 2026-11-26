extends SceneTree

func _ready() -> void:
	var etc2: Variant = ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc")
	var f := FileAccess.open("user://etc2_check.txt", FileAccess.WRITE)
	if f:
		f.store_string("ETC2_ASTC=" + str(etc2))
		f.close()
