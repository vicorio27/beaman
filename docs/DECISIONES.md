# Decisiones técnicas — Nivel 01

Decisiones tomadas donde el spec no especifica (sección 42: "elegir la solución más simple y documentarla").

## Fase 1 — Base

- **Resolución:** viewport 320x180, ventana 1280x720, stretch `viewport` con escala entera. Filtro de texturas `nearest` y snap de transforms a píxel.
- **Input:** las acciones (`move_*`, `interact`, `cancel`) se registran por código en `autoload/Controls.gd`, con teclado + gamepad. Teclado: WASD/flechas, E/Espacio/Enter = interactuar, Q/Esc = cancelar. Gamepad: stick izquierdo/D-pad, A = interactuar, B = cancelar.
- **Ciudad (estilo EarthBound):** arte propio en `tools/art/draw_barrio.py` → `assets/barrio/` (paleta propia, no pasa por `apply_palette.py`): suelo en tiles de 16 px (pasto, pasto seco, tierra, asfalto roto, vereda, cordón, hormigón, agua, barro, puente, baldosas) y edificios/objetos como sprites en perspectiva oblicua con contorno oscuro. `tools/build_city.gd` arma `City.tscn`: capas Ground / Details / Shadows y un nodo `World` con Y-sort donde van edificios, objetos y el jugador (así pasa por delante y por detrás). Cada sprite tiene el origen al pie y su colisión en la base. Cables entre postes con `Line2D` combado, cuervos, perros y un farol que parpadea con `AnimatedSprite2D`. Regenerar pisa los cambios hechos a mano en City.tscn.
- **Protagonista de la ciudad:** `tools/art/draw_protagonist_topdown.py` recolorea el personaje de Kenney para que sea el mismo del sueño (pelo negro, camisa blanca gastada, jean). `CharacterFrames.protagonist()`.
- **Jugador:** `CharacterBody2D` en modo flotante (top-down). El origen está en los pies; la colisión es solo la base (10x6) para que pueda pasar "detrás" de cosas más adelante. Sprite animado de la hoja de Kenney (`CharacterFrames.gd`, reutilizable para NPCs; el costado se espeja para mirar a la derecha).
- **Lugares:** cada escena jugable (City, Bakery, Cafe) usa `scripts/world/Location.gd`, que ubica al jugador en el punto de entrada, limita la cámara (centrándola si el lugar es más chico que la pantalla) y pone paredes en el borde.
- **Puertas:** `scripts/world/Door.gd` (Area2D). Se atraviesan caminando hacia ellas o con interactuar. Sin escena destino son puertas cerradas que dicen una línea (una vez por acercamiento si se empuja; siempre si se aprieta interactuar). Solo se entra a los lugares con algo que contar (spec: no construir la ciudad completa).
- **Transiciones:** autoload `SceneRouter` (fundido a negro + punto de entrada por nombre de Marker2D, p. ej. `FromBakery`). El jugador no se mueve durante la transición.
- **Narrador:** autoload `Narrator.say(texto)` para líneas cortas que se desvanecen solas. Los diálogos con NPCs van aparte (Fase 2).
- **Interiores:** se generan con `tools/build_interiors.gd` con Kenney Roguelike Indoors (CC0) + tiles propios dibujados por `tools/art/draw_interior_tiles.py` (paredes, pisos, pan, pizarrón, cafetera, harina, cajas).
- **Filtro de ánimo:** `scenes/ui/MoodFilter.tscn` + `assets/shaders/mood.gdshader`. El hambre lleva la imagen de un registro cálido a uno frío tipo Signalis; modo memoria en sepia. Panel de prueba oculto: en debug, F3 lo muestra y ahí 1/2 cambian el hambre y 3 el modo memoria.
- **Paleta propia:** Resurrect 64 (Lospec) + 12 tonos urbanos propios (grises cálidos, tierras, verdes gastados). `tools/art/apply_palette.py` convierte las hojas originales de `assets/tilesets/source/` (Godot las ignora) a `assets/tilesets/`. Reglas: los verdes turquesa de Kenney se corren a verde pasto y se desaturan; celestes solo a azules; grises lavanda solo a grises cálidos; naranjas fuertes se quedan en naranjas. Si se agrega arte nuevo: ponerlo en `source/` y correr el script.
- **Sombras:** `scripts/world/ShadowLayer.gd`. Luz desde arriba a la izquierda. Los generadores registran una forma por edificio, árbol, farol, objeto y mueble; la capa las pinta juntas en una imagen al cargar (sin doble oscurecido donde se superponen). El protagonista tiene su propia sombra (Polygon2D).
- **Detalles:** `tools/art/draw_decals.py` dibuja 21 decals (grietas, aceite, hojas, papeles, colillas, chicles, yuyos, flores, alcantarillas, rejillas, grafitis, carteles, lata, harina, migas). Los generadores los salpican con una semilla fija (el mapa sale igual cada vez), con más densidad bajo el puente.
- **Cámara:** hija del jugador, con suavizado; los límites y las paredes invisibles del borde los fija `City.gd` según `world_size` (960x992).
- **Arte viejo:** el pack de beat 'em up quedó en `_old/` (con `.gdignore`, Godot no lo importa). Se conservaron la fuente PressStart2P y dos sonidos útiles (`click.wav`, `eat-food.wav`).

## Layout del mapa

```
 [edificios]   PARQUE    [edificios]
 ───────────── calle norte ─────────────
  BARRIO   │  edificios │ PANADERIA  CAFE
           │   centro   │ PLAZA (fuente)
 ───────── calle del río ───────────────
  bajo puente → PUENTE   (río)
          ZONA INDUSTRIAL (galpones)
```

El jugador empieza bajo el puente (tile 25,44), marcado con el nodo `Start`.

## Sueño 1 — Beat 'em up (vista de costado)

- **Flujo:** `scenes/prologue/Fight.tscn` (callejón + El Tuerto) → `Truck.tscn` (avenida + camión + motos) → `Lilato.tscn` (Lilato + serpiente) → `Continue.tscn` (CONTINUE? / GAME OVER) → `City.tscn` ("DÍA 1 — 06:17", línea "Otra vez ese sueño."). El juego arranca en `Fight.tscn` con "DÍA 0 — 23:40".
- **Arte:** personajes, jefe, capas de cuchillo, chispas y retratos del pack viejo de beat 'em up (`_old/`). Arte propio en `tools/art/draw_prologue.py`: callejón (1280 px), camión "Harinas El Sol", ciudad de noche, ramas, carteles, faroles, árboles, cartel bajo, puente final, armas en el piso y vidrios. Las capas de botella y caño se generan a partir de dónde está el cuchillo en cada cuadro. Todo pasa por `apply_palette.py`.
- **Luchadores:** `Brawler.gd` (base, sin física, golpes por distancia y profundidad, capa de arma sincronizada cuadro a cuadro) → `FightPlayer.gd` (combo, armas, agacharse si la escena lo permite) / `FightEnemy.gd` (IA, variante con cuchillo que lo suelta) → `FightBoss.gd` (aguante, guardia, embestida, barra propia).
- **Arena del callejón:** `FightArena.gd`. Oleadas en `WAVES` ("+knife" = matón armado), tipos en `TYPES`, armas iniciales en `ITEMS`. Máximo 2 matones pegando a la vez (el jefe siempre). Chispa + congelado breve en cada golpe. Puntaje en `Dream.score` (static, pasa entre escenas).
- **Camión:** `TruckRide.gd`. Fases: AVENIDA (correr y saltar al camión que arranca, matones a pie detrás) → COLGADO → FINAL. Sin obstáculos que peguen. Equilibrio: péndulo invertido (`INSTABILITY`, `DAMPING`, `CONTROL`; viento, curvas y baches como fuerzas); el cuerpo cuelga de un nodo en las manos con frames propios (`tools/art/draw_hanging.py`: colgado, piernas a cada lado, patada, una mano). Al pasar `SLIP_ANGLE` se suelta una mano (3 botones para volver; si no, pierde vida). Motos (`BIKERS`, de a 2): se ponen al lado, avisan en rojo y pegan; botón = patada hacia atrás (`KICK_RANGE`). Ganar: STAGE CLEAR → trepa al techo → puente bajo. Perder (vida 0): se cae. Ambos → CONTINUE. Medidor en el HUD (sin filtro). El narrador se muestra arriba (`Narrator.say(texto, true)`) para no tapar la acción.
- **Lilato (jefa final):** `scenes/prologue/Lilato.tscn` + `LilatoArena.gd` (arena de una pantalla bajo el puente). `FightLilato.gd` extiende `FightEnemy` (zarpazo, giro que pega a los dos lados, teletransporte detrás del jugador, líneas por umbral de vida). Al caer deja el súper cuchillo (`superknife` en `FightPlayer.WEAPONS`, no se gasta). `Serpent.gd`: cabeza + segmentos en cadena, estados slither / windup / lunge / stuck / spit / tail_windup / dead; solo `hit(true)` (súper cuchillo) le baja vida, y en `stuck` vale doble. Arte en `tools/art/draw_lilato.py`. El camión (ganando o cayéndose) lleva a esta escena.
- **HUD de arcade:** `ArcadeHud.gd`. Solo en sueños; en la vida real el HUD sigue siendo el mínimo del spec.
- **Filtro de ánimo:** `MoodFilter.forced_distress` en las escenas del sueño; sube con los golpes.
- **SceneRouter:** `go(escena, spawn, título, línea)`; `intro(título)` para la primera escena. En debug, **F2** saltea a la escena siguiente (`debug_skip()`).
- **Sueños futuros:** cada uno será una carpeta de escenas propia (carreras, sigilo...), que termina con un `SceneRouter.go` de vuelta a la realidad.

## Vida real: hambre, reloj y mochila

- **GameState** (autoload): plata, hambre (0-100), día, mochila de 8 casilleros (`{"id", "qty"}` o vacío), misión actual, marcas de historia (`flags`), y `ui_open` (hay una ventana abierta: el jugador no se mueve y el reloj se frena). `new_game()` arranca con la foto (no se puede tirar) y la camiseta. Lo llama la pantalla de CONTINUE antes de despertar.
- **TimeManager** (autoload): reloj del día; 1 segundo real = 1 minuto de juego (06:17 a 22:00 ≈ 16 minutos). Solo corre en lugares de la vida real (`Location` lo prende y lo apaga al salir). Cada minuto baja el hambre (`GameState.HUNGER_PER_HOUR` = 4). `skip(horas)` para desmayos y dormir.
- **Objetos:** `scripts/systems/Items.gd` (base de datos: nombre, descripción, tipo, pila, comida). Íconos en `assets/items/` (`tools/art/draw_items.py`).
- **HUD** (`scripts/ui/Hud.gd`): solo hambre (barra de 10, roja bajo 40), plata y hora. **Mochila** (`scripts/ui/InventoryUI.gd`): Tab / I / Y del joystick; E usa/come, X tira, Q cierra.
- **Survival** (`scripts/systems/Survival.gd`): bajo 60 comentarios; bajo 40 camina al 80% y la cámara se mece; bajo 20 al 65% y se mece más; en 0 se desmaya: 3 horas después despierta en el banco de la plaza (spawn `Desmayo`) con hambre 20 y le falta algo al azar de la mochila. El filtro de ánimo lee el hambre real.
- **Cosas para agarrar:** `scripts/world/Pickup.gd` (Area2D con ícono que brilla y el cartel "AGARRAR"). Las pone `build_city.gd` en `place_pickups()`.
- `Location` agrega HUD, mochila y Survival a cada lugar de la vida real. Los sueños no los tienen.
- **Reloj y luz:** `TimeManager.MINUTES_PER_SECOND` = 1,5. `scripts/systems/DayNight.gd` (solo en lugares con `Location.outdoor = true`; los interiores lo apagan): `CanvasModulate` con color por hora (puntos en `KEYS`) y `PointLight2D` en los faroles, la panadería y el café que se prenden de noche.
- **Lukas:** `scripts/world/Lukas.gd` (CharacterBody2D sin capa de colisión: el jugador lo atraviesa; choca con paredes). Lo agrega `Location` al lado del jugador. Sigue, se sienta, y con "olfatear" (F / RB) va hasta el `Pickup` más cercano (prefiere comida y escondidos), ladra y lo destapa. Arte en `tools/art/draw_lukas.py`. Los `Pickup` con `concealed = true` no se ven ni se agarran hasta que Lukas los encuentra.
- **Misiones:** definiciones en `scripts/systems/Quests.gd` (main / side / optional), estado en `GameState.quests`, reglas en el autoload `QuestDirector` (comer cumple "conseguir comida" y abre "al anochecer, volvé al puente"; juntar latas y cartones; Lukas olfatea). HUD: principal siempre visible + contador; aviso al empezar/cumplir. Tab: lista de misiones arriba de la mochila.
- **Fuente:** Press Start 2P no tiene mayúsculas con tilde: en textos en mayúscula se escribe sin tilde ("DIA", "MISION").
- **Lilato recurrente:** se asoma en el callejón después de la segunda oleada (`FightArena._lilato_cameo`). Pelea más larga: 180 de vida y etapa enojada a la mitad; serpiente con 20 de vida y etapa enojada.

## Día 1: gente, diálogos y la noche

- **Diálogos:** autoload `Dialogue` (`await Dialogue.talk([[nombre, texto], ...], opciones)` → índice elegido; cancelar = la última). Texto que se escribe solo, arriba/abajo para elegir. Las líneas sin nombre son del protagonista. Al cerrar, `GameState.block_input(0.2)` evita que el mismo botón abra una puerta o agarre algo (`GameState.input_blocked()` lo usan jugador, puertas, objetos y NPCs).
- **NPCs:** `scripts/npc/NPC.gd` (vista desde arriba, hoja de Kenney por fila; mira al jugador; cartel "HABLAR"; `talk_reach` grande para hablar por encima de un mostrador; ruta opcional ida y vuelta). Lo que dice cada uno: autoload `Conversations` (una función por `npc_id`). Los ubican los generadores con `add_npc()`: Don Germán (fila 6) en la panadería, Marta (fila 3) en el café, Wilson (fila 9) recorriendo el camino de tierra, Samuel (fila 12) junto al río.
- **Trabajo de Don Germán:** `scripts/world/CarryJob.gd`: 4 bultos de la pila (al lado de las cajas) al horno; cargando camina al 70% (`Player.carry_factor`). Paga $20.000 + un pan y pasa 1 hora.
- **Mandado de Marta:** objeto "pedido"; se entrega tocando la puerta `Puerta_house_c_40` (la de "—Andate"); Marta paga $8.000 al volver.
- **Wilson:** compra latas a $300 y botellas a $200.
- **Samuel:** la primera vez da el consejo del cambuche; después, "quedarme un rato" adelanta el reloj hasta las 18:00.
- **La noche del Día 1** (`QuestDirector`): a las 18:00 avisa que vuelva al puente; en la ciudad aparece el desconocido (NPC `stranger`) en el campamento; al acercarse dice "Yo llegué primero" y la misión pasa a "Encontrá dónde pasar la noche". Lugares para dormir: `scripts/world/SleepSpot.gd` (`banco`, `kiosco`, `rio`; el del río arma el cambuche con 3 cartones y marca `flags.cambuche`).
- **Escena de la noche:** `scenes/world/Night.tscn` + `NightSequence.gd`: acomodarse (con Lukas), la fotografía (frente y dorso con la frase escrita a mano; arte en `tools/art/draw_photo.py`), la memoria corta (pelota y "¡Vamos, campeón!"), resumen del día (`GameState.stats`: plata ganada, comidas) y FIN DEL CAPITULO 1. Vuelve al principio.

## La primera memoria, jugable

- `scenes/world/Memory1.tscn` + `scripts/world/Memory1.gd`: después de la foto, `NightSequence` pasa a la memoria. Patio en sepia (`MoodFilter.memory_on`), él de chico (el mismo Player al 80%), una pelota que se patea caminando contra ella o con E (siempre tiende a irse hacia la luz del fondo). Cuando la pelota pasa x 250, entra la sombra larga de un adulto (nunca se ve quién) y la voz "—¡Vamos, campeón!". Al llegar a la luz (y con la voz en pantalla al menos 2,5 s) se corta a blanco, marca `flags.memory_1_seen` y agrega "pelota" a `flags.memories`. Vuelve a `Night.tscn`, que sigue con "Cierra los ojos." y el resumen.
- **Bug corregido:** `PackedVector2Array([x, y, x, y...])` con números sueltos NO arma puntos (quedan todos en 0,0) y el polígono no se dibuja. Siempre usar `Vector2(x, y)`. Esto escondía las sombras en el piso de NPCs, Lukas, los luchadores del beat 'em up y el humo del camión; ya aparecen.

## Tono: humor negro

- Se reescribieron unos 45 textos (puertas, objetos, hambre, Lukas, la noche, diálogos y el sueño) con la guía "Tono del libreto" de `DISENO_CIUDAD_Y_SISTEMAS.md`. La foto, la memoria y Lilato quedan sin chiste a propósito. Los textos de puertas y objetos están en `build_city.gd`, así que hay que regenerar `City.tscn`.
- `Narrator`: el cuadro crece según el texto (medido con `get_multiline_string_size`) y, abajo, crece hacia arriba. El texto de la noche ahora tiene lugar para 4 líneas.
- **Ajuste de tono:** el usuario pidió humor negro tipo Deadpool, "alguien gracioso, no que dé lástima". Se reescribieron otra vez los textos: él habla en primera persona, rompe la cuarta pared y en la noche intenta zafar de la foto con un chiste y no le sale.

## Música, plata, cambuche y Lukas

- **Música:**
  - Autoload `MusicDirector`: tema por nombre de escena; en la ciudad, día o noche según la hora. `force()` cambia el tema mientras dure la escena (la serpiente); `cut()` corta en seco (la memoria).
  - Bus "Music" con LowPassFilter, más `pitch_scale` según el hambre.
  - Los WAV (22050 Hz, mono) los arma `tools/audio/compose.py` (numpy). Las colas de las notas vuelven al principio, así el loop no tiene corte.
- **GameState:**
  - `hygiene` (+ `is_dirty()`, `hygiene_changed`), `calm_until` (Lukas) y `cambuche` (dict: spot, mejoras, box, alcancia).
  - `craft()`; `build_cambuche` / `move_cambuche` / `box_add` / `box_take`.
  - `new_day(spot)`: hambre e higiene de la noche, lluvia, robos, saqueo de la caja, policía, Lukas sin comer, reinicio de lo diario. Devuelve las líneas de la mañana.
- `Items.RECIPES` y `Items.UPGRADES`; tipos nuevos: `ingrediente`, `lukas`, `juguete`. Arte en `tools/art/draw_economy.py`.
- **SleepSpot:**
  - Banco y kiosco son solo para dormir.
  - Río, callejón y parque llevan cambuche, con menú (caja, alcancía, mejoras, cocinar).
  - Cada lugar tiene un spawn `Wake_<id>` para despertar ahí.
- **ServiceSpot (baño y pensión):** lo que pasa vive en `Conversations` (`_bano`, `_pension`).
- `building(..., service)` pone un servicio en vez de puerta: la pensión es la casa gris en (300,380).
- **Tiendas:** `Conversations._shop(who, items)`, con listas SHOP_GERMAN / MARTA / ROSA / WILSON. Doña Rosa es un NPC de la fila 15 con su carrito en la plaza.
- **NightSequence:**
  - El Día 1 sigue igual y termina en "FIN DEL CAPITULO 1 / Pero la vida no tiene créditos".
  - Después viene la mañana (`new_day`) y la ciudad.
  - Del Día 2 en adelante, la noche es corta.
- **Controles:** C / LB = armar (en la mochila). F / RB = menú de Lukas (antes era olfatear directo).

## Día 2 tutorial y el recuerdo de la moto

- **Quests:**
  - `t_cambuche` → `t_lukas` → `t_bano` → `moto_cafe`, encadenadas en `QuestDirector._day2_tutorial()`.
  - El baño marca `flags.bathed = day`.
  - `GameState.main_quest()` da prioridad a `donde_dormir`.
  - `new_day()` cierra lo que haya quedado abierto del Día 1.
- **La moto del presente:**
  - Sprite `moto_parked` + ServiceSpot `moto_cafe`, en `QuestDirector.MOTO_POS`.
  - Se crea al entrar a la ciudad mientras `moto_cafe` está activa.
- **`scenes/world/FlashbackMoto.tscn`** (armada por código, como Memory1):
  - Tiles del barrio, `CanvasModulate` cálido, MoodFilter sin angustia.
  - El vendedor es un NPC `chaqueta` (fila 0, teñido) y la moto es un ServiceSpot `fb_moto`.
  - Lo que dicen está en `Conversations` (`_chaqueta`, `_fb_moto`, `_moto_cafe`).
- **`scenes/world/MotoRide.tscn`:** carretera pseudo-3D por segmentos (proyección por tramo, curva acumulada, lomas con easing).
  - Se dibuja con `_draw` y `draw_primitive`, que no triangula y no falla con tramos casi planos.
  - Sprites escalados y recortados por las lomas; niebla hacia el horizonte; cielo y cerros con paralaje.
  - Choques: autos, baches, conos, y árboles o postes fuera de la calle.
  - Al final: `assets/moto/llegada.png` + diálogo, y vuelve a la ciudad (`FromCafe`).
  - Tema `moto_ride` y ruido de motor `engine.wav` (el pitch sube con la velocidad).
- **Arte** en `tools/art/draw_moto.py`. **Música:** `flashback` (cumbia en mayor) y `moto_ride` en `compose.py`.
- **`MusicDirector`:** `force("")` deja la escena en silencio, y `cut()` ahora también la deja en silencio (antes la memoria volvía a sonar durante la fundida).
- **Pickups:** lo que se agarra no vuelve a aparecer hasta el día siguiente (`flags.taken[nombre] = día`). Antes reaparecía cada vez que se entraba a la ciudad.

## La cédula y el centro

- **`tools/build_centro.gd`** hereda de `build_city.gd` (mismo TileSet y helpers) y arma `Centro.tscn`:
  - Avenida con Registraduría, Foto Express y edificios.
  - Plazoleta con paradero (`bus_centro`).
  - Celador (NPC, fila 9).
  - Spawns `FromBus` y `FromRegistraduria`.
  - Arte en `tools/art/draw_centro.py`.
- **La ciudad** tiene un paradero `bus_barrio` y un spawn `FromBus`. Se usa en `Conversations._bus()`.
- **Quests:** `hablar_german` (Día 3) → `cedula` + `c_plata` / `c_foto` / `c_direccion` → `recoger_cedula`.
  - `QuestDirector._cedula()` marca y desmarca los requisitos según la mochila y la plata (`_toggle`).
  - También crea a Zaida en el centro (NPC fila 3 teñido de violeta) mientras falte la dirección.
- **`GameState.main_quest()`:** devuelve la principal activa más reciente (el paso actual de la historia). `donde_dormir` sigue teniendo prioridad. En el Día 3 se cierran las del tutorial que hayan quedado abiertas.
- **`scenes/world/Fila.tscn` + `Fila.gd`:**
  - Reloj propio (3 min de juego por segundo).
  - Gente adelante = f(hora de llegada).
  - Turnos cada 3 s y colados con ventana de reacción.
  - Ventanilla con chequeo de requisitos.
  - Al salir, `TimeManager.skip()` del tiempo de la fila. La música es la del vals de radio.
- **Objetos del trámite:** `foto_doc`, `carta_german`, `direccion_zaida`, `cedula`. Son "fixed": no se tiran ni se los roban.

## Ánimo, transeúntes, niveles del cambuche, fuente y pedir

- **GameState:**
  - `mood` + `change_mood()` + `mood_level()` (0 a 3) + `mood_changed`.
  - Ajustes de la mañana en `new_day()`: `SLEEP_MOOD`, `cambuche_mood()`, robos, lluvia.
  - `HOT_FOOD` sube el ánimo al comer.
  - Niveles del cambuche: `cambuche_level()`, que sale de las flags toldo + cobija, paredes y zinc. `BOX_CAPACITY`, `LEVEL_THEFT`, `LEVEL_MOOD`, `CAMBUCHE_NAMES`.
- **Ampliaciones** en `Items.EXPANSIONS` (lo que pide cada nivel y la frase). Se aplican desde "Mejorar" en el cambuche (`SleepSpot._upgrade`). La caja respeta la capacidad.
- **HUD:** la carita (`assets/ui/mood_*.png`, de `tools/art/draw_mood.py`) en el panel de arriba. **MoodFilter:** la angustia es el máximo entre la del hambre y la del ánimo.
- **Transeúntes:**
  - `scripts/npc/Passerby.gd`: camina un carril y reacciona una vez a menos de 28 px. Las contestaciones de él tienen un cooldown global (variables `static`).
  - `scripts/world/PasserbySpawner.gd`: la agrega `Location` en los lugares de afuera, con carriles por escena.
- **`Fuente.tscn` / `Fuente.gd`:** dibujado a mano (`_draw`). Las monedas tienen posición real y aparente (seno). El celador pasa por away → turning → looking. Semilla por día, para que las monedas sean las mismas ese día.
- **`Pedir.tscn` / `Pedir.gd`:** tabla `TYPES` (tipo → acción → chance, plata, líneas). Vuelve a la escena y al spawn guardados en `flags.pedir_return`. Rinde la mitad si se repite en el día (`flags.pedir_<escena>`).
- **Arte:** Rancho y Ranchito, estiba, clavos, zinc y radio en `draw_economy.py`; fuente con agua y vaso en `draw_centro.py`.

## SUEÑO 2: PLOMO (raycaster)

- **`scenes/dreams/Plomo.tscn` + `scripts/dreams/Plomo.gd`:** raycasting clásico en `_draw`.
  - Un rayo DDA por columna (320); el trozo de pared se dibuja con `draw_texture_rect_region`.
  - Sombra por distancia y por cara (x/y).
  - Las puertas suben (`doors` = apertura 0..1) y después la celda pasa a `"o"`.
  - Los sprites se proyectan con la matriz inversa de la cámara y se dibujan por corridas de columnas visibles (z-buffer), para no hacer una llamada por columna.
- **El mapa** se arma por código (32x24): letras por textura (`#` ladrillo, `C` grafiti, `Z` zinc, `W` madera, `G` oro, `D` puerta, `L` puerta con llave, `E` salida).
- **Enemigos:** tabla `KINDS`, máquina de estados idle/chase/attack/pain/flee/dead, visión con `los()`. Ataques: melee, hitscan, ráfaga, proyectil (pedido, cuchillos). El ruido de los disparos alerta a los que están cerca.
- **Disparo del jugador:** hitscan por perdigón (la escopeta tira 7). Le pega al enemigo más cercano dentro de un radio perpendicular al rayo y antes de la pared. Sin munición pasa a la pistola si hay balas; si no, al puño.
- **Música:** `plomo` y `plomo_boss` (metal chiptune en `compose.py`). El mouse queda capturado mientras se juega.
- **NightSequence:** en la noche del Día 3 (si no lo soñó) va a Plomo. Plomo marca `dream2_seen`, `dream2_won` y `dream_return`, y vuelve a Night, que sigue con el resumen y la mañana.
- **Arte:** `tools/art/draw_shooter.py` (texturas 32x32, figuras de frente 32x48 escaladas para los jefes, armas 80x56, caras 24x26).

## Habilidades y episodios de los sueños

- **`scripts/systems/Skills.gd`:** `DEFS` (nombre y descripción), `ORDER`, `DREAM_SKILL` (sueño → habilidad).
- **GameState:** `skills`, `has_skill()`, `learn()` (que deja `flags.skill_toast`) y la señal `skill_learned`.
- **Dónde se aplican los efectos:**
  - Aguante: Passerby, Pedir, FightArena (vida), Plomo (`_hit`).
  - Sangre fría: Fila (`REACT`), Fuente (aviso del celador), Plomo (dispersión y daño).
  - Labia: Pedir (chance), `Conversations._buy` (precio), Plomo (cooldown de los jefes).
  - Rebusque: Wilson (pago), Lukas (radio de olfato), Plomo (drops).
- **Dónde se ven:** el aviso en el HUD (`Hud._show_skill`), la lista en InventoryUI y el texto al despertar en NightSequence.
- **FightArena configurable:**
  - Variables `waves`, `types`, `items`, `lines`, `boss_name`, `next_scene`, `bg_path`, `intro_title`, `player_hp`, `lilato_cameo` y `rain`.
  - Ganchos `setup()`, `before_start()` y `_level_done()`.
  - El Episodio 1 sigue igual (los valores por defecto son las constantes de antes).
- **`scenes/dreams/Callejon2.tscn` + `Callejon2.gd`** heredan por ruta de FightArena. `FightCamila.gd` usa las animaciones de Lilato. Guillermo es un FightBoss con la hoja `guillermo.png`. Arte en `tools/art/draw_episode2.py` (recoloreos y el fondo `ep2_bg.png`).
- **NightSequence:** `DREAMS` (día → sueño) y `WAKE` (líneas al despertar). Los sueños vistos se guardan en `flags.dreams_seen`. Cada sueño vuelve con `flags.dream_return = <id>` y `flags.dream_won`.

## PLOMO por episodios

- **`Plomo.gd` es configurable:**
  - Variables `dream_id`, `title_text`, `subtitle`, `recap`, `wall_tex`, `kinds` (con `"sprite"` opcional), `pickup_tex`, `projectile_tex`, `checkpoints`, `mini_kind`, `boss_kind`, `summon_kind`, `summon_points`, `mini_zone`, `boss_zone`, `music`, `music_boss`, colores de cielo y piso, `drawn_sky`, `weapon_prefix`, `face_prefix`, `finish_note` y `lines`.
  - Ganchos `setup()`, `_build_map()`, `_place()`, `_special()`, `extra_sprites()`, `_on_exit()` y `_zone_of()`.
- **Ataques genéricos de los enemigos:** `"throw:<textura>"` (tira uno) y `"fan:<textura>"` (abanico de tres).
- **El episodio 1 es el de niño:** arte en `tools/art/draw_shooter_kid.py` (`wall_kid_*`, `kid_<enemigo>_*`, `kw_*`, `kidface_*`).
- **`PlomoEp2.gd` y `PlomoEp3.gd`** heredan por ruta: cambian las paredes del mismo plano, los enemigos y los jefes. Arte en `tools/art/draw_shooter2.py`. Ep3 tiene a Zaida como sprite extra que no pelea, con diálogo en `_special()` y la elección en `_on_exit()`.
- **Habilidades por sueño** (`Skills.DREAM_SKILL`): plomo2 → rebusque, plomo3 → lazo_lukas (provisorio).
- **Prueba:** `test_plomo_ep.gd` (con la variable de entorno `PLOMO_SCENE`); los tres episodios se terminan con el bot.

## Vínculos, favores y sueños por hechos

- **GameState:** `bonds` (npc → 0..3), `bond()`, `raise_bond()`, la señal `bond_changed` y `BOND_NAMES`. Los robos bajan con el vínculo de Samuel y con Lazo con Lukas.
- **HUD:** `_show_bond` ("LAZO MÁS FUERTE / DON GERMÁN 1/3"). En el Tab, las habilidades y los lazos van en dos líneas cortas.
- **Conversations:** `_german_favor`, `_marta_favor`, `_samuel_favor` (arma la carta con tres elecciones, guardadas en `flags.carta_texto`) y `_rosa_favor` (va a `Puesto.tscn`). Las opciones `[LABIA]` van en Marta, la pensión y el celador. `door_hook()` reemplaza el chequeo del mandado en `Door.gd`; la carta se entrega en `LETTER_DOOR` (`Puerta_house_e_936`).
- **QuestDirector `_favors()`:** esconde el anillo (`ANILLO_POS`) y el collar (`COLLAR_POS`, frente a la casa de tejas) como Pickups ocultos que solo encuentra Lukas, y dispara la escena de la casa (`_cat_scene`). Lukas prioriza los objetos especiales al olfatear.
- **`scenes/world/Puesto.tscn` + `Puesto.gd`:** el minijuego del puesto, con el señor de negro a la mitad.
- **NightSequence:** `DREAMS` es una lista en orden; `_dream_tonight()` respeta `DREAM_GAP` y `flags.last_dream_day`, y `_dream_when()` tiene las condiciones de cada sueño.

## Dificultad y guardado

- **`GameState.difficulty()` / `diff(área)`** con `SKILL_DOMAINS`.
- **Dónde se aplica:** Pickup (no aparecer o esconderse, con una semilla por nombre y día), Lukas (radio y espera), `pass_time` (hambre y suciedad), `new_day` (robos y hambre de la noche), `Conversations._price()` (precios en la lista y al comprar), el pago de Wilson, Passerby, Fila, Fuente, Pedir, Puesto y `Plomo.dream_hard`.
- **Guardar:** `GameState.save_game(escena, spawn)` / `load_game()` en `user://partida.save` (`store_var`). Se guarda el estado completo más el reloj, la escena y el spawn.
- **Cuencos:** ServiceSpot `cuenco_N` (los maneja `Conversations._cuenco`), con un spawn `Spawn_cuenco_N` en `build_city` y `build_centro`, y el arte `assets/barrio/cuenco.png`.
- **`scenes/ui/Title.tscn`** es la escena inicial (`run/main_scene`).
- **Sed de Lukas:** `Lukas.thirsty()`, el aviso en `QuestDirector._daily()` y la misión diaria `lukas_agua`.

## Sueños 6 y 7

- **`Callejon3.gd` + `FightBrenda.gd`:** Brenda huye (`FLEE_DISTANCE`) y tira maletas con `arena.enemy_throw()`. `walk_bounds` la deja dentro de la pantalla. Al caer se sienta y no desaparece. Arte en `tools/art/draw_episode3.py` (`brenda.png`, `item_maleta.png`, `ep3_bg.png`).
- **`Boxeo.gd`:** todo dibujado con `_draw`.
  - Estados de Mauricio: idle, wind, recover, taunt, guard, hurt, dizzy. Estados del chico: idle, dodge_l, dodge_r, block, punch, hook, hurt, tired.
  - Corazones; cuenta de caídas (Mauricio se levanta en 4, 6 y 8 con el 70%, 50% y 30% de vida); levantarse apretando E.
  - Tres rounds y la decisión de los jueces.
  - `M_HP` = 150: un bot perfecto llega al segundo round.
  - Música `boxeo` (`compose.py`).
- **NightSequence:** se agregan `callejon3` y `mauricio1` a `DREAMS` y `WAKE` (por ahora se disparan en cadena). `Skills.DREAM_SKILL` ya los tenía.

## La familia (los disparadores de los sueños 6 y 7)

- **Teléfono:** `telefono.png` + ServiceSpot `telefono` en `build_city` (462,400). Lo maneja `Conversations._telefono`. La misión `llamar_mama` la arranca `QuestDirector._family()`, después de `f_carta_volver` o desde el Día 8.
- **Mauricio:** NPC `mauricio` (fila 6, teñido) y `MotoPapa` en `PAPA_POS`. Aparecen en la ciudad después del sueño 6 (al día siguiente, de 9 a 17). Lo maneja `Conversations._mauricio_plaza`, que se los lleva en la moto.
- **NightSequence:** `callejon3` se dispara con `flags.llamo_mama` y `mauricio1` con `flags.papa_encuentro`. Se guarda `flags.dream_day_<id>`.
- **`Narrator.hide_now()`** se llama al empezar `Dialogue.talk`.

## Serie CARRERAS

- `scripts/dreams/Carrera.gd` extiende `MotoRide.gd`, que ahora es configurable (colores, frases y meta en `setup()`). Las escenas son `Carrera1..4.tscn` (`episode` 1-4). El arte está en `tools/art/draw_carreras.py`.
- Rivales en `RIVALS` (pace, throw, monster). Los objetos tirados son obstáculos con kind zapato/bolso/cadena y tienen sus propias frases en `MotoRide._ride`.
- `PeleaGuillermo.gd/.tscn` extiende `FightArena`: un solo jefe (`guillermo.png`) y vuelve con `dream_return = carrera3`.
- `Narrator.top_y`: las carreras lo ponen en 26 y lo devuelven a 40 en `_exit_tree`.
- `NightSequence`:
  - `_dream_tonight` elige el primer sueño no visto cuyo hecho ya pasó (antes, el orden de la lista bloqueaba).
  - El título "SUEÑO N" se calcula.
  - `callejon2` sale de la lista (el archivo queda) y `carrera1` hereda su disparador (la cédula) y su habilidad (Labia).

## PLOMO: EL DEALER

- `PlomoDealer.gd/.tscn` extiende `Plomo.gd`. El arte está en `tools/art/draw_shooter_dealer.py`:
  - Paredes: `wall_dl_*`.
  - Sprites: `dl_*`.
  - Recogibles: `d_*`.
  - Kits de armas y cara: Lisandro `dw_`/`dface_`, él con armadura `sw_`/`sface_`.
- `Plomo.gd` ganó `max_hp`, `move_mult`, `dmg_mult` y `wall_tint`; la cara del HUD se calcula con `hp/max_hp`.
- El giro está en `PlomoDealer._damage`: el slayer no baja del 25% y llama a `_role_swap`, que:
  - intercambia las posiciones;
  - cambia `boss_kind` a `"lisandro"`;
  - recarga el kit con `_load_kit`;
  - mueve el checkpoint 3 adonde quedó.
- Las llamadas a Camila, Guillermo y Lilato son a 0.66 y 0.33 de la vida de Lisandro.
- `NightSequence`: `plomo_dealer` se dispara dos días después de `carrera3`.


## Parque, menú SUEÑOS, locura

- **Parque:**
  - El mapa es `tools/build_parque.gd` (extiende `build_city.gd`) y genera `scenes/world/Parque.tscn`. El arte está en `tools/art/draw_parque.py` (iglesia, tienda, glorieta, árboles verdes, bancas, flores, cachivaches, ajedrez, estatua, palomas y los íconos de las rarezas).
  - Los NPC salen de la hoja de Kenney, teñidos con `_tint()`.
  - Las conversaciones están al final de `Conversations.gd`: `_iglesia`, `_padre`, `_fabiola`, `_aurelio`, `_leonor`, `_efrain`, `_mono`, `_viejos`, `_banca`, `_palomas`.
  - `_bus_from(here)` reemplaza a `_bus` en los tres paraderos.
- **Pedir** elige el fondo según el lugar: el Parque usa la iglesia.
- **PasserbySpawner:** se agregaron los carriles del Parque.
- **MusicDirector:** el Parque usa el día/noche de afuera y cuenta como escena con hambre.
- **Items:** nuevo tipo `"rareza"`, con `"use"` (tres líneas según la locura). `GameState.add_locura` y `locura_level` (los umbrales son 5 y 12).
- **Narrator:** los mensajes de arriba son una franja fina y semitransparente, con contorno. `Plomo.gd` pone `top_y = 2` y las carreras 26; el valor por defecto es 40.
- **Title:** opción SUEÑOS con la lista `DREAMS`. `SceneRouter.go` redirige al título cuando hay `flags.arcade` y el destino es Night o City.
