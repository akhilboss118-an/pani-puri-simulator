extends Node
## Root scene. Builds the world once, owns the UI layers and routes state
## changes between the menu, the shift and the day report.

var world: WorldBuilder
var player: Player
var ui_layer: CanvasLayer

var menu: MainMenu
var hud: HUD
var inventory_panel: InventoryPanel
var upgrades_panel: UpgradesPanel
var settings_panel: SettingsPanel
var pause_panel: PausePanel
var report_panel: ReportPanel
var goals_panel: GoalsPanel
var collection_panel: CollectionPanel
var model_gallery_panel: ModelGalleryPanel
var tutorial: Tutorial

var _menu_camera: Camera3D
var _menu_time: float = 0.0

var _film_active: bool = false
var _film_time: float = 0.0
var _film_step: int = 0
var _film_timeline: Array = [
	{"at": 0.0, "fn": "film_menu"},
	{"at": 3.2, "fn": "film_counter"},
	{"at": 4.6, "fn": "film_take"},
	{"at": 5.8, "fn": "film_crack"},
	{"at": 7.0, "fn": "film_potato"},
	{"at": 8.2, "fn": "film_pani"},
	{"at": 9.4, "fn": "film_plate"},
	{"at": 10.8, "fn": "film_serve"},
	{"at": 12.0, "fn": "film_quick_puri"},
	{"at": 13.4, "fn": "film_quick_puri"},
	{"at": 14.8, "fn": "film_quick_puri"},
	{"at": 16.2, "fn": "film_quick_puri"},
	{"at": 17.2, "fn": "film_combo"},
	{"at": 18.4, "fn": "film_inventory"},
	{"at": 20.0, "fn": "film_close"},
	{"at": 20.4, "fn": "film_upgrades"},
	{"at": 22.0, "fn": "film_close"},
	{"at": 22.4, "fn": "film_grant"},
	{"at": 23.4, "fn": "film_wide"},
	{"at": 25.2, "fn": "film_flags"},
	{"at": 27.0, "fn": "film_hold"},
]

var _update_timeline: Array = [
	{"at": 0.0, "fn": "film_menu"},
	{"at": 3.0, "fn": "film_counter"},
	{"at": 4.5, "fn": "film_take"},
	{"at": 5.7, "fn": "film_crack"},
	{"at": 6.9, "fn": "film_potato"},
	{"at": 8.1, "fn": "film_pani"},
	{"at": 9.3, "fn": "film_plate"},
	{"at": 10.6, "fn": "film_serve"},
	{"at": 11.8, "fn": "film_quick_puri"},
	{"at": 13.0, "fn": "film_quick_puri"},
	{"at": 14.2, "fn": "film_quick_puri"},
	{"at": 15.4, "fn": "film_quick_puri"},
	{"at": 16.4, "fn": "film_combo"},
	{"at": 21.2, "fn": "film_grant"},
	{"at": 22.6, "fn": "film_grant_machine"},
	{"at": 23.6, "fn": "film_wide"},
	{"at": 25.0, "fn": "film_flags"},
	{"at": 27.0, "fn": "film_machine"},
	{"at": 29.5, "fn": "film_wide"},
	{"at": 31.5, "fn": "film_flags"},
	{"at": 33.5, "fn": "film_hold"},
	{"at": 36.0, "fn": "film_machine"},
	{"at": 39.0, "fn": "film_wide"},
	{"at": 42.0, "fn": "film_flags"},
	{"at": 45.0, "fn": "film_hold"},
	{"at": 48.0, "fn": "film_wide"},
	{"at": 51.0, "fn": "film_flags"},
	{"at": 54.0, "fn": "film_hold"},
]


func _ready() -> void:
	Game.root = self
	_build_world()
	_build_ui()
	Events.day_ended.connect(_on_day_ended)
	Events.rush_hour_changed.connect(_on_rush_music)
	show_menu()
	if "--smoke" in OS.get_cmdline_user_args():
		_run_smoke_test.call_deferred()
	elif "--tutsmoke" in OS.get_cmdline_user_args():
		_run_tutorial_smoke.call_deferred()
	elif "--film" in OS.get_cmdline_user_args():
		_run_film.call_deferred()
	elif "--updatefilm" in OS.get_cmdline_user_args():
		_run_update_film.call_deferred()
	elif "--shots" in OS.get_cmdline_user_args():
		_run_screenshot_tour.call_deferred()


func _build_world() -> void:
	world = WorldBuilder.new()
	world.name = "World"
	add_child(world)
	world.build(int(Game.settings.quality))

	player = Player.new()
	player.name = "Player"
	world.add_child(player)
	player.global_position = world.player_spawn
	player.set_active(false)
	world.player = player

	_menu_camera = Camera3D.new()
	_menu_camera.name = "MenuCamera"
	_menu_camera.fov = 60.0
	add_child(_menu_camera)
	_menu_camera.position = Vector3(4.8, 2.45, 4.6)
	_menu_camera.look_at(Vector3(0.2, 1.5, 8.8))
	_menu_camera.current = true


func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	add_child(ui_layer)

	hud = HUD.new()
	hud.name = "HUD"
	hud.setup(player)
	ui_layer.add_child(hud)
	hud.visible = false

	menu = MainMenu.new()
	menu.name = "MainMenu"
	ui_layer.add_child(menu)
	menu.new_game_pressed.connect(func(): Game.start_new_game())
	menu.continue_pressed.connect(func(): Game.continue_game())
	menu.quit_pressed.connect(func(): Game.quit_game())

	inventory_panel = InventoryPanel.new()
	upgrades_panel = UpgradesPanel.new()
	settings_panel = SettingsPanel.new()
	pause_panel = PausePanel.new()
	report_panel = ReportPanel.new()
	goals_panel = GoalsPanel.new()
	collection_panel = CollectionPanel.new()
	model_gallery_panel = ModelGalleryPanel.new()
	for panel in [inventory_panel, upgrades_panel, settings_panel, pause_panel, report_panel, goals_panel, collection_panel, model_gallery_panel]:
		ui_layer.add_child(panel)

	tutorial = Tutorial.new()
	tutorial.name = "Tutorial"
	tutorial.setup(player, world)
	ui_layer.add_child(tutorial)


# ------------------------------------------------------------------ screens

func show_menu() -> void:
	Game.overlay_open = false
	get_tree().paused = false
	_close_panels()
	if tutorial:
		tutorial.cancel()
	if world:
		world.customer_manager.close_stall()
	if player:
		player.set_active(false)
	if _menu_camera:
		_menu_camera.current = true
	menu.visible = true
	menu.refresh()
	hud.visible = false
	Game.set_state(Game.State.MENU)
	Audio.stop_ambience()
	Audio.play_music("menu")
	if not Game.is_mobile():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func start_game(_is_new: bool) -> void:
	menu.visible = false
	_close_panels()
	Game.overlay_open = false
	get_tree().paused = false
	if _menu_camera:
		_menu_camera.current = false
	if player:
		player.camera.current = true
		player.set_active(true)
	hud.visible = true
	Audio.start_ambience()


func on_day_started(day: int) -> void:
	menu.visible = false
	hud.visible = true
	if _menu_camera:
		_menu_camera.current = false
	if player:
		player.camera.current = true
		_reset_player()
		player.set_active(true)
	if world:
		world.customer_manager.begin_day()
		world.plate.clear_plate()
		world.apply_day_theme(day)
	Game.overlay_open = false
	get_tree().paused = false
	Audio.start_ambience()
	Audio.play_music("day")
	if Game.pending_tutorial:
		Game.pending_tutorial = false
		tutorial.start()
	else:
		Events.toast.emit("Day %d - stall open. Read the order card, then start cooking." % day, "good")


func _reset_player() -> void:
	if player.held_item != null:
		player.held_item.queue_free()
		player.held_item = null
	Events.held_changed.emit("")
	player.global_position = world.player_spawn
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO


# ------------------------------------------------------------------- panels

func open_inventory() -> void:
	_open_only(inventory_panel)


func open_upgrades() -> void:
	_open_only(upgrades_panel)


func open_settings() -> void:
	_open_only(settings_panel)


func open_pause() -> void:
	_open_only(pause_panel)


func open_goals() -> void:
	_open_only(goals_panel)


func open_collection() -> void:
	_open_only(collection_panel)


func open_models() -> void:
	_open_only(model_gallery_panel)


func _open_only(panel: OverlayPanel) -> void:
	if Game.state != Game.State.PLAYING:
		return
	_close_panels()
	panel.open()


func _close_panels() -> void:
	for panel in [inventory_panel, upgrades_panel, settings_panel, pause_panel, report_panel, goals_panel, collection_panel, model_gallery_panel]:
		if panel != null and panel.visible:
			panel.close()


func apply_quality() -> void:
	if world:
		world.apply_quality(int(Game.settings.quality))


func _on_day_ended(report: Dictionary) -> void:
	if tutorial:
		tutorial.cancel()
	if world:
		world.customer_manager.close_stall()
	if player:
		player.set_active(false)
	hud.visible = false
	report_panel.set_report(report)
	report_panel.open()
	Audio.play("dayend", 1.0, -4.0)
	Audio.play_music("menu")


func _on_rush_music(active: bool) -> void:
	if Game.state == Game.State.PLAYING:
		Audio.play_music("rush" if active else "day")


func _process(delta: float) -> void:
	if _film_active:
		_film_tick(delta)
	if Game.state == Game.State.MENU and _menu_camera != null:
		_menu_time += delta
		var drift := sin(_menu_time * 0.11) * 0.55
		_menu_camera.position = Vector3(4.8 + drift, 2.45 + sin(_menu_time * 0.07) * 0.1, 4.6 - drift * 0.3)
		_menu_camera.look_at(Vector3(0.2, 1.5, 8.8))


# ---------------------------------------------------------------- promo film

## Deterministic 30-second gameplay tour recorded by Godot's movie writer with
## --write-movie. Dev-only: never triggered during normal play.
func _run_film() -> void:
	await get_tree().process_frame
	Game.start_new_game()
	await get_tree().process_frame
	process_mode = Node.PROCESS_MODE_ALWAYS  # panels pause the tree; keep the timeline running
	world.customer_manager.call("freeze_for_tutorial")
	world.customer_manager.call("spawn_tutorial_customer")
	hud.visible = false
	_film_time = 0.0
	_film_step = 0
	_film_active = true


func _run_update_film() -> void:
	await get_tree().process_frame
	Game.start_new_game()
	await get_tree().process_frame
	process_mode = Node.PROCESS_MODE_ALWAYS
	world.customer_manager.call("freeze_for_tutorial")
	world.customer_manager.call("spawn_tutorial_customer", 8)
	hud.visible = true
	_film_time = 0.0
	_film_step = 0
	_film_timeline = _update_timeline
	_film_active = true


func _film_tick(delta: float) -> void:
	_film_time += delta
	while _film_step < _film_timeline.size() and _film_time >= float(_film_timeline[_film_step].get("at", 0.0)):
		var entry: Dictionary = _film_timeline[_film_step]
		_film_step += 1
		call(String(entry.get("fn", "")))


func _film_move(pos: Vector3, ry: float, rx: float) -> void:
	player.global_position = pos
	player.rotation.y = ry
	player.camera.rotation.x = rx


func film_menu() -> void:
	hud.visible = false
	if _menu_camera:
		_menu_camera.current = true
		_menu_camera.position = Vector3(2.0, 2.2, 3.5)
		_menu_camera.look_at(Vector3(0.0, 1.4, 8.9))
	_menu_time = 0.0


func film_counter() -> void:
	hud.visible = true
	if _menu_camera:
		_menu_camera.current = false
	player.camera.current = true
	_film_move(Vector3(0.0, 0.2, 10.25), 0.0, -0.12)


func film_take() -> void:
	_film_move(Vector3(-1.85, 0.2, 10.15), 0.0, -0.08)
	world.stall.puri_box.interact(player)


func film_crack() -> void:
	world.stall.puri_box.interact(player)


func film_potato() -> void:
	_film_move(Vector3(-1.4, 0.2, 10.15), 0.0, -0.08)
	world.stall.potato.interact(player)


func film_pani() -> void:
	_film_move(Vector3(0.3, 0.2, 10.15), 0.0, -0.08)
	world.stall.pani_mint.interact(player)


func film_plate() -> void:
	_film_move(Vector3(1.72, 0.2, 10.15), 0.0, -0.08)
	world.stall.plate.interact(player)


func film_serve() -> void:
	_film_move(Vector3(1.0, 0.2, 10.15), 0.0, 0.02)
	world.stall.plate.interact(player)


func film_quick_puri() -> void:
	if Orders.active_customer == null:
		world.customer_manager.call("spawn_tutorial_customer", 9)
	_film_move(Vector3(0.3, 0.2, 10.15), 0.0, -0.1)
	world.stall.puri_box.interact(player)
	world.stall.puri_box.interact(player)
	world.stall.potato.interact(player)
	world.stall.pani_mint.interact(player)
	world.stall.plate.interact(player)
	world.stall.plate.interact(player)


func film_combo() -> void:
	_film_move(Vector3(0.8, 0.2, 10.2), 0.0, -0.05)


func film_inventory() -> void:
	open_inventory()


func film_upgrades() -> void:
	open_upgrades()


func film_close() -> void:
	_close_panels()


func film_grant() -> void:
	_grant_restaurant_upgrades()
	world.sync_upgrades()


func film_grant_machine() -> void:
	_grant_machine_upgrades()
	world.sync_upgrades()


func film_machine() -> void:
	_film_move(Vector3(2.0, 0.2, 10.6), -0.2, -0.16)


func film_wide() -> void:
	_film_move(Vector3(0.0, 0.2, 4.5), PI, 0.06)


func film_flags() -> void:
	_film_move(Vector3(-14.0, 0.2, 2.5), 2.55, 0.04)


func film_hold() -> void:
	_film_move(Vector3(0.0, 0.2, 4.5), PI, 0.1)


# --------------------------------------------------------- tutorial smoke test

## Dev-only check that the guided first order freezes time, matches one puri,
## and hands control back to a running day when served.
func _run_tutorial_smoke() -> void:
	await get_tree().process_frame
	var failures: Array[String] = []
	Game.settings.tutorial_done = false
	Game.start_new_game()
	await get_tree().process_frame
	await get_tree().process_frame
	if not tutorial.is_active():
		failures.append("tutorial did not start")
	if Clock.running:
		failures.append("clock was not frozen")
	if int(Orders.active_order.get("quantity", -1)) != 1:
		failures.append("tutorial order is not one puri")
	if not Game.settings.has("tutorial_done"):
		failures.append("tutorial setting missing")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		await _capture(ProjectSettings.globalize_path("res://build/screenshots"), "13_tutorial")

	var box: PuriBoxStation = world.stall.puri_box
	var potato: BowlStation = world.stall.potato
	var pani: PaniStation = world.stall.pani_mint
	var plate: PlateStation = world.stall.plate
	box.interact(player)   # take
	box.interact(player)   # crack
	potato.interact(player)
	pani.interact(player)
	plate.interact(player) # place
	plate.interact(player) # serve
	await get_tree().create_timer(0.3).timeout
	if Orders.day_served < 1:
		failures.append("tutorial puri was not served")
	if Clock.running == false:
		failures.append("clock did not resume")
	if not bool(Game.settings.tutorial_done):
		failures.append("tutorial completion not saved")
	if tutorial.is_active():
		failures.append("tutorial still active after serving")

	if failures.is_empty():
		print("TUT SMOKE OK: freeze, scripted order, six steps, serve, resume")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("TUT SMOKE FAIL: " + f)
		get_tree().quit(1)


# --------------------------------------------------------------- smoke test

func _run_smoke_test() -> void:
	await get_tree().process_frame
	var failures: Array[String] = []
	print("SMOKE: starting new game")
	Game.start_new_game()
	await get_tree().process_frame
	await get_tree().process_frame

	if world == null or player == null:
		failures.append("world/player missing")
		_finish_smoke(failures)
		return

	var box: PuriBoxStation = world.stall.puri_box
	var potato: BowlStation = world.stall.potato
	var pani: PaniStation = world.stall.pani_mint
	var plate: PlateStation = world.stall.plate
	var trash: TrashStation = world.stall.trash

	if Goals.goals.size() != 3:
		failures.append("daily goals did not initialise")

	for station in world.get_tree().get_nodes_in_group("interactable"):
		var prompt: String = station.get_prompt(player)
		if prompt == "":
			failures.append("empty prompt on " + station.name)

	for i in 3:
		box.interact(player)
		box.interact(player)
		potato.interact(player)
		pani.interact(player)
		plate.interact(player)
		if player.held_item != null:
			failures.append("puri %d still in hand" % i)

	if plate.puris.size() != 3:
		failures.append("plate has %d puris, expected 3" % plate.puris.size())

	world.customer_manager.call("_spawn")
	await get_tree().process_frame
	if world.customer_manager.queue.is_empty():
		failures.append("customer did not spawn")
		_finish_smoke(failures)
		return
	var customer: Customer = world.customer_manager.queue[0]
	world.customer_manager.call("_promote", customer)
	await get_tree().process_frame

	var cash_before := Economy.cash
	plate.interact(player)
	await get_tree().process_frame
	if Orders.day_served <= 0:
		failures.append("order was not served")
	if Economy.cash <= cash_before:
		failures.append("customer did not pay")

	var goal_tracked := false
	for goal in Goals.goals:
		if int(goal.get("progress", 0)) > 0:
			goal_tracked = true
	if not goal_tracked:
		failures.append("daily goals did not track serving")

	box.interact(player)
	box.interact(player)
	trash.interact(player)
	if player.held_item != null:
		failures.append("trash did not clear held item")

	Game.end_day(true)
	await get_tree().process_frame
	if not report_panel.visible:
		failures.append("day report did not open")
	report_panel.close()
	Game.next_day()
	await get_tree().process_frame
	if Game.day != 2:
		failures.append("next day did not advance")

	var cash_saved := Economy.cash
	SaveManager.save_game()
	Economy.cash = 1
	if not SaveManager.load_game():
		failures.append("save load failed")
	if Economy.cash != cash_saved:
		failures.append("cash not restored from save (%d vs %d)" % [Economy.cash, cash_saved])

	_finish_smoke(failures)


func _finish_smoke(failures: Array[String]) -> void:
	if failures.is_empty():
		print("SMOKE OK: prep, serve, pay, trash, report, next day, save/load")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("SMOKE FAIL: " + f)
		get_tree().quit(1)


# ---------------------------------------------------------- screenshot tour

func _run_screenshot_tour() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var out_dir := ProjectSettings.globalize_path("res://build/screenshots")
	DirAccess.make_dir_recursive_absolute(out_dir)

	await _capture(out_dir, "01_menu")

	Game.start_new_game()
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	await _capture(out_dir, "02_stall")

	player.global_position = Vector3(0.0, 0.2, 10.6)
	player.rotation.y = 0.0
	player.camera.rotation.x = -0.24
	await _capture(out_dir, "03_counter")

	# A customer mid-order, viewed from the serving side of the counter.
	world.customer_manager.call("_spawn")
	await get_tree().create_timer(0.5).timeout
	if not world.customer_manager.queue.is_empty():
		var customer: Customer = world.customer_manager.queue[0]
		world.customer_manager.call("_promote", customer)
		customer.global_position = Vector3(1.55, 0.14, 7.35)
		customer.target_position = Vector3(1.55, 0.14, 7.35)
		customer.has_arrived = true
		customer.state = Customer.State.ORDER
		customer.face_towards(player.global_position)
	player.global_position = Vector3(1.15, 0.2, 10.55)
	player.rotation.y = -0.1
	player.camera.rotation.x = -0.1
	await get_tree().create_timer(0.4).timeout
	await _capture(out_dir, "04_customer")

	# Filled plate close-up.
	var box: PuriBoxStation = world.stall.puri_box
	var potato: BowlStation = world.stall.potato
	var pani: PaniStation = world.stall.pani_mint
	var plate: PlateStation = world.stall.plate
	for i in 3:
		box.interact(player)
		box.interact(player)
		potato.interact(player)
		pani.interact(player)
		plate.interact(player)
	player.global_position = Vector3(1.5, 0.2, 10.55)
	player.rotation.y = -0.06
	player.camera.rotation.x = -0.38
	await _capture(out_dir, "05_plate")

	open_inventory()
	await get_tree().create_timer(0.3).timeout
	await _capture(out_dir, "06_inventory")
	inventory_panel.close()

	open_upgrades()
	await get_tree().create_timer(0.3).timeout
	await _capture(out_dir, "07_upgrades")
	upgrades_panel.close()

	_grant_restaurant_upgrades()
	world.sync_upgrades()
	player.global_position = Vector3(0.0, 0.2, 4.5)
	player.rotation.y = PI
	player.camera.rotation.x = 0.02
	await get_tree().create_timer(0.3).timeout
	await _capture(out_dir, "09_restaurant")

	player.global_position = Vector3(0.0, 0.2, 11.8)
	player.rotation.y = 0.0
	player.camera.rotation.x = 0.04
	await _capture(out_dir, "10_palace")

	player.global_position = Vector3(0.0, 0.2, 4.5)
	player.rotation.y = PI
	player.camera.rotation.x = 0.16
	await get_tree().create_timer(0.3).timeout
	await _capture(out_dir, "11_franchise")

	player.global_position = Vector3(-14.0, 0.2, 2.5)
	player.rotation.y = 2.55
	player.camera.rotation.x = 0.04
	await get_tree().create_timer(0.3).timeout
	await _capture(out_dir, "12_world_tour")

	open_collection()
	await get_tree().create_timer(0.3).timeout
	await _capture(out_dir, "13_collection")
	collection_panel.close()

	open_models()
	await get_tree().create_timer(0.4).timeout
	await _capture(out_dir, "14_models")
	model_gallery_panel.close()

	_grant_machine_upgrades()
	world.sync_upgrades()
	player.global_position = Vector3(2.0, 0.2, 10.6)
	player.rotation.y = -0.2
	player.camera.rotation.x = -0.18
	await get_tree().create_timer(0.4).timeout
	await _capture(out_dir, "14_machine")

	Game.day = 3
	world.apply_day_theme(3)
	player.global_position = Vector3(0.0, 0.2, 4.5)
	player.rotation.y = PI
	player.camera.rotation.x = 0.02
	await get_tree().create_timer(0.5).timeout
	await _capture(out_dir, "15_rain")

	Game.day = 5
	world.apply_day_theme(5)
	await get_tree().create_timer(0.5).timeout
	await _capture(out_dir, "16_diwali")

	Game.end_day(true)
	await get_tree().create_timer(0.3).timeout
	await _capture(out_dir, "08_report")

	print("SHOTS OK: wrote screenshots to ", out_dir)
	get_tree().quit(0)


func _capture(dir: String, shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := dir.path_join(shot_name + ".png")
	image.save_png(path)
	print("SHOT ", path)


## Buys every restaurant tier so the camera fly-through can show all five
## visuals. Development/screenshot helper only.
func _grant_restaurant_upgrades() -> void:
	if player == null:
		return
	var original_cash := Economy.cash
	var original_level := Progression.level
	Economy.cash = maxi(Economy.cash, 300000)
	Progression.level = Progression.MAX_LEVEL
	for id in ["restaurant_reno", "fine_dining", "pani_puri_palace", "franchise_hq", "world_tour"]:
		Progression.buy(id)
	Economy.cash = original_cash
	Progression.level = original_level


func _grant_machine_upgrades() -> void:
	if player == null:
		return
	var original_cash := Economy.cash
	var original_level := Progression.level
	Economy.cash = maxi(Economy.cash, 150000)
	Progression.level = Progression.MAX_LEVEL
	for id in ["potato_machine", "turbo_peeler", "auto_fill_arm"]:
		Progression.buy(id)
	Economy.cash = original_cash
	Progression.level = original_level
