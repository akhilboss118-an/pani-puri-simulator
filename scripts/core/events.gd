extends Node
## Global signal bus.
##
## Systems never reach into each other's UI. They emit here and whichever
## screen cares listens. Keeps the gameplay layer testable without a scene.

signal toast(text: String, kind: String)
signal money_changed(cash: int)
signal stock_changed(ingredient_id: String)
signal reputation_changed(value: float)
signal prompt_changed(text: String)
signal held_changed(label: String)
signal order_updated(order: Dictionary)
signal order_cleared()
signal time_changed(hour: int, minute: int)
signal day_ended(report: Dictionary)
signal state_changed(state: int)
signal quality_result(score: float, message: String)
signal price_changed(price: int)
signal upgrade_purchased(upgrade_id: String)
signal xp_changed(level: int, xp: int, xp_to_next: int, ratio: float)
signal level_up(level: int)
signal settings_changed()
signal overlay_changed(open: bool)
