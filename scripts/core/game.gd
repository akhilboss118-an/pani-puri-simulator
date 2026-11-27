extends Node
## High level game state and scene flow.
##
## Owns the state machine (menu / playing / paused / day end), the day counter
## and player settings. Everything else is a service that Game resets when a
## new business day starts.

enum State { MENU, PLAYING, PAUSED, DAY_END }

const SETTINGS_PATH := "user://settings.cfg"
const VERSION := "1.2.0"

var state: State = State.MENU
var day: int = 1
var root: Node = null
var overlay_open: bool = false
var pending_tutorial: bool = false

var settings := {
	"mouse_sensitivity": 0.28,
	"quality": 1,          # 0 low, 1 medium, 2 high
	"master_volume": 0.75,
	"invert_y": false,
	"reduced_motion": false,
	"show_fps": false,
	"tutorial_done": false,
}

var _quality_names := ["Low", "Medium", "High"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_load_settings()
	Audio.apply_volume(settings.master_volume)


func _unhandled_input(event: InputEvent) -> void:
	if overlay_open:
		return
	if event.is_action_pressed("pause") and state == State.PLAYING:
		if root:
			root.call("open_pause")
	elif event.is_action_pressed("toggle_goals") and state == State.PLAYING:
		if root:
			root.call("open_goals")
	elif event.is_action_pressed("toggle_collection") and state == State.PLAYING:
		if root:
			root.call("open_collection")


# ---------------------------------------------------------------- input setup

func _setup_input() -> void:
	_bind_keys("move_forward", [KEY_W, KEY_UP])
	_bind_keys("move_back", [KEY_S, KEY_DOWN])
	_bind_keys("move_left", [KEY_A, KEY_LEFT])
	_bind_keys("move_right", [KEY_D, KEY_RIGHT])
	_bind_keys("interact", [KEY_E, KEY_SPACE])
	_bind_keys("sprint", [KEY_SHIFT])
	_bind_keys("pause", [KEY_ESCAPE])
	_bind_keys("toggle_inventory", [KEY_TAB, KEY_I])
	_bind_keys("toggle_upgrades", [KEY_U])
	_bind_keys("toggle_report", [KEY_R])
	_bind_keys("toggle_goals", [KEY_G])
	_bind_keys("toggle_collection", [KEY_B])
	_bind_joy_button("interact", JOY_BUTTON_A)
	_bind_joy_button("pause", JOY_BUTTON_START)
	_bind_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_bind_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_bind_joy_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_bind_joy_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)
	_bind_joy_axis("look_left", JOY_AXIS_RIGHT_X, -1.0)
	_bind_joy_axis("look_right", JOY_AXIS_RIGHT_X, 1.0)
	_bind_joy_axis("look_up", JOY_AXIS_RIGHT_Y, -1.0)
	_bind_joy_axis("look_down", JOY_AXIS_RIGHT_Y, 1.0)


func _bind_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)


func _bind_joy_button(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func _bind_joy_axis(action: String, axis: int, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)


# ------------------------------------------------------------------ flow

func set_state(new_state: State) -> void:
	state = new_state
	Events.state_changed.emit(int(state))


func start_new_game() -> void:
	day = 1
	Economy.reset()
	Inventory.reset()
	Progression.reset()
	Orders.reset()
	Clock.reset()
	Achievements.reset()
	pending_tutorial = not bool(settings.get("tutorial_done", false)) and not _dev_run()
	if root:
		root.world.sync_upgrades()
	set_state(State.PLAYING)
	start_day(true)


func continue_game() -> void:
	var loaded := SaveManager.load_game()
	if not loaded:
		start_new_game()
		return
	pending_tutorial = false
	if root:
		root.world.sync_upgrades()
	set_state(State.PLAYING)
	resume_day()


func _dev_run() -> bool:
	var args := OS.get_cmdline_user_args()
	return "--smoke" in args or "--shots" in args or "--film" in args


## Fresh days skip spoilage; days after the first apply it in Inventory.begin_day.
func start_day(fresh: bool = false) -> void:
	if not fresh:
		Inventory.begin_day()
	Clock.begin_day()
	Progression.begin_day()
	Goals.begin_day(day)
	set_state(State.PLAYING)
	if root:
		root.on_day_started(day)


## Continue from a saved clock instead of resetting to opening time.
func resume_day() -> void:
	Clock.resume()
	Progression.begin_day()
	set_state(State.PLAYING)
	if root:
		root.on_day_started(day)


func end_day(closed_by_player: bool = false) -> void:
	if state != State.PLAYING:
		return
	Clock.stop()
	var report := {
		"day": day,
		"revenue": Economy.day_revenue,
		"expenses": Economy.day_expenses,
		"profit": Economy.day_revenue - Economy.day_expenses,
		"served": Orders.day_served,
		"lost": Orders.day_lost,
		"rating": Orders.day_rating,
		"tips": Orders.day_tips,
		"best_combo": Orders.best_combo,
		"goals": Goals.to_dict(),
		"theme": GameData.theme_label(day),
		"reputation": Progression.reputation,
		"closed_by_player": closed_by_player,
	}
	SaveManager.save_game()
	var day_xp := 30 + int(maxi(0, report.profit) / 120.0) + int(report.served) * 2
	var gained := Progression.add_xp(day_xp)
	if gained > 0:
		Events.toast.emit("Day complete: Level %d! Keep going." % Progression.level, "good")
	report["xp_gained"] = day_xp
	report["level"] = Progression.level
	report["xp"] = Progression.xp
	report["xp_to_next"] = Progression.xp_to_next()
	set_state(State.DAY_END)
	Achievements.on_day_end(report)
	Events.day_ended.emit(report)


func next_day() -> void:
	day += 1
	Orders.reset_day()
	Economy.begin_day()
	start_day()


func set_paused(paused: bool) -> void:
	if paused and state == State.PLAYING:
		set_state(State.PAUSED)
		get_tree().paused = true
	elif not paused and state == State.PAUSED:
		get_tree().paused = false
		set_state(State.PLAYING)


func quit_to_menu() -> void:
	get_tree().paused = false
	set_state(State.MENU)
	if root:
		root.show_menu()


func quit_game() -> void:
	SaveManager.save_game()
	get_tree().quit()


# --------------------------------------------------------------- settings

func apply_setting(key: String, value: Variant) -> void:
	if not settings.has(key):
		return
	settings[key] = value
	if key == "master_volume":
		Audio.apply_volume(float(value))
	_save_settings()
	Events.settings_changed.emit()


func quality_name() -> String:
	return _quality_names[clampi(int(settings.quality), 0, 2)]


func weather() -> String:
	return GameData.weather_for_day(day)


func festival() -> String:
	return GameData.festival_for_day(day)


func rep_multiplier() -> float:
	return 2.0 if festival() == "Diwali" else 1.0


func xp_multiplier() -> float:
	return 1.5 if festival() == "Holi" else 1.0


func is_mobile() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func is_web() -> bool:
	return OS.has_feature("web")


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for key in settings.keys():
		if cfg.has_section_key("settings", key):
			settings[key] = cfg.get_value("settings", key)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in settings.keys():
		cfg.set_value("settings", key, settings[key])
	cfg.save(SETTINGS_PATH)
