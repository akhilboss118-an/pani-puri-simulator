extends Node
## Lightweight localization. Godot's TranslationServer does the lookup; this
## wrapper stores the active locale in settings and exposes t().

const LOCALES := ["en", "hi"]

var locale: String = "en"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_locale(String(Game.settings.get("locale", "en")))


func set_locale(value: String) -> void:
	locale = value if LOCALES.has(value) else "en"
	TranslationServer.set_locale(locale)
	Events.settings_changed.emit()


func t(key: String) -> String:
	return tr(key)


func language_name(code: String) -> String:
	if code == "hi":
		return "हिंदी"
	return "English"
