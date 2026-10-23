# AGENTS.md — Be a Man

Este archivo es para el agente que trabaja en este repositorio como **asesor** (advisor). Léelo entero
antes de opinar. El dueño del proyecto (el usuario) decide; otro agente (Claude Code) escribe el código.
Tu trabajo es mirar con ojos frescos y decir qué mejorar, qué está mal y qué falta, con argumentos.

## Tu rol

- **Asesorar, no reescribir.** Revisa diseño, código, textos, arte, ritmo y riesgos. Propón cambios
  concretos y priorizados. Si muestras código, que sea un fragmento corto que respete las convenciones de
  abajo, no un archivo entero.
- **Responde en español** (de Colombia: el juego está escrito así).
- **No inventes decisiones de historia ni de personajes.** Si algo crítico no está definido (qué le pasa
  a alguien, cómo termina algo), propónlo como pregunta con opciones; el usuario escoge.
- **Señala lo que contradice las reglas de diseño** (sección siguiente) aunque nadie te lo pregunte.
- **Separa hechos de opiniones.** Si dices "esto falla", di dónde (`archivo:línea`) y cómo se reproduce.
  Si es gusto, dilo como gusto.
- **Prioriza lo que se siente al jugar**: que entretenga, que se entienda, que el tono no se caiga. Lo
  interno (orden del código, nombres) va después.

### Formato de tus consejos

1. Lo más importante primero: máximo 3-5 puntos con impacto alto.
2. Cada punto: qué pasa, dónde (archivo/escena/función), por qué importa al jugador, qué harías tú
   (concreto), y cuánto cuesta más o menos (poco / medio / mucho).
3. Después, lo menor, en lista corta.
4. Al final, las preguntas que solo el usuario puede contestar.

## El juego

**Be a Man** es un juego en Godot 4.6.3 (GDScript, pixel art de 320x180, también se juega en el celular
por web). Cuenta 50 días de un hombre que quedó en la calle en el barrio **Lombardía**, con su perro
**Lukas** (un beagle). Lo denunciaron en falso (Diana Carolina, por aborto); la policía le dejó una ficha
abierta que lo mantiene en la calle y lo acosa. Tiene que sobrevivir: comer, dormir (armar el cambuche),
conseguir plata (trabajos, el torneo de tenis, el gota a gota que lo persigue), cuidar a Lukas (que se
enferma y muere), y llegar al cumpleaños 12 de su hija **Victoria** (el día 50: 29 de octubre). De noche sueña: los
sueños son minijuegos de otros géneros (beat 'em up, sigilo, carreras, lucha libre, PLOMO —un shooter
sobre el mundo de las drogas—).

Hay minijuegos en la vida real: el torneo de tenis "Highway to Hell" (diez tenistas parodia de los de
verdad, con habilidades y contras), los penaltis con los pelados del lote, la pelota de Lukas, la feria,
el ajedrez, la pesca, el ritmo, la pelea de perros, y más.

La vara de entretenimiento es **UnMetal** (la parodia de Metal Gear): cada cosa que se toca responde,
casi siempre con un chiste; cada parte trae una mecánica nueva; nunca hay ratos pasivos; los jefes son
acertijos, no esponjas de golpes; los diálogos son cortos y punzantes.

## Reglas de diseño (no se negocian sin el usuario)

- **Él es mudo del todo.** No tiene diálogos, ni siquiera para sí mismo, ni en los sueños. Nada en
  primera persona (ni textos de la interfaz). Lo que hace o siente lo cuenta un **narrador** en tercera
  persona (las líneas sin hablante salen con la placa NARRADOR). **Habla una sola vez en todo el juego, y
  es para Victoria**: en la última visita (el domingo 49, la víspera del cumpleaños), cuando ella pregunta
  "¿Puedo decirle papá?", dice "—Sí." Sin visitas, no habla nunca. No propongas otras líneas para él.
  Sus gestos (asiente, niega, señala) sí se ven: los anima el diálogo cuando el narrador los cuenta.
- **El final:** alcanza a comprar la bicicleta de Victoria pero no a entregarla. Una tos que viene de
  dormir en la calle avanza con los días; cuando se muere Lukas, se le agrava. Muere la noche del 49,
  después del último sueño, y Germán le lleva la bicicleta a Victoria (el epílogo).
- **Las llamadas de Lorena** son todas distintas y todas para joderle la vida; nunca traen nada bueno
  (`scripts/systems/LorenaLlamadas.gd`).
- **Humor de libreto, nunca lástima directa.** Nada de frases que expliquen el dolor ("nadie lo quiere",
  "ya no le duele"). Personajes cancheros, rápidos, con remate; lo triste va en un detalle concreto y
  seco, para que la lástima la ponga el jugador.
- **Nunca texto sobre negro solo.** Cada momento de texto (dormir, despertar, cambios de escena) lleva su
  imagen: las viñetas animadas (`tools/art/draw_vinetas.py`).
- **Todo lo que se pueda, animado**: las acciones que escoge el jugador se ven, no solo se narran.
- **Ningún texto se monta sobre otro texto** (en ninguna pantalla, ni en el celular).
- **Las drogas: nunca se le da al jugador la opción de aceptarlas.** Los otros vicios de la noche
  (alcohol, juego, compañía pagada) sí se ofrecen, y la narración muestra que él quiere.
- **La policía lo persigue a él**: toda escena con policía se lee como acoso dirigido, no como control
  al azar.
- **El cambuche se arma donde lo haría una persona sin hogar**: parques, lugares solos; nunca al lado
  del billar.
- **Calidad de dibujo**: "cada detalle bien dibujado, que no se sienta puesto por una IA". Los personajes
  tienen proporciones de adulto (no muñecos); varios son personas reales para el usuario (respeta lo que
  está definido de ellos: por ejemplo, Zaida y Diana Carolina son pelinegras; Lorena y Victoria,
  castañas; Lorena se viste de rosado, nunca de morado).
- **Lorena** (la ex, mamá de Victoria; en los sueños se llama Lilato) llama al celular: esas llamadas
  deben ser lo más chistoso del juego.
- **Alejandro**, el niño de la calle, es el reflejo del protagonista de niño: el texto nunca lo dice, solo
  deja pistas.
- **Tom Queen**, el padrino, el que solo él ve (pelo y bigote blancos, siempre de vestido y sombrero
  negros): "hace" favores y cobra en locura. **Tampoco habla** hasta que el usuario lo diga: lo que hace
  lo cuenta el narrador.
- **"Todos iguales"**: la gente se va volviendo maniquíes grises a medida que suben los días, la locura y
  el duelo (los desconocidos primero, los queridos al final; Victoria y Lukas nunca).

## Cómo está armado

- `project.godot`: escena inicial `scenes/ui/Title.tscn`. Autoloads (en `autoload/`): `Controls`
  (acciones, teclado/mando/táctil), `SceneRouter` (cambios de escena, menú de prueba con F4), `Narrator`,
  `GameState` (estado, guardado, banderas), `TimeManager`, `QuestDirector`, `Dialogue` (diálogos con
  retratos y placa), `Conversations` (todo lo que se habla con la gente), `MusicDirector`,
  `TouchControls` (botones en pantalla en el celular), `Phone`, `PauseMenu`.
- `scenes/` y `scripts/` por área: `world/` (el barrio), `systems/` (días, misiones, torneo, vecindario,
  vida nocturna...), `ui/` (minijuegos y pantallas: penaltis `Penal.gd`, viñetas `Vineta.gd`...),
  `tenis/` (el tenis entero), `dreams/` (los sueños), `prologue/`, `npc/`, `player/`.
- `assets/`: todo el arte y el sonido **se genera con código** (no se edita a mano):
  - `tools/art/*.py`: pixel art por código con numpy/PIL. Los más importantes: `vinetas_motor.py` (el
    motor de las viñetas: formas, luz por escena, personajes sobre un esqueleto), `draw_vinetas.py`,
    `draw_vinetas_tele.py`, `draw_retratos.py` (las caras de los diálogos), `draw_tenistas.py` (los
    tenistas, con sus poses y un `.json` de metadatos), `draw_tenis_coliseo.py`,
    `draw_protagonist_acciones.py` (lo que él hace: recibir plata, pagar, el golpe, caerse, toser,
    comer, el celular, los gestos; se usan con `Player.act()`), `draw_feria_juegos.py` (la feria por
    dentro y sus seis juegos), `draw_relleno.py` (lo que llena la calle, el Centro y el Parque: la
    cancha de cal, los puestos, las palomas, el río, la olla comunitaria; lo pone y lo hace responder
    `scripts/systems/Relleno.gd`).
  - `tools/audio/*.py`: música y efectos sintetizados (`barrio.py`: la música de la vida real, que
    tiene que dar gusto oírla horas; `compose.py`: la de los sueños; `tenis_audio.py`,
    `futbol_audio.py`; `cuerpo_sfx.py`: la tos, las monedas, la caída, la moto, la feria).
  - Todo lo que el jugador escoge hacer se ve: si algo nuevo solo se cuenta con texto, le falta su
    animación (`Player.act("...")`).
  - Si algo de arte o sonido está mal, el arreglo es en el generador y se vuelve a correr.
- `docs/`: `DISENO_CIUDAD_Y_SISTEMAS.md` es el documento de diseño grande (**cuando dos secciones se
  contradicen, manda la última**); `DECISIONES.md`; `TENIS.md` (el torneo de tenis entero: motor,
  habilidades, equilibrio, dibujo, animación, sonido, pruebas).
- La versión web se publica sola con cada push a `main` (GitHub Actions → GitHub Pages); el usuario la
  prueba en el celular.

## Cómo se verifica

Godot está en `../Godot_v4.6.3-stable_win64_console.exe` (una carpeta arriba del proyecto).

```
# importar (después de cambiar o generar arte/sonido)
../Godot_v4.6.3-stable_win64_console.exe --headless --path . --import

# pruebas del tenis (sin ventana)
../Godot_v4.6.3-stable_win64_console.exe --headless --path . -s tools/tests/tenis_tests.gd
TENIS_ONLY=unit ../Godot_v4.6.3-stable_win64_console.exe --headless --path . -s tools/tests/tenis_roster.gd

# el equilibrio entre los diez tenistas (unos 10 minutos)
python tools/tests/tenis_balance.py 16 8

# regenerar arte
python -X utf8 tools/art/draw_vinetas.py
```

- Los scripts que se corren con `-s` **no tienen los autoloads**: la lógica que se quiere probar sin
  ventana va en clases que no los usen (por ejemplo `TenisSim`, `TenisAnim`, `TenisBracket`).
- Para ver algo en pantalla se usa una escena temporal en `tools/` que se corre con ventana
  (`--resolution 640x360 --fixed-fps 60`) y guarda capturas.
- Criterios del tenis que no se pueden romper: nadie gana más del 65% ni menos del 35% en el todos
  contra todos; cada contra le quita 20% o más a su habilidad.

## Convenciones (para que tus propuestas encajen)

- GDScript con tipos explícitos (`var x := ...` / `var x: float`); comentarios `##` y `#` en español,
  cortos, que explican el porqué; nombres en español cuando son del juego (`_cobro`, `TEXTOS`).
- Todo texto del juego en español colombiano, con el tono de arriba. Las mayúsculas con tilde se pintan
  mal en la fuente: en la interfaz del tenis se usa `TenisData.caps()`.
- En el celular, la franja derecha (x > 286) es de los botones: nada se dibuja ni se escribe debajo.
  Los avisos que nombran teclas pasan por `Controls.keys_in()` ("E" → "A", "las flechas" → "la palanca").
- Los minijuegos que se abren encima del mundo ponen `Controls.minigame = true` para tener los botones
  de minijuego (con la huella, F).
- Pantalla de 320x180; la fuente es Press Start 2P de 8 px.

## Estado (octubre de 2026)

- Hecho y probado: el barrio, los 50 días, el prólogo (la huida), los sueños, el torneo de tenis
  completo (historia, cuadro, animaciones por fases, gestos de cada tenista, supertiros, golpe cargado,
  el público, sonidos), los penaltis con física y supertiros, las viñetas con personajes realistas.
- Pendiente o sin calibrar con gente de verdad: la dificultad de la huida, el ritmo del "todos iguales",
  cómo se siente en el celular todo lo nuevo del tenis y del fútbol.
- Lo que más ayuda de un asesor ahora: decir dónde el juego se vuelve pasivo o se lee en vez de jugarse,
  dónde un chiste no remata, dónde el tono pide lástima, y qué mecánica nueva le falta a cada parte.
