class_name PuriBoxStation
extends Interactable
## Clear glass/acrylic counter jar packed with crispy golden puris.
## Take a shell from the jar, or tap the rim to crack one open.

var _stack: Node3D
var _puris: Array[MeshInstance3D] = []
var _jar_body: Node3D


func _ready() -> void:
	super._ready()
	station_label = "Puri jar"
	_build()
	add_hit_box(Vector3(0.44, 0.44, 0.42), Vector3(0, 0.2, 0))
	Events.stock_changed.connect(_on_stock_changed)
	_sync_fill()


func _build() -> void:
	_jar_body = Node3D.new()
	_jar_body.name = "JarVisual"
	add_child(_jar_body)

	var steel := MeshFactory.material(Color("c6ccd0"), 0.25, 0.82)
	var brass := MeshFactory.material(Color("d6a449"), 0.26, 0.85)
	var glass := MeshFactory.material_glass(Color("eef6fa"), 0.24, 0.08)

	# Stainless steel tray base
	var base := MeshFactory.cylinder(_jar_body, 0.185, 0.024, Vector3(0, 0.012, 0), Color("c6ccd0"), "Base", 18, true)
	base.material_override = steel

	# Golden puris piled inside the transparent jar
	_stack = Node3D.new()
	_stack.name = "PuriPile"
	_jar_body.add_child(_stack)
	var puri_mat := MeshFactory.material(Color("e6a94e"), 0.65, 0.02)
	var puri_warm := MeshFactory.material(Color("d9943b"), 0.68, 0.02)
	var layers := [
		{"y": 0.055, "r": 0.11, "n": 7},
		{"y": 0.105, "r": 0.105, "n": 7},
		{"y": 0.155, "r": 0.11, "n": 7},
		{"y": 0.205, "r": 0.10, "n": 7},
		{"y": 0.255, "r": 0.09, "n": 6},
		{"y": 0.305, "r": 0.075, "n": 5},
	]
	var idx := 0
	for layer in layers:
		var n := int(layer.n)
		for i in n:
			var a := TAU * float(i) / float(n) + idx * 0.4
			var r := float(layer.r) * (0.42 if (i == 0 and n >= 6) else 1.0)
			var pos := Vector3(cos(a) * r, float(layer.y), sin(a) * r)
			var p := MeshFactory.sphere(_stack, 0.052, pos, Color("e6a94e"), "Shell", 10, false)
			p.scale = Vector3(1.0, 0.78, 1.0)
			p.material_override = puri_mat if idx % 2 == 0 else puri_warm
			_puris.append(p)
			idx += 1

	# Large transparent crystal jar cylinder + rim
	var jar := MeshFactory.cylinder(_jar_body, 0.21, 0.42, Vector3(0, 0.22, 0), Color("eef6fa"), "GlassJar", 22, false)
	jar.material_override = glass
	var rim := MeshFactory.torus(_jar_body, 0.198, 0.22, Vector3(0, 0.43, 0), Color("d4dce0"), "JarRim", 0.22, 0.75)
	rim.material_override = steel
	# Clear/steel lid resting behind the jar
	var lid := MeshFactory.cylinder(_jar_body, 0.195, 0.022, Vector3(0.14, 0.44, -0.14), Color("c6ccd0"), "Lid", 18, false)
	lid.rotation.x = 0.85
	lid.rotation.z = -0.35
	lid.material_override = steel


func _on_stock_changed(id: String) -> void:
	if id == "" or id == "puri":
		_sync_fill()


func _sync_fill() -> void:
	if _puris.is_empty():
		return
	var stock := Inventory.get_stock("puri")
	if stock <= 0:
		for p in _puris:
			p.visible = false
		return
	var ratio := clampf(float(stock) / 55.0, 0.25, 1.0)
	var show_count := int(ceil(ratio * float(_puris.size())))
	for i in _puris.size():
		_puris[i].visible = i < show_count


func _pulse() -> void:
	if _jar_body == null or Game.settings.get("reduced_motion", false):
		return
	_jar_body.scale = Vector3(1.04, 0.96, 1.04)
	var tw := create_tween()
	tw.tween_property(_jar_body, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func get_prompt(player: Node) -> String:
	var held = player.get("held_item")
	if held == null:
		if Inventory.has("puri"):
			return "Take a puri shell (%d left)" % Inventory.get_stock("puri")
		return "Out of puri shells - restock in Inventory"
	if held.data.state == PuriData.State.EMPTY:
		return "Crack the puri open"
	return "Hands full - finish this puri first"


func interact(player: Node) -> void:
	var held = player.get("held_item")
	if held == null:
		if not Inventory.consume("puri"):
			Events.toast.emit("Out of puri shells. Restock in the Inventory panel.", "bad")
			Audio.play("bad", 1.0, -10.0)
			return
		var item := PuriItem.create()
		player.call("carry_item", item)
		if player.has_method("play_hand_action"):
			player.call("play_hand_action", "take")
		_pulse()
		Audio.play("scoop", 1.1, -9.0)
		return
	if held.data.state == PuriData.State.EMPTY:
		held.data.open()
		held.refresh()
		if player.has_method("play_hand_action"):
			player.call("play_hand_action", "crack")
		if held.has_method("play_crack_fx"):
			held.call("play_crack_fx")
		_pulse()
		Audio.play("crack", 1.0, -7.0)
		return
	Events.toast.emit("This puri is already open. Add filling or place it on the plate.", "info")
