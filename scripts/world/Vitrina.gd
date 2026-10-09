extends AnimatedSprite2D
## La vitrina de TV RADIO: de día, las teles prendidas; de 20 a 8, la reja abajo.


func _ready() -> void:
	TimeManager.hour_changed.connect(func(_h: int): _refresh())
	_refresh()


func _refresh() -> void:
	var h := TimeManager.hour()
	play("default" if h >= 8 and h < 20 else "noche")
