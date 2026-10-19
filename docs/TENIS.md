# El torneo de tenis (Highway to Hell)

Tenis arcade con tenistas caricaturizados. Esta es la referencia del motor, de los tenistas y de cómo se prueba. La parte narrativa todavía no está; ver "Lo que falta".

## Cómo está armado

Todo está en `scripts/tenis/`. La simulación no sabe nada de pantallas.

| Archivo | Qué hace |
|---|---|
| `TenisScore.gd` | El conteo: puntos, deuce o punto de oro, juegos, desempate, sets y quién saca. |
| `TenisData.gd` | Los datos: formatos, física, golpes, tenistas (`PLAYERS`), quiénes juegan (`ROSTER`) y la dificultad. |
| `TenisSim.gd` | El partido en pasos fijos de 1/60 s: la pelota (altura, efecto, bote, curva), los golpes, el error, los puntos y el ánimo. La misma semilla da el mismo partido. |
| `TenisAbilities.gd` | Un solo marco para todas las habilidades (`DEFS`) y las reglas de sus contras. |
| `TenisAI.gd` | La máquina. Ve lo mismo que un jugador y usa el mismo error. No lee lo que aprieta el humano. |
| `TenisMatch.gd` | La cancha que se dibuja y se juega (`scenes/tenis/TenisMatch.tscn`). Si se abre sin `setup` (F6), primero se escogen el tenista y el rival. |

**Controles:**
- Flechas: moverse y apuntar.
- E: golpe plano.
- Q: cortado. Q con arriba: dejada. En el saque, Q es el saque por abajo.
- X: globo.
- F: la habilidad.

**Formato arcade:** un set a 4 juegos, con desempate en 3-3 a 7 puntos.

## El error de un golpe

σ (en metros) = e0 · (1 + manos · dificultad) · potencia · ánimo · caos · ejecución · habilidad · rasgos

| Término | Cómo se calcula |
|---|---|
| e0 | 0.23 + 0.035 · (10 − destreza). La destreza es la precisión, o el toque en el cortado, el globo y la dejada. |
| manos | 1.3 − 0.04 · toque: cuánto le pesa la pelota difícil. |
| dificultad | La velocidad de la que viene, lo estirado que está, la altura, si va corriendo, el cansancio, el efecto, el ritmo, la pelota pesada y el caos del que pegó. |
| potencia | Pegarle más duro que su pegada natural cuesta mucho; la pegada natural (el atributo) cuesta poco. |

El error es gaussiano y se corta a 2.5σ, así que el azar no da vuelta una ventaja clara.

La máquina estima su riesgo con la misma física y el mismo σ, sobre 16 muestras fijas que no tocan el azar del partido. Escoge el golpe con una elección suave entre los que valen parecido, más su estilo.

La dificultad de la máquina cambia la reacción, el ruido al decidir, la limpieza al ejecutar y qué tan seguido le juega la contra al otro. Nunca le cambia los atributos.

## Los tenistas

Los atributos van de 1 a 10 y pueden llevar cuartos (5.75): un punto entero de precisión mueve demasiado el equilibrio.

| Tenista | Apodo | Pot | Prec | Def | Toq | Comp | Caos | Rasgos y manera de jugar |
|---|---|---|---|---|---|---|---|---|
| Alexander Bublikov | El agente del caos | 9 | 6.75 | 7 | 9 | 6 | 8 | Dejadas y cortados. Lo raro repetido le sube el error; en peloteos largos se aburre; saca por abajo al que resta lejos. |
| Aryna Sabalenkova | La artillería | 10 | 5.75 | 5 | 3 | 5 | 3 | Plano, duro y parada adentro. Corriendo de lado falla más. |
| Gaël Monfiz | El acróbata | 6 | 4.75 | 9 | 6 | 6 | 6 | Globos y cortados desde la tribuna. Se cansa 30% más. |
| Novak Yokovich | El devorador de esperanzas | 3 | 5 | 6 | 3 | 7 | 3 | Cortado y paciencia; resta mejor (7% menos error). |
| Corentin Moutette | El provocador (zurdo) | 5 | 7 | 6 | 9 | 5 | 8 | Dejadas, cortados y cambios de ritmo. Si no manda, se pierde. |
| Frances Tiafuego | El showman | 5 | 4.5 | 4 | 6 | 4 | 5 | Ataque y ángulos; vive del público. |
| Ben Sheltron | El lanzacohetes (zurdo) | 10 | 5.75 | 5 | 4 | 5 | 4 | El saque más rápido y los ángulos abiertos. Segundo saque y defensa, flojos. |
| Nick Kyrgistán | El volátil | 8 | 4 | 5 | 6 | 2 | 7 | Talento y dejadas, cero paciencia. |
| Jannik Pecador | El compilador | 6 | 6.75 | 6 | 4 | 8 | 1 | Todo al fondo y limpio (95% de sus golpes van al fondo). |
| Roger Fedorer | El artista | 6 | 4.5 | 6 | 10 | 6 | 4 | Cortado, toque, subida. Apurado y por el revés, sufre (45% más error). |

Lo que los distingue en la cancha (del todos contra todos): el tipo de golpe, y qué parte va al fondo, dura (21 m/s o más) o abierta. Por ejemplo, Sabalenkova y Sheltron pegan igual de duro, pero Sheltron abre la cancha el 40% de las veces y ella el 5%.

La potencia se ve en la velocidad: el que pega más duro le mete más liftado (si no, la pelota no le bajaría y el cálculo del golpe la frenaría para que entre).

### Las habilidades

| Habilidad | De | Cuesta | Qué hace | La contra | Contrarrestada |
|---|---|---|---|---|---|
| ¿Por qué no? | Bublikov | 45 | El amague: sale para un lado y se tuerce al otro, a contrapié. | Quieto y al centro cuando él le pega. | Casi sin curva y 30% más error. |
| Demolición controlada | Sabalenkova | 55 | 3 golpes: 30% menos error, 12% más potencia, pelotas altas que pesan. | Cortadas, globos, dejadas, o hacerla correr. | Sin empuje y 60% más error. |
| La gravedad es opcional | Monfiz | 35 | Se tira (0.45 s): alcance ×1.9, devuelve a contrapié; queda en el piso. | Moverlo de lado a lado, bien abierto. | Sin ventaja, 50% más error, más rato en el piso. |
| Todavía no | Yokovich | 50 | Devuelve la difícil (22% menos error) y los dos siguientes salen mejor. | Variar: dos golpes distintos y los dos lados. | Sin nada y 45% más error. |
| Queja formal | Moutette | 45 | Se queja de todo: mientras dura (3 golpes suyos), el otro erra 45% más. | Quedarse atrás y tranquilo. | No le llega al otro, y el que falla más (30%) es él. |
| ¡Vamos! | Tiafuego | 50 | 2 golpes con el público: 35% menos error, 15% más potencia. Se carga con ganadores. | Devolverle profundo: no hay pelota para lucirse. | 80% más error. |
| Llamada de larga distancia | Sheltron | 60 | En el primer saque: 25% más potencia y la pelota pesa. | Restar bien atrás. | Sin potencia extra, 80% más error, y la devolución le queda fácil al otro. |
| Modo Kyrgios | Kyrgistán | 45 | 3 golpes: 40% menos error. Si pierde ese punto, se calienta dos puntos. | Nada de regalos: profunda y al centro. | 50% más error. |
| Ejecución perfecta | Pecador | 45 | 4 golpes: 35% menos error. Se carga pegando limpio. | Romperle la secuencia: cortadas, globos, cambios de lado. Se juzga golpe a golpe. | 50% más error en ese golpe. |
| Punto de firma | Fedorer | 50 | Dos golpes: un cambio de ritmo lento con curva, y el remate a contrapié. | Apurarlo y no darle una cómoda (al fondo). | 40% más error. |

**Reglas comunes:**
- El medidor se carga golpeando, con ganadores y con lo de cada uno: la defensa difícil, pegarle corriendo, lo raro, cambiar de golpe, pegar limpio.
- No se carga mientras la habilidad está prendida.
- Todas se acaban al terminar el punto. Si no se alcanzó a usar, se pierde lo gastado.
- La barra naranja titila cuando la habilidad está lista, y la rayita marca cuánto cuesta.
- La máquina sabe cuál es su contra: si se la están jugando, se guarda la habilidad. La máquina rival se la juega con la probabilidad de su dificultad (fácil nunca, normal la mitad de los puntos, difícil casi siempre).

### Agregar un tenista

1. Una entrada en `TenisData.PLAYERS` con `attr`, `traits`, `ai` (pesos de golpes, `style`, `risk`, `home_depth`, `return_depth`) y `ability`.
2. Si trae habilidad nueva, una entrada en `TenisAbilities.DEFS`. Se arma con los campos que ya existen: `mods`, `first`, `each`, `counter`, `ai`, `window`.
3. Ponerlo en `ROSTER` y correr las pruebas.

El motor no se toca, salvo que la habilidad necesite un tipo de contra nuevo. En ese caso se agrega en `counter_rule()`.

## El torneo y el cuadro

`TenisBracket.gd` es el cuadro, sin dibujo: siembra, previa, avance, eliminación, quién llegó hasta dónde, simular un partido entre máquinas, y guardar y cargar (`to_dict` / `from_dict`).

Con cualquier número de inscritos, el cuadro es la potencia de 2 más grande que cabe, y los que sobran juegan una previa entre los peores sembrados. Con los 10:

| Ronda | Quiénes |
|---|---|
| Previa (día 1) | 7 contra 10 y 8 contra 9 |
| Cuartos (día 2) | El 1 contra el ganador de 8-9, el 4 contra el 5, el 3 contra el 6, y el 2 contra el ganador de 7-10 |
| Semifinal (día 3) y final (día 4) | El 1 y el 2 solo se pueden cruzar en la final |

`TenisData.TOURNAMENT` lleva:
- Los inscritos en orden de siembra (el ranking de la parodia): Yokovich, Pecador, Sabalenkova, Fedorer, Sheltron, Tiafuego, Monfiz, Kyrgistán, Bublikov y Moutette.
- El formato de cada ronda: la previa y los cuartos en formato corto (a 2 juegos, con punto de oro: unos 2 minutos entre máquinas) y la semifinal y la final en arcade (unos 5 minutos).
- Las rondas por día.
- La bolsa de los profesionales: de $2.000.000 por llegar a la previa a $50.000.000 el campeón. Es plata de ellos, no del protagonista; lo de él se define con la historia.

`scenes/tenis/TenisTorneo.tscn` (F6 en el editor) es el torneo de principio a fin:
1. Se escoge con quién jugar (`TenisPicker`, el mismo selector del partido suelto).
2. Sale el cuadro. El tuyo va en dorado, el que perdió queda apagado y el próximo partido titila.
3. Si el próximo partido es el tuyo, se juega (E). Si no, se ve entre máquinas (E) o se simula al instante (X). La X simula todo lo de los demás hasta tu próximo partido, o hasta el final si ya te sacaron (`simulate_until`).
4. Al final de cada partido sale el resumen (ganadores, aces, errores, dobles faltas, habilidad, puntos, el peloteo más largo) y se vuelve al cuadro con el resultado anotado.
5. Al final, el campeón, su bolsa y hasta dónde llegaste tú.

Se guarda en `TenisTorneo.saved` mientras el juego está abierto. Guardarlo en la partida (GameState) va con la historia.

Las mayúsculas en pantalla pasan por `TenisData.caps()`, que quita las tildes de las vocales: la fuente dibuja la mayúscula con tilde como si fuera minúscula ("DíA").

## El dibujo

**Los tenistas** salen de `tools/art/draw_tenistas.py` y quedan en `assets/tenis/<id>.png`.
- Celdas de 32x42 con los pies en (16, 40). La fila 0 es de espaldas (el de abajo) y la fila 1 de frente (el de arriba).
- Hay 20 poses: listo (2), correr (4), drive (preparar, pegar, terminar), revés (lo mismo), saque (lanzar, pegar, terminar), tirada, en el piso, celebra, lamentarse y dejada.
- Cada pose es un esqueleto que se pinta con piezas de 2 px. Después va el contorno del juego y encima, a mano, lo de cada uno:
  - Bublikov: altísimo, despeinado, raya negra.
  - Sabalenkova: cola mona, falda y el tigre en el antebrazo.
  - Monfiz: piel oscura, balaca, camiseta amarilla con el costado negro.
  - Yokovich: cuello blanco y franja azul.
  - Moutette: bajito, crespo, celeste. Sheltron: alto, rapado, naranja. Los dos zurdos (la hoja se voltea).
  - Tiafuego: trencitas, verde limón y morado. Kyrgistán: gorra roja al revés, de negro, tatuajes.
  - Pecador: pelo zanahoria crespo, menta. Fedorer: todo de blanco, balaca blanca, raqueta roja.

`TenisMatch._pose()` escoge la pose según la cancha:
- Un golpe reciente: drive o revés según el lado de la pelota.
- La pelota que llega: prepara.
- El saque, la estirada, el piso.
- Correr o estar listo.
- Después del punto: celebrar (ganador o ace) o lamentarse (error no forzado).

**El coliseo** sale de `tools/art/draw_tenis_coliseo.py` y queda en `assets/tenis/coliseo.png`, más `coliseo_grita.png` con el público de pie.
- La cancha va en perspectiva: de 6.6 px por metro en el fondo a 8.6 en el frente, y 4.6 a lo largo. Es la misma cuenta de `TenisMatch.w2s`; si se cambia en un lado, se cambia en el otro.
- Tiene tribunas con gradas, pasillos y puestos vacíos, la tribuna del fondo, las vallas con los patrocinadores del barrio (la Caverna del Gamer, la panadería de Don Germán), los reflectores y la silla del juez.
- La gente se para después de un ganador, de un peloteo largo o cuando se cierra un juego.

**El tablero**, arriba a la izquierda, muestra por jugador el nombre, los juegos y los puntos (0, 15, 30, 40, AD), el cansancio y el medidor de la habilidad. Una pelotica marca quién saca.

## Las pruebas

Todas corren sin ventana:

```
../Godot_v4.6.3-stable_win64_console.exe --headless --path . -s tools/tests/tenis_tests.gd
../Godot_v4.6.3-stable_win64_console.exe --headless --path . -s tools/tests/tenis_roster.gd
```

`TENIS_ONLY=unit|sim|counter` corre solo una parte y `TENIS_N` pone los partidos por cruce.

**`tenis_tests.gd`** (45 pruebas): el conteo; que el error baje con la precisión y quede acotado; la misma semilla da el mismo partido; cómo se reparten los puntos; y el cuadro (la siembra, la previa, avanzar, no anotar dos veces, guardar y cargar, el torneo entero con un solo campeón, la bolsa, cuadros de 4 y de 5, simular hasta tu partido y que cada ronda tenga un formato que exista).

**`tenis_roster.gd`, la parte `unit`** (44 pruebas):
- Activar, gastar, no activar dos veces, acabarse a los golpes y al final del punto, y la espera.
- La estirada: cuándo sale, que cansa, y el piso si falla. El amague se tuerce.
- Lo nuevo de los seis: la queja sobre el otro, el cañonazo en el saque, los dos golpes de la firma, el bajón de Kyrgistán, la racha que se corta a la mitad.
- Cada contra se prende con lo que pasa en la cancha.

**`tools/tests/tenis_balance.py`**: el todos contra todos y las contras, repartidos en 8 procesos de Godot y juntados al final (unos 10 minutos). Con `rate`, una medición rápida de cada uno contra el parejo (un minuto), para ajustar.

```
python tools/tests/tenis_balance.py 16 8      # 16 partidos por cruce, 8 procesos
python tools/tests/tenis_balance.py rate 32   # cada uno contra "base"
```

Resultado del 2026-10-18 (45 cruces, 16 partidos cada uno; las contras con 48 partidos por caso):

| Criterio | Resultado |
|---|---|
| Nadie gana más del 65% ni menos del 35% | De 40.3% (Sheltron) a 56.2% (Bublikov) |
| Cada uno juega distinto: golpe, fondo, dureza o apertura (0.15 o más) | El par más parecido (Monfiz y Tiafuego) difiere en 0.20 |
| Cada contra le quita 20% o más a su habilidad | De −22% a −54% |
| La máquina que sabe la contra la logra más seguido | Las diez: por ejemplo 31→67% contra Fedorer, 0→56% contra Moutette |

Hay piedra, papel o tijera a propósito: los de toque (cortados, dejadas) les ganan más a los que pegan plano, porque eso es justo la contra de sus habilidades.

**Reparto de los puntos** (20 partidos entre dos tenistas parejos):
- Peloteo promedio de 8.9 golpes.
- 40% ganadores y aces, 27% errores no forzados y el resto forzados.

## Lo que falta

- **El dibujo que falta:** los recogebolas (él), las caras de cerca para los diálogos y un público que se mueva más.
- **La música:** rock original.
- **Los diálogos:** en una tabla de datos.
- **La historia:** el gota a gota y la llegada del torneo al barrio; él de recogebolas; los tenistas que abandonan y él que termina el partido con la raqueta de ellos; el premio.
