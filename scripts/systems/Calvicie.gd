class_name Calvicie
## Él se va quedando calvo con los días (como la tos: es parte de lo que la calle le va quitando).
## Cada hoja suya tiene sus versiones <nombre>_c1/_c2/_c3 (tools/art/calvicie.py); aquí se escoge la del día.
##   0  días 1-12   el pelo de siempre
##   1  días 13-25  las entradas
##   2  días 26-38  la coronilla pelada, la franja a los lados
##   3  días 39-50  calvo


static func etapa() -> int:
	var d := GameState.day
	if d <= 12:
		return 0
	if d <= 25:
		return 1
	if d <= 38:
		return 2
	return 3


## La ruta de la hoja para hoy: "res://.../player.png" -> "res://.../player_c2.png" (si existe).
static func path(p: String) -> String:
	# Si no hay de esa etapa, la más cercana para atrás (las viñetas solo tienen la 2 y la 3).
	for e in range(etapa(), 0, -1):
		var alt := "%s_c%d.%s" % [p.get_basename(), e, p.get_extension()]
		if ResourceLoader.exists(alt):
			return alt
	return p


static func tex(p: String) -> Texture2D:
	return load(path(p))
