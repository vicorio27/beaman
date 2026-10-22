class_name Torneo
## EL TORNEO EN EL BARRIO (Highway to Hell): lo que toca el juego. Los datos y las reglas están en
## TenisHistoria (sin pantallas); el día de trabajo, en TenisJornada.
##   - DayTasks._marta (día 31): el cobrador le pasa la deuda (deuda()).
##   - GameState.new_day: manana() pone las líneas de la mañana (la llegada del coliseo, lo que pasó
##     ayer en la cancha, cuánto falta) y el cobro del día 36.
##   - Vecindario: el coliseo por fuera, en el potrero de arriba (visible()).
##   - Conversations ("torneo"): la entrada (puerta()).
## Estado (GameState.flags):
##   "gota_deuda": lo que debe (0 o nada: no debe). "gota_vence": el último día para pagar.
##   "torneo": {"bracket": dict, "seed": n, "usados": [ids que ya abandonaron], "trabajo": día de la
##     última jornada, "contratado": bool, "ganado": plata de todas las jornadas, "por": [ids por los
##     que terminó partidos], "salvados": [ids por los que ganó], "ultimo": id del último que le dejó
##     la raqueta}.
##   "torneo_volver": [escena, camino al punto de la entrada] (para volver de la jornada).

const JORNADA := "res://scenes/tenis/TenisJornada.tscn"


static func state() -> Dictionary:
	return GameState.flags.get("torneo", {})


## ¿Está el coliseo en el barrio hoy?
static func visible() -> bool:
	return not state().is_empty() and TenisHistoria.dia_torneo(GameState.day) >= 0


## ¿Se puede trabajar ahora? (de 8 a 6, una jornada por día)
static func abierto() -> bool:
	var h := TimeManager.hour()
	return visible() and h >= TenisHistoria.ABRE and h < TenisHistoria.CIERRA


static func trabajo_hoy() -> bool:
	return int(state().get("trabajo", -1)) == GameState.day


## El cobrador le pasa la deuda (lo llama DayTasks._marta).
static func deuda() -> void:
	var f := GameState.flags
	f["gota_deuda"] = TenisHistoria.DEUDA
	f["gota_vence"] = GameState.day + TenisHistoria.PLAZO
	GameState.start_quest("gota_deuda")


static func debe() -> int:
	return int(GameState.flags.get("gota_deuda", 0))


# ---------------------------------------------------------------- La mañana

## Las líneas de la mañana (desde GameState.new_day, con el día ya cambiado).
static func manana() -> Array:
	var g := GameState
	var f := g.flags
	var lines := []
	var d := TenisHistoria.dia_torneo(g.day)
	if g.day == TenisHistoria.DIA_LLEGA and state().is_empty():
		var seed_ := randi() % 100000
		f["torneo"] = {"bracket": TenisBracket.new(TenisData.TOURNAMENT["entrants"]).to_dict(), "seed": seed_,
			"usados": [], "trabajo": -1, "contratado": false, "ganado": 0, "por": [], "salvados": [], "ultimo": ""}
		lines.append(TenisHistoria.TEXTOS["llega"])
		g.start_quest("torneo_trabajo")
	elif not state().is_empty() and (d > 0 or g.day == TenisHistoria.DIA_LLEGA + 4):
		lines.append_array(_ayer(d - 1 if d > 0 else 3))
	if g.day == TenisHistoria.DIA_LLEGA + 4 and not state().is_empty() and not f.get("torneo_fin", false):
		lines.append_array(_fin())
	if debe() > 0:
		var vence := int(f.get("gota_vence", 0))
		if g.day > vence:
			lines.append_array(_cobro())
		else:
			var left := vence - g.day
			var falta := maxi(0, debe() - g.money)
			lines.append((TenisHistoria.TEXTOS["gota_ultimo"] if left == 0 else TenisHistoria.TEXTOS["gota_faltan"] % (left + 1))
				+ (TenisHistoria.TEXTOS["gota_tiene"] if falta == 0 else TenisHistoria.TEXTOS["gota_falta"] % TenisData.money(falta)))
	return lines


## Lo que pasó ayer en el coliseo: los partidos que quedaron se juegan (sin él), y el que él salvó vuelve.
static func _ayer(r: int) -> Array:
	var st := state()
	var b := TenisBracket.from_dict(st["bracket"])
	if r < 0 or r >= b.rounds.size():
		return []
	var lines := []
	var worked := int(st.get("trabajo", -1)) == GameState.day - 1
	var m := b.next_match()
	while not m.is_empty() and int(m["round"]) == r:
		b.simulate(m, TenisBracket.match_seed(m, int(st["seed"])))
		m = b.next_match()
	st["bracket"] = b.to_dict()
	if not worked:
		lines.append(TenisHistoria.TEXTOS["no_fue"])
	var ultimo: String = st.get("ultimo", "")
	if worked and ultimo != "" and ultimo in st.get("salvados", []) and b.alive(ultimo) and r + 1 < b.rounds.size():
		lines.append(str(TenisHistoria.ABANDONOS.get(ultimo, {}).get("vuelve", "")))
	return lines


## El torneo se acabó: el campeón, el coliseo que se va, y la raqueta.
static func _fin() -> Array:
	var g := GameState
	var st := state()
	g.flags["torneo_fin"] = true
	var b := TenisBracket.from_dict(st["bracket"])
	var champ := b.champion()
	var lines := []
	if champ != "":
		lines.append(TenisHistoria.TEXTOS["campeon"] % TenisData.player(champ)["name"])
	g.complete_quest("torneo_trabajo")
	var ultimo: String = st.get("ultimo", "")
	if ultimo != "" and g.count("raqueta") == 0 and g.add_item("raqueta") > 0:
		lines.append(TenisHistoria.TEXTOS["raqueta_queda"] % TenisData.player(ultimo)["name"])
	return lines


## La mañana del cobro: con la plata, se acaba; sin ella, se lleva lo que tenga y la mochila.
static func _cobro() -> Array:
	var g := GameState
	var f := g.flags
	var lines := []
	var owe := debe()
	f.erase("gota_deuda")
	g.complete_quest("gota_deuda")
	if g.money >= owe:
		g.add_money(-owe)
		g.raise_bond("marta")
		g.change_mood(10.0)
		f["gota_pagada"] = true
		f["cobro_escena"] = "paga"  # en la calle, al empezar el día, se ve (QuestDirector._cobrador)
		lines.append(TenisHistoria.TEXTOS["cobro_paga"])
	else:
		var had := g.money
		g.add_money(-had)
		var lost := 0
		for i in g.SLOTS:
			var s = g.inventory[i]
			if s != null and not Items.info(s["id"]).get("fixed", false):
				g.inventory[i] = null
				lost += 1
		g.inventory_changed.emit()
		g.change_mood(-15.0)
		f["gota_mochila"] = true
		f["cobro_escena"] = "lleva" if lost > 0 or had > 0 else "nada"
		lines.append(TenisHistoria.TEXTOS["cobro_lleva"] % TenisData.money(had) if lost > 0 or had > 0 else TenisHistoria.TEXTOS["cobro_nada"])
	return lines


# ---------------------------------------------------------------- La entrada

## La entrada del coliseo (Conversations "torneo"): de 8 a 6, una jornada por día.
static func puerta(spot: Node) -> void:
	var st := state()
	if not visible():
		return
	if trabajo_hoy():
		await Dialogue.talk([["EL ORGANIZADOR", TenisHistoria.TEXTOS["ya_trabajo"][GameState.day % 2]]])
		return
	if not abierto():
		await Dialogue.talk([["", TenisHistoria.TEXTOS["cerrado"]]])
		return
	if not st.get("contratado", false):
		await Dialogue.talk(TenisHistoria.ORGANIZADOR_PRIMERA)
		st["contratado"] = true
	var d := TenisHistoria.dia_torneo(GameState.day)
	var i := await Dialogue.talk([["EL ORGANIZADOR", TenisHistoria.ORGANIZADOR_DIA[clampi(d, 0, 3)]]], TenisHistoria.TEXTOS["a_la_cancha"])
	if i != 0:
		return
	var scene := spot.get_tree().current_scene
	GameState.flags["torneo_volver"] = [scene.scene_file_path, str(scene.get_path_to(spot))]
	SceneRouter.go(JORNADA)
