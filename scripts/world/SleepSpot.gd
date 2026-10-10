class_name SleepSpot
extends Area2D
## Un lugar donde pasar la noche (se duerme cuando la misión es buscar dónde dormir).
##   "banco" (plaza) y "kiosco" (techito del kiosco viejo): solo para dormir.
##   "rio", "callejon", "parque": se puede armar el cambuche (uno solo a la vez; se puede mudar).
##     "rio" es el principal: debajo del puente, donde se despierta el primer día.
##     El cambuche tiene caja para guardar cosas, la alcancía, mejoras (toldo, cocinita, candado,
##     cobija) y, con la cocinita, se cocina. Su estado vive en GameState.cambuche.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const NIGHT_SCENE := "res://scenes/world/Night.tscn"
const CARTONS_NEEDED := 3
const NAMES := {"banco": "el banco de la plaza", "kiosco": "el techito del kiosco viejo",
	"rio": "el cambuche del puente", "callejon": "el cambuche del callejón", "parque": "el cambuche del parque"}
## Cómo es cada lugar (se dice al armar).
const ABOUT := {
	"rio": "(Debajo del puente, donde se despertó el primer día. Tranquilo y húmedo. Lo más parecido a una casa.)",
	"callejon": "(Entre las bodegas: seco, pero de noche pasa de todo.)",
	"parque": "(En el parque: bonito. La policía pasa seguido.)",
}
const UPGRADE_LINES := {
	"toldo": "(Toldo puesto.)",
	"cocinita": "(Cocinita instalada.)",
	"candado": "(Candado en la caja.)",
	"alarma": "(Latas colgadas alrededor del cambuche, a la altura de la rodilla.)",
	"trampa": "(Tabla con clavos en la entrada, tapada con cartón.)",
	"cobija": "(Cobija puesta.)",
}

@export var spot_id := "banco"

var _player: Node2D
var _hint: Label
var _visual: Node2D


func _ready() -> void:
	add_to_group(Focus.GROUP)
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(28, 16)
	s.shape = r
	add_child(s)
	_hint = Label.new()
	_hint.add_theme_font_override("font", FONT)
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.add_theme_constant_override("outline_size", 3)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_color_override("font_color", Color(0.75, 0.8, 1.0))
	_hint.position = Vector2(-36, -30)
	_hint.size = Vector2(72, 10)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.z_index = 5
	_hint.visible = false
	add_child(_hint)
	_visual = Node2D.new()
	add_child(_visual)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	GameState.cambuche_changed.connect(_refresh_visual)
	_refresh_visual()


func is_cambuche_spot() -> bool:
	return spot_id in GameState.CAMBUCHE_SPOTS


func _on_enter(b: Node2D) -> void:
	if b.is_in_group("player"):
		_player = b
		_update_hint()


func _on_exit(b: Node2D) -> void:
	if b == _player:
		_player = null
		_hint.visible = false


func _update_hint() -> void:
	if is_cambuche_spot():
		_hint.text = "CAMBUCHE" if GameState.has_cambuche(spot_id) else "ARMAR"
		_hint.visible = true
	else:
		_hint.text = "DORMIR"
		_hint.visible = GameState.is_active("donde_dormir")


func _process(_delta: float) -> void:
	Focus.dim(self, _hint)
	if _player == null or GameState.input_blocked() or SceneRouter.busy:
		return
	if not Input.is_action_just_pressed("interact") or not Focus.mine(self):
		return
	if is_cambuche_spot():
		_cambuche()
	elif GameState.is_active("donde_dormir"):
		_offer_sleep()


## El cambuche se ve donde está: cartones (o con toldo) y la cocinita.
func _refresh_visual() -> void:
	for c in _visual.get_children():
		c.queue_free()
	if not GameState.has_cambuche(spot_id):
		if spot_id == "rio":  # el campamento de siempre, bajo el puente
			var camp := Sprite2D.new()
			camp.texture = load("res://assets/barrio/camp.png")
			camp.centered = false
			camp.offset = Vector2(-17, -camp.texture.get_height() + 4)
			_visual.add_child(camp)
		if _player:
			_update_hint()
		return
	var c := GameState.cambuche
	var bed := Sprite2D.new()
	var art: String = ["cambuche", "cambuche", "cambuche_toldo", "rancho", "ranchito"][GameState.cambuche_level()]
	if art == "cambuche" and c["toldo"]:
		art = "cambuche_toldo"
	bed.texture = load("res://assets/barrio/%s.png" % art)
	bed.centered = false
	bed.offset = Vector2(-16, -bed.texture.get_height() + 4)
	_visual.add_child(bed)
	if c["cocinita"]:
		var stove := Sprite2D.new()
		stove.texture = load("res://assets/barrio/cocinita.png")
		stove.position = Vector2(-20, -2)
		_visual.add_child(stove)
	if _player:
		_update_hint()


func _offer_sleep() -> void:
	var i := await Dialogue.talk([["", "(¿Pasar la noche en %s?)" % NAMES[spot_id]]], ["Dormir acá", "Todavía no"])
	if i != 0:
		return
	GameState.flags["sleep_spot"] = spot_id
	GameState.complete_quest("donde_dormir")
	SceneRouter.go(NIGHT_SCENE)


# ---------------------------------------------------------------- Cambuche

func _cambuche() -> void:
	if not GameState.has_cambuche(spot_id):
		await _build()
		if GameState.has_cambuche(spot_id) and (GameState.is_active("donde_dormir") or _is_night()):
			await _offer_sleep()
		return
	while true:
		var opts := ["Caja", "Alcancía", "Mejorar", "Cocinar", "Tablero", "Salir"]
		if GameState.is_active("donde_dormir") or _is_night():
			opts.push_front("Dormir")
		var i := await Dialogue.talk([["", "(Su cambuche. %s)" % _status()]], opts)
		match opts[i]:
			"Dormir":
				GameState.flags["sleep_spot"] = spot_id
				GameState.complete_quest("donde_dormir")
				SceneRouter.go(NIGHT_SCENE)
				return
			"Caja":
				await _box()
			"Alcancía":
				await _piggy_bank()
			"Mejorar":
				await _upgrade()
			"Cocinar":
				await _cook()
			"Tablero":
				await Conversations.run("tablero", null)
			_:
				return


## En el cambuche se puede dormir cualquier noche (no hace falta la misión de buscar dónde).
func _is_night() -> bool:
	var h := TimeManager.hour()
	return h >= 19 or h < 5


func _status() -> String:
	var c := GameState.cambuche
	var have := []
	for u in Items.UPGRADES:
		if c.get(u, false):
			have.append(Items.info(u)["name"].to_lower())
	var level := GameState.cambuche_level()
	var head := "Nivel %d: %s." % [level, GameState.CAMBUCHE_NAMES[level]]
	return head + ((" Tiene: %s." % ", ".join(have)) if not have.is_empty() else " Cartón.")


func _build() -> void:
	var has_bed := GameState.count("cama_carton") > 0
	var has_cartons := GameState.count("carton") >= CARTONS_NEEDED
	if GameState.has_cambuche():
		var i := await Dialogue.talk([["", ABOUT[spot_id]], ["", "(¿Mudar el cambuche acá? Con caja, alcancía y mejoras.)"]],
			["Mudarme", "No"])
		if i == 0:
			GameState.move_cambuche(spot_id)
			await Dialogue.talk([["", "(Mudanza completa.)"]])
		return
	if not has_bed and not has_cartons:
		await Dialogue.talk([["", ABOUT[spot_id]],
			["", "(Para armar un cambuche: tres cartones, o una cama de cartón [C].)"]])
		return
	var build := await Dialogue.talk([["", ABOUT[spot_id]], ["", "(¿Armar el cambuche acá?)"]],
		["Armar el cambuche", "Todavía no"])
	if build != 0:
		return
	if has_bed:
		GameState.remove_item("cama_carton")
	else:
		GameState.remove_item("carton", CARTONS_NEEDED)
	GameState.build_cambuche(spot_id)
	await Dialogue.talk([["", "(Cartones en el piso, una caja al lado.)"]])


func _box() -> void:
	while true:
		var i := await Dialogue.talk([["", "(La caja del cambuche. %s)" % ("Con candado." if GameState.cambuche["candado"] else "Sin candado: cualquiera la abre.")]],
			["Guardar", "Sacar", "Salir"])
		if i == 0:
			var slots := []
			var opts := []
			for k in GameState.SLOTS:
				var s = GameState.inventory[k]
				if s != null and not Items.info(s["id"]).get("fixed", false):
					slots.append(k)
					opts.append("%s x%d" % [Items.info(s["id"])["name"], s["qty"]])
			if slots.is_empty():
				await Dialogue.talk([["", "(No tiene nada para guardar.)"]])
				continue
			opts.append("Nada")
			var j := await Dialogue.talk([["", "(¿Qué guardar? %d/%d lugares)" % [GameState.cambuche["box"].size(), GameState.box_capacity()]]], opts)
			if j < slots.size():
				var s = GameState.inventory[slots[j]]
				var already: bool = GameState.cambuche["box"].any(func(b): return b["id"] == s["id"])
				if not already and GameState.cambuche["box"].size() >= GameState.box_capacity():
					await Dialogue.talk([["", "(La caja está llena. Para guardar más, hay que ampliar el cambuche.)"]])
					continue
				GameState.box_add(s["id"], s["qty"])
				GameState.remove_slot(slots[j], s["qty"])
		elif i == 1:
			var box: Array = GameState.cambuche["box"]
			if box.is_empty():
				await Dialogue.talk([["", "(La caja está vacía.)"]])
				continue
			var opts := []
			for s in box:
				opts.append("%s x%d" % [Items.info(s["id"])["name"], s["qty"]])
			opts.append("Nada")
			var j := await Dialogue.talk([["", "(¿Qué sacar?)"]], opts)
			if j < box.size():
				GameState.box_take(j)
		else:
			return


func _piggy_bank() -> void:
	var c := GameState.cambuche
	var i := await Dialogue.talk([["", "(La alcancía: $%d de $%d para el regalo de Victoria. En el bolsillo: $%d.)" % [c["alcancia"], GameState.GIFT_GOAL, GameState.money]]],
		["Guardar todo", "Guardar la mitad", "Sacar todo", "Salir"])
	match i:
		0, 1:
			var amount: int = GameState.money if i == 0 else GameState.money / 2
			if amount <= 0:
				await Dialogue.talk([["", "(No hay nada que guardar.)"]])
				return
			GameState.money -= amount
			GameState.money_changed.emit(GameState.money)
			c["alcancia"] += amount
			GameState.cambuche_changed.emit()
			await Dialogue.talk([["", "($%d a la alcancía.)" % amount]])
		2:
			if c["alcancia"] <= 0:
				await Dialogue.talk([["", "(Está vacía.)"]])
				return
			GameState.money += c["alcancia"]
			GameState.money_changed.emit(GameState.money)
			c["alcancia"] = 0
			GameState.cambuche_changed.emit()
			await Dialogue.talk([["", "(Saca todo. Se queda mirando la alcancía vacía.)"]])


## La pantalla de mejoras (CambucheUI): qué se puede poner, qué falta y qué se gana. Se elige, se pone
## y vuelve a la pantalla, hasta salir.
func _upgrade() -> void:
	while true:
		var id: String = await CambucheUI.choose(self)
		if id == "":
			return
		var c := GameState.cambuche
		if id.begins_with("nivel_"):
			var plan: Dictionary = Items.EXPANSIONS[int(id.substr(6))]
			for item in plan["needs"]:
				GameState.remove_item(item, plan["needs"][item])
			c[plan["flag"]] = true
			TimeManager.skip(1.0)
			GameState.change_mood(8.0)
			GameState.cambuche_changed.emit()
			await Dialogue.talk([["", plan["line"]]])
		else:
			GameState.remove_item(id)
			c[id] = true
			GameState.cambuche_changed.emit()
			await Dialogue.talk([["", UPGRADE_LINES[id]]])


func _cook() -> void:
	if not GameState.cambuche["cocinita"]:
		await Dialogue.talk([["", "(Sin cocinita no hay cocina. Lata y vela, [C] en la mochila.)"]])
		return
	if GameState.count("arroz") == 0:
		await Dialogue.talk([["", "(No hay qué cocinar. Arroz donde Germán.)"]])
		return
	if not GameState.has_space_for("sopa"):
		await Dialogue.talk([["", "(No cabe la sopa en la mochila.)"]])
		return
	GameState.remove_item("arroz")
	GameState.add_item("sopa")
	TimeManager.skip(0.5)
	await Dialogue.talk([["", "(Arroz, agua de la llave, una vela y media hora.)"],
		["", "(Sopa de arroz.)"]])
