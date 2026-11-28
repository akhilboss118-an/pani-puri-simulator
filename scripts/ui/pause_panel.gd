class_name PausePanel
extends OverlayPanel
## In-game menu. Also the place to close the stall early.

var _info: Label


func _init() -> void:
	title_text = "Paused"


func _build_content() -> void:
	_info = UIKit.label("", 14, UIKit.MUTED)
	content.add_child(_info)
	content.add_child(UIKit.hsep(2))

	content.add_child(UIKit.section_header("Shift", UIKit.FILIGREE))

	var resume := UIKit.gold_slab("Resume shift", 50)
	resume.pressed.connect(close)
	content.add_child(resume)

	content.add_child(UIKit.section_header("Manage", UIKit.FILIGREE_DIM))

	var stock := UIKit.slab_button("Stock & restock", UIKit.FILIGREE, 44)
	stock.pressed.connect(_open_other.bind("inventory"))
	content.add_child(stock)

	var upgrades := UIKit.slab_button("Upgrades & pricing", UIKit.FILIGREE, 44)
	upgrades.pressed.connect(_open_other.bind("upgrades"))
	content.add_child(upgrades)

	var settings := UIKit.slab_button("Settings", UIKit.FILIGREE, 44)
	settings.pressed.connect(_open_other.bind("settings"))
	content.add_child(settings)

	var cloud := UIKit.slab_button("Save & leaderboards", UIKit.FILIGREE, 44)
	cloud.pressed.connect(func():
		close()
		Game.root.call("open_cloud")
	)
	content.add_child(cloud)

	content.add_child(UIKit.hsep(4))

	var close_stall := UIKit.slab_button("Close stall for today", UIKit.EMBER, 44)
	close_stall.pressed.connect(_on_close_stall)
	content.add_child(close_stall)

	var quit := UIKit.slab_button("Quit to main menu", UIKit.FILIGREE_DIM, 44)
	quit.pressed.connect(_on_quit)
	content.add_child(quit)


func _on_open() -> void:
	_info.text = "Day %d  •  %s\nCash ₹%d  •  Reputation %d" % [
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
