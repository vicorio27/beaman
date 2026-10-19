class_name TenisHistoria
## El torneo en la historia, sin pantallas (los datos y las reglas; se prueban sin ventana en
## tools/tests/tenis_tests.gd). Lo que toca el juego (la plata, las mañanas, la puerta) está en
## scripts/systems/Torneo.gd; el día de trabajo, en scripts/tenis/TenisJornada.gd.
##
## La historia (docs/TENIS.md, "La historia"):
##   - Día 31: el cobrador del gota a gota donde Marta. Se meta como se meta (pagándole el abono o
##     espantándolo), el cobrador le pasa la deuda: "el que se mete, responde". $80.000 en cuatro días,
##     o la mochila.
##   - Día 32, en la mañana: en el potrero de arriba amaneció un coliseo. El torneo dura cuatro días
##     (previa, cuartos, semifinal y final, uno por día).
##   - Él trabaja de recogebolas (de 8 a 6, una jornada por día): sueldo y propinas por traer rápido
##     las pelotas. Y cada día un profesional abandona a la mitad de su partido (cada uno a su manera),
##     y el organizador manda al mudo a terminarlo con la raqueta del que se fue.
##   - Día 36, en la mañana: el cobrador. Con la plata, se acaba. Sin ella, se lleva la mochila.

const DEUDA := 80000
const DIA_COBRADOR := 31      # el día de Marta (DayTasks)
const DIA_LLEGA := 32         # el primer día del torneo
const PLAZO := 4              # días para pagar: vence en la noche del 35, cobra la mañana del 36
const ABRE := 8               # la jornada: de 8 a 6
const CIERRA := 18

const SUELDO := 12000
const PROPINA_BOLA := 300      # por pelota traída rápido
const RAPIDO := 4.0           # segundos: traerla antes de esto es "rápido"
const LENTO := 8.0            # después de esto, el tenista le grita
## Lo que le da el profesional si él le gana el partido que dejó tirado (según la ronda), y si lo pierde.
const PROPINA_GANA := {"Previa": 10000, "Cuartos": 15000, "Semifinal": 25000, "Final": 40000}
const CONSUELO := 3000
## Después de cuántos juegos se va el que abandona (en el formato corto, en el primero).
const ABANDONA_JUEGOS := {"corto": 1, "arcade": 2, "real": 3}

## Cómo abandona cada uno. "pop": lo que sale en la cancha; "lines": la escena (el narrador va con "");
## "raqueta": cómo le pasa la raqueta; "vuelve": la mañana siguiente, si siguió en el torneo (porque él ganó).
const ABANDONOS := {
	"kyrgistan": {"pop": "¡KYRGISTÁN SE VA!",
		"lines": [["", "(Kyrgistán pierde un punto. Lo mira al juez. Mira la raqueta. Mira al público.)"],
			["KYRGISTÁN", "—¡Esto es un circo! ¡Un circo de barrio! ¡Me voy!"],
			["", "(Rompe la raqueta contra el piso. Saca otra del maletín. La rompe también. La tercera la tira entera, de puro cansado. Se va.)"]],
		"salida": "furia",
		"raqueta": "(La que no alcanzó a romper. Todavía está tibia de rabia.)",
		"vuelve": "Kyrgistán volvió al coliseo. Dice que nunca se fue. Nadie le lleva la contraria."},
	"monfiz": {"pop": "¡CALAMBRE!",
		"lines": [["", "(Monfiz se tira por una pelota imposible. Llega. La devuelve. Y se queda en el piso.)"],
			["MONFIZ", "—Calambre. Los dos. Las dos piernas. Y uno en una parte que no sabía que tenía."],
			["", "(Lo sacan en camilla, saludando al público como si hubiera ganado.)"]],
		"raqueta": "(Le grita desde el túnel, con una sonrisa enorme: —¡Usted puede! ¡Tírese!)",
		"salida": "camilla",
		"vuelve": "Monfiz volvió caminando como un pato. Dice que el calambre fue \"artístico\"."},
	"moutette": {"pop": "¡DESCALIFICADO!",
		"lines": [["MOUTETTE", "—¡Esa pelota fue adentro! ¡Y la anterior! ¡Y la de ayer! ¡Exijo hablar con el juez del juez!"],
			["EL JUEZ", "—Señor Moutette, es la queja número cuarenta. Está descalificado."],
			["MOUTETTE", "—Quiero poner una queja por la descalificación."]],
		"raqueta": "(La dejó tirada en el piso, para no tener que dársela.)",
		"salida": "camina",
		"vuelve": "Moutette volvió con un abogado. El abogado se quejó del café."},
	"bublikov": {"pop": "¡SE ABURRIÓ!",
		"lines": [["", "(Bublikov saca por abajo. Gana el punto. Bosteza.)"],
			["BUBLIKOV", "—No. Ya está. Me aburrí. Esto ya lo vi."],
			["", "(Se va a parar al pie de la silla del juez. Desde ahí le dice cómo cantar los puntos.)"]],
		"raqueta": "(Desde la silla, sin mirarlo: —Haga algo raro. Algo que yo no haría. ... Eso yo sí lo haría.)",
		"salida": "silla",
		"vuelve": "Bublikov volvió. Dice que se desaburrió viendo jugar al mudo."},
	"sabalenkova": {"pop": "¡SIN CUERDAS!",
		"lines": [["", "(Sabalenkova le pega tan duro a la pelota que se le revientan las cuerdas. A las cinco raquetas. En cinco golpes.)"],
			["SABALENKOVA", "—¡AAAAAH! ... (Grita igual sin pelota.) No hay más. Me voy a encordar. Usted, termine."]],
		"raqueta": "(La única que aguantó. Pesa como una puerta.)",
		"salida": "camina",
		"vuelve": "Sabalenkova volvió con veinte raquetas nuevas. Ya reventó tres en el calentamiento."},
	"tiafuego": {"pop": "¡SE FUE A LA TRIBUNA!",
		"lines": [["", "(Tiafuego hace un ganador. Celebra con la tribuna. Sube a la tribuna. Lo cargan. Se lo llevan.)"],
			["TIAFUEGO", "—¡VAMOOOS! ... ¡Ya vuelvo! ... ¡No vuelvo! ¡Siga usted, recogebolas!"]],
		"raqueta": "(La raqueta bajó de la tribuna de mano en mano, como un muerto famoso.)",
		"salida": "tribuna",
		"vuelve": "Tiafuego volvió. Dice que la tribuna lo devolvió solo cuando se cansó."},
	"sheltron": {"pop": "¡UNA LLAMADA!",
		"lines": [["", "(Le suena el celular a Sheltron, en el bolsillo de la pantaloneta. En la mitad del punto.)"],
			["SHELTRON", "—Larga distancia. Tengo que contestar. ... ¿Aló? ¿Mamá? Sí, estoy jugando. No, no he comido."],
			["", "(Se va hablando hacia el túnel. Con la mano libre le hace señas a él: que juegue.)"]],
		"raqueta": "(La raqueta todavía vibra del último saque.)",
		"salida": "tel",
		"vuelve": "Sheltron volvió. La llamada duró toda la noche. Era la mamá."},
	"pecador": {"pop": "¡SE COLGÓ!",
		"lines": [["", "(Pecador se queda quieto en la mitad de la cancha. No parpadea. La pelota le pasa por al lado.)"],
			["PECADOR", "—Error. Fuera de memoria. Reiniciando. ... Reiniciando. ..."],
			["", "(Se lo llevan cargado, recto como una tabla, a ver si alguien lo desconecta y lo vuelve a conectar.)"]],
		"raqueta": "(La raqueta está tan limpia que da miedo usarla.)",
		"salida": "tabla",
		"vuelve": "Pecador volvió. Lo desconectaron y lo volvieron a conectar. Funcionó."},
	"yokovich": {"pop": "¡PIDIÓ EL FISIO!",
		"lines": [["YOKOVICH", "—Fisio. Necesito el fisio. Me duele... (Se toca la pierna. La otra.) ...esto."],
			["EL ORGANIZADOR", "—El fisio se demora cuarenta minutos. El canal no espera. ¡Recogebolas!"]],
		"raqueta": "(Se acostó en la toalla. Lo va a mirar jugar con cara de que todavía no ha perdido.)",
		"salida": "toalla",
		"vuelve": "Yokovich volvió. Ya no le duele nada. Nunca le dolió nada."},
	"fedorer": {"pop": "¡LA ESPALDA!",
		"lines": [["", "(Fedorer se agacha por una dejada. No se vuelve a enderezar. Se queda así, con elegancia.)"],
			["FEDORER", "—La espalda. Tengo cuarenta y tantos. ... No le digan a nadie. Usted, termine. Con estilo, por favor."]],
		"raqueta": "(La raqueta roja. Huele a perfume caro y a ungüento.)",
		"salida": "doblado",
		"vuelve": "Fedorer volvió, derechito. Dice que fue \"un momento de reflexión\"."},
}

## El organizador: la primera vez lo contrata; después, cada mañana, una línea.
const ORGANIZADOR_PRIMERA := [
	["EL ORGANIZADOR", "—¿Usted es el de la fila? ¿Busca trabajo? Necesito recogebolas. Se me fueron tres: uno a la feria y dos con la feria."],
	["", "(Lo mira de arriba abajo: la barba, la corbata, un zapato de cada color.)"],
	["EL ORGANIZADOR", "—¿No habla? ¿Nada? ... Perfecto. Usted no opina, no pide autógrafos y no le da entrevistas al canal. Contratado."],
	["EL ORGANIZADOR", "—Doce mil el día, más las propinas. Se agacha al lado de la red, quieto. Se acaba el punto, corre, trae la pelota y vuelve. Rápido."],
	["EL ORGANIZADOR", "—Y no se mueva mientras juegan. Un recogebolas que se mueve es un recogebolas muerto. Bueno, despedido. Es casi lo mismo."],
]
const ORGANIZADOR_DIA := [
	"—¡El mudo! Llegó. A la cancha, que hoy hay previa. Y no se quede mirando: el que mira es público, y el público paga.",
	"—Cuartos de final. Hoy hay cámaras. No mire a las cámaras. Bueno, usted no mira nada. Siga así.",
	"—Semifinal. Si hoy también se me va uno, ya sabe. Ya es como el suplente oficial. No le subo el sueldo.",
	"—La final. La final, mudo. Hoy no se me va nadie. ... ¿Verdad que no? ... Póngase cerca de la silla, por si acaso.",
]


## El día del torneo (0 = previa, 1 = cuartos...) o -1 si hoy no hay.
static func dia_torneo(day: int, rounds: int = 4) -> int:
	var i := day - DIA_LLEGA
	return i if i >= 0 and i < rounds else -1


## Quién abandona hoy, entre los partidos que faltan de la ronda r: {"slot", "id"} (o {} si no hay).
## Prefiere a los que no han abandonado antes; entre ellos, lo decide la semilla (el mismo torneo, el
## mismo abandono).
static func quien_abandona(b: TenisBracket, r: int, usados: Array, seed_: int) -> Dictionary:
	var cands := []
	for m in b.pending(r):
		for side in ["a", "b"]:
			if not m[side] in usados:
				cands.append({"slot": int(m["slot"]), "id": m[side]})
	if cands.is_empty():  # ya abandonaron todos los de hoy alguna vez: se repite
		for m in b.pending(r):
			cands.append({"slot": int(m["slot"]), "id": m["a"]})
	if cands.is_empty():
		return {}
	return cands[posmod(seed_ * 7 + r * 13, cands.size())]


## Lo que se gana en una jornada: el sueldo, las propinas de las pelotas y la del profesional.
static func paga(round_name: String, gano: bool, bolas_rapidas: int) -> Dictionary:
	var pro: int = PROPINA_GANA.get(round_name, 0) if gano else CONSUELO
	return {"sueldo": SUELDO, "bolas": bolas_rapidas * PROPINA_BOLA, "pro": pro,
		"total": SUELDO + bolas_rapidas * PROPINA_BOLA + pro}


## Después de cuántos juegos abandona, según el formato.
static func juegos_para_abandonar(fmt: String) -> int:
	return int(ABANDONA_JUEGOS.get(fmt, 2))
