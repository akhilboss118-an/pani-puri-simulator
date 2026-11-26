class_name PausePanel
extends OverlayPanel
## In-game menu. Also the place to close the stall early.

var _info: Label


func _init() -> void:
	title_text = "Paused"


func _build_content() -> void:
	_info = UIKit.label("", 16, UIKit.MUTED)
	content.add_child(_info)
	content.add_child(UIKit.hsep(4))

	var resume := UIKit.button("Resume shift", 50)
	resume.pressed.connect(close)
	content.add_child(resume)

	var stock := UIKit.button("Stock & restock", 46)
	stock.pressed.connect(_open_other.bind("inventory"))
	content.add_child(stock)

	var upgrades := UIKit.button("Upgrades & pricing", 46)
	upgrades.pressed.connect(_open_other.bind("upgrades"))
	content.add_child(upgrades)

	var settings := UIKit.button("Settings", 46)
	settings.pressed.connect(_open_other.bind("settings"))
	content.add_child(settings)

	content.add_child(UIKit.hsep(6))

	var close_stall := UIKit.button("Close stall for today", 46)
	close_stall.add_theme_stylebox_override("normal", UIKit.style(Color("4a2a1c"), 12, Color("8a4a2a"), 1, 16))
	close_stall.pressed.connect(_on_close_stall)
	content.add_child(close_stall)

	var quit := UIKit.button("Quit to main menu", 46)
	quit.pressed.connect(_on_quit)
	content.add_child(quit)


func _on_open() -> void:
	_info.text = "Day %d  -  %s\nCash Rs %d  -  Reputation %d" % [
		Game.day, Clock.time_string(), Economy.cash, int(round(Progression.reputation)),
	]


func _open_other(which: String) -> void:
	close()
	match which:
		"inventory":
			Game.root.call("open_inventory")
		"upgrades":
			Game.root.call("open_upgrades")
		"settings":
			Game.root.call("open_settings")


func _on_close_stall() -> void:
	close()
	Game.end_day(true)


func _on_quit() -> void:
	close()
	Game.quit_to_menu()
