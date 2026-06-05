extends CanvasLayer

@onready var _bar: ProgressBar = $BalanceBar
@onready var _good_label: Label = $BalanceBar/GoodLabel
@onready var _bad_label: Label = $BalanceBar/BadLabel


func _ready() -> void:
	GameManager.balance_changed.connect(_on_balance_changed)
	# Seed with the current balance in case counts already changed before we connected.
	_on_balance_changed(0.5, 0.5)
	GameManager._emit()


func _on_balance_changed(good_ratio: float, bad_ratio: float) -> void:
	_bar.value = good_ratio * 100.0
	_good_label.text = "GOOD %d%%" % round(good_ratio * 100.0)
	_bad_label.text = "BAD %d%%" % round(bad_ratio * 100.0)
