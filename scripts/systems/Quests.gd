class_name Quests
## Definición de las misiones. Tipos: "main" (principal, en orden), "side" (secundaria),
## "optional" (opcional, chiquita). El estado vive en GameState.quests; las reglas de cuándo
## se cumplen, en QuestDirector.

const DEFS := {
	# Día 1 — principales
	"conseguir_comida": {"title": "Conseguí algo para comer", "kind": "main"},
	"pasar_el_dia": {"title": "Al anochecer, volvé al puente", "kind": "main"},
	"donde_dormir": {"title": "Encontrá dónde pasar la noche", "kind": "main"},
	# Día 1 — secundarias
	"latas": {"title": "Juntá 5 latas o botellas", "kind": "side", "goal": 5},
	"cartones": {"title": "Juntá 3 cartones para dormir", "kind": "side", "goal": 3},
	"bultos_german": {"title": "Cargá los bultos de Don Germán", "kind": "side"},
	"mandado_marta": {"title": "Llevá el pedido de Marta", "kind": "side"},
	# Día 1 — opcionales
	"lukas_olfato": {"title": "Que Lukas busque comida [F]", "kind": "optional"},
	# Día 2 — principales: aprender lo básico, en orden (y después, el recuerdo de la moto)
	"t_cambuche": {"title": "Armá el cambuche: 3 cartones [C]", "kind": "main"},
	"t_lukas": {"title": "Dale de comer a Lukas [F]", "kind": "main"},
	"t_bano": {"title": "Bañate: baño de la plaza, $1.000", "kind": "main"},
	"moto_cafe": {"title": "Esa moto frente al café...", "kind": "main"},
	# Día 3 en adelante — la cédula (varios días)
	"hablar_german": {"title": "Don Germán te quiere decir algo", "kind": "main"},
	"cedula": {"title": "Sacá la cédula en el centro", "kind": "main"},
	"c_plata": {"title": "Juntá $55.000 para el trámite", "kind": "side"},
	"c_foto": {"title": "Fotos tipo documento (centro)", "kind": "side"},
	"c_direccion": {"title": "Conseguí una dirección", "kind": "side"},
	"recoger_cedula": {"title": "Recogé la cédula", "kind": "main"},
	# Favores (vínculos)
	"f_anillo": {"title": "El anillo de Germán (bodegas)", "kind": "side"},
	"f_anillo_volver": {"title": "Llevale el anillo a Germán", "kind": "side"},
	"f_carta": {"title": "La carta de Samuel (casa del este)", "kind": "side"},
	"f_carta_volver": {"title": "Volvé con Samuel", "kind": "side"},
	"f_gato": {"title": "Encontrá a Michi, el gato de Marta", "kind": "side"},
	"f_gato_volver": {"title": "Contale a Marta", "kind": "side"},
	# La familia (disparan los sueños 6 y 7)
	"llamar_mama": {"title": "Llamá a mamá (teléfono, $500)", "kind": "side"},
	"papa_plaza": {"title": "Ese hombre de la moto, en la plaza", "kind": "side"},
	# Del Día 2 en adelante (se repiten cada día)
	"sobrevivir": {"title": "Sobreviví hasta la noche", "kind": "main"},
	"lukas_comida": {"title": "Dale de comer a Lukas [F]", "kind": "optional"},
	"lukas_agua": {"title": "Dale agua a Lukas (cuenco: guarda)", "kind": "optional"},
	"banarse": {"title": "Bañate: baño de la plaza, $1.000", "kind": "optional"},
	# Victoria: verla, que lo vea, y pedir visitas en la Defensoría de Familia
	"v_colegio": {"title": "Victoria sale a las 12 (centro)", "kind": "main"},
	"v_defensoria": {"title": "Pedí visitas: Defensoría (centro)", "kind": "main"},
	"v_audiencia": {"title": "La audiencia en la Defensoría", "kind": "main"},
	"v_visita": {"title": "Visita: domingo 10-12, Parque", "kind": "main"},
	# El final: que se sepa la verdad, y el cumpleaños
	"v_verdad": {"title": "La verdad: Defensoría (pruebas)", "kind": "main"},
	"v_cumple": {"title": "El cumpleaños de Victoria", "kind": "main"},
	# Misterios (las pistas van al tablero del cambuche)
	"m_el": {"title": "¿Quién es \"él\"? (tablero)", "kind": "side"},
	"m_tejas": {"title": "La casa de tejas (tablero)", "kind": "side"},
	"m_negro": {"title": "El señor de negro (tablero)", "kind": "side"},
	# Del Día 2 en adelante (una vez)
	"regalo_hija": {"title": "Regalo para Victoria", "kind": "side"},
	"armar_cambuche": {"title": "Armá tu cambuche [C en la mochila]", "kind": "side"},
	# Encargos del día (DayTasks): uno por día marcado, hasta la noche
	"hoy_comer3": {"title": "Hoy: comer tres veces", "kind": "side"},
	"hoy_alcancia": {"title": "Hoy: $10.000 más en la alcancía", "kind": "side"},
	"hoy_truco": {"title": "Hoy: enseñarle algo a Lukas", "kind": "side"},
	"hoy_no_pedir": {"title": "Hoy: no pedir ni una moneda", "kind": "side"},
	"hoy_trabajar": {"title": "Hoy: trabajar (obra, reparto, ruta)", "kind": "side"},
	"hoy_bano": {"title": "Hoy: verme decente (bañado)", "kind": "side"},
	"hoy_tumba": {"title": "Hoy: el árbol amarillo (Parque)", "kind": "side"},
	"hoy_vet1": {"title": "Hoy: vacunas de Lukas (veterinaria)", "kind": "side"},
	"hoy_vet2": {"title": "Hoy: control de Lukas (veterinaria)", "kind": "side"},
	"hoy_vet3": {"title": "Hoy: las gotas de Lukas (veterinaria)", "kind": "side"},
	"hoy_rosa": {"title": "Hoy: Doña Rosa te necesita (puesto)", "kind": "side"},
	"hoy_samuel": {"title": "Hoy: aguapanela para Samuel", "kind": "side"},
	"hoy_wilson": {"title": "Hoy: ayudale a Wilson con las latas", "kind": "side"},
	"hoy_german": {"title": "Hoy: una flor para Don Germán", "kind": "side"},
	"hoy_mono": {"title": "Hoy: el show del Mono (Parque)", "kind": "side"},
	"hoy_marta": {"title": "Hoy: el cobrador, donde Marta", "kind": "side"},
	"hoy_efrain": {"title": "Hoy: Don Efraín te busca (Parque)", "kind": "side"},
	"hoy_zaida1": {"title": "Hoy: Zaida (centro)", "kind": "side"},
	"hoy_zaida2": {"title": "Hoy: Zaida (plaza)", "kind": "side"},
	"hoy_zaida3": {"title": "Hoy: Zaida (Parque)", "kind": "side"},
	"hoy_zaida4": {"title": "Hoy: Zaida (centro)", "kind": "side"},
	"hoy_zaida5": {"title": "Hoy: Zaida, la última vez (plaza)", "kind": "side"},
}

const KIND_LABEL := {"main": "PRINCIPAL", "side": "SECUNDARIA", "optional": "OPCIONAL"}


static func title(id: String) -> String:
	if id == "sobrevivir":
		return "Día %d: llegá a la noche" % GameState.day
	if id == "recoger_cedula" and GameState.flags.has("cedula_day"):
		return "Recogé la cédula (desde el día %d)" % GameState.flags["cedula_day"]
	return DEFS.get(id, {"title": id})["title"]


static func kind(id: String) -> String:
	return DEFS.get(id, {"kind": "side"})["kind"]


## Progreso "(3/5)" para las que juntan cosas; "" para las demás.
static func progress_text(id: String) -> String:
	match id:
		"latas":
			return " (%d/5)" % mini(5, GameState.count("lata") + GameState.count("botella"))
		"cartones":
			return " (%d/3)" % mini(3, GameState.count("carton"))
		"c_plata":
			return " ($%dk/55k)" % mini(55, GameState.money / 1000)
		"regalo_hija":
			var have: int = GameState.cambuche.get("alcancia", 0)
			return " ($%dk/%dk)" % [have / 1000, GameState.GIFT_GOAL / 1000]
	return ""
