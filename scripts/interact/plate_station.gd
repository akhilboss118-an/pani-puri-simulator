class_name PlateStation
extends Interactable
## The serving plate on the handover counter. This is where the order is
## assembled and where the player serves the waiting customer.

var puris: Array[PuriItem] = []
var _plate_root: Node3D
var _count_label: Label3D


func _ready() -> void:
	super._ready()
	station_label = "Serving plate"
	_build()
	add_hit_box(Vector3(0.5, 0.14, 0.5), Vector3(0, 0.05, 0))


func _build() -> void:
	_plate_root = Node3D.new()
	_plate_root.name = "Plate"
	add_child(_plate_root)
	var steel := MeshFactory.material(Color("cfd5da"), 0.2, 0.88)
	var plate_base := MeshFactory.cylinder(_plate_root, 0.24, 0.018, Vector3(0, 0.01, 0), Color("d5d9dc"), "Plate", 24)
	plate_base.material_override = steel
	var rim := TorusMesh.new()
	rim.inner_radius = 0.22
	rim.outer_radius = 0.252
	rim.rings = 20
	rim.ring_segments = 8
	var rim_mi := MeshInstance3D.new()
	rim_mi.mesh = rim
	rim_mi.position = Vector3(0, 0.022, 0)
	rim_mi.material_override = steel
	rim_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_plate_root.add_child(rim_mi)
	_count_label = MeshFactory.label(self, "0 / %d" % Progression.plate_capacity(), Vector3(0, 0.22, 0), 34, Color("fff2d4"), 0.0024)
	_count_label.visible = false


func _slot_position(index: int) -> Vector3:
	var col := index % 3
	var row := int(index / 3)
	return Vector3((col - 1) * 0.115, 0.03 + row * 0.002, (row - 1) * 0.115 + 0.02)


func capacity() -> int:
	return Progression.plate_capacity()


func is_full() -> bool:
	return puris.size() >= capacity()


func get_prompt(player: Node) -> String:
	var held = player.get("held_item")
	if held != null:
		if is_full():
			return "Plate is full - serve the customer"
		return "Place puri on plate (%d/%d)" % [puris.size(), capacity()]
	if Orders.active_customer != null and not puris.is_empty():
		return "Serve order (%d/%d puris)" % [puris.size(), int(Orders.active_order.get("quantity", 0))]
	if not puris.is_empty():
		return "Take back the last puri"
	return "Serving plate - bring a finished puri"


func can_interact(_player: Node) -> bool:
	return true


func interact(player: Node) -> void:
	var held = player.get("held_item")
	if held != null:
		if is_full():
			Events.toast.emit("The plate is full. Serve the customer first.", "info")
			return
		var item: PuriItem = player.call("take_held_item")
		if item == null:
			return
		var start_global := item.global_position
		var slot_idx := puris.size()
		var target_local := _slot_position(slot_idx)
		var target_rot := randf_range(-PI, PI)
		item.reparent(_plate_root)
		puris.append(item)
		if player.has_method("play_hand_action"):
			player.call("play_hand_action", "place")
		if Game.settings.get("reduced_motion", false):
			item.transform = Transform3D(Basis(Vector3.UP, target_rot), target_local)
			item.scale = Vector3.ONE
		else:
			item.global_position = start_global
			item.scale = Vector3(1.25, 1.25, 1.25)
			var mid_local := (item.position + target_local) * 0.5 + Vector3(0, 0.14, 0)
			var tw := item.create_tween()
			tw.tween_property(item, "position", mid_local, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(item, "scale", Vector3(1.08, 1.08, 1.08), 0.09)
			tw.parallel().tween_property(item, "rotation", Vector3(0, target_rot, 0), 0.18)
			tw.tween_property(item, "position", target_local, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(item, "scale", Vector3(1.0, 0.85, 1.0), 0.1)
			tw.tween_property(item, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		Audio.play("click", 1.3, -14.0)
		_refresh_label()
		return

	if Orders.active_customer != null and not puris.is_empty():
		var manager := get_tree().get_first_node_in_group("customer_manager")
		if manager == null:
			return
		var data_list: Array[PuriData] = []
		for item in puris:
			data_list.append(item.data)
		var served: bool = manager.call("serve_plate", data_list)
		if served:
			if player.has_method("play_hand_action"):
				player.call("play_hand_action", "serve")
			if not Game.settings.get("reduced_motion", false) and _plate_root != null:
				var ptw := create_tween()
				ptw.tween_property(_plate_root, "position:z", -0.14, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				ptw.tween_property(_plate_root, "position:z", 0.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			for item in puris:
				item.queue_free()
			puris.clear()
			_refresh_label()
		return

	if not puris.is_empty():
		var last: PuriItem = puris.pop_back()
		player.call("carry_item", last, true)
		_refresh_label()
		return

	Events.toast.emit("Nothing to serve yet. Prepare a puri first.", "info")


func _refresh_label() -> void:
	if _count_label:
		_count_label.text = "%d / %d" % [puris.size(), capacity()]
		_count_label.visible = not puris.is_empty()
		Audio.play("click", 1.0, -16.0)


func clear_plate() -> void:
	for item in puris:
		item.queue_free()
	puris.clear()
	_refresh_label()
