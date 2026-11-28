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

	# --- stations on the counter (arranged like the reference stall layout) ---
	var puri_box := PuriBoxStation.new()
	puri_box.position = Vector3(-1.68, 0.96, counter_z - 0.02)
	root.add_child(puri_box)

	# Back row: Potato, Chickpeas, Mint Pani, Garlic Pani (when unlocked), Sweet Chutney
	var potato := BowlStation.new()
	potato.configure("potato", 2, 0.145)
	potato.position = Vector3(-1.02, 0.96, counter_z - 0.14)
	root.add_child(potato)

	var chickpea := BowlStation.new()
	chickpea.configure("chickpea", 2, 0.14)
	chickpea.position = Vector3(-0.56, 0.96, counter_z - 0.14)
	root.add_child(chickpea)

	var pani_mint := PaniStation.new()
	pani_mint.configure("mint")
	pani_mint.position = Vector3(-0.04, 0.96, counter_z - 0.14)
	root.add_child(pani_mint)

	var pani_garlic := PaniStation.new()
	pani_garlic.configure("garlic")
	pani_garlic.position = Vector3(0.40, 0.96, counter_z - 0.14)
	root.add_child(pani_garlic)
	pani_garlic.set_enabled(Progression.has_upgrade("garlic_pani"))

	var chutney := ChutneyStation.new()
	chutney.position = Vector3(0.84, 0.96, counter_z - 0.14)
	root.add_child(chutney)

	# Front row: Serving plate centered + 3 small katori bowls (onion, coriander, masala)
	var plate := PlateStation.new()
	plate.position = Vector3(-0.48, 0.96, counter_z + 0.24)
	root.add_child(plate)

	var onion := BowlStation.new()
	onion.configure("onion", 2, 0.08)
	onion.position = Vector3(0.16, 0.96, counter_z + 0.23)
	root.add_child(onion)

	var coriander := BowlStation.new()
	coriander.configure("coriander", 2, 0.08)
	coriander.position = Vector3(0.44, 0.96, counter_z + 0.23)
	root.add_child(coriander)

	var masala := BowlStation.new()
	masala.configure("masala", 2, 0.08)
	masala.position = Vector3(0.72, 0.96, counter_z + 0.23)
	root.add_child(masala)

	var trash := TrashStation.new()
	trash.position = Vector3(2.6, 0.12, 9.5)
	root.add_child(trash)

	var potato_machine := PotatoMachine.new()
	potato_machine.position = Vector3(3.2, 0.12, 9.1)
	root.add_child(potato_machine)

	var counter_chalk := _counter_chalkboard(root, counter_z)

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
		"sub_sign": sign_data.sub_sign,
		"menu_label": sign_data.menu_label,
		"chalk_label": counter_chalk,
	}


static func _counter(root: Node3D, z: float) -> void:
	var wood_tex := MeshFactory.noise_texture("counter_wood", Color("7a4c28"), 0.045, 96, 33)
	var wood_top_mat := StandardMaterial3D.new()
	wood_top_mat.albedo_texture = wood_tex
	wood_top_mat.uv1_scale = Vector3(4, 1.5, 1)
	wood_top_mat.roughness = 0.62
	wood_top_mat.metallic = 0.04
	var wood_mat := MeshFactory.material(Color("633e24"), 0.72, 0.04)
	var wood_dark := MeshFactory.material(Color("452a17"), 0.78, 0.04)
	var steel_mat := MeshFactory.material(Color("bfc5ca"), 0.28, 0.78)
	var brass_mat := MeshFactory.material(Color("d6a449"), 0.26, 0.84)

	var body := MeshFactory.box(root, Vector3(4.3, 0.86, 0.86), Vector3(0, 0.43, z), GameData.C_WOOD, "Counter")
	body.material_override = wood_mat
	# Warm oiled wooden counter plank top (matching the rich timber counter in the reference!)
	var top := MeshFactory.box(root, Vector3(4.42, 0.085, 0.94), Vector3(0, 0.915, z), Color("7a4c28"), "CounterTop", 0.0, false)
	top.material_override = wood_top_mat
	MeshFactory.box(root, Vector3(4.44, 0.032, 0.045), Vector3(0, 0.94, z + 0.46), Color("d6a449"), "CounterLip", 0.0, false).material_override = brass_mat
	MeshFactory.box(root, Vector3(4.44, 0.032, 0.045), Vector3(0, 0.94, z - 0.46), Color("d6a449"), "CounterFrontLip", 0.0, false).material_override = brass_mat

	# Customer-facing front panel (z - 0.44): teal wainscot + warm brass crest
	MeshFactory.box(root, Vector3(4.02, 0.54, 0.05), Vector3(0, 0.45, z - 0.44), GameData.C_TEAL, "FrontPanel")
	MeshFactory.box(root, Vector3(4.06, 0.05, 0.06), Vector3(0, 0.74, z - 0.44), GameData.C_ORANGE, "Trim", 0.0, false)
	var front_crest := Label3D.new()
	front_crest.text = "PANI PURI"
	front_crest.font = UIKit.display_font(800)
	front_crest.font_size = 40
	front_crest.pixel_size = 0.0038
	front_crest.position = Vector3(-0.85, 0.5, z - 0.475)
	front_crest.rotation.y = PI
	front_crest.modulate = Color("fff0cf")
	front_crest.outline_size = 3
	front_crest.outline_modulate = Color("2a1a10")
	front_crest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	front_crest.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(front_crest)

	# Vendor-facing side (z + 0.43): clean slatted timber + brass foot rail
	MeshFactory.box(root, Vector3(4.0, 0.64, 0.05), Vector3(0, 0.46, z + 0.425), Color("4a3222"), "NearPanel").material_override = wood_dark
	for i in 7:
		MeshFactory.box(root, Vector3(0.04, 0.58, 0.02), Vector3(-1.75 + i * 0.58, 0.45, z + 0.455), Color("352115"), "NearSlat", 0.0, false)
	MeshFactory.box(root, Vector3(4.06, 0.035, 0.07), Vector3(0, 0.80, z + 0.43), Color("d6a449"), "NearTrim", 0.0, false).material_override = brass_mat
	var rail := MeshFactory.cylinder(root, 0.022, 3.8, Vector3(0, 0.28, z + 0.49), Color("d6a449"), "BrassRail", 8, false)
	rail.rotation.z = PI / 2.0
	rail.material_override = brass_mat

	# Stack of green banana-leaf dona bowls next to the puri jar (matching reference!)
	for i in 8:
		var dona := MeshFactory.cylinder(root, 0.095 + i * 0.002, 0.011, Vector3(-1.28, 0.965 + i * 0.012, z + 0.22), Color("70863a").lightened(i * 0.02), "LeafPlate", 14, false)
		dona.material_override = MeshFactory.material(Color("70863a"), 0.82, 0.0)

	# Stack of spare foil/steel serving trays on the right side of the counter
	for i in 8:
		var tray := MeshFactory.box(root, Vector3(0.24, 0.01, 0.18), Vector3(1.16, 0.965 + i * 0.012, z + 0.12), Color("cfd5da"), "SpareTray", 0.06, false)
		tray.material_override = steel_mat

	# wheels
	for sx in [-1.85, 1.85]:
		for sz in [-0.26, 0.26]:
			var wheel := MeshFactory.cylinder(root, 0.16, 0.1, Vector3(sx, 0.16, z + sz), Color("24201d"), "Wheel", 12, false)
			wheel.rotation.z = PI / 2.0
			var hub := MeshFactory.cylinder(root, 0.075, 0.112, Vector3(sx, 0.16, z + sz), Color("d6a449"), "WheelHub", 10, false)
			hub.rotation.z = PI / 2.0
			hub.material_override = brass_mat
	MeshFactory.add_box_collider(root, Vector3(4.3, 0.95, 0.88), Vector3(0, 0.475, z), 1)


static func _counter_chalkboard(root: Node3D, z: float) -> Label3D:
	# Angled wooden-framed chalkboard standing right on the right side of the counter
	var board := Node3D.new()
	board.name = "CounterChalkboard"
	board.position = Vector3(1.68, 0.96, z - 0.04)
	board.rotation.y = -0.32
	root.add_child(board)
	var frame_mat := MeshFactory.material(Color("6b4423"), 0.72, 0.03)
	var slate := MeshFactory.box(board, Vector3(0.46, 0.56, 0.03), Vector3(0, 0.30, 0), Color("1b221e"), "Slate", 0.0, false)
	slate.rotation.x = -0.18
	MeshFactory.box(board, Vector3(0.50, 0.035, 0.045), Vector3(0, 0.58, -0.05), Color("6b4423"), "TopFrame", 0.0, false).material_override = frame_mat
	MeshFactory.box(board, Vector3(0.50, 0.035, 0.045), Vector3(0, 0.02, 0.05), Color("6b4423"), "BotFrame", 0.0, false).material_override = frame_mat
	MeshFactory.box(board, Vector3(0.035, 0.58, 0.045), Vector3(-0.235, 0.30, 0), Color("6b4423"), "LFrame", 0.0, false).material_override = frame_mat
	MeshFactory.box(board, Vector3(0.035, 0.58, 0.045), Vector3(0.235, 0.30, 0), Color("6b4423"), "RFrame", 0.0, false).material_override = frame_mat
	var lbl := Label3D.new()
	lbl.text = "Pani Puri\n₹%d/-\n(6 Pcs)" % Progression.price_per_puri
	lbl.font = UIKit.display_font(700)
	lbl.font_size = 40
	lbl.pixel_size = 0.00175
	lbl.position = Vector3(0, 0.31, 0.022)
	lbl.rotation.x = -0.18
	lbl.modulate = Color("f8ecd2")
	lbl.outline_size = 0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	board.add_child(lbl)
	return lbl


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
	MeshFactory.box(root, Vector3(1.85, 0.46, 0.03), Vector3(0.95, 0.46, z - 0.405), Color("211812"), "Menu", 0.0, false)
	var label := Label3D.new()
	label.text = "PANI PURI  Rs 30\nEXTRA PURI  Rs 30"
	label.font = UIKit.ui_font(700, 1)
	label.font_size = 36
	label.pixel_size = 0.0036
	label.position = Vector3(0.95, 0.46, z - 0.425)
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
