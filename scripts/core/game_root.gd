extends Node
## Root scene. Builds the world once, owns the UI layers and routes state
## changes between the menu, the shift and the day report.

var world: WorldBuilder
var player: Player
var ui_layer: CanvasLayer
var post_fx: CanvasLayer

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
var cloud_panel: CloudPanel
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

var _promo_timeline: Array = [
	{"at": 0.0, "fn": "promo_menu"},
	{"at": 3.4, "fn": "promo_enter_stall"},
	{"at": 5.2, "fn": "promo_glide_jar"},
	{"at": 5.9, "fn": "promo_take"},
	{"at": 6.6, "fn": "promo_crack"},
	{"at": 7.3, "fn": "promo_glide_potato"},
	{"at": 7.9, "fn": "promo_potato"},
	{"at": 8.4, "fn": "promo_masala"},
	{"at": 9.0, "fn": "promo_glide_pani"},
	{"at": 9.6, "fn": "promo_pani"},
	{"at": 10.3, "fn": "promo_glide_plate"},
	{"at": 10.9, "fn": "promo_plate"},
	{"at": 11.7, "fn": "promo_quick_puri"},
	{"at": 12.6, "fn": "promo_quick_puri"},
	{"at": 13.5, "fn": "promo_serve"},
	{"at": 14.8, "fn": "promo_inventory"},
	{"at": 16.6, "fn": "promo_close"},
	{"at": 16.8, "fn": "promo_upgrades"},
	{"at": 18.6, "fn": "promo_close"},
	{"at": 18.8, "fn": "promo_expand_palace"},
	{"at": 21.3, "fn": "promo_machine"},
	{"at": 23.0, "fn": "promo_rain"},
	{"at": 25.0, "fn": "promo_diwali_night"},
	{"at": 27.6, "fn": "promo_done"},
]

var _promo60_timeline: Array = [
	{"at": 0.00, "fn": "p60_menu"},
	{"at": 5.75, "fn": "p60_enter_stall"},
	{"at": 8.00, "fn": "p60_customer_order"},
	{"at": 9.90, "fn": "p60_glide_jar"},
	{"at": 10.55, "fn": "promo_take"},
	{"at": 11.40, "fn": "promo_crack"},
	{"at": 12.20, "fn": "promo_glide_potato"},
	{"at": 12.85, "fn": "promo_potato"},
	{"at": 13.55, "fn": "p60_chickpea"},
	{"at": 14.30, "fn": "promo_masala"},
	{"at": 15.05, "fn": "p60_chutney"},
	{"at": 16.05, "fn": "promo_glide_pani"},
	{"at": 16.65, "fn": "promo_pani"},
	{"at": 17.35, "fn": "promo_glide_plate"},
	{"at": 17.90, "fn": "promo_plate"},
	{"at": 18.65, "fn": "p60_quick_puri"},
	{"at": 19.45, "fn": "p60_quick_puri"},
	{"at": 20.55, "fn": "p60_serve_customer"},
	{"at": 22.85, "fn": "p60_waste_bin"},
	{"at": 25.00, "fn": "p60_settings"},
	{"at": 26.85, "fn": "p60_controls"},
	{"at": 28.70, "fn": "p60_stock"},
	{"at": 32.40, "fn": "p60_upgrades"},
	{"at": 36.50, "fn": "p60_expand"},
	{"at": 41.70, "fn": "p60_machine"},
	{"at": 45.30, "fn": "p60_goals"},
	{"at": 46.85, "fn": "p60_badges"},
	{"at": 48.35, "fn": "p60_gallery"},
	{"at": 50.10, "fn": "p60_rain"},
	{"at": 52.20, "fn": "p60_diwali"},
	{"at": 54.50, "fn": "p60_report"},
	{"at": 60.20, "fn": "promo_done"},
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
	elif "--promo" in OS.get_cmdline_user_args():
		_run_promo.call_deferred()
	elif "--promo60" in OS.get_cmdline_user_args():
		_run_promo60.call_deferred()
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
	_menu_camera.fov = 56.0
	add_child(_menu_camera)
	_menu_camera.position = Vector3(-9.6, 2.5, 1.6)
	_menu_camera.look_at(Vector3(18.0, 2.6, 0.2))
	_menu_camera.current = true


func _build_ui() -> void:
	post_fx = preload("res://scripts/ui/post_fx.gd").new()
	post_fx.name = "PostFX"
	add_child(post_fx)
	post_fx.call("apply_quality", int(Game.settings.quality))

	ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	ui_layer.layer = 10
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
	cloud_panel = CloudPanel.new()
	for panel in [inventory_panel, upgrades_panel, settings_panel, pause_panel, report_panel, goals_panel, collection_panel, model_gallery_panel, cloud_panel]:
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
	var old_item := player.take_held_item()
	if old_item != null:
		old_item.queue_free()
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


func open_cloud() -> void:
	_open_only(cloud_panel)


func _open_only(panel: OverlayPanel) -> void:
	if Game.state != Game.State.PLAYING:
		return
	_close_panels()
	panel.open()


func _close_panels() -> void:
	for panel in [inventory_panel, upgrades_panel, settings_panel, pause_panel, report_panel, goals_panel, collection_panel, model_gallery_panel, cloud_panel]:
		if panel != null and panel.visible:
			panel.close()


func apply_quality() -> void:
	if world:
		world.apply_quality(int(Game.settings.quality))
	if post_fx:
		post_fx.call("apply_quality", int(Game.settings.quality))


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
		var drift := sin(_menu_time * 0.09) * 0.22
		_menu_camera.position = Vector3(
			-9.6 + drift * 0.4,
			2.5 + sin(_menu_time * 0.06) * 0.05,
			1.6 + drift * 0.4)
		_menu_camera.look_at(Vector3(18.0, 2.6, 0.2 + drift * 0.2))


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
	world.customer_manager.call("spawn_tutorial_customer", 1)
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


func _run_promo() -> void:
	await get_tree().process_frame
	process_mode = Node.PROCESS_MODE_ALWAYS
	_film_time = 0.0
	_film_step = 0
	_film_timeline = _promo_timeline
	_film_active = true


func _glide_player(pos: Vector3, ry: float, rx: float, dur: float) -> void:
	if player == null:
		return
	var tw := create_tween().set_parallel(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(player, "global_position", pos, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(player, "rotation:y", ry, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(player.camera, "rotation:x", rx, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func promo_menu() -> void:
	show_menu()
	if _menu_camera:
		_menu_camera.current = true
		_menu_camera.position = Vector3(-11.0, 2.5, 1.6)
		var tw := create_tween()
		tw.tween_property(_menu_camera, "position", Vector3(-6.0, 2.45, 1.6), 3.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func promo_enter_stall() -> void:
	Game.start_new_game()
	player.set_active(false)
	menu.visible = false
	hud.visible = true
	if _menu_camera:
		_menu_camera.current = false
	player.camera.current = true
	world.customer_manager.call("freeze_for_tutorial")
	var cust: Customer = world.customer_manager.call("spawn_tutorial_customer", 1)
	if cust:
		var order := {
			"recipe_id": "classic",
			"name": "Classic Pani Puri",
			"quantity": 3,
			"pani": "mint",
			"spice": 1,
			"sweet": false,
			"onion": false,
			"chickpea": false,
			"price": Progression.price_for(GameData.recipe("classic")),
			"customer": "Priya",
			"note": "Make it crispy!",
			"vip": false,
			"tip_mult": 1.2,
			"dialogue": "order_pani",
		}
		cust.customer_name = "Priya"
		cust.global_position = Vector3(-0.1, 0.14, 7.45)
		cust.target_position = Vector3(-0.1, 0.14, 7.45)
		cust.face_towards(Vector3(0.0, 0.14, 10.45))
		cust.begin_order(order)
		Orders.set_active(order, cust)
	_film_move(Vector3(0.0, 0.2, 10.45), 0.0, -0.14)
	_glide_player(Vector3(-0.3, 0.2, 10.35), 0.1, -0.18, 1.4)


func promo_glide_jar() -> void:
	_glide_player(Vector3(-1.35, 0.2, 10.2), 0.28, -0.24, 0.65)


func promo_take() -> void:
	world.stall.puri_box.interact(player)


func promo_crack() -> void:
	world.stall.puri_box.interact(player)


func promo_glide_potato() -> void:
	_glide_player(Vector3(-0.8, 0.2, 10.2), 0.14, -0.26, 0.55)


func promo_potato() -> void:
	world.stall.potato.interact(player)


func promo_masala() -> void:
	_glide_player(Vector3(0.35, 0.2, 10.25), -0.2, -0.3, 0.45)
	world.stall.masala.interact(player)


func promo_glide_pani() -> void:
	_glide_player(Vector3(-0.04, 0.2, 10.25), 0.0, -0.26, 0.55)


func promo_pani() -> void:
	world.stall.pani_mint.interact(player)


func promo_glide_plate() -> void:
	_glide_player(Vector3(-0.45, 0.2, 10.35), 0.04, -0.32, 0.55)


func promo_plate() -> void:
	world.stall.plate.interact(player)


func promo_quick_puri() -> void:
	world.stall.puri_box.interact(player)
	world.stall.puri_box.interact(player)
	world.stall.potato.interact(player)
	world.stall.masala.interact(player)
	world.stall.pani_mint.interact(player)
	world.stall.plate.interact(player)


func promo_serve() -> void:
	_glide_player(Vector3(-0.2, 0.2, 10.4), 0.0, -0.12, 0.45)
	world.stall.plate.interact(player)


func promo_inventory() -> void:
	open_inventory()


func promo_upgrades() -> void:
	open_upgrades()


func promo_close() -> void:
	_close_panels()


func promo_expand_palace() -> void:
	_grant_restaurant_upgrades()
	_grant_machine_upgrades()
	world.sync_upgrades()
	_film_move(Vector3(0.0, 0.2, 4.4), PI, 0.06)
	_glide_player(Vector3(2.2, 0.2, 4.6), PI - 0.18, 0.08, 2.3)


func promo_machine() -> void:
	_film_move(Vector3(1.65, 0.2, 9.75), -1.1, -0.28)
	_glide_player(Vector3(1.85, 0.2, 9.55), -1.22, -0.24, 1.5)


func promo_rain() -> void:
	Game.day = 3
	Clock.minutes = 17 * 60 + 15
	Clock._emit_time()
	world.apply_day_theme(3)
	_film_move(Vector3(-4.2, 0.2, -1.5), PI * 0.86, 0.04)
	_glide_player(Vector3(-2.0, 0.2, -0.5), PI * 0.94, 0.06, 1.8)


func promo_diwali_night() -> void:
	Game.day = 5
	Clock.minutes = 19 * 60 + 45
	Clock._emit_time()
	world.apply_day_theme(5)
	_film_move(Vector3(-5.0, 0.2, 3.6), PI * 0.78, 0.08)
	_glide_player(Vector3(0.5, 0.2, 4.2), PI * 1.05, 0.08, 2.4)


func promo_done() -> void:
	get_tree().quit(0)


func _run_promo60() -> void:
	await get_tree().process_frame
	process_mode = Node.PROCESS_MODE_ALWAYS
	_film_time = 0.0
	_film_step = 0
	_film_timeline = _promo60_timeline
	_film_active = true


func p60_menu() -> void:
	show_menu()
	if _menu_camera:
		_menu_camera.current = true
		_menu_camera.fov = 60.0
		_menu_camera.position = Vector3(-11.2, 2.55, 1.6)
		var tw := create_tween()
		tw.tween_property(_menu_camera, "position", Vector3(-5.6, 2.5, 1.4), 5.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func p60_enter_stall() -> void:
	Game.start_new_game()
	player.set_active(false)
	menu.visible = false
	hud.visible = true
	if _menu_camera:
		_menu_camera.current = false
	player.camera.current = true
	player.camera.fov = 78.0
	world.customer_manager.call("freeze_for_tutorial")
	var c1: Customer = world.customer_manager.call("spawn_tutorial_customer", 1)
	if c1:
		c1.customer_name = "Customer 1"
		c1.global_position = Vector3(-2.6, 0.14, 7.45)
		c1.walk_to(Vector3(-0.1, 0.14, 7.45), 0)
		c1._bubble.visible = false
		c1._bubble_bg.visible = false
		c1._bubble_frame.visible = false
		c1._bar_fill.visible = false
		c1._bar_bg.visible = false
		if c1._badge:
			c1._badge.visible = false
		Orders.clear_active()
		world.customer_manager.active = null
	# Spawn NPC 2 walking cleanly from the right into slot 1 so both NPCs meet side-by-side!
	var c2 := Customer.new()
	c2.customer_name = "Customer 2"
	c2.model_index = 2
	world.customer_manager.add_child(c2)
	c2.setup(4.0)
	c2.set_personality("foodie", false)
	c2.exit_position = world.exit_point
	c2.global_position = Vector3(3.4, 0.14, 7.45)
	c2.walk_to(Vector3(0.85, 0.14, 7.45), 1)
	c2.departed.connect(world.customer_manager._on_departed)
	c2.walked_out.connect(world.customer_manager._on_walked_out)
	c2.finished_eating.connect(world.customer_manager._on_finished_eating)
	world.customer_manager.customers.append(c2)
	world.customer_manager.queue.append(c2)

	_film_move(Vector3(0.0, 0.2, 10.72), 0.0, -0.14)
	_glide_player(Vector3(-0.1, 0.2, 10.65), 0.02, -0.14, 1.8)


func p60_customer_order() -> void:
	var cm = world.customer_manager
	if cm.queue.is_empty():
		return
	var c1: Customer = cm.queue[0]
	var order := {
		"recipe_id": "classic",
		"name": "Classic Pani Puri",
		"quantity": 3,
		"pani": "mint",
		"spice": 1,
		"sweet": true,
		"onion": false,
		"chickpea": true,
		"price": Progression.price_for(GameData.recipe("classic")),
		"customer": "Customer 1",
		"note": "Make it crispy!",
		"vip": false,
		"tip_mult": 1.2,
		"dialogue": "order_onion",
	}
	c1.global_position = Vector3(-0.1, 0.14, 7.45)
	c1.target_position = c1.global_position
	c1.face_towards(Vector3(0.0, 0.14, 10.65))
	c1.begin_order(order)
	cm.active = c1
	Orders.set_active(order, c1)


func p60_glide_jar() -> void:
	_glide_player(Vector3(-1.32, 0.2, 10.4), 0.26, -0.22, 0.6)


func p60_chickpea() -> void:
	_glide_player(Vector3(-0.48, 0.2, 10.35), 0.08, -0.26, 0.5)
	world.stall.chickpea.interact(player)


func p60_chutney() -> void:
	_glide_player(Vector3(0.62, 0.2, 10.35), -0.14, -0.26, 0.5)
	world.stall.chutney.interact(player)


func p60_quick_puri() -> void:
	world.stall.puri_box.interact(player)
	world.stall.puri_box.interact(player)
	world.stall.potato.interact(player)
	world.stall.chickpea.interact(player)
	world.stall.masala.interact(player)
	world.stall.chutney.interact(player)
	world.stall.pani_mint.interact(player)
	world.stall.plate.interact(player)


func p60_serve_customer() -> void:
	_glide_player(Vector3(-0.1, 0.2, 10.55), 0.0, -0.10, 0.55)
	world.stall.plate.interact(player)


func p60_waste_bin() -> void:
	world.stall.puri_box.interact(player)
	world.stall.puri_box.interact(player)
	_glide_player(Vector3(1.90, 0.2, 10.35), -0.68, -0.46, 0.60)
	await get_tree().create_timer(0.60).timeout
	if player.held_item != null:
		world.stall.trash.interact(player)


func p60_settings() -> void:
	menu.visible = false
	menu._controls_modal.visible = false
	hud.visible = true
	open_settings()


func p60_controls() -> void:
	_close_panels()
	hud.visible = false
	menu.visible = true
	menu._controls_modal.visible = true


func p60_stock() -> void:
	menu._controls_modal.visible = false
	menu.visible = false
	hud.visible = true
	open_inventory()
	Inventory.add_stock("puri", 35)
	Inventory.add_stock("potato", 20)


func p60_upgrades() -> void:
	open_upgrades()
	Progression.set_price(35)
	Economy.cash = maxi(Economy.cash, 8000)
	Progression.buy("garlic_pani")
	world.sync_upgrades()


func p60_expand() -> void:
	_close_panels()
	_grant_restaurant_upgrades()
	world.sync_upgrades()
	player.camera.fov = 74.0
	_film_move(Vector3(-2.2, 0.2, 4.0), PI - 0.22, 0.08)
	_glide_player(Vector3(2.4, 0.2, 4.2), PI + 0.20, 0.08, 5.0)


func p60_machine() -> void:
	_grant_machine_upgrades()
	world.sync_upgrades()
	player.camera.fov = 76.0
	_film_move(Vector3(3.75, 0.2, 8.05), 2.66, -0.36)
	_glide_player(Vector3(3.15, 0.2, 7.75), 3.09, -0.32, 3.3)


func p60_goals() -> void:
	open_goals()


func p60_badges() -> void:
	open_collection()


func p60_gallery() -> void:
	open_models()
	model_gallery_panel.select_model_by_name("customer_2")


func p60_rain() -> void:
	_close_panels()
	player.camera.fov = 74.0
	Game.day = 3
	Clock.minutes = 17 * 60 + 15
	Clock._emit_time()
	world.apply_day_theme(3)
	_film_move(Vector3(-4.2, 0.2, -1.5), PI * 0.86, 0.05)
	_glide_player(Vector3(-1.8, 0.2, -0.4), PI * 0.94, 0.07, 2.0)


func p60_diwali() -> void:
	Game.day = 5
	Clock.minutes = 19 * 60 + 45
	Clock._emit_time()
	world.apply_day_theme(5)
	_film_move(Vector3(-4.5, 0.2, 3.6), PI * 0.80, 0.08)
	_glide_player(Vector3(0.4, 0.2, 4.1), PI * 1.04, 0.08, 2.2)


func p60_report() -> void:
	Economy.day_expenses = mini(Economy.day_expenses, 620)
	Game.end_day(true)


func film_menu() -> void:
	hud.visible = false
	if _menu_camera:
		_menu_camera.current = true
		_menu_camera.position = Vector3(-9.6, 2.5, 1.6)
		_menu_camera.look_at(Vector3(18.0, 2.6, 0.2))
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
		world.customer_manager.call("spawn_tutorial_customer", 2)
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

	# Let the staggered title-screen entrance settle before capturing.
	await get_tree().create_timer(1.3).timeout
	await RenderingServer.frame_post_draw
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
		customer.global_position = Vector3(-0.1, 0.14, 7.45)
		customer.target_position = Vector3(-0.1, 0.14, 7.45)
		customer.has_arrived = true
		customer.state = Customer.State.ORDER
		customer.face_towards(player.global_position)
	player.global_position = Vector3(-0.1, 0.2, 10.45)
	player.rotation.y = 0.0
	player.camera.rotation.x = -0.14
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
	player.global_position = Vector3(-0.25, 0.2, 10.45)
	player.rotation.y = 0.05
	player.camera.rotation.x = -0.34
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
