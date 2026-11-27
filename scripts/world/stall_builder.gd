class_name StallBuilder
extends RefCounted
## Builds the player's cart out of primitives and returns the station nodes so
## the world can wire upgrades to them.

static func build(parent: Node3D) -> Dictionary:
	var root := Node3D.new()
	root.name = "Stall"
	parent.add_child(root)

	var counter_z := 8.85
	_counter(root, counter_z)
	_canopy(root)
	var sign_data := _signage(root, counter_z)
	_side_table(root)

	# --- stations on the counter -------------------------------------------
	var puri_box := PuriBoxStation.new()
	puri_box.position = Vector3(-1.85, 0.98, counter_z)
	root.add_child(puri_box)

	var potato := BowlStation.new()
	potato.configure("potato", 2, 0.105)
	potato.position = Vector3(-1.4, 0.98, counter_z)
	root.add_child(potato)

	var chickpea := BowlStation.new()
	chickpea.configure("chickpea", 2, 0.095)
	chickpea.position = Vector3(-1.07, 0.98, counter_z)
	root.add_child(chickpea)

	var onion := BowlStation.new()
	onion.configure("onion", 2, 0.09)
	onion.position = Vector3(-0.76, 0.98, counter_z)
	root.add_child(onion)

	var coriander := BowlStation.new()
	coriander.configure("coriander", 2, 0.085)
	coriander.position = Vector3(-0.47, 0.98, counter_z)
	root.add_child(coriander)

	var masala := BowlStation.new()
	masala.configure("masala", 2, 0.08)
	masala.position = Vector3(-0.2, 0.98, counter_z)
	root.add_child(masala)

	var pani_mint := PaniStation.new()
	pani_mint.configure("mint")
	pani_mint.position = Vector3(0.3, 0.98, counter_z)
	root.add_child(pani_mint)

	var pani_garlic := PaniStation.new()
	pani_garlic.configure("garlic")
	pani_garlic.position = Vector3(0.72, 0.98, counter_z)
	root.add_child(pani_garlic)
	pani_garlic.set_enabled(Progression.has_upgrade("garlic_pani"))

	var chutney := ChutneyStation.new()
	chutney.position = Vector3(1.08, 0.98, counter_z)
	root.add_child(chutney)

	var plate := PlateStation.new()
	plate.position = Vector3(1.72, 0.98, counter_z)
	root.add_child(plate)

	var trash := TrashStation.new()
	trash.position = Vector3(2.6, 0.12, 9.5)
	root.add_child(trash)

	var potato_machine := PotatoMachine.new()
	potato_machine.position = Vector3(3.2, 0.12, 9.1)
	root.add_child(potato_machine)

	return {
		"root": root,
		"plate": plate,
		"puri_box": puri_box,
		"potato": potato,
		"chickpea": chickpea,
		"onion": onion,
		"coriander": coriander,
		"masala": masala,
		"pani_mint": pani_mint,
		"pani_garlic": pani_garlic,
		"chutney": chutney,
		"trash": trash,
		"potato_machine": potato_machine,
		"sign": sign_data.sign,
		"menu_label": sign_data.menu_label,
	}


static func _counter(root: Node3D, z: float) -> void:
	MeshFactory.box(root, Vector3(4.2, 0.86, 0.7), Vector3(0, 0.43, z), GameData.C_WOOD, "Counter")
	MeshFactory.box(root, Vector3(4.2, 0.09, 0.72), Vector3(0, 0.905, z), GameData.C_STEEL, "CounterTop", 0.0, false)
	MeshFactory.box(root, Vector3(3.9, 0.5, 0.04), Vector3(0, 0.42, z - 0.37), GameData.C_TEAL, "FrontPanel")
	MeshFactory.box(root, Vector3(3.9, 0.05, 0.04), Vector3(0, 0.7, z - 0.37), GameData.C_ORANGE, "Trim", 0.0, false)
	# wheels
	for sx in [-1.8, 1.8]:
		for sz in [-0.2, 0.2]:
			var wheel := MeshFactory.cylinder(root, 0.16, 0.1, Vector3(sx, 0.16, z + sz), Color("2b2622"), "Wheel", 10, false)
			wheel.rotation.z = PI / 2.0
	MeshFactory.add_box_collider(root, Vector3(4.2, 0.95, 0.7), Vector3(0, 0.475, z), 1)


static func _canopy(root: Node3D) -> void:
	var z := 8.85
	for x in [-2.1, 2.1]:
		for dz in [-0.55, 0.55]:
			MeshFactory.cylinder(root, 0.035, 2.6, Vector3(x, 1.3, z + dz), Color("4a4038"), "Pole", 8, false)
	# striped awning, with a bright unshaded underside so it reads as fabric
	# catching light instead of a dark ceiling above the vendor.
	for i in 6:
		var color := GameData.C_ORANGE if i % 2 == 0 else Color("f2e2c4")
		var x := -2.34 + i * 0.78
		MeshFactory.box(root, Vector3(0.78, 0.06, 1.45), Vector3(x, 2.62, z), color, "Stripe", 0.0, false)
		var under := MeshFactory.quad(root, Vector2(0.76, 1.43), Vector3(x, 2.587, z), color.lightened(0.16), "StripeUnder")
		under.rotation.x = PI / 2.0
	MeshFactory.box(root, Vector3(4.75, 0.1, 0.12), Vector3(0, 2.55, z - 0.72), Color("cf4a34"), "Valance", 0.0, false)
	# hanging bulbs
	for x in [-1.4, 0.0, 1.4]:
		MeshFactory.cylinder(root, 0.006, 0.35, Vector3(x, 2.36, z - 0.2), Color("2b2622"), "Cord", 6, false)
		var bulb := MeshFactory.sphere(root, 0.055, Vector3(x, 2.16, z - 0.2), Color("ffd27a"), "Bulb", 8, false)
		var mat := MeshFactory.material(Color("ffd27a"), 0.4, 0.0, true)
		mat.emission_enabled = true
		mat.emission = Color("ffb347")
		mat.emission_energy_multiplier = 1.6
		bulb.material_override = mat


static func _signage(root: Node3D, z: float) -> Dictionary:
	# The main board sits on top of the canopy. From the vendor side you see its
	# back, not a wall of text in your face.
	var sign_root := MeshFactory.signboard(root, "PANI PURI", Vector3(0, 2.98, z - 0.55), 3.5, GameData.C_ORANGE, Color("fff4dc"), 0.56, PI)
	sign_root.name = "MainSign"
	MeshFactory.box(root, Vector3(3.64, 0.07, 0.16), Vector3(0, 2.66, z - 0.55), Color("8a3a18"), "SignBase", 0.0, false)
	for sx in [-1.55, 1.55]:
		MeshFactory.cylinder(root, 0.03, 0.22, Vector3(sx, 2.7, z - 0.55), Color("5a4030"), "SignPost", 6, false)
	# Smaller board hanging under the valance, still above eye level.
	var sub_sign := MeshFactory.signboard(root, "GOLGAPPA  -  CHAAT", Vector3(0, 2.36, z - 0.73), 2.6, GameData.C_TEAL, Color("fff4dc"), 0.2, PI)
	sub_sign.name = "SubSign"
	MeshFactory.box(root, Vector3(2.3, 0.52, 0.03), Vector3(0, 0.42, z - 0.39), Color("211812"), "Menu", 0.0, false)
	var label := Label3D.new()
	label.text = "PANI PURI  Rs 30\nEXTRA PURI  Rs 30"
	label.font_size = 40
	label.pixel_size = 0.004
	label.position = Vector3(0, 0.42, z - 0.41)
	label.rotation.y = PI
	label.modulate = Color("f7e6c4")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(label)
	return {"sign": sign_root, "sub_sign": sub_sign, "menu_label": label}


static func _side_table(root: Node3D) -> void:
	# decorative fryer and crates, kept out of the interaction lane
	MeshFactory.box(root, Vector3(0.8, 0.6, 0.7), Vector3(-2.85, 0.3, 8.9), Color("5b4632"), "SideTable")
	MeshFactory.cylinder(root, 0.26, 0.2, Vector3(-2.85, 0.72, 8.9), Color("3a3330"), "Kadai", 14)
	MeshFactory.cylinder(root, 0.23, 0.04, Vector3(-2.85, 0.8, 8.9), Color("6b4a1f"), "Oil", 14, false)
	for i in 3:
		MeshFactory.box(root, Vector3(0.34, 0.3, 0.34), Vector3(-2.4 + i * 0.05, 0.15 + i * 0.3, 9.55), Color("a97b4a").darkened(i * 0.08), "Crate", 0.2 * i)
