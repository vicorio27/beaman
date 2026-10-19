# El torneo de tenis (Highway to Hell)

Tenis arcade con tenistas caricaturizados. Esta es la referencia del motor, de los tenistas, de cómo entra en la historia y de cómo se prueba.

## Cómo está armado

Todo está en `scripts/tenis/`. La simulación no sabe nada de pantallas.

| Archivo | Qué hace |
|---|---|
| `TenisScore.gd` | El conteo: puntos, deuce o punto de oro, juegos, desempate, sets y quién saca. |
| `TenisData.gd` | Los datos: formatos, física, golpes, tenistas (`PLAYERS`), quiénes juegan (`ROSTER`) y la dificultad. |
| `TenisSim.gd` | El partido en pasos fijos de 1/60 s: la pelota (altura, efecto, bote, curva), los golpes, el error, los puntos y el ánimo. La misma semilla da el mismo partido. |
| `TenisAbilities.gd` | Un solo marco para todas las habilidades (`DEFS`) y las reglas de sus contras. |
| `TenisAI.gd` | La máquina. Ve lo mismo que un jugador y usa el mismo error. No lee lo que aprieta el humano. |
| `TenisPublico.gd` | El fondo del coliseo y la gente de las tribunas, cada uno por su lado: se para, aplaude, se agarra la cabeza y hace la ola. |
| `TenisAnim.gd` | Qué cuadro del dibujo le toca a cada jugador en cada momento (correr, prepararse, pegar, sacar), sin pantallas. También aguanta el golpe del saque hasta que la raqueta llega a la pelota. |
| `TenisMatch.gd` | La cancha que se dibuja y se juega (`scenes/tenis/TenisMatch.tscn`). Si se abre sin `setup` (F6), primero se escogen el tenista y el rival. Con `ballboy`, él es el recogebolas; con `abandon_games`, el de abajo abandona y él termina el partido. |
| `TenisCuadro.gd` | El dibujo del cuadro (lo usan el torneo suelto y la jornada). |
| `TenisHistoria.gd` | La historia, sin pantallas: la deuda, las fechas, la paga, cómo abandona cada uno y quién abandona cada día. Y todo lo que se dice en el torneo, en tablas: `ABANDONOS` (por tenista), `ORGANIZADOR_PRIMERA` / `ORGANIZADOR_DIA` y `TEXTOS` (las mañanas, el cobro, la puerta y la jornada). |
| `TenisJornada.gd` | El día de trabajo en el coliseo (`scenes/tenis/TenisJornada.tscn`). |
| `scripts/systems/Torneo.gd` | Lo que toca el juego: la deuda, las mañanas, el cobro y la entrada del coliseo. |

**Controles:**
- Flechas: moverse y apuntar.
- E: golpe plano.
- Q: cortado. Q con arriba: dejada. En el saque, Q es el saque por abajo.
- X: globo.
- F: la habilidad.

**En el celular** (los controles en pantalla, `TouchControls`, en su modo de minijuego): la palanca aparece donde se ponga el dedo en la mitad izquierda, y a la derecha A (plano), B (cortado; con la palanca arriba, dejada), X (globo) y la huellita (la habilidad). Los avisos del tenis nombran esos botones (`Controls.keys_in`: "A: SEGUIR", y en todo el juego "las flechas" pasa a ser "la palanca"); los "NOMBRE VS NOMBRE" que no caben quedan con los apellidos (`TenisData.versus`), y nada se dibuja debajo de la franja de los botones (x > 286): el resumen del partido se corre a la izquierda y esconde el tablero, la copa del cuadro va encima del puesto del campeón y el tenista del selector se corre.

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

**La cinta** (`TenisSim.NETCORD`): la pelota que pasa rozando la red (menos de 3,5 cm por encima) salta y cae donde quiera: casi siempre del otro lado, cortica, y a veces de vuelta (y es error del que pegó). Sale una cada ~120 golpes; suena la red, el público hace "uuuy" y sale "¡LA CINTA!".

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

## La historia

**La deuda (día 31).** El encargo de Marta: el cobrador del gota a gota en el café. Se meta como se meta, le pasa la deuda: "el que se mete, responde". Si le paga el abono ($10.000), el cobrador tacha a Marta y lo anota a él. Si lo espanta mirándolo sin parpadear, el cobrador se va y vuelve a asomarse para decírselo. Debe $80.000 en cuatro días, o se lleva la mochila.

**El coliseo (días 32 a 35).** En la mañana del 32 amanece un coliseo en el potrero de arriba, entre La Caverna del Gamer y el billar. Por fuera se ven:
- La tribuna de andamio, el pasacalle, los afiches de los tenistas y la reja con los patrocinadores del barrio.
- La última fila del público, que se para cada tanto, los banderines y los reflectores de noche.

El torneo se juega igual vaya él o no: un día por ronda.

**La jornada.** De 8 a 6, una por día, en la entrada del coliseo. La primera vez, el organizador lo contrata porque no habla.
1. El cuadro del día, con su partido titilando.
2. Es el recogebolas, agachado al lado de la red. Mientras juegan, quieto (si se mueve le gritan, y esa pelota no tiene propina). Cuando se acaba el punto, corre por la pelota con las flechas (corre como los tenistas: de perfil de lado, de espaldas o de frente) y la trae: el saque que sigue lo espera. Traerla en menos de 4 segundos da $300; después de 8, le gritan.
3. A la mitad (después del primer juego en el formato corto, del segundo en el arcade), el de abajo abandona a su manera: Kyrgistán rompe raquetas, Monfiz se acalambra, Moutette se hace descalificar, Bublikov se aburre, Sabalenkova revienta las cuerdas, Tiafuego se va con la tribuna, Sheltron contesta una llamada de la mamá, Pecador se cuelga, Yokovich pide el fisio y Fedorer se queda doblado de la espalda. El organizador lo manda a él a terminar el partido con la raqueta del que se fue: juega como ese tenista (sus números y su habilidad), con su dibujo (la corbata, el jean y un zapato de cada color).
   - Antes se ve cómo se va cada uno (`TenisMatch.exit_pro`, `ABANDONOS[id]["salida"]`): Kyrgistán deja dos raquetas rotas en el piso y se va rápido; a Monfiz se lo llevan dos camilleros en camilla, y a Pecador tieso, como una tabla; Bublikov se va a parar al pie de la silla del juez y Yokovich se acuesta en una toalla al lado de la cancha (los dos se quedan mirando el resto del partido); Tiafuego se mete en la tribuna, lo levantan y se pierde entre la gente, y la raqueta baja después, por el aire; Sheltron se va hablando por celular, Fedorer doblado, a pasitos, y Moutette y Sabalenkova caminando. La raqueta queda en el piso.
   - Después de la línea del organizador, él camina hasta la raqueta, se agacha, la coge y juega desde ahí (`walk_in`).
4. La paga: $12.000 de sueldo, las propinas de las pelotas y lo del profesional: si le ganó el partido, de $10.000 (previa) a $40.000 (final); si lo perdió, $3.000 "por la molestia". Cuatro horas de reloj.

Cada día abandona uno distinto, si se puede (`TenisHistoria.quien_abandona`). Si él ganó, ese tenista vuelve al día siguiente con su línea.

**El final (mañana del día 36).**
- El campeón y el coliseo que se va.
- La raqueta del último que le dejó terminar un partido (no se pierde).
- El cobrador: con los $80.000 se acaba (y Marta lo quiere más). Sin ellos, se lleva la plata que tenga y todo lo de la mochila que no sea fijo.

Ganando las cuatro jornadas se juntan unos $147.000; trabajando las cuatro y perdiendo todo, $60.000. Con lo que ya tenga en el bolsillo, alcanza si trabaja y gana alguna.

**Para probar:** en el menú de prueba (F4), "Torneo: la deuda y a dormir (día 32)".

## El dibujo

**Los tenistas** salen de `tools/art/draw_tenistas.py` y quedan en `assets/tenis/<id>.png`.
- Celdas de 50x48 con los pies en (25, 46): cabe el saque estirado y la raqueta con el brazo afuera sin cortarse. La fila 0 es de espaldas (el de abajo) y la fila 1 de frente (el de arriba).
- `assets/tenis/tenistas.json` trae el orden de las columnas y, por pose, dónde queda la cabeza de la raqueta (y la mano de la pelota en el saque). Con eso, al pegarle, la pelota sale de la raqueta y la del saque va en la mano.
- Hay 124 poses:
  - **Correr de perfil** (8 cuadros, para cada lado): un ciclo de carrera de verdad. Las piernas van con ángulos y largos fijos (el pie no se estira ni se encoge), la cadera baja en el apoyo y sube en el vuelo, los brazos van al revés de las piernas. El brazo y la pierna de allá van detrás y más oscuros. La cabeza de lado tiene ojo, nariz, oreja y el pelo de cada uno (la cola de Sabalenkova, la visera de Kyrgistán para atrás, las trencitas...). A él la corbata le vuela por encima del hombro.
  - **Correr de espaldas y de frente** (8 cuadros): un pie en el piso y el otro con el talón arriba, el cuerpo que sube y baja, los brazos alternados. El brazo que va adelante se tapa con el cuerpo.
  - **Pasitos de lado** (4 cuadros, para cada lado, sin dar la espalda a la red), **frenar** (para cada lado) y **el saltito** (2).
  - **El drive y el revés** (8 cada uno): se gira, la raqueta arriba y atrás, baja, le pega bajito, a la cintura o alto, y termina por encima del hombro (en dos cuadros). El **cortado** (3) y la **dejada**.
  - **El saque** (9): bota la pelota (2), bajan los brazos, la tira, el trofeo (rodillas dobladas, la raqueta arriba), la raqueta detrás de la espalda, le pega estirado y en puntas, y cae hacia adelante (2). El **saque por abajo** (2).
  - **La espera** (3): rebota en las puntas. **Celebrar** (3): el puño dos veces, "¡vamos!", y los brazos arriba. **Lamentarse** (2): las manos en la cabeza y la cabeza agachada.
  - **Lo de cada uno** (14, `TenisAnim.PERSONA`): Bublikov se encoge de hombros (gane o pierda); Sabalenkova grita con los puños abajo; Monfiz baila; Yokovich, las manos al pecho y los brazos abiertos al público; Moutette le reclama al juez; Tiafuego, la mano en la oreja (más duro); Sheltron, el teléfono y cuelga; Kyrgistán abre los brazos al ganar y, al perder, levanta la raqueta y la estrella contra el piso; Fedorer saluda con la raqueta. Él, cuando gana un punto, se queda mirando la raqueta.
  - **Tirarse** (2: el impulso y el vuelo), en el piso, y **levantarse** (2: de rodillas, agachado).
  - **Caminar** de espaldas o de frente (4) y de perfil (8, para cada lado), sin raqueta: los que se van de la cancha y los camilleros.
  - Las del recogebolas, las de irse (parado, el celular, doblado, acostado, los brazos arriba) y la raqueta en el piso (entera y rota).
- Fedorer tiene el revés a una mano (`ONE_HAND`): la izquierda acompaña la raqueta y, al pegarle, se va para atrás. Él, con la raqueta de Fedorer, sigue con su revés a dos manos.
- Los cuadros del medio salen de mezclar dos poses (`mix`), y los de un lado tienen su espejo (`mirror`) que deja la raqueta en la mano derecha. De frente, y en los zurdos, la hoja se arma con el lado cambiado.
- `camillero.png`: los que se llevan a Monfiz y a Pecador (de blanco, con la cruz roja), con las mismas poses.
- Cada pose es un esqueleto que se pinta con piezas de 2 px. Después va el contorno del juego y encima, a mano, lo de cada uno:
  - Bublikov: altísimo, despeinado, raya negra.
  - Sabalenkova: cola mona, falda y el tigre en el antebrazo.
  - Monfiz: piel oscura, balaca, camiseta amarilla con el costado negro.
  - Yokovich: cuello blanco y franja azul.
  - Moutette: bajito, crespo, celeste. Sheltron: alto, rapado, naranja. Los dos zurdos (la hoja se voltea).
  - Tiafuego: trencitas, verde limón y morado. Kyrgistán: gorra roja al revés, de negro, tatuajes.
  - Pecador: pelo zanahoria crespo, menta. Fedorer: todo de blanco, balaca blanca, raqueta roja.
  - Él (`el.png`, sin raqueta, de recogebolas; `el_<id>.png`, con la raqueta de cada uno): la camiseta negra del torneo, y encima lo suyo: la corbata roja (de espaldas, tirada por encima del hombro), el jean, un zapato negro y uno rojo, la barba con canas.
- Agachado y recogiendo son del recogebolas: esperando el punto y cogiendo la pelota (o la raqueta del que se fue).

**Cómo se mueven en la cancha** (`TenisAnim.gd`):
- El cuadro de correr sale de lo que lleva corrido, no del tiempo: un cuadro cada 0,27 m de perfil, 0,3 m hacia la red y 0,22 m para atrás (pasos más cortos). Así los pies no patinan.
- De lado: los primeros 0,18 s son pasitos; si sigue, corre de perfil. Al parar después de correr de lado, frena un momento con el pie de afuera estirado.
- Cuando el otro le pega, el saltito, si está quieto. Esperando, rebota en las puntas.
- Después de tirarse, se levanta: de rodillas y agachado. Al ganar un punto bueno, el puño; con un error fácil, las manos en la cabeza.
- La pelota viene: según cuánto le falta (`eta`), se gira, la raqueta atrás y abajo. Si viene corriendo, sigue corriendo hasta el último momento (si no, patina en la pose de pegar).
- Le pega con el contacto bajito (la pelota por debajo de 0,45 m), a la cintura o alto (por encima de 1,3 m), y la pelota sale de la cabeza de la raqueta: en 0,12 s llega a donde va de verdad.
- El saque: al apretar arranca el movimiento y el golpe le llega a la simulación a los 0,52 s (0,24 s por abajo), cuando la raqueta encuentra la pelota, con lo que se apretó al empezar. La pelota se ve en la mano, sube y baja hasta la raqueta.
- **Los supertiros** (las habilidades, cuando se llena la barra): el primer golpe con la habilidad congela el juego un instante, la pantalla destella y tiembla, suena el cañonazo (`super`), el público se para y arriba sale una franja con el nombre (en dos renglones si no cabe). Mientras dure, la pelota sale encendida del color del tenista, con estela de fuego, y al picar suelta chispas. Cuando la barra se llena, suena (`carga`); la primera vez, si es la de uno, sale "F: ¡SUPERTIRO!".
- Lo que le da peso: donde pica la pelota queda un anillo que se abre y se apaga; la sombra de la pelota se achica y se aclara mientras más alto va; sale polvito de los pies al frenar, al caer del saltito, al tirarse, al levantarse y al estrellar la raqueta; y la pantalla tiembla un pixel con los cañonazos (0,08 s) y los aces (0,15 s).
- La estela: en el golpe, la cabeza de la raqueta deja un arco claro (una curva suave por donde pasó, cuadro a cuadro) que se apaga en 0,13 s; y la pelota, cuando va a más de 17 m/s, deja tres pelotas apagadas atrás.
- La altura en la pantalla (la de la pelota y la de la red) es de 16 px por metro abajo, como los jugadores, y cada vez menos arriba (`TenisMatch.zh`), para que un globo no se salga de la pantalla. La red mide 0,914 m: llega a la cadera.

`TenisMatch._pose()` escoge la pose según la cancha:
- Un golpe reciente: drive o revés según el lado de la pelota.
- La pelota que llega: prepara.
- El saque, la estirada, el piso.
- Correr o estar listo.
- Después del punto: celebrar (ganador o ace) o lamentarse (error no forzado).

**El coliseo por fuera** (en el barrio) sale de `tools/art/draw_tenis_afuera.py` (`assets/barrio/coliseo_afuera.png` y su `.json`, más el ícono de la raqueta).

**El coliseo** sale de `tools/art/draw_tenis_coliseo.py`: `assets/tenis/coliseo.png` (las tribunas vacías) y la gente aparte, para que se mueva: `publico.png` (una fila por persona, ya oscurecida según la grada) y `publico.json` (dónde va cada una, si trae bandera, si es perezosa y en qué punto de la ola está).
- La cancha va en perspectiva: de 10.5 px por metro en el fondo a 13.5 en el frente, y 4.6 a lo largo. Es la misma cuenta de `TenisMatch.w2s`; si se cambia en un lado, se cambia en el otro.
- Tiene tribunas con gradas, pasillos y puestos vacíos, la tribuna del fondo, las vallas con los patrocinadores del barrio (la Caverna del Gamer, la panadería de Don Germán), los reflectores y la silla del juez.
- **El público** (`TenisPublico.gd`, 526 personas) tiene nueve cuadros por persona: sentada, aplaudiendo (2), de pie con los brazos arriba (2), con las manos en la cabeza, con la bandera ondeando (2) y volteando a mirar.
  - Con un ace, un ganador de peloteo largo o un juego que se cierra, se para casi todo el estadio, primero los que estaban cerca del punto. Con un ganador corto o un peloteo de 12, la mitad. Con el resto de puntos, aplauden unos cuantos.
  - Con un error fácil o una doble falta, unos cuantos se agarran la cabeza (con el "uuuy").
  - La ola da la vuelta al estadio (sube por la izquierda, cruza el fondo y baja por la derecha) cuando se cierra un set y cuando él toma la raqueta: el público no sabe quién es, pero le hace la ola.
  - Sola, todo el tiempo: alguno aplaude, alguno se para a estirarse y alguno voltea a mirar. Los perezosos (uno de cada ocho) no se paran por nada, ni por la ola.

**Las caras para los diálogos** salen de `tools/art/draw_retratos.py` (`assets/portraits/<id>.png`), con los colores de su dibujo de la cancha. En `Dialogue.SPEAKERS`, cada uno lleva su apodo en la placa.
- Los diez: Bublikov despeinado y aburrido, Sabalenkova gritando (la cola rubia, el sudor), Monfiz con la balaca amarilla, Yokovich con la franja azul, Moutette crespo y sudando, Tiafuego con trencitas, Sheltron rapado, Kyrgistán con la gorra roja al revés, la chivera y la cadena, Pecador pelirrojo con pecas, y Fedorer con la balaca blanca anudada atrás.
- El organizador: gordo, engominado, saco morado y camisa rosada, cadena y el audífono del canal.
- El juez de silla: viejo, calvo, gafas, saco azul y corbata.

Para ellos, el generador de retratos aprendió: el pelo despeinado, rapado y en trencitas; la balaca; la gorra al revés; la camiseta de tenis (cuello, raya, franja o costado de otro color); los ojos aburridos, el grito y el sudor.

**El tablero**, arriba a la izquierda, muestra por jugador el nombre, los juegos y los puntos (0, 15, 30, 40, AD), el cansancio y el medidor de la habilidad. Una pelotica marca quién saca.

## La música y los sonidos

Salen de `tools/audio/tenis_audio.py`, que usa los instrumentos de `compose.py`. Es rock de estadio original, en la mayor, y no copia a AC/DC: guitarra rítmica saturada con acordes de quinta y aire entre los golpes (La-Do-Re / La-Sol-Mi), bajo en corcheas, batería recta, las palmas del público en el coro y una guitarra que canta arriba.

| Tema | Dónde suena |
|---|---|
| `tenis_partido` (128) | En la cancha, mientras juegan los profesionales (y el recogebolas). |
| `tenis_el` (142, un tono arriba) | Desde que él toma la raqueta (`TenisMatch.take_over`): más rápido, con doble bombo en el coro y la guitarra cantando todo el tiempo. |
| `tenis_cuadro` (112) | El cuadro y la paga: el mismo riff con la mano apagada. |
| `tenis_afuera` | En el barrio, cerca del coliseo, de 8 a 6: el partido a través de la tribuna (sin agudos) y el murmullo del público. Va por el bus de la música (se apaga con la misma opción). |

Los sonidos de la cancha (`assets/audio/tenis/`):
- La raqueta: `golpe`, o `golpe_duro` si la pelota sale a 22 m/s o más, o con habilidad.
- El bote y la red.
- El público: el "uuuy" con el error no forzado y la doble falta; el estadio de pie (`ovacion`) con el ace, el ganador después de un peloteo largo o el juego que se cierra; aplausos con el resto.
- Con el dibujo (`TenisMatch._pose_sounds`): el chillido de las zapatillas al frenar después de correr de lado (`chillido` o `chillido2`, en la mitad de las frenadas: en todas cansa); la raqueta cortando el aire (`zas`) cuando baja para pegarle; y la raqueta contra el piso (`rompe`) cuando Kyrgistán la estrella.
- Sabalenkova grita en cada golpe (`grito`: un "¡ah!" con voz que baja y un poco de aire).

## Las pruebas

Todas corren sin ventana:

```
../Godot_v4.6.3-stable_win64_console.exe --headless --path . -s tools/tests/tenis_tests.gd
../Godot_v4.6.3-stable_win64_console.exe --headless --path . -s tools/tests/tenis_roster.gd
```

`TENIS_ONLY=unit|sim|counter` corre solo una parte y `TENIS_N` pone los partidos por cruce.

**`tenis_tests.gd`** (66 pruebas): el conteo; que el error baje con la precisión y quede acotado; la misma semilla da el mismo partido; cómo se reparten los puntos; y el cuadro (la siembra, la previa, avanzar, no anotar dos veces, guardar y cargar, el torneo entero con un solo campeón, la bolsa, cuadros de 4 y de 5, simular hasta tu partido y que cada ronda tenga un formato que exista) y la historia (las fechas, que cada uno tenga cómo abandonar y cómo irse de la cancha, quién abandona, la paga y que alcance para la deuda solo trabajando bien), que cada texto que pide el código esté en `TEXTOS` y que el VS quepa al lado de los botones. Y el dibujo en movimiento: un partido entero mirado cuadro por cuadro (cada pose que pide `TenisAnim` está en las hojas y se ve de todo), que el saque salga cuando llega la raqueta, que corriendo de lado el cuadro cambie con la distancia, el contacto según la altura y los gestos de cada uno.

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

Nada de lo que estaba en la lista. Lo que siga sale de jugarlo (en el computador y en el celular).
