extends CanvasLayer

@onready var _bar: ProgressBar = $BalanceBar
@onready var _good_label: Label = $BalanceBar/GoodLabel
@onready var _bad_label: Label = $BalanceBar/BadLabel
@onready var _mana_circle: Control = $BottomRight/ManaCircle


func _ready() -> void:
	GameManager.balance_changed.connect(_on_balance_changed)
	GameManager.mana_changed.connect(_on_mana_changed)
	_on_balance_changed(0.5, 0.5)
	GameManager._emit()
	_on_mana_changed(GameManager.mana, GameManager.MAX_MANA)


func _on_balance_changed(good_ratio: float, bad_ratio: float) -> void:
	_bar.value = good_ratio * 100.0
	_good_label.text = "GOOD %d%%" % round(good_ratio * 100.0)
	_bad_label.text = "BAD %d%%" % round(bad_ratio * 100.0)


func _on_mana_changed(current: int, maximum: int) -> void:
	_mana_circle.call("set_mana", current, maximum)
