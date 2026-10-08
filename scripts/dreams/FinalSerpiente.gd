extends "res://scripts/prologue/LilatoArena.gd"
## EL SUEÑO FINAL — fase 3 de 3: bajo el puente, como en el prólogo. Lilato (más fuerte), el súper
## cuchillo y la serpiente. Esta vez, cuando la serpiente cae, se deshace: denuncias, fotos, la portada.
## Abajo de todo, la página 14. Lilato queda destruida: en el sueño, para siempre.

const NIGHT := "res://scenes/world/Night.tscn"


func _ready() -> void:
	super._ready()
	player.max_hp = 90
	player.hp = 90
	lilato.max_hp = 260
	lilato.hp = 260
	lilato.speed = 62.0
	lilato.damage = 8


func _intro() -> void:
	mood.forced_distress = 0.55
	await get_tree().create_timer(0.6).timeout
	await Dialogue.talk([
		["", "Bajo el puente. Donde empezó todo. El agua sube hasta las rodillas."],
		["LILATO", "—¿Todavía? ¿Después de todo lo que hice?"],
		["YO", "—Por todo lo que hiciste."],
		["LILATO", "—Estás más flaco. Te queda mal."],
		["YO", "—Vos estás igual. Eso es lo que te queda mal."],
	])
	hud.show_boss("LILATO")
	hud.set_boss(1.0)
	lilato.life_changed.connect(hud.set_boss)
	lilato.set_physics_process(true)
	phase = Phase.LILATO
	_sfx["gogogo"].play()


## La serpiente cae: se deshace. Fin del sueño, y de ella en los sueños.
func _on_serpent_died() -> void:
	phase = Phase.CLEAR
	mood.forced_distress = 0.2
	MusicDirector.force("")
	shake(6.0)
	await get_tree().create_timer(1.2).timeout
	await Dialogue.talk([
		["", "La serpiente se deshace. No en sangre: en papeles."],
		["", "Denuncias. La foto borrosa. La portada del periódico, con su cara en grande. Todo flotando en el río."],
		["", "Abajo de todo, chiquita, la página 14."],
		["LILATO", "—Yo solo quería que la niña fuera mía."],
		["YO", "—Nunca fue tuya. Ni mía. Es de ella."],
		["ÉL", "Tenía una frase mejor. La tenía guardada desde el día uno. No la necesito. Esa estuvo bien."],
		["", "Lilato se vuelve humo. El humo se lo lleva el río. Después, nada."],
		["", "Ya no va a volver a ningún sueño. Ni a ningún callejón. Ni a ningún domingo."],
	])
	# El gran sueño: del otro lado del río, alguien lo espera.
	mood.forced_distress = 0.0
	MusicDirector.force("night")
	await Dialogue.talk([
		["", "Deja de llover. El agua baja. Sale el sol, que en este sueño nunca había salido."],
		["", "Del otro lado del río, en la orilla, alguien lo espera moviendo la cola."],
		["", "Lukas. Gordito. Sin tos. Con las orejas al viento."],
		["", "Detrás de él, la Renegade. Negra mate, farola redonda, el tanque tibio. El rayón, justo donde estaba."],
		["", "Se sube. Lukas salta al tanque, adelante, como si siempre hubiera ido ahí."],
		["", "Arranca. La moto suena igual que el primer día."],
		["", "Esta vez no tiene que llegar a ninguna parte."],
	])
	_banner.text = "GAME CLEAR"
	_banner.visible = true
	await get_tree().create_timer(2.0).timeout
	GameState.flags["dream_won"] = true
	GameState.flags["dream_return"] = "final"
	GameState.flags["lilato_destruida"] = true
	FinalRush.finish()
	phase = Phase.DONE
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(NIGHT)


func debug_skip() -> void:
	_on_serpent_died()
