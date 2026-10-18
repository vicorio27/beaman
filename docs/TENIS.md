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

## Los tenistas de la tajada vertical

Los atributos van de 1 a 10.

| | Bublikov | Sabalenkova | Monfiz | Yokovich |
|---|---|---|---|---|
| Apodo | El agente del caos | La artillería | El acróbata | El devorador de esperanzas |
| Potencia | 9 | 10 | 6 | 3 |
| Precisión | 7 | 6 | 5 | 4 |
| Defensa | 7 | 5 | 9 | 6 |
| Toque | 9 | 3 | 6 | 3 |
| Compostura | 6 | 5 | 5 | 7 |
| Caos | 7 | 3 | 6 | 3 |
| Rasgos | Cada dejada o saque por abajo seguido le sube el error; en peloteos largos se aburre; saca por abajo al que resta lejos. | Pegarle corriendo de lado le sube el error. | Se cansa 30% más corriendo y resta desde la tribuna. | Resta mejor: 7% menos error devolviendo el saque. |
| Estilo | Dejadas y cortados | Plano y parada adentro | Globos y cortados desde atrás | Cortado y paciencia |

### Las habilidades

**¿Por qué no?** (Bublikov)
- Cuesta 45 y se arma para el golpe siguiente.
- Efecto: el amague. La pelota sale hacia un lado y se tuerce en el aire al otro, a contrapié del rival.
- La contra: estar quieto y al centro cuando él le pega.
- Contrarrestada: la curva queda casi en nada y erra un 30% más.

**Demolición controlada** (Sabalenkova)
- Cuesta 55 y dura 3 golpes.
- Efecto: 30% menos error y 12% más potencia. Cada pelota pica alta y le pesa al otro (+0.45 de dificultad).
- La contra: mandarle cortadas, globos o dejadas, o hacerla correr de lado.
- Contrarrestada: no empuja y erra un 60% más.

**La gravedad es opcional** (Monfiz)
- Cuesta 35. Se usa cuando la pelota se le va y le da 0.45 s de estirada.
- Efecto: alcance ×1.9 y velocidad ×1.5. Devuelve a contrapié y con más potencia.
- Costo: gasta 14 de energía y queda en el piso: 0.7 s si le pegó, 1.3 s si no.
- La contra: hacerlo correr de lado a lado, con las dos últimas pelotas abiertas y cada una a un lado.
- Contrarrestada: devuelve sin ventaja, erra un 50% más y se demora 0.7 s más en pararse.

**Todavía no** (Yokovich)
- Cuesta 50 y dura 3 golpes.
- Efecto: devuelve la difícil con 22% menos error y después pega con 10% menos error y 8% más potencia. Queda confiado.
- La contra: variar, con dos golpes distintos y los dos lados en las últimas tres.
- Contrarrestada: no hay bonificación y erra un 45% más.

**Reglas comunes:**
- El medidor se carga golpeando, con ganadores y con lo de cada uno: la defensa difícil, pegarle corriendo, lo raro.
- No se carga mientras la habilidad está prendida.
- Todas se acaban al terminar el punto. Si no se alcanzó a usar, se pierde lo gastado.
- La barra naranja titila cuando la habilidad está lista, y la rayita marca cuánto cuesta.
- La máquina sabe cuál es su contra: si se la están jugando, se guarda la habilidad.

### Agregar un tenista

1. Una entrada en `TenisData.PLAYERS` con `attr`, `traits`, `ai` (pesos de golpes, `style`, `risk`, `home_depth`, `return_depth`) y `ability`.
2. Si trae habilidad nueva, una entrada en `TenisAbilities.DEFS`. Se arma con los campos que ya existen: `mods`, `first`, `each`, `counter`, `ai`, `window`.
3. Ponerlo en `ROSTER` y correr las pruebas.

El motor no se toca, salvo que la habilidad necesite un tipo de contra nuevo. En ese caso se agrega en `counter_rule()`.

## El dibujo

**Los tenistas** salen de `tools/art/draw_tenistas.py` y quedan en `assets/tenis/<id>.png`.
- Celdas de 32x42 con los pies en (16, 40). La fila 0 es de espaldas (el de abajo) y la fila 1 de frente (el de arriba).
- Hay 20 poses: listo (2), correr (4), drive (preparar, pegar, terminar), revés (lo mismo), saque (lanzar, pegar, terminar), tirada, en el piso, celebra, lamentarse y dejada.
- Cada pose es un esqueleto que se pinta con piezas de 2 px. Después va el contorno del juego y encima, a mano, lo de cada uno:
  - Bublikov: altísimo, despeinado, raya negra.
  - Sabalenkova: cola mona, falda y el tigre en el antebrazo.
  - Monfiz: piel oscura, balaca, camiseta amarilla con el costado negro.
  - Yokovich: cuello blanco y franja azul.

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

**`tenis_tests.gd`** (27 pruebas): el conteo; que el error baje con la precisión y quede acotado; la misma semilla da el mismo partido; y cómo se reparten los puntos.

**`tenis_roster.gd`, la parte `unit`** (29 pruebas):
- Activar, gastar, no activar dos veces, acabarse a los golpes y al final del punto, y la espera.
- La estirada: cuándo sale, que cansa, y el piso si falla.
- El amague se tuerce, y cada contra se prende con lo que pasa en la cancha.

**`tenis_roster.gd`, las simulaciones** (resultado del 2026-10-18):

| Criterio | Resultado |
|---|---|
| Nadie gana más del 65% ni menos del 35% en el todos contra todos (32 partidos por cruce) | Bublikov 46%, Sabalenkova 42%, Monfiz 51%, Yokovich 61% |
| Cada uno juega distinto: la mezcla de golpes difiere en 0.15 o más entre cualquier par | El par más parecido (Monfiz y Yokovich) difiere en 0.27 |
| La contra le quita 20% o más a cada habilidad (puntos ganados cuando la usa, contra forzada sí o no) | −33%, −40%, −27% y −31% |
| La contra se puede jugar: la máquina que la sabe la logra más seguido | 46→98%, 33→71%, 0→59% y 31→87% |

**Reparto de los puntos** (20 partidos entre dos tenistas parejos):
- Peloteo promedio de 8.9 golpes.
- 40% ganadores y aces, 27% errores no forzados y el resto forzados.

## Lo que falta

- **El dibujo que falta:** los recogebolas (él), las caras de cerca para los diálogos y un público que se mueva más.
- **La música:** rock original.
- **Los otros seis:** Moutet, Tiafoe, Shelton, Kyrgios, Sinner y Federer.
- **El cuadro del torneo.**
- **Los diálogos:** en una tabla de datos.
- **La historia:** el gota a gota y la llegada del torneo al barrio; él de recogebolas; los tenistas que abandonan y él que termina el partido con la raqueta de ellos; el premio.
