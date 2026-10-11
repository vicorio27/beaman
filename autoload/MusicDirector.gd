extends Node
## La música: elige el tema según la escena (y la hora, en la ciudad), con fundido cruzado.
## Los temas los genera tools/audio/compose.py en assets/music/.
## Con hambre la música se apaga (filtro) y se desafina un poco, como el filtro de imagen.
##   MusicDirector.force("lilato_serpent")  cambia el tema mientras dure la escena actual.
##   MusicDirector.cut()                    corta en seco (la memoria).

const TRACKS := {
	"Fight": "dream_fight",
	"Truck": "truck",
	"Lilato": "lilato",
	"Continue": "",
	"Bakery": "bakery",
	"Cafe": "cafe",
	"Night": "night",
	"Memory1": "memory",
	"FlashbackMoto": "flashback",
	"MotoRide": "moto_ride",
	"MotoLorena": "moto_ride",
	"Fila": "cafe",
	"Fuente": "flashback",
	"Pedir": "city_day",
	"Puesto": "city_day",
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
	"Obra": "city_day",
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
## Escenas donde el hambre afecta la música.
const HUNGRY_SCENES := ["City", "Bakery", "Cafe", "Centro", "Fila", "Fuente", "Pedir", "Parque"]

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _current := "-"
var _forced := ""
var _forced_scene: Node
var _check := 0.0
var _lowpass: AudioEffectLowPassFilter


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, BUS)
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(idx, _lowpass)
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = BUS
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)


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
	if scene.name in ["City", "Centro", "Parque"]:
		var h := TimeManager.hour()
		return "city_day" if h >= 6 and h < 18 else "city_night"
	return TRACKS.get(scene.name, _current)


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
	_current = track
	var old := _players[_active]
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
	new.play()
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
