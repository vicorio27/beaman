extends Node
## La música: elige el tema según la escena (y la hora, en el barrio), con fundido cruzado.
## Los temas los generan tools/audio/barrio.py (la vida real) y tools/audio/compose.py (los sueños)
## en assets/music/. Los del barrio y las radios siguen donde iban: entrar a la panadería y salir no
## los vuelve a empezar.
## Con hambre la música se apaga (filtro) y se desafina un poco, como el filtro de imagen.
##   MusicDirector.force("lilato_serpent")  cambia el tema mientras dure la escena actual.
##   MusicDirector.cut()                    corta en seco (la memoria).
##   MusicDirector.set_enabled(false)       apaga la música (no los sonidos). Se elige en el título o en
##                                          la pausa y se guarda en user://ajustes.cfg.
##   MusicDirector.duck(0.8)                aparta el tema (cerca del coliseo manda el partido); vuelve
##                                          solo al cambiar de escena.

const TRACKS := {
	"Huida": "",  # (la pone Huida.gd: "panico" mientras cuenta, "huida" al correr)
	"Fight": "dream_fight",
	"Truck": "truck",
	"Lilato": "lilato",
	"Continue": "",
	"Bakery": "bakery",
	"Cafe": "cafe",
	"Feria": "feria",
	"TenisMatch": "tenis_partido",
	"TenisTorneo": "tenis_cuadro",
	"TenisJornada": "tenis_cuadro",
	"Billar": "bakery",
	"Night": "night",
	"Memory1": "memory",
	"FlashbackMoto": "flashback",
	"MotoRide": "moto_ride",
	"MotoLorena": "moto_ride",
	"Fila": "cafe",
	"Fuente": "flashback",
	"Pedir": "barrio",
	"Puesto": "barrio",
	"Title": "night",
	"Callejon3": "dream_fight",
	"Carrera1": "",
	"Carrera2": "",
	"Carrera3": "",
	"Carrera4": "",
	"Plomo": "",
	"Callejon2": "dream_fight",
	"PeleaGuillermo": "dream_fight",
	"PlomoEp2": "",
	"PlomoEp3": "",
	"PlomoDealer": "",
	"PlomoDealer1": "",
	"PlomoDealer2": "",
	"PlomoDealer3": "",
	"Lucha1": "",
	"Epilogo": "night",
	"FinalOperativo": "",
	"FinalCallejon": "dream_fight",
	"FinalSerpiente": "",
	"Obra": "barrio",
	"Reparto": "",
	"Sigilo1": "",
	"Sigilo2": "",
	"Sigilo3": "",
	"Sigilo4": "",
	"Lucha2": "",
	"Lucha3": "",
	"Lucha4": "",
}
const VOLUME_DB := -7.0
const FADE := 1.5
const BUS := "Music"
## Los temas van por su propio bus (que sale al de música): así se pueden apartar sin tocar lo demás
## que suena por el de música (el partido desde la calle).
const THEME_BUS := "Tema"
## Los que retoman donde iban (los demás arrancan del principio).
const RESUME := ["barrio_manana", "barrio_dia", "barrio_tarde", "barrio_noche", "bakery", "cafe"]
## Escenas donde el hambre afecta la música.
const HUNGRY_SCENES := ["City", "Bakery", "Cafe", "Centro", "Fila", "Fuente", "Pedir", "Parque"]

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _current := "-"
var _forced := ""
var _forced_scene: Node
var _check := 0.0
var _lowpass: AudioEffectLowPassFilter
var _pos := {}
var _duck := 0.0
var _duck_scene: Node
var enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Los buses se crean subiendo bus_count, no con add_bus(): en la web (Godot 4.6) add_bus() los
	# deja en otro orden por dentro, y lo que se le hace a uno le cae a otro (el send del tema le
	# llegaba al Master y la web quedaba muda; apagar la música apagaba también los sonidos).
	var idx := AudioServer.bus_count
	var theme := idx + 1
	AudioServer.bus_count = idx + 2
	AudioServer.set_bus_name(idx, BUS)
	AudioServer.set_bus_send(idx, "Master")
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(idx, _lowpass)
	AudioServer.set_bus_name(theme, THEME_BUS)
	AudioServer.set_bus_send(theme, BUS)
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = THEME_BUS
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	var cfg := ConfigFile.new()
	if cfg.load(Controls.SETTINGS) == OK:
		enabled = cfg.get_value("sonido", "musica", true)
	AudioServer.set_bus_mute(idx, not enabled)


## Aparta el tema (0 = normal, 1 = casi no se oye) mientras dure la escena.
func duck(amount: float) -> void:
	_duck = clampf(amount, 0.0, 1.0)
	_duck_scene = get_tree().current_scene


## Prende o apaga la música: calla el bus (los temas siguen corriendo por debajo, así al prenderla
## suena el que toca). Los sonidos van por otro bus y no cambian.
func set_enabled(on: bool) -> void:
	enabled = on
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS), not on)
	var cfg := ConfigFile.new()
	cfg.load(Controls.SETTINGS)
	cfg.set_value("sonido", "musica", on)
	cfg.save(Controls.SETTINGS)


func _process(delta: float) -> void:
	_check -= delta
	if _check <= 0.0:
		_check = 0.25
		var want := _wanted()
		if want != _current:
			_play(want)
	_adapt(delta)


func _wanted() -> String:
	var scene := get_tree().current_scene
	if scene == null:
		return _current
	if _forced_scene != null and is_instance_valid(_forced_scene) and scene == _forced_scene:
		return _forced
	_forced_scene = null
	var track: String = TRACKS.get(scene.name, _current)
	if scene.name in ["City", "Centro", "Parque"] or track == "barrio":
		return barrio()
	return track


## El barrio tiene un tema para cada parte del día (así no suena siempre lo mismo).
func barrio() -> String:
	var h := TimeManager.hour()
	if h >= 6 and h < 10:
		return "barrio_manana"
	if h >= 10 and h < 14:
		return "barrio_dia"
	if h >= 14 and h < 18:
		return "barrio_tarde"
	return "barrio_noche"


## Cambia el tema mientras dure la escena actual ("" = silencio).
func force(track: String) -> void:
	_forced = track
	_forced_scene = get_tree().current_scene
	_play(track)


## Vuelve a la música normal del lugar (deja de forzar).
func release() -> void:
	_forced_scene = null


## Corta en seco, sin fundido.
func cut() -> void:
	for p in _players:
		p.stop()
		p.volume_db = -80.0
	_current = ""
	_forced = ""  # y queda en silencio mientras dure esta escena
	_forced_scene = get_tree().current_scene


func _play(track: String) -> void:
	var old := _players[_active]
	if old.playing and _current in RESUME:
		_pos[_current] = old.get_playback_position()
	_current = track
	_active = 1 - _active
	var new := _players[_active]
	if old.playing:
		var t := create_tween()
		t.tween_property(old, "volume_db", -80.0, FADE)
		t.tween_callback(old.stop)
	if track == "":
		return
	var stream: AudioStreamWAV = load("res://assets/music/%s.wav" % track)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	new.stream = stream
	new.volume_db = -40.0
	new.play(_pos.get(track, 0.0))
	create_tween().tween_property(new, "volume_db", VOLUME_DB, FADE)


## Hambre: menos agudos y un poco más grave, a medida que baja de 40.
func _adapt(delta: float) -> void:
	var k := 0.0
	var scene := get_tree().current_scene
	if scene and scene.name in HUNGRY_SCENES:
		k = clampf((40.0 - GameState.hunger) / 40.0, 0.0, 1.0)
	var cutoff := lerpf(20000.0, 700.0, pow(k, 0.6))
	_lowpass.cutoff_hz = lerpf(_lowpass.cutoff_hz, cutoff, minf(1.0, delta * 2.0))
	var pitch := 1.0 - 0.06 * k
	for p in _players:
		p.pitch_scale = lerpf(p.pitch_scale, pitch, minf(1.0, delta * 2.0))
	if _duck_scene != scene:
		_duck = 0.0
	var bus := AudioServer.get_bus_index(THEME_BUS)
	var want := linear_to_db(1.0 - 0.88 * _duck)
	AudioServer.set_bus_volume_db(bus, move_toward(AudioServer.get_bus_volume_db(bus), want, delta * 24.0))
