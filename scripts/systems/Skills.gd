class_name Skills
## Habilidades: se aprenden al terminar cada sueño y sirven en los dos mundos (lo que aprende
## soñando le sirve en la vida, y al revés). Siete en total; después de la cuarta, se espacian.
## Dónde se aprende cada una: DREAM_SKILL (por sueño) y ContinueScreen (la primera).

const DEFS := {
	"aguante": {"name": "Aguante",
		"desc": "El desprecio de la gente te baja la mitad de ánimo. En los sueños, más vida."},
	"sangre_fria": {"name": "Sangre fría",
		"desc": "Más tiempo para reaccionar (colados, el celador de la fuente). En los sueños, mejor puntería."},
	"labia": {"name": "Mirada",  # (el id sigue siendo "labia")
		"desc": "Se queda mirando fijo hasta que la gente se incomoda: pedir y los carteles rinden más, y todo sale 10% más barato. En los sueños, los jefes dudan antes de atacar."},
	"rebusque": {"name": "Rebusque",
		"desc": "Latas y botellas valen 50% más y Lukas olfatea más lejos. En los sueños, los enemigos sueltan más cosas."},
	"cocinero": {"name": "Cocinero de calle",
		"desc": "Lo que cocinás en el cambuche llena más. En los sueños, la comida cura el doble."},
	"paso_firme": {"name": "Paso firme",
		"desc": "Caminás más rápido y el hambre no te frena tanto. En los sueños, te movés más rápido."},
	"lazo_lukas": {"name": "Lazo con Lukas",
		"desc": "Lukas encuentra cosas escondidas más seguido y su compañía te levanta más el ánimo."},
}
const ORDER := ["aguante", "sangre_fria", "labia", "rebusque", "cocinero", "paso_firme", "lazo_lukas"]
## Qué habilidad deja cada sueño (el primero, el beat 'em up del prólogo, deja "aguante").
## Los dos últimos van en los próximos sueños (todavía por hacer):
##   beat 'em up 3 (Brenda, la mamá que se fue a Ibagué) → Cocinero de calle: aprendió a cocinarse solo.
##   el sueño de Mauricio (el papá que se fue cuando él tenía 15) → Paso firme: aprendió a caminar solo.
const DREAM_SKILL := {"plomo_d1": "sangre_fria", "carrera1": "labia", "sigilo1": "rebusque", "carrera3": "lazo_lukas",
	"callejon3": "cocinero", "lucha4": "paso_firme"}


static func name_of(id: String) -> String:
	return DEFS.get(id, {"name": id})["name"]


static func desc(id: String) -> String:
	return DEFS.get(id, {"desc": ""})["desc"]
