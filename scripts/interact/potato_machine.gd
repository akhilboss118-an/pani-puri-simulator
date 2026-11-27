class_name PotatoMachine
extends Interactable
## Bought appliance that turns raw potatoes into filling on its own. The basic
## unit produces stock passively; the final upgrade auto-fills a held puri when
## the player walks close, saving one step of the prep loop.

var _enabled: bool = false
var _timer: float = 8.0
var _drum: Node3D
var _puffs: Array[Node3D] = []
var _time: float = 0.0


func _ready() -> void:
	super._ready()
	station_label = "Potato prep machine"
	_build()
	add_hit_box(Vector3(0.75, 0.8, 0.6), Vector3(0, 0.45, 0))
	set_enabled(false)


func _build() -> void:
	# stand and body
	MeshFactory.box(self, Vector3(0.8, 0.12, 0.65), Vector3(0, 0.06, 0), Color("3a2d22"), "MachineFeet")
	MeshFactory.box(self, Vector3(0.68, 0.62, 0.52), Vector3(0, 0.42, 0), Color("9aa0a5"), "MachineBody")
	MeshFactory.box(self, Vector3(0.7, 0.05, 0.54), Vector3(0, 0.74, 0), GameData.C_TEAL, "MachineTop", 0.0, false)
	# hopper with raw potatoes
	MeshFactory.cylinder(self, 0.22, 0.18, Vector3(-0.16, 0.86, 0), Color("b8bcc0"), "Hopper", 12, false)
	for i in 4:
		var angle := TAU * float(i) / 4.0
		var potato := MeshFactory.sphere(self, 0.055, Vector3(-0.16 + cos(angle) * 0.08, 0.96, sin(angle) * 0.07), GameData.C_POTATO, "RawPotato", 8, false)
		potato.scale = Vector3(1.2, 0.7, 1.0)
	# spinning peeling drum
	_drum = Node3D.new()
	_drum.name = "PeelDrum"
	_drum.position = Vector3(0.12, 0.48, -0.28)
	add_child(_drum)
	MeshFactory.cylinder(_drum, 0.16, 0.24, Vector3.ZERO, Color("d9d2c4"), "Drum", 12, false)
	for i in 6:
		var angle := TAU * float(i) / 6.0
		MeshFactory.box(_drum, Vector3(0.02, 0.22, 0.04), Vector3(cos(angle) * 0.16, 0, sin(angle) * 0.16), GameData.C_GOLD, "DrumFin", 0.0, false)
	# filling nozzle
	MeshFactory.cylinder(self, 0.05, 0.16, Vector3(0.12, 0.3, 0.28), Color("cfd3d6"), "Nozzle", 8, false)
	for i in 2:
		var puff := MeshFactory.sphere(self, 0.035, Vector3(0.12 + i * 0.04, 0.62 + i * 0.08, 0.3), Color(1, 1, 1, 0.55), "Steam", 6, false)
		_puffs.append(puff)
	MeshFactory.signboard(self, "POTATO PREP", Vector3(0, 0.68, 0.28), 0.62, Color("211812"), Color("f7e6c4"), 0.12)
	visible = false


func set_enabled(value: bool) -> void:
	_enabled = value
	visible = value
	collision_layer = 4 if value else 0
	_timer = 1.0 if value else 8.0


func get_prompt(player: Node) -> String:
	if not _enabled:
		return "Potato prep machine locked - buy it in Upgrades"
	if Progression.has_upgrade("auto_fill_arm") and _held_needs_potato(player):
		return "Auto-fill arm is filling your puri - just walk closer"
	return "Potato machine - peels into filling automatically"


func interact(_player: Node) -> void:
	if not _enabled:
		return
	Events.toast.emit("The machine peels on its own. Buy the Auto-Fill Arm to fill puris hands-free.", "info")


func _process(delta: float) -> void:
	if not _enabled or Game.state != Game.State.PLAYING:
		return
	_time += delta
	if _drum != null:
		_drum.rotation.y += delta * 3.2
	for i in _puffs.size():
		var puff := _puffs[i]
		puff.position.y = 0.62 + i * 0.08 + sin(_time * 2.0 + i) * 0.03
		puff.scale = Vector3.ONE * (0.8 + 0.25 * sin(_time * 3.0 + i))

	# passive production: raw potatoes -> potato filling
	_timer -= delta
	if _timer <= 0.0:
		_timer = maxf(1.0, Progression.machine_interval())
		if Inventory.has("raw_potato") and Inventory.get_stock("potato") < Inventory.get_capacity("potato"):
			Inventory.consume("raw_potato")
			Inventory.add_stock("potato", 1)
			Audio.play("scoop", randf_range(1.25, 1.45), -14.0)

	if not Progression.has_upgrade("auto_fill_arm"):
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or global_position.distance_to(player.global_position) > 2.1:
		return
	var held = player.get("held_item")
	if held == null or not _held_needs_potato(player):
		return
	var data: PuriData = held.data
	if not Inventory.has("potato"):
		return
	Inventory.consume("potato")
	data.add_ingredient("potato", 2)
	data.auto_filled = true
	held.refresh()
	Events.held_changed.emit(data.describe())
	Audio.play("scoop", 1.1, -12.0)


func _held_needs_potato(player: Node) -> bool:
	var held = player.get("held_item")
	if held == null:
		return false
	var data: PuriData = held.data
	return data.state != PuriData.State.EMPTY and not data.has_ingredient("potato") and data.pani == "none"
