# Diseño — La ciudad viva, el cambuche y los sistemas

> **Estado:** propuesta para revisar. Complementa el spec del Nivel 01 (`SPEC_Nivel_01_El_Primer_Dia.md`).
> Lo marcado con **[A CONFIRMAR]** es una decisión abierta.
> **Confirmado:** su hija va a aparecer en el juego. **[A CONFIRMAR]** cómo (memorias, la fotografía,
> el motivo de fondo de todo el viaje, Lukas, la estación de tren...).

---

## 1. Estructura: lineal, pero con calle para recorrer

El juego avanza por **días**. Cada día tiene una **columna de misiones principales** (lineal) y,
alrededor, una ciudad que se puede recorrer libremente **hasta donde la historia la abrió**.

```text
DÍA  →  misiones principales (en orden)  →  noche: dormir  →  sueño (a veces)  →  DÍA siguiente
          │
          └─ alrededor: misiones secundarias, NPCs, buscar cosas, mejorar el cambuche
```

- Las misiones principales **abren zonas nuevas** de la ciudad.
- Lo ya abierto queda siempre accesible: la ciudad crece, nunca se achica.
- Hay pocas zonas, pero densas: cada una con 1 o 2 NPCs, cosas para encontrar y un lugar posible
  para dormir.

### Cómo se cierran las zonas (sin paredes invisibles)

Cada borde cerrado tiene un motivo dentro del mundo, y la misión que lo abre tiene sentido:

| Zona | Qué la cierra | Cómo se abre |
|---|---|---|
| Zona industrial | Portón con candado | Samuel le muestra el hueco en la reja (Día 1) |
| Mercado | Cinta de la policía (hubo un operativo) | Al otro día ya no está (Día 2) |
| Centro (iglesia / refugio, ferretería) | Paso bajo nivel inundado | Baja el agua después de la lluvia (Día 2) |
| Reciclaje / basurero | Perro bravo en la entrada | Darle de comer, o que Lukas lo distraiga (Día 3) |
| Estación de tren | Guardia de seguridad | Misión de historia **[A CONFIRMAR]** (¿relacionada con su hija?) |

---

## 2. Hambre: el sistema principal

Rango 0–100. Baja con el tiempo (aprox. **−4 por hora de juego**) y más rápido si corre o trabaja.
El reloj corre a **1,5 minutos de juego por segundo** (un día de 06:17 a 22:00 dura unos 10 minutos),
con ciclo de luz: amanecer azulado, mediodía, atardecer naranja, noche con faroles.

| Hambre | Qué pasa |
|---|---|
| 100–60 | Normal. Registro cálido. |
| 60–40 | La imagen empieza a lavarse. Comentarios sueltos ("Me suena la panza"). |
| 40–20 | Camina más lento, no puede correr. Mareos: la cámara se mece un poco. Algunos NPCs lo notan y le ofrecen algo, o lo esquivan. |
| 20–1 | No puede hacer trabajos pesados. Visión cerrada (viñeta fuerte, registro frío). |
| 0 | **Se desmaya.** Despierta horas después en otro lado (el refugio, una vereda) y le falta algo de la mochila. No hay game over: hay consecuencia. |

- La comida cura distinto: fruta +15, pan +25, sándwich +40, comida caliente +60.
- **Comer caliente** también baja el estrés (ver 6).
- La comida que se guarda **se pone fea**: el pan dura 2 días; la comida caliente hay que comerla ya.

---

## 3. Inventario y guardar cosas

### La mochila (lo que lleva encima)

- **8 casilleros.** Al estilo Signalis: poco espacio, cada cosa que levanta es una decisión.
- Algunas cosas se apilan (latas, cartones hasta 5); la mayoría no.
- **La fotografía** ocupa un casillero fijo que no se puede tirar.
- Se abre con un botón (**Tab** / **Y** en el joystick): grilla chica, el nombre y una línea de
  descripción por cosa. Acciones: **usar / comer**, **mirar**, **tirar**.

| Tipo | Ejemplos |
|---|---|
| Comida | pan, fruta, sándwich, tinto (café) |
| Materiales | cartón, plástico (lona), palet, alambre, frazada, colchón |
| Para vender | latas, botellas, chatarra |
| Herramientas | encendedor, linterna, candado |
| Especiales | fotografía, llave del galpón, cosas de la historia |

### Guardar cosas

- En el **cambuche** se puede guardar en una **caja** (12 casilleros) cuando se consigue una.
- **Riesgo**: si el cambuche no está protegido (sin techo, sin candado), a la mañana **puede faltar
  algo** de la caja. Al principio pasa seguido; con candado, nunca.
- El refugio no deja guardar nada (regla del lugar).

---

## 4. El cambuche

"Cambuche" es su lugar: dónde duerme, guarda cosas y se recupera. **Armarlo y mejorarlo es la
columna de misiones de los primeros días.**

### Tipos de lugares para dormir

| Lugar | Pros | Contras |
|---|---|---|
| Bajo el puente | Gratis, conocido | La primera noche está ocupado; húmedo |
| Banco de la plaza | Siempre disponible | Expuesto: frío, lluvia, la policía lo echa a la madrugada |
| Zaguán de un local cerrado | Techo contra la lluvia | El dueño lo echa al abrir (6:00) |
| Galpón abandonado | Seco y escondido | Tétrico: más estrés; hay que entrar por la reja |
| Refugio (iglesia) | Cama, comida caliente | Cupos y horario (entrar antes de las 20:00); no se guardan cosas; reglas |
| **Cambuche propio** | Es suyo, se mejora, se guardan cosas | Hay que construirlo; lo pueden saquear |

### Construir el cambuche propio

Se arma en un lugar que el jugador elige entre 2 o 3 sitios abiertos (bajo el puente, detrás del
galpón, al lado del río). Cada mejora es una misión chica:

| Nivel | Necesita | Da |
|---|---|---|
| 1. Cartones | 3 cartones (contenedores, el reciclador) | Dormir sin mojarse por abajo |
| 2. Techo | 1 plástico / lona (la obra, el mercado) | Protege de la lluvia |
| 3. Colchón | Colchón (el tirado del barrio, hay que limpiarlo) + frazada | Dormir recupera más |
| 4. Caja | Caja de madera / huacal (el mercado) | Guardar cosas (12 casilleros) |
| 5. Candado | Candado ($ en la ferretería) | Nadie le toca la caja |
| Extras | Vela, linterna, foto pegada en la pared | Bajan el estrés |

Dormir bien (cambuche mejorado, panza llena) hace que el día siguiente empiece con más hambre
aguantada y menos estrés. Dormir mal hace lo contrario.

---

## 5. NPCs

Pocos, con vida propia y rutina. Ninguno existe solo para dar una misión.

| NPC | Dónde | Rol |
|---|---|---|
| **Don Germán** | Tienda-panadería | Basado en Germán, un tendero que fue muy amable con él. Trabajo (descargar harina del camión de "Harinas El Sol"), le guarda pan del día anterior. **Muy amable**, lo trata con respeto: el lugar más cálido del barrio. |
| **Marta** | Café | Mandados (llevar un pedido) a cambio de plata; conversaciones. Tiene sus propios problemas. |
| **Samuel** | Calle / bajo el puente | Vive en la calle hace años. **Le enseña a armar el cambuche** y le muestra la ciudad (hueco en la reja del galpón). Mentor, con sus opiniones. |
| **Wilson, el reciclador** | Con su carro, recorre el barrio | Compra latas, botellas y cartón: la forma más estable de hacer plata. |
| **Doña Rosa** | Puesto de tintos y arepas, esquina de la plaza | Vende comida caliente barata; a veces fía. |
| **Lukas** (beagle) | Con él, siempre | Su perro: el único que se quedó. Lo sigue a todos lados. **Olfatea comida y cosas escondidas** (los beagles tienen el mejor olfato). Ladra si alguien se acerca al cambuche de noche. Baja el estrés. **[A CONFIRMAR]** ¿Tiene relación con su hija (era de ella, se lo regaló a ella)? |
| **El agente** | Plaza, de madrugada | Echa a los que duermen en el banco. No es malo ni bueno: cumple. |
| **Los muchachos** | Esquina del kiosco | Molestan, piden "peaje". Ecos de los matones del sueño. **No se pelea en la vida real**: se esquiva, se paga o se va. |
| **Hermana Clara** | Refugio (Centro) | Reglas, cama, sopa. Más adelante, la puerta a hablar de lo que le pasa (salud mental). |

---

## 6. Estrés y salud mental

### Día 1: existe, pero no se ve

Hay una variable de **estrés** escondida desde el principio. No hay barra. Se nota en:
- el filtro (más grano, más frío, más lento para volver a lo cálido),
- detalles que se vuelven raros (un grafiti que cambia, un cuervo que lo sigue con la mirada),
- los sueños (más estrés = sueño más difícil).

| Sube con | Baja con |
|---|---|
| Dormir expuesto, mojarse, frío | Comer caliente |
| Hambre baja | Dormir bien en su cambuche |
| Que lo echen, lo rechacen, lo roben | Hablar con Samuel, Marta, Doña Rosa |
| Pesadillas | Lukas cerca |
| Lugares tétricos (galpón) | Mirar la fotografía (pero puede abrir recuerdos duros) |

### Cuándo se desbloquea como sistema

En el **Día 3** (propuesta): después de una noche muy mala, despierta en el refugio. La Hermana
Clara le habla. A partir de ahí aparece en la mochila una **libreta**: cada día puede escribir cómo
se siente (eligiendo frases), y eso es la "salud mental" visible: no una barra de 0 a 100, sino un
estado con palabras ("Aguanto", "Cansado", "No doy más") que cambia lo que puede decir y hacer.

- Estados bajos cierran opciones de diálogo (no se anima a pedir), y abren otras (más honestas).
- Estados muy bajos traen **ataques de pánico**: un mini sueño despierto de unos segundos.

**Confirmado:** la libreta es la forma.

---

## 7. Misiones

### Cómo se ven las misiones

- **HUD**: debajo de la barra de hambre, siempre la **principal** ("> Conseguí algo para comer")
  y a la derecha cuántas secundarias/opcionales hay ("+3 Tab").
- **Aviso** en el medio de la pantalla cuando empieza una ("NUEVA MISION") o se cumple
  ("MISION CUMPLIDA").
- **Tab**: arriba la lista de MISIONES (principal en amarillo, secundarias con progreso "(3/5)",
  opcionales en gris); abajo la mochila.

### Día 1 (el que estamos haciendo)

Principales (en orden):
1. **Algo para comer**: trabajar en la panadería, pedir o buscar.
2. **Dónde pasar la noche**: el puente está ocupado. Samuel: *"Si vas a dormir en la calle, armate
   algo."* Elegir lugar (banco, zaguán o galpón) y conseguir **cartones** (nivel 1 del cambuche).
3. **La noche**: la fotografía, la primera memoria, dormir.

Secundarias del Día 1:
- **El mandado de Marta**: llevar un pedido a una casa del barrio (la de "—Andate"). $.
- **Latas para Wilson**: juntar 5 latas o botellas y vendérselas. $.
- **Lukas**: pedirle que busque comida (olfato).

### Días 2 y 3 (esbozo)

- Día 2: se abren el Mercado y el Centro. Mejoras del cambuche (techo, colchón). Trabajo en el
  mercado. Segundo sueño.
- Día 3: Reciclaje. Caja y candado. Refugio y desbloqueo de la salud mental. Tercer sueño.

---

## 8. Sueños: cada uno, un género y un miedo

Cada sueño es un videojuego distinto y termina con un **jefe que es uno de sus miedos**.

| Sueño | Género | Jefe | Miedo |
|---|---|---|---|
| 1 | Beat 'em up | **Lilato** → la serpiente | **Su ex pareja, que no lo deja ver a su hija.** Debajo del odio, el miedo: **perder a su hija**. Lilato es quien se interpone. Habla como alguien que lo conoció ("Yo te cuidaba"), y se vuelve serpiente. |
| 2 | Carreras | La grúa / el operativo | Perderlo todo de golpe (desalojo) |
| 3 | Sigilo | Los Ojos | La vergüenza: que lo vean así |

### Los jefes: cada uno, una herida

Los jefes de los sueños están basados en personas reales de su vida. **Regla de nombres:** nombres
de pila reales, **sin apellidos**; instituciones y empresas con **nombres inventados** (si el juego se
muestra o se publica, no hay datos reales de nadie).

| Jefe | La herida | El miedo que representa |
|---|---|---|
| **Lilato** | Su ex: no lo deja ver a su hija | Perder a su hija (recurrente: está en todos los sueños) |
| **Camila** | Destruyó a un amigo y le quitó todo | Ver cómo le quitan a la gente que quiere |
| **Guillermo** | Traicionó a todos sus amigos por estar con ella | Que los amigos lo traicionen |
| **Lisandro** | Lo mandó a matar por envidia | Morir |
| **Brenda** (su mamá) | Cuando se enteró, se fue a Ibagué y lo dejó solo | Que lo abandonen cuando más lo necesita |
| **Mauricio** (su papá) | Se fue cuando él tenía 15; le dice a todos que todavía los ve | La mentira de que alguien está, sin estar |
| **José Mario Camilo** (su jefe) | Le contó a la empresa su problema con las drogas; todos lo miran con asco | La vergüenza |
| **Clínica Eiren** (salud mental) | Filtró sus datos | No poder confiar ni en quien lo tiene que cuidar |
| **Zaida** | Fue su amiga; intentó manipularlo | Ser manipulado. **Jefa ambigua** (ver abajo) |
| **Los rappitenderos** (app "Rapidito") | Los sentía siguiéndolo | Sentirse vigilado (ver abajo) |

### En qué sueño aparece cada uno **[A CONFIRMAR]**

| Sueño | Género | Jefe chico | Gran jefe |
|---|---|---|---|
| 1 | Beat 'em up | El Tuerto (callejón) | **Lilato → serpiente** |
| 2 | Carreras | Rappitenderos en moto (persecución) | **Lisandro** (te persigue para matarte) |
| 3 | Sigilo | José Mario Camilo (la oficina: que no te vean) | **Clínica Eiren** (sacar tu expediente) |
| 4 | Plataformas / huida | Guillermo | **Camila** |
| 5 | Ritmo / baile, o casa embrujada | Mauricio (aparece y desaparece: "todavía los veo") | **Brenda** (la casa que se vacía) |
| 6 | Conversación / juicio | — | **Zaida** (ambigua) |
| Final | Todos los géneros mezclados | Todos, de a uno | **Lilato** (la última) |

### Zaida: la jefa que no pega

No pelea con golpes: **intenta convencerlo**. Su "barra de vida" es la de él: cada frase que acepta
lo acerca a hacer lo que ella quiere. El jugador elige respuestas. Según lo que elija, la pelea termina:
- **en paz** (él pone el límite sin odiarla), o
- **en contra** (él cae en la manipulación, o la corta con rabia).
No hay final "correcto": el juego no le dice al jugador qué pensar de ella.

### Los rappitenderos: dos formas

1. **En los sueños** son enemigos de verdad: aparecen en moto o bici; se les puede **tirar cosas**.
   Al azar, algunos **vuelven a pelear** y otros **salen asustados**.
2. **En la vida real** son **percepción**: un repartidor de "Rapidito" cruza la calle. Cuando el
   **estrés está alto**, parece que lo sigue (se frena, lo mira, la pantalla se pone rara). Si le tira
   algo, el repartidor se asusta o lo insulta y se va, pero **el estrés sube igual**. El jugador nunca
   sabe si de verdad lo seguía. (En la vida real no hay combate: es una reacción, no una pelea.)

### Lilato: jefa recurrente

Lilato **vuelve en todos los sueños**, cada vez con otra forma según el género del sueño.
A veces es un **jefe chico** al principio o a la mitad (aparece, pelea un rato y se escapa), y a veces
es **el gran jefe** del final. Siempre se la puede ver antes de pelearla: se asoma de lejos, mira y
se va. En el sueño 1 se asoma en el callejón ("—Jaja. Seguí corriendo.") y es la jefa final.

| Sueño | Lilato es... |
|---|---|
| 1 Beat 'em up | Gran jefa (final): Lilato → serpiente |
| 2 Carreras | Jefa chica: maneja un auto que lo encierra a mitad de carrera **[A CONFIRMAR]** |
| 3 Sigilo | Gran jefa: es la que vigila **[A CONFIRMAR]** |

### Lilato (jefe final del sueño 1)

Al final del camión, el camión frena en el puente. Bajo el puente, bajo la lluvia, lo espera ella.

- **Fase 1: Lilato.** Chiquita, cara linda, vestido lila, pelo largo. Rápida: ráfagas de saliva, un giro que
  barre, y desaparece y reaparece detrás de él. Habla entre ataques. **A la mitad se enoja**
  ("—No la vas a ver nunca más."): más rápida, aparece detrás más seguido.
- Al vencerla, cae y deja en el piso el **súper cuchillo** (brilla).
- **Fase 2: la serpiente.** Lilato se transforma. Los golpes comunes rebotan: **solo el súper
  cuchillo la daña.**
  - **Embestida**: avisa (la cabeza se echa atrás), cruza la pantalla; hay que salir de su línea.
  - **Veneno**: escupe charcos que quedan en el piso un rato y lastiman si se pisan.
  - **Coletazo**: la cola barre un costado de la pantalla.
  - Después de la embestida queda **trabada unos segundos con la cabeza en el piso**: ahí es
    cuando se le pega.
  - **A la mitad se enoja** ("—¡¿Me vas a dejar?!"): embiste más rápido, avisa menos, escupe más.
- Al matarla: "FINAL STAGE CLEAR" → "INSERT COIN" → no hay créditos → despierta.

> El sueño ya no termina con el puente que lo barre en el techo del camión: el camión lo lleva al
> puente, y ahí está Lilato.

---

## 9. Orden de implementación (confirmado)

1. **Lilato y la serpiente** — hecho.
2. Inventario (mochila de 8) + hambre real con el tiempo + comer — **hecho** (falta: comida que se pone fea, caja del cambuche).
3. Reloj del día y misiones (registro de objetivos) — **hecho**: reloj más rápido con día y noche,
   misiones del Día 1 (comida → al anochecer al puente; secundarias latas y cartones; opcional Lukas),
   HUD y Tab. Falta: el evento del puente ocupado, el cambuche y la noche.
3b. **Lukas** (beagle que olfatea) — **hecho**.
4. NPCs del Día 1 con diálogos: Don Germán, Marta, Samuel, Wilson — **hecho** (más la noche: puente ocupado, lugares para dormir, cambuche nivel 1, fotografía y resumen). La memoria jugable (la pelota) también está **hecha**.
5. Cambuche nivel 1 y lugares para dormir; guardado.
6. Zonas que se abren por historia (Día 2 en adelante).
7. Estrés escondido → luego libreta de salud mental.


## Tono del libreto: humor negro tipo Deadpool

La historia es triste, pero él **no da lástima: es gracioso.** Es canchero y rápido, un sobreviviente que se ríe de todo, sobre todo de sí mismo. El chiste es su escudo.

**Reglas**
1. **Él se ríe primero.** Es irreverente y confiado, nunca quejumbroso. Nada de "pobre de mí": su desgracia es material de stand-up.
2. **Sabe que está en un videojuego.** Le habla al jugador ("Ojo, jugador: si se vacía la barrita, es tu culpa"), comenta la barra de hambre, los casilleros, el DLC, a "los de diseño", el jefe final, CONTINUE? y las monedas. El sueño es literalmente un juego, así que ahí el meta es el doble.
3. **Habla en primera persona.** Cuando la cosa se pone seria, **deja de hablar él y entra un narrador en tercera persona**, más frío. Ese cambio de voz avisa que esto ya no es chiste.
4. **El escudo se rompe en los golpes fuertes:** la foto, las memorias, Lilato, la hija, el padre y la madre. Él intenta zafar con un chiste y no le sale (ver la noche: "—Bueno. Este es el momento triste del juego... yo mientras..." / "No termina la frase."). Eso pega mucho más que estar triste todo el tiempo.
5. **La gente buena no es blanco** (Germán, Samuel, Marta, Wilson). Les hace chistes, pero con cariño. El blanco libre es el sistema: la clínica, la empresa, Rapidito, la policía y los vecinos que no abren.
6. **Los jefes de los sueños** pueden ser ridículos y él se burla en la pelea, pero lo que ellos dicen duele de verdad.
7. **Corto y con remate al final.** Que entre en 2 o 3 líneas de pantalla.

**Chistes que se repiten**
- Bienes raíces: cartón = finca raíz, cambuche = primera propiedad a su nombre, puente = penthouse con vista.
- Reseñas de hotel y de vecinos ("Reseña: una estrella. No volvería").
- Lukas, empleado del mes y acreedor ("Ya le debo como cuarenta").
- Lógica de videojuego: el pollo en el barril, el contenido descargable, el inventario que no deja acumular riqueza.
- "Dignidad: ahí vamos" en el resumen del día.


## Música

La genera el código (→ `assets/music/*.wav`): la de los sueños, `tools/audio/compose.py` (chiptune, guitarra pulsada, cajita de música); la de la vida real, `tools/audio/barrio.py` (marimba, guitarra de nylon, piano eléctrico, vibráfono, piano, contrabajo, tiple y percusión suave, con reverb de sala, en estéreo). Los loops empalman sin corte. La elige el autoload `MusicDirector` según la escena y la hora, con fundido cruzado.

| Escena | Tema |
|---|---|
| Sueño (beat 'em up) | `dream_fight`: chiptune rockero tipo Streets of Rage |
| Camión | `truck`: el mismo riff, más rápido, con doble bombo |
| Lilato | `lilato`: épica en re menor |
| La serpiente | `lilato_serpent`: lo de Lilato, desafinado, una octava abajo y con bits de menos |
| CONTINUE? | silencio |
| El barrio, 6 a 10 | `barrio_manana`: marimba y guitarra en re mayor, con pájaros lejos |
| El barrio, 10 a 14 | `barrio_dia`: cumbia suave en sol (requinto, marimba, piano eléctrico, guacharaca) |
| El barrio, 14 a 18 | `barrio_tarde`: bossa en fa (piano eléctrico, vibráfono, escobillas) |
| El barrio, 18 a 6 | `barrio_noche`: guitarra en 12/8, piano eléctrico y grillos, en mi |
| Panadería de Germán, el billar | `bakery`: un bolero de trío (requinto con trémolo) en una radio de mesa |
| Café de Marta, la fila | `cafe`: un vals con tiple y bandola en la radio |
| La noche, el título, el final | `night`: el tema del juego, piano solo |
| La feria | `feria`: la cumbia del mediodía, de fiesta |
| Los recuerdos con sol, la fuente | `flashback`: la mañana, más rápida y con más sol |
| La memoria | `memory`: cajita de música desafinada que se corta en seco |

Con hambre (debajo de 40) la música pierde agudos y baja de tono, igual que el filtro de imagen.

**La de la vida real tiene que aguantarse horas (2026-10-20).** La de antes (loops de 27 a 55 s, guitarra de ruido, disco rayado, cinta que se desafina, radio AM chillona) cansaba tanto que daba pereza volver al juego. Ahora: temas de 75 a 110 s con partes A y B y cada vuelta arreglada distinto; acordes con séptima; instrumentos suaves; nada de ruido ni desafinación; el barrio cambia de tema cada cuatro horas del juego, y los del barrio y las radios siguen donde iban al entrar y salir de un lugar (`MusicDirector.RESUME`).

## Plata: en qué se gasta

- **Comida:**
  - Germán: pan $1.500, arroz $2.000, vela $500 y concentrado para Lukas $2.000.
  - Marta: tinto $1.000 y sándwich $6.000.
  - Doña Rosa, en la plaza: empanada $1.500, arepa $3.000 y aguapanela $1.000.
- **Higiene:** baja con las horas. Si estás SUCIO (aparece en el HUD), Marta y Doña Rosa no te atienden. Germán te atiende igual, y te dice con cariño dónde está el baño. El baño público de la plaza cuesta $1.000.
- **Pensión ($15.000, la casa gris del barrio):** se paga de noche. No te roban, te bañás y dormís mejor. Lukas entra "sin respirar".
- **Cosas para el cambuche, donde Wilson:** cuerda $1.000, plástico $2.500, candado $4.000 y cobija $5.000.
- **Alcancía para la hija:** está en el cambuche. La meta es $150.000 para un regalo (misión "Regalo para tu hija"). Cuando se llega a la meta, la línea va sin chiste.
- **Robos:** al despertar, según dónde dormiste:
  - Banco 45%, kiosco 30%, callejón 30%, parque 20%, río 15%, pensión 0%.
  - Te llevan la mitad de la plata del bolsillo. Si no tenés plata, se llevan un objeto.
  - La caja del cambuche sin candado se puede saquear cuando dormís en otro lado.
  - En el parque, la policía puede llevarse el cambuche.
- **El día sigue:** después de la noche viene el día siguiente (antes volvía al principio). Del Día 2 en adelante:
  - Principal: "Día N: sobreviví hasta la noche". A las 18:00 pasa a "Encontrá dónde pasar la noche".
  - Cada día: darle de comer a Lukas.
  - Cuando estás sucio: bañarte.

## Combinar y el cambuche

- **Combinar en la mochila (C):**
  - Cama de cartón = 3 cartones.
  - Toldo = plástico + cuerda.
  - Cocinita = lata + vela.
  - Pelota de trapo = camiseta + cuerda.
- **El cambuche se arma en tres lugares** (uno a la vez; se puede mudar con todo):
  - **Río:** tranquilo y húmedo.
  - **Callejón** entre las bodegas: seco, pero peligroso.
  - **Parque:** lindo, pero pasa la policía.
- **Menú del cambuche:**
  - **Dormir.**
  - **Caja:** guardar y sacar cosas.
  - **Alcancía.**
  - **Mejorar:**
    - Toldo: no te mojás.
    - Cocinita: permite cocinar.
    - Candado: protege la caja.
    - Cobija: la noche te da menos hambre.
  - **Cocinar:** arroz → sopa.

## Lukas

F abre su menú:
- **Buscá:** olfatea. Si ayer no comió, a veces no trabaja ("Sindicato de beagles").
- **Acariciar:** un rato de calma; el filtro de angustia baja.
- **Comida:** concentrado, o compartir lo que tengas. Una vez por día.
- **Jugar:** le tirás la pelota de trapo. La va a buscar y la trae, o se acuesta encima ("así funciona la propiedad privada").


## Día 2: aprender lo básico, y el recuerdo de la moto

**El Día 2 es un tutorial.** Las principales van en orden y cada una enseña una mecánica:
1. Armar el cambuche: 3 cartones, [C] para combinar.
2. Darle de comer a Lukas [F].
3. Bañarse en el baño de la plaza ($1.000).
4. Esa moto frente al café...

Cuando aprendió lo básico, aparece frente al café una café racer igual a la que tuvo. La toca y empieza el recuerdo **(ANTES)**:
- **El taller de motos usadas.** Calle cálida y con sol: el pasado era mejor, o así se acuerda. El señor de la chaqueta de cuero le vende la **UM Renegade 180 café**: *"Tiene un rayón en el tanque: le da carácter." / "—Como a mí esta cara."*. Le paga con un año de ahorros en billetes de veinte. El casco se lo regala: *"Para que no me la devuelva en una bolsa."*
- **La ruta.** Vista desde atrás, pseudo-3D (tipo Road Rash / OutRun).
  - Atardecer, guayacanes amarillos, lomas y curvas.
  - Tráfico colombiano (taxi, buseta, camión), baches y conos.
  - TIEMPO, km/h y una barra hasta "LA CASA DE ELLA". Se guarda el mejor tiempo (`flags.moto_best`).
  - Él, joven, todavía es gracioso pero con esperanza: *"—Ella la va a ver y se va a reír. Se ríe lindo."*
- **La llegada: Lilato**, la mamá de Victoria, sale a la puerta: *"—¡Está hermosa!"*. Se sube atrás y él arranca *"por primera vez en su vida, sin apuro"*. Narrador en tercera persona, sin chiste: *"Ninguno de los dos sabía lo que venía después."*
- **De vuelta al presente:** *"La café de enfrente arranca y se va. El dueño ni me miró. Bueno. Ya tampoco era mía."*

Lilato, que es el jefe final del sueño, acá aparece antes de todo, cuando la quería.


## Día 3 en adelante: la cédula (el primer objetivo de varios días)

**El motivo:** Germán le consigue trabajo fijo en la obra de su cuñado, pero piden cédula. *"Con trabajo, plata. Con plata, abogado. Con abogado... Victoria. Y todo empieza con un papel."* Ganar la cédula abre el centro (una zona nueva).

**Requisitos (secundarias que se marcan solas):**
- **$55.000.** No alcanza en un día; compite con la alcancía de Victoria.
- **Fotos tipo documento** en Foto Express, en el centro: $8.000, y solo si está limpio.
- **Una dirección**, de una de dos maneras:
  - **Germán:** *"Déjeme hablarlo con mi señora. Venga mañana."* Al día siguiente se la da anotada en una bolsa de pan: *"Si le llega correspondencia, se la guardo con el pan."*
  - **Zaida:** aparece "por casualidad" frente a la Registraduría. Sabe lo de la Clínica Eiren y que necesita una dirección, aunque él no se lo dijo. Ofrece la suya y una cita sin fila para el día siguiente. Si aceptás, `flags.zaida_favor` queda como deuda para más adelante: *"Yo te encuentro. Siempre te encuentro."*

**El viaje:** al centro se llega desde el paradero de la plaza: bus $2.500 (20 min) o caminando (1 hora, gratis).

**La fila (minijuego):**
- Abren a las 8 y cierran a las 11. Cuantos más tarde llegás, más gente hay adelante. La fila avanza sola.
- Hay colados: tenés un segundo y medio para reclamar con E. Si no, se meten delante.
- En la ventanilla, si falta algo: *"Le falta: ... Siguiente."*
- Si está todo: *"Vuelva en cinco días hábiles." / "—¿Y eso cuánto es en días normales?" / "—Depende. Siguiente."* Son 2 días del juego.
- Si vas de parte de Zaida, entrás casi primero (y la gente te mira como si te hubieras colado, porque te colaste).

**Recoger la cédula:** *"Un papel que dice que existo."* Germán se pone feliz y le avisa al cuñado (`flags.obra_ready`: el trabajo en la obra viene después).

**Día 4 (pendiente):** empiezan a aparecer los rappitenderos, y con ellos la libreta y el estrés.


## Ánimo, transeúntes, el cambuche que crece y los minijuegos de plata

**Ánimo** (carita en el HUD: bien, regular, mal, muy mal):
- **Baja con:**
  - el desprecio de la gente: -3, o -5 si está sucio;
  - los robos: -10;
  - la caja saqueada: -8;
  - la policía: -12;
  - dormir en el banco: -5, en el kiosco: -3;
  - mojarse: -5;
  - equivocarse al pedir: -2, y con la policía -4;
  - que lo agarren en la fuente: -6.
- **Sube con:**
  - acariciar a Lukas: +6, como mucho una vez por hora;
  - jugar con él: +4;
  - comida caliente: +3 (sopa, arepa, tinto, aguapanela, empanada);
  - hablar con Germán: +3 por día;
  - bañarse: +5;
  - la pensión: +8;
  - el cambuche según su nivel, cada mañana: +3, +6 o +10;
  - ampliar el cambuche: +8.
- **Efectos:**
  - Con ánimo bajo el mundo se ve más angustiante (MoodFilter, igual que el hambre).
  - Por debajo de 15 camina más lento y ya no le salen los chistes (al pedir, los chistes fallan; a los transeúntes les contesta "...").
  - Avisos al bajar de 35: *"Hoy el mundo pesa más."* Y al bajar de 15: *"Hoy no me sale ni el chiste. Eso es grave."*

**Transeúntes:**
- Caminan por las veredas de la ciudad y del centro, de 7 a 20.
- Al pasar cerca reaccionan una sola vez:
  - desprecio en el 45% de los casos (75% si está sucio): *"—¡Consiga trabajo!"*, *"—Ese perro está mejor que usted."*, se tapan la nariz o se cambian de andén;
  - amabilidad, muy rara vez: *"—Tome, para un tintico."*
- Él a veces contesta: *"Gracias. Su opinión es muy importante para nosotros."*

**El cambuche crece (niveles):**

| Nivel | Nombre | Cómo | Caja | Robos | Ánimo cada mañana |
|---|---|---|---|---|---|
| 1 | Cartones | 3 cartones o cama de cartón | 4 | x1 | 0 |
| 2 | Cambuche | toldo + cobija | 6 | x0,8 | +3 |
| 3 | Rancho | 4 estibas + clavos | 8 | x0,5 | +6 |
| 4 | Ranchito | 2 láminas de zinc + radio + clavos | 10 | x0,3 | +10 |

- Las estibas están tiradas detrás de las bodegas y en el centro, o se le compran a Wilson. Wilson también vende clavos, zinc y una radio vieja.
- Cada nivel se ve distinto en el mapa. El resumen de la noche dice el nivel.

**Minijuegos de plata:**
- **La fuente del centro** (una vez por día, de 7 a 20):
  - Se pescan monedas de deseos con la mano. El agua engaña: se ven corridas de donde están (refracción).
  - El celador se gira ("!"); si te ve agarrando, te echa con la mitad.
  - Unos $3.600 por día.
- **Pedir**, afuera de la panadería o frente a Foto Express (1 hora):
  - Pasan 10 personas y se elige pedir, un chiste, el truco de Lukas o quedarse callado.
  - Cada tipo de persona responde a algo distinto:
    - la pareja, al perrito;
    - el obrero, a que le pidas;
    - el estudiante, a un chiste;
    - con el apurado y la policía, mejor callarse;
    - el de corbata casi nunca da, pero cuando da, da mucho.
  - La segunda vez en el día y el lugar, la compasión rinde la mitad.


## SUEÑO 2: "PLOMO" (shooter tipo Doom), la noche del Día 3

- **Jefe final: Lisandro**, el que lo mandó a matar por envidia. El sueño da vuelta la pesadilla: ahora va él a buscarlo. Fases según la vida:
  - *"—¿Usted? ¿Todavía vivo?"*
  - A los 2/3 llama a dos motorizados: *"—Yo mandé a que lo mataran. Por envidia, sí. ¿Y qué?"*
  - A 1/3 se enfurece: *"—¿Qué tenía usted que no tuviera yo?"*
  - Al morir: *"—La gente lo quería a usted. A mí me tenían miedo. No es lo mismo."*
  - Él contesta: *"Respuesta a su pregunta: tenía amigos. Y un perro. Bueno. El perro todavía lo tengo."*
- **Lilato, mini jefe recurrente**, en la bodega. Tira cuchillos de a tres. *"—Otra vez vos."* / *"—No la vas a ver nunca más."* Al morir suelta la llave de la mansión: *"—Tomá. Ya que te querés ir..."* (la misma frase del primer sueño).
- **Enemigos:**
  - jíbaro: cuchillo, cuerpo a cuerpo;
  - campanero: pita, alerta a todos y huye;
  - motorizado: rápido, dispara de lejos;
  - rappitendero: tira pedidos, es su forma en el sueño.
- **Nivel:** callejón (ladrillo) → calle (grafiti, carros quemados) → bodega (madera) → mansión de Lisandro (oro con su L) → SALIDA.
- **Armas:** puño, pistola y escopeta.
- **Para agarrar:** balas, cartuchos, empanada, aguapanela, chaleco y la llave.
- **HUD de Doom** con la cara del protagonista, que se golpea según la vida y sonríe al agarrar algo bueno.
- **Al morir:** CONTINUE? 9 (reaparece al principio de la zona). Si se acaba la cuenta, se despierta igual: *"Ni en sueños gana. Bueno, ya es costumbre."*
- **Pantalla de resultados:** TIEMPO, BAJAS, *"SECRETOS 0/0 (no hay secretos: el barrio sabe todo)"*.
- **Al despertar:** *"Lisandro. Hace años que no pensaba en él. El cuerpo sí se acuerda."*

**Sueños hasta ahora:** 1 beat 'em up (Lilato, jefe final), 2 shooter (Lisandro; Lilato, mini jefe).


## Habilidades (se aprenden soñando, sirven en los dos mundos)

Cada sueño terminado deja una habilidad. Son 4 en los primeros niveles y después 3 más (7 en total).

| # | Habilidad | Se aprende en | Vida real | Sueños |
|---|---|---|---|---|
| 1 | Aguante | Sueño 1 (beat 'em up, prólogo) | el desprecio baja la mitad de ánimo | +25% de vida en el beat 'em up, -20% de daño en PLOMO |
| 2 | Sangre fría | Sueño 2 (PLOMO 1) | +50% de tiempo con los colados; el celador de la fuente avisa antes | la mitad de dispersión y +15% de daño |
| 3 | Labia | Sueño 3 (beat 'em up 2) | +15% al pedir y en los chistes; todo 10% más barato | los jefes de PLOMO atacan más despacio |
| 4 | Rebusque | Sueño 4 (PLOMO 2, por hacer) | latas y botellas +50%; Lukas olfatea más lejos | los enemigos sueltan más cosas |
| 5 | Cocinero de calle | por definir | lo cocinado llena más | la comida cura el doble |
| 6 | Paso firme | por definir | caminás más rápido, el hambre frena menos | te movés más rápido |
| 7 | Lazo con Lukas | por definir | Lukas encuentra más; su compañía da más ánimo | — |

**Cómo se ven:**
- La del primer sueño aparece como aviso en el HUD al despertar el Día 1.
- Las demás aparecen en la noche, al despertar: *"Algo aprendió en el sueño. HABILIDAD: ..."*.
- En el Tab, abajo de la mochila: *"HAB: Aguante, Sangre fría..."*.

## Los sueños son series (cada una retoma donde quedó)

| Noche | Sueño | Serie | Episodio | Jefes |
|---|---|---|---|---|
| prólogo | 1 | Beat 'em up | 1 | El Tuerto, Lilato → la serpiente |
| Día 3 | 2 | PLOMO | 1 | Lilato (mini), Lisandro |
| Día 5 | 3 | Beat 'em up | 2 | Camila y Guillermo |
| (por hacer) | 4 | PLOMO | 2: "La Empresa" | José Mario Camilo |
| (por hacer) | 5 | Beat 'em up | 3: la terminal | Brenda |
| (por hacer) | 6 | PLOMO | 3: Clínica Eiren | (Zaida, ambigua) |

**Beat 'em up, episodio 2 (sueño 3):**
- *"ANTERIORMENTE... La serpiente cayó al río. Y él cayó con ella."*
- Empieza en la madriguera de la serpiente (con la piel mudada en el piso) y sale a la calle de los traidores:
  - la compraventa con las cosas de Guillermo en la vitrina (guitarra, tele, la foto de los amigos);
  - el bar El Parche;
  - un grafiti "C+G" tachado.
- **Camila y Guillermo pelean juntos.** Camila pega y se aleja; si le pegan, Guillermo embiste para defenderla.
  - Si cae Camila primero, Guillermo se rinde: *"—¿Y ahora qué hago? Ella decidía todo."* Se elige **perdonarlo** (*"—Yo también lo quería, hermano. Por eso dolió."*) o terminar la pelea.
  - Si cae Guillermo primero, Camila se va riéndose: *"—Igual ya no me servía."* Queda `dream_camila_escaped`, para que vuelva más adelante.
- **Final:** la terminal y un bus a IBAGUÉ: *"Alguien se sube sin mirar atrás. Camina igual que él."* (adelanta el episodio de Brenda).


## La serie PLOMO crece con él

- **PLOMO 1** (niño, unos diez años): demonios de dibujo infantil, paredes de crayón, estrellas y luna con cara, mano con manga de rayas, y la cara del HUD con curitas y lágrimas en vez de sangre.
  - Lilato con cuernitos; Lisandro como un gran diablo rojo de traje blanco.
  - *"Respuesta a su pregunta: tenía amigos. Y un perro. Bueno, todavía no tengo perro: tengo diez años."*
- **PLOMO 2: "La Empresa"** (adulto).
  - *"La SALIDA de la mansión no daba a la calle. Daba a una oficina. Ahora tiene treinta y pico, corbata..."*
  - Enemigos: oficinistas que tiran tazas, guardas y Recursos Humanos (*"¡Voy a reportar esto!"*).
  - Mini jefa: Recursos Humanos, que tiene la tarjeta de acceso.
  - Jefe: **José Mario Camilo**, que tira chismes. *"—Yo solo conté la verdad. ¿O no consumía?"* / *"—Usted no era el problema. Yo necesitaba uno."*
  - Al final, la salida da a un pasillo blanco que huele a hospital.
- **PLOMO 3: "Clínica Eiren"**.
  - Enemigos: enfermeros con jeringa, archivistas que tiran papeles y guardas.
  - Mini jefa: Lilato (*"Tomá la llave. Ya que ahora te querés curar..."*).
  - Jefe: **El Expediente**, un monstruo hecho de su historia clínica (*"Datos: compartidos. Con una tal Zaida."*). Él le contesta: *"No soy un expediente. Soy un tipo con un perro."*
  - **Zaida** aparece en el pasillo sin pelear (te da balas: *"Yo ya leí tu expediente. Todo."*) y te espera en la SALIDA: creerle o no (`flags.zaida_trust`).

---

## CONFIRMADO: misiones de la vida real, habilidades y ritmo de los sueños

### 1. Favores: "ayudame a encontrar algo", "hacé esto por mí"
Cada persona del barrio tiene un **vínculo** (0 a 3). Los favores lo suben, y cada nivel abre algo concreto en la vida real.

| Persona | Favores (ejemplos) | Lo que abre el vínculo |
|---|---|---|
| Don Germán | "Se me cayó el anillo de matrimonio en la bodega" (lo encuentra Lukas). "Llevale pan a la señora del 4B, que no puede salir." | pan del día gratis; te guarda cosas; dirección y trabajo en la obra |
| Marta | "Se me perdió el gato" (Lukas). "Llevale el almuerzo a mi hijo al colegio." | te fía; te deja usar el baño del café |
| Wilson | "Juntame 10 botellas, que tengo un pedido grande." "Se llevaron mi carreta: ayudame a recuperarla." | mejores precios; materiales raros (zinc, radio) |
| Samuel | "Ayudame a escribirle una carta a mi hija" (él no sabe escribir: usa la libreta, y es un espejo de Victoria). "Acompañame a cobrar lo de la pensión." | te avisa de las redadas; te enseña lugares para dormir |
| Doña Rosa | "Cuidame el puesto una hora" (minijuego de vender empanadas). | fiado; almuerzo los domingos |

Tipos de favor: **encontrar** (con el olfato de Lukas), **llevar** (mandados), **conseguir** (juntar o fabricar), **acompañar** (pasar tiempo) y **ayudar con alguien** (diálogos).

### 2. Para qué sirven las habilidades
Además de su efecto pasivo, cada habilidad **abre opciones de diálogo marcadas** (tipo *[LABIA]*) y algunos caminos:
- **Aguante:** aguantar la fila larga sin irse; seguir pidiendo con el ánimo bajo.
- **Sangre fría:** los minijuegos de reacción (fila, fuente y, más adelante, escapar de la policía).
- **Labia:** convencer (que Marta te fíe, que el celador te deje pasar, negociar con la abogada).
- **Rebusque:** chatarra de valor para empeñar; materiales raros.
- **Lazo con Lukas:** trucos nuevos de Lukas para pedir; de noche avisa de los ladrones (menos robos).
- **Cocinero de calle:** recetas que se pueden vender (sancocho en el puesto de Rosa).
- **Paso firme:** llegar a tiempo a los trabajos con horario (la obra).

### 3. Cuándo van los sueños: por hechos de la historia, no por días fijos
Un sueño **después de lo que lo sacude** (como mucho uno cada dos noches):

| Sueño | Se sueña la noche... | Por qué |
|---|---|---|
| Beat 'em up 1 (Lilato) | antes del Día 1 (prólogo) | ya está |
| PLOMO 1, de niño (Lisandro) | del día que empieza el trámite de la cédula | volver a "existir" despierta al que lo quiso borrar |
| Beat 'em up 2 (Camila y Guillermo) | del día que recoge la cédula | ahora que existe en papeles, aparecen los que lo traicionaron |
| PLOMO 2 (José Mario) | del primer día en la obra | el miedo a que se repita lo de la empresa |
| PLOMO 3 (Clínica, Zaida) | después de la primera cita de salud mental (la libreta) | la clínica que filtró sus datos |
| Beat 'em up 3 (Brenda) | del día que intenta llamar a su mamá | el bus a Ibagué |

Por ahora están puestos de forma **provisoria** en los días 3, 5, 7 y 9 (`NightSequence.DREAMS`).


## Favores hechos (nivel 1 de cada vínculo) y los hilos de mal rollo

| Favor | Cómo | Giro | Abre (vínculo 1) |
|---|---|---|---|
| **Germán: el anillo** (desde el Día 4) | Se le cayó detrás de las bodegas; lo encuentra Lukas (F → Buscá). | *"Era de Mercedes. Mi señora. Hace seis años que se fue... Ella decía que el pan sale mejor si uno lo amasa con algo que quiere puesto."* | **Pan del día** gratis, todos los días |
| **Marta: Michi, el gato** (desde el Día 3) | Lukas encuentra el collar frente a **la casa de tejas** (la del pedido, la que nunca abre). | La puerta se abre una rendija, una mano muy blanca empuja al gato afuera: *"—Ya no lo necesito."* Marta cuenta que ahí no vive nadie: Doña Inés murió en 2019, la encontraron a los tres días, y los pedidos siguen llegando por la app, pagados, a nombre de ella. | Te deja usar el **baño del café** (aunque estés sucio) |
| **Samuel: la carta** (desde el Día 4) | Él no sabe escribir: elegís las frases (empieza / qué le dice / cómo termina) y la llevás a la casa del fondo, al este. | La hija, Diana, se fue hace años: *"Dígale que ella lo esperó. Mucho tiempo. Después ya no."* Le mentís (*"Se parece a usted." / "Pobrecita."*) o le decís la verdad (*"Guárdela usted. Algún día tal vez tenga a quién dársela"*: te quedás con la carta). Él cierra: *"Victoria. Yo no voy a esperar once años."* | Te avisa de la gente rara: **-30% de robos** |
| **Rosa: el puesto** (desde el Día 3, de 8 a 16) | Minijuego: despachar empanadas, arepas y aguapanela a tiempo (izquierda, arriba, derecha). | A la mitad llega **el señor de negro**: *"Dígale que esta semana son cincuenta."* Lukas le gruñe como nunca. Con **[SANGRE FRÍA]** lo mirás a los ojos. Rosa: *"La semana pasada eran treinta... Aquí el que cuenta, no cuenta más."* | **Fiado**: una empanada por día si no tenés plata |

**Hilos que quedan abiertos** (para el mal rollo de más adelante):
- Quién vive en la casa de tejas (`casa_tejas_misterio`).
- La extorsión en el barrio (`vacuna_rosa`).
- La carta de Samuel que quedó sin dueño (`samuel_mentira` / la carta en la mochila).
- Zaida (`zaida_trust`).

**Opciones de habilidad hechas:**
- **[LABIA]:** el celador te deja pasar casi primero (*"Diga que es mi sobrino"*), Marta te fía un tinto por día y la pensión te la deja en $12.000.
- **[SANGRE FRÍA]:** mirar a los ojos al señor de negro.
- **Lazo con Lukas:** -40% de robos de noche.

**Sueños por hechos** (`NightSequence._dream_when`, como mucho uno cada 2 noches):
- PLOMO 1 cuando empieza el trámite de la cédula.
- Beat 'em up 2 cuando ya tiene la cédula.
- PLOMO 2 cuando Germán le consigue la obra.
- PLOMO 3, por ahora, después de PLOMO 2 (hasta que exista la cita de salud mental).


## Dificultad que sube de a poco (y las habilidades la alivian, sin volverla fácil)

`GameState.difficulty()` vale 0 en los Días 1 y 2, y llega a 1 cerca del Día 12. Cada área tiene su dificultad (`diff(área)`), y la habilidad que le corresponde la baja un 40%.

| Área | Qué se pone difícil (al máximo) | La alivia |
|---|---|---|
| buscar | hasta 45% de lo tirado no aparece ese día; hasta 65% está escondido (solo con Lukas); Wilson paga 30% menos | Rebusque |
| olfato | Lukas olfatea hasta 40% más cerca y descansa el doble | Lazo con Lukas |
| hambre | el hambre baja hasta 40% más rápido; la noche cuesta 30% más | Cocinero de calle |
| cuerpo | la suciedad sube hasta 50% más rápido | Paso firme |
| precios | hasta +25% ("la inflación también llega a la calle") | Labia |
| robos | hasta +60% de chance | Lazo con Lukas |
| social | más desprecio de la gente (+20%) y duele 50% más | Aguante |
| reflejos | fila más larga y menos tiempo con los colados; el celador de la fuente avisa menos y mira más; en el puesto la gente tiene menos paciencia | Sangre fría |
| pedir | la gente da hasta 35% menos | Labia |

En los sueños, cada episodio pega más: PLOMO 2 (+30% de vida y +15% de daño de los enemigos), PLOMO 3 (+60% y +30%), beat 'em up 2 (+25% de vida).

Medición en la ciudad (objetos que no son de favores): Día 1: 16 visibles y 3 escondidos. Día 6: 12, 6 y 3 que no aparecen. Día 12: 4, 10 y 7. Día 12 con Rebusque: 9, 7 y 5.

## Guardar: solo en los cuencos de agua de Lukas

- Hay cuencos con agua en cuatro lugares: al lado de la panadería, bajo el puente, en el parque y en la plazoleta del centro (*"Alguien lo llena para los perros de la calle"*).
- Lukas toma agua y ahí se puede guardar: *"PARTIDA GUARDADA. Lo único que guardo en la vida, y es esto."*
- **Sed:** desde el Día 2, si a las 14:00 Lukas todavía no tomó agua, jadea, y al olfatear falla el 40% de las veces (*"Con sed no huele nada"*). Misión diaria: "Dale agua a Lukas".
- **Título nuevo** (escena inicial): CONTINUAR, si hay partida guardada (vuelve al cuenco, con el día y la hora), o NUEVA PARTIDA (el sueño 1).


### Dónde se gana cada habilidad (actualizado)

| Sueño | Habilidad |
|---|---|
| 1, beat 'em up (Lilato) | Aguante |
| 2, PLOMO 1 (Lisandro) | Sangre fría |
| 3, beat 'em up 2 (Camila y Guillermo) | Labia |
| 4, PLOMO 2 (José Mario) | Rebusque |
| 5, PLOMO 3 (Clínica Eiren) | Lazo con Lukas |
| 6, beat 'em up 3 (Brenda) **— por hacer** | **Cocinero de calle**: la mamá se fue y aprendió a cocinarse solo |
| 7, el sueño de Mauricio **— por hacer** | **Paso firme**: el papá se fue cuando él tenía 15 y aprendió a caminar solo |


## SUEÑO 6: beat 'em up, episodio 3 (Brenda)
- Retoma desde el bus a Ibagué: la terminal (taquillas, un reloj) → adentro del bus (*"PROHIBIDO HABLAR CON EL CONDUCTOR"*) → Ibagué, ciudad musical (palos de mango) → la casa de ella, con la puerta entreabierta.
- Los enemigos tienen +50% de vida y +1 de daño.
- **Brenda no pelea: se escapa.** Si él se acerca, corre para el otro lado (dentro de la pantalla). De lejos le tira **maletas**. Acorralada, empuja.
  - *"—¡No me siga! ¡Váyase!"*
  - *"—Yo no podía quedarme. Me iban a matar a mí también."*
  - *"—Usted ya era grande. Yo pensé que usted podía solo."*
- **Al alcanzarla**, ella se sienta: *"—Yo me fui porque tenía miedo. Usted también tenía miedo, y se quedó."*
  - **Abrazarla:** *"Huele a la misma crema de cuando él era chiquito."* / *"—No era fuerte, ma. No me quedaba otra."*
  - **Dejarla ir:** *"—Váyase, ma. Ya sé el camino a la terminal."*
  - Queda guardado en `flags.dream_brenda`.
- **Final:** una olla de sopa en el fogón; él se sirve solo. Habilidad: **Cocinero de calle**.

## SUEÑO 7: boxeo contra Mauricio (tipo Punch-Out!!)
- Él tiene **15 años** (cuando Mauricio se fue). Ring en un garaje, "VELADA DE DOMINGO". Mauricio sube con **chaleco de motociclista** (le gustaban las motos).
- **Controles:** izquierda y derecha esquivan, abajo cubre, E pega, arriba + E pega fuerte.
- **Mauricio avisa sus golpes:**
  - jab: se esquiva o se cubre;
  - gancho izquierdo o derecho: hay que esquivar hacia el lado contrario;
  - **"la promesa"** (*"—El domingo voy. Se lo juro."*): un uppercut que no se puede cubrir.
- **Cuando miente** (*"Yo los veo todos los domingos"*, *"Su mamá me alejó"*, *"Le mandaba plata"*), el público abuchea **al chico** (le creen a él), pero Mauricio queda abierto: el **contragolpe pega doble**.
- **Corazones:** se gastan al pegarle a la guardia y al recibir golpes. Sin corazones, el chico se cansa.
- **Caídas:** tres caídas de Mauricio son nocaut. Si el que cae es el chico, hay que apretar E rápido para levantarse.
- En la esquina, Lukas con una toalla (*"No tiene sentido. Es perfecto."*).
- **Tres rounds.** Si se llega a los puntos, **gana Mauricio**: *"El jurado le creyó. Como todos."* Eso empuja a buscar el nocaut.
- **Nocaut:** *"—Yo... los veía. Desde lejos. Los domingos." / "—Ya sé, pa. Desde lejos." / "Él se baja del ring solo. Camina derecho. Por primera vez, sin mirar atrás."*
- Habilidad: **Paso firme**.

Los sueños 6 y 7 se disparan con hechos de la vida real (ver "La familia").


## La familia: los hechos que disparan los sueños 6 y 7 (sin chistes)

**La llamada a la mamá → sueño 6 (Brenda).**
- Aparece después de ayudar a Samuel con la carta (o desde el Día 8): *"Samuel esperó once años una carta. Yo tengo un número de memoria. Y un teléfono en la plaza."*
- Teléfono público al lado del paradero de la plaza; la llamada cuesta $500.
- *"(Tuuu... tuuu...) / —¿Aló? ¿Quién es?"*
  - **Hablar:** *"—Ma. Soy yo." / "—¿Está bien? ¿Está comiendo?" / "—Sí. Más o menos. Tengo un perro." / "—Mijo... no me llame a este número. Aquí no saben de usted. Aquí estoy empezando otra vez."*
  - **Colgar:** *"—¿Es usted? ... Si es usted... yo..."*, y él cuelga antes del final.
- Ánimo -8. Queda en `flags.llamada_mama`.

**Mauricio en la plaza → sueño 7 (boxeo).**
- Un día después del sueño de Brenda, de 9 a 17: una moto grande parqueada al lado del puesto de Rosa, y un señor con chaleco de cuero.
- **No lo reconoce.** *"—¿Qué me mira, joven? ¿Tiene hambre? Tome. Pa' un tinto."* (le da $1.000)
  - **Decirle quién es:** *"—Pa. Soy yo." / "—No, joven. Se confundió. Yo tengo dos hijos y están muy bien. Los veo todos los domingos."*
  - **Callar:** *"—Con gusto. Y ese perro, cuídelo, que es buen perro."*
- Se va en la moto, que *"suena igual que hace quince años, cuando se fue"*.
- Ánimo -10. Queda en `flags.papa_respuesta`.

Además: cuando empieza un diálogo, el narrador se calla, para que no se mezclen los textos.


## SUEÑO 7 ahora es un TORNEO de boxeo (para llegar a Mauricio)
Cada amigo de Mauricio, sin querer, cuenta una verdad sobre él. Entre peleas, los piques con Mauricio desde el costado del ring.

| Pelea | Rival | Cómo pelea | La verdad que se le escapa |
|---|---|---|---|
| 1 | **Raúl**, "el compadre" | grande y lento; ganchos pesados; toma aguardiente en pleno round | *"Su papá es un berraco, mijo. Usted no le llega."* |
| 2 | **Alvarito**, "el de las motos" | rápido; dobles jabs | *"Los domingos no iba a verlos, mijo. Venía a mi taller."* |
| 3 | **El Pecas** | finta (amaga; si esquivás antes, te remata); uppercuts | *"Mauricio me enseñó a boxear a mí. A mí sí."* |
| Final | **Mauricio** | 3 rounds y 3 caídas. **Fase 2**, desde la segunda caída: se saca el chaleco, va más rápido, pega "la arrancada" (dos ganchos seguidos) y **deja de mentir** | fase 1: *"Los veo todos los domingos"*; fase 2: *"Me fui porque no sabía ser papá. Y no aprendí."* |

- **Los amigos:** un round y dos caídas. A los puntos gana el que pegó más.
- **Mauricio:** a los puntos gana él (*"El jurado le creyó"*).
- **Si perdés una pelea:** revancha o despertarse.
- **Final:** *"Los veía desde lejos. Desde el taller de Alvarito." / "—Ya sé, pa. Desde lejos." / Raúl, Alvarito y el Pecas se miran; nadie aplaude.*
- Un bot que reacciona perfecto gana el torneo, pero contra Mauricio llega al segundo round y termina con 4 de vida.


### Los rivales del torneo (corregido): los amigos de trago de Mauricio

| Rival | Quién es | Cómo se ve y cómo pelea | Lo que deja escapar |
|---|---|---|---|
| **Raúl** | el primer borracho, el que tiene plata | camisa amarilla, cadena de oro; ganchos pesados; toma aguardiente en pleno round | *"Con lo que me gasto en trago le pago la vida a usted. Y no lo hago."* |
| **Alvarito** | el segundo borracho, de gran corazón | cara buena; pega poco y casi sin ganas | *"Su papá hablaba de ustedes. Borracho, pero hablaba."*; al final: *"Los quería. A su manera. Una manera muy mala, pero los quería."* |
| **El Pecas** | el tercer borracho, el de las motos, lambón con Mauricio | chaqueta de cuero; finta | *"¡Lo que usted diga, don Mauricio!"* / *"Los domingos salíamos en moto. Él y yo. A Melgar."* |
| **Mauricio** | motos y trago | **bajito y ancho**, chaleco | fase 2: *"Ya no más chaleco. Ya no más trago."* / *"Tomaba para no pensar en ustedes. Y funcionaba. Eso es lo peor."* |

- **Están borrachos:** se tambalean y los tiempos de sus golpes cambian al azar (más los primeros, menos Mauricio). En la fase 2, a Mauricio se le pasa la borrachera y pelea serio.
- **Final:** *"Los veía desde la moto, con el Pecas."* Raúl pide otra ronda, el Pecas mira para otro lado y **Alvarito es el único que aplaude, despacio**.


## El mapa de las series (un minijuego por "bache")

| Serie | Género | Con quién |
|---|---|---|
| Beat 'em up | pelea de calle | Lilato (prólogo) → **Brenda**. Su segunda fase es **"La de mil caras"**: es mentirosa, así que se transforma en gente que él quiere (Germán, Rosa, Lukas) para engañarlo. Hay que encontrar la verdadera, y las copias atacan. |
| **Carreras** | motos pseudo-3D | Camila → Guillermo → los dos juntos (+ mano a mano con Guillermo) → Diana Carolina |
| PLOMO | shooter | Lisandro. Se juega siendo él, el dealer, y al final se cambian los papeles. |
| Sigilo | infiltración | Walter, Nicolás y Eddy, y al final José Mario |
| Boxeo | Punch-Out | Mauricio |

## Serie CARRERAS (hecha)

La historia: Camila lo buscó en una fiesta de Guillermo y él le dijo que no. Furiosa, le contó a Guillermo al revés, y Guillermo le creyó.

- **Ep. 1, Camila.** Empieza con la escena de la fiesta, donde él la rechaza con dos opciones de respuesta, las dos con chiste. En la carrera, ella va **de copiloto en la moto de otro**, tirándole zapatos.
- **Ep. 2, Guillermo.** Llega furioso: "¿CON MI MUJER?". Va **en camioneta**, y Camila va en el platón tirando bolsos.
- **Ep. 3, los dos en moto.** "La camioneta era lenta, por eso nos ganó." Al ganar viene una **pelea a mano limpia con Guillermo** (beat 'em up). Desde el piso, él por fin escucha la verdad... y se va con ella igual. Queda `flags.guillermo_sabe`.
- **Ep. 4, Diana Carolina.** No es una carrera: es una huida de la policía y del ejército, con retenes, camiones y patrullas. Si lo alcanzan tres veces, lo atrapan. Al final está el río, y ella en la orilla con el celular todavía prendido.
- **Segundas fases**, desde la mitad de la pista:
  - Camila se vuelve **La Devoradora**: se infla, tira carteras y estira los brazos hacia un carril. Antes avisa con "¡BRAZOS! IZQ/CENTRO/DER", y si lo agarra lo frena.
  - Guillermo se vuelve **el marrano con gafas y cadenas de oro**, que tira cadenas de oro al camino.
- **Dificultad:** los rivales van pegados a él (si se queda atrás lo pasan, si se alejan aflojan). En la recta final, el último 12%, no hay ayuda: gana el que no se cayó. Si pierde, puede pedir revancha o despertarse.
- **Cuándo se sueñan:**
  - Ep. 1: con la cédula. Reemplaza a callejon2 y enseña Labia.
  - Ep. 2 a 4: provisoriamente, tres días después del anterior de la serie.
  - Los sueños ahora se numeran solos, y cada serie va a su ritmo: se sueña el primero cuyo hecho ya pasó.
- **Textos:** en las carreras, el narrador va arriba de todo (no tapa la calle) y el HUD está en dos líneas cortas. En las peleas, el narrador también va arriba (antes tapaba a los peleadores).

## Camino latente: la carretera (anotado, sin hacer)

En cualquier momento puede tirar todo a la mierda: agarrar una moto o un carro e irse por carretera. Conoce otra gente y quizás es feliz. Pero eso es **olvidar a su hija y rendirse**: es un final, no una ruta más. La tentación tiene que aparecer en los peores momentos (como una moto con las llaves puestas, o un camionero que ofrece llevarlo), y el juego tiene que hacer que se sienta como una salida real y bonita. Ahí está lo que duele.

## PLOMO: EL DEALER (hecho)

- **Se juega siendo Lisandro**, en el mismo barrio de crayón del episodio 1, pero de noche y con los dibujos del niño tachados en rojo.
  - Es poderoso: 200 de vida, ×1.5 de daño y las tres armas desde el principio (pistola y escopeta de oro, manos con anillos).
- **Lo que se recoge son drogas:**
  - **La bolsita** se la toma siempre, aunque tenga la vida llena. Le da 7 s de "subida": camina ×1.45, hace ×3 de daño y la pantalla cambia de color. Después vienen 3 s de bajón: lento, con poco daño y la pantalla gris.
  - **Las pepas** curan.
  - **El maletín de plata** es la armadura.
- **Enemigos (como los ve él):** tombos, sapos (que pitan y avisan), dealers rivales con cachos y motorizados. El mini jefe es **el Coronel**, que tiene la llave ("Usted me debe este mes").
- **El jefe: "El que no se muere"**, el protagonista con armadura verde y visor (tipo Doom Slayer) y la correa de Lukas en el cinturón.
- **El giro:** cuando al que no se muere le queda un cuarto de vida, se cambian los papeles.
  - Se intercambian de lugar. Ahora uno es él, con armadura, escopeta, 100 de vida y 100 de chaleco, y Lisandro es el jefe.
  - Las bolsitas que quedaban se vuelven empanadas.
  - A los 2/3 de vida, Lisandro llama a **Camila (La Devoradora, que tira bolsos en abanico) y a Guillermo (el marrano, que tira cadenas)**.
  - A 1/3 aparece **Lilato**: "Vine en el peor momento. Siempre vengo en el peor momento."
- **Cuándo se sueña:** dos días después de la Carrera 3. Por ahora no enseña habilidad.


## Tono (corrección del 2026-10-04): humor negro, no infantil

Él solo está sobreviviendo y **se está volviendo loco sin saberlo**. Los chistes son secos y oscuros, sin juegos de palabras tiernos. La locura no se nombra nunca: se nota en lo que él cuenta como normal (un santo le contesta, las baldosas cambian, la muñeca opina) y en cómo reacciona la gente (la señora que se cambia de banca).

- **Contador escondido:** `flags.locura`, que lee `GameState.locura_level()`: 0 está bien, 1 está raro, 2 ya habla con las cosas.
  - Sube al perder el tiempo (banca, palomas, música, iglesia) y con los cachivaches de Don Efraín.
  - Falta: que suba con lo violento (cuando exista PLOMO en la vida real).
- **Ya reescrito con este tono:** las descripciones de la comida y los materiales, y algunas líneas de las carreras y del dealer.
- **Pendiente:** una pasada por los diálogos viejos de Conversations.

## Menú SUEÑOS (título)

Cada minijuego se puede jugar suelto desde el título:
- callejón de Lilato
- PLOMO 1, Dealer, 2 y 3
- Carreras 1 a 4
- mano a mano con Guillermo
- Brenda
- el torneo de Mauricio
- el recuerdo de la Renegade

Arranca una partida limpia con `flags.arcade`. Cuando el sueño termina (va a Night o a City), `SceneRouter.go` lo manda de vuelta al título.

## El Parque de San Judas (nuevo lugar)

El lugar **menos lúgubre** del juego: pasto verde, árboles con hojas, una iglesia de tejas, una glorieta y gente que saluda. Se llega en bus desde el barrio o el centro: todos los paraderos llevan a los otros dos ($2.500, o una hora caminando).

**Ganar plata ayudando** (cada trabajo una vez por día):

| Quién | Qué | Horario | Paga |
|---|---|---|---|
| Padre Hernando (iglesia) | barrer el atrio y limpiar las bancas, 2 h | 7-12 | $6.000 + pan |
| Doña Fabiola (olla comunitaria) | ayudar a servir, 1 h | 11-14 | $3.000 + plato (también se puede pedir un plato gratis) |
| Don Aurelio (tienda La Esperanza) | descargar el camión, 2 h (1,5 con Paso Firme) | 7-11 | $8.000 |
| Doña Leonor (flores) | hacer ramos, 1 h | 8-18 | $3.000 (también vende una flor, $1.000) |
| Don Efraín (cachivaches) | cuidarle el puesto, 2 h | todo el día | $4.000 + una rareza |

**Perder el tiempo** (sube el ánimo y la locura):
- **El Mono en la glorieta:** escuchar 1 h, o darle $500.
- **Las palomas:** mirarlas, o darles pan.
- **El ajedrez de Don Octavio y Don Ramiro:** mirar, o apostar $1.000.
- **Las bancas:** sentarse 1 h.
- **La iglesia:** sentarse 1 h, o prender una vela por Victoria ($500).
- **Pedir** en las gradas de la iglesia.
- **Agua para Lukas** (cuenco 5, donde se guarda la partida).

**Las rarezas de Don Efraín:** reloj sin agujas, estampita de San Judas, muñeca sin un ojo (Gloria), dentadura postiza y casete de boleros. Al usarlas, "le hablan", y lo que dicen depende de la locura.


### Pasada de tono a los diálogos viejos (hecha)

**Regla: que no dé lástima, que sea interesante.** Él nunca pide compasión ni se queja de sí mismo. Es alguien que:
- lee a la gente,
- vigila (duerme con un ojo, revisa la puerta tres veces),
- tiene un pasado que asoma sin explicarse (el olor a hospital, la mano que busca un arma),
- y tiene una calma rara que a veces se le quiebra (no se acuerda si la caja estaba vacía).

Se sacaron la autocompasión ("como mi agenda", "propina por existir", "mi dignidad doblada") y los chistes de videojuego infantiles ("pollo asado en un barril", "rutina de skincare").

Se revisaron las conversaciones del barrio y del centro, el cambuche, pedir, el puesto de Rosa, Lukas, la noche, el hambre y los robos.


## Calendario de sueños (simulado en una partida típica)

| Día | Sueño | Lo dispara |
|---|---|---|
| 3 | PLOMO 1 (el niño) | se abre el centro (Germán) |
| 6 | Carrera 1 (Camila) | la cédula |
| 8 | PLOMO 2 (la empresa) | la obra lista |
| 10 | Brenda | la llamada a la mamá |
| 12 | Torneo de Mauricio | el papá en la plaza |
| 14 | Carrera 2 (Guillermo) | serie |
| 16 | PLOMO 3 (la clínica) | serie |
| 18 | Carrera 3 + mano a mano | serie |
| 20 | PLOMO: el dealer | serie |
| 22 | Carrera 4 (Diana Carolina) | serie |
| 23-30 | **libre**: sigilo (José Mario), final de Lilato, el cumpleaños de Victoria (día 30) | por hacer |

- Los sueños que dispara un hecho real (`EVENT_DREAMS`) tienen prioridad: se sueñan la primera noche libre. Siempre hay como mínimo dos noches entre sueños.
- **Reloj:** 1,8 minutos de juego por segundo real (antes 1,5). Un día dura unos 8 minutos y medio.


## Calendario reordenado (2026-10-04, reemplaza al anterior)

Sale PLOMO del niño. La Empresa pasa al sigilo y la clínica sale del calendario.

| Día (partida típica) | Sueño | Estado |
|---|---|---|
| 3 | PLOMO 1: La esquina (Lisandro) | hecho |
| 5 | PLOMO 2: La cocina (lo dispara algo violento: el señor de negro o un ladrón en el cambuche) | hecho |
| 7 | Carrera 1: Camila | hecho |
| ~8 | Sigilo 1: Walter | por hacer |
| 9 | Brenda (un solo sueño largo, con "la de mil caras") | por rediseñar |
| 11-14 | Torneo, una pelea por noche y con gancho: Raúl, Alvarito, el Pecas, Mauricio | hecho como boxeo; **pasa a lucha libre estilo WWE/Raw** |
| 16 | Carrera 2: Guillermo | hecho |
| ~17 | Sigilo 2: Nicolás | por hacer |
| 19 | Carrera 3 + mano a mano con Guillermo | hecho |
| ~20 | Sigilo 3: Eddy | por hacer |
| 21 | PLOMO 3: El que no se muere (la pelea bien Doom: plasma, refuerzos, el giro) | hecho |
| 23 | Carrera 4: Diana Carolina | hecho |
| ~25 | Sigilo 4: José Mario | por hacer |
| 26-28 | Final de Lilato | por diseñar |
| 30 | El cumpleaños de Victoria | por diseñar |

- Entre sueños hay como mínimo una noche libre. La excepción es el torneo, que va en noches seguidas (`CHAIN_DREAMS`) para dejar al jugador con expectativa.
- Si pierde una pelea del torneo, la revancha vuelve otra noche y el torneo no avanza sin ella.

## El cambuche: dormir y protegerlo

- **Dormir:** se puede dormir en el cambuche cualquier noche (de 19 a 5), sin esperar la misión.
- **Trampas** (se ponen con Mejorar):
  - Alarma de latas: 2 latas + cuerda.
  - Tabla con clavos: estiba + clavos.
- **Lukas de guardia:** si ese día comió y tomó agua (o con Lazo con Lukas).
- **Samuel lo cuida una noche** a cambio de comida (opción en su diálogo).
- **Defenderlo de noche:**
  - A veces llega un ladrón mientras duerme ahí: tres reacciones rápidas (la flecha que diga, en rojo).
  - La alarma y Samuel dan más tiempo, y Lukas de guardia gana la primera.
  - Con dos de tres lo espanta (con la trampa, "ese no vuelve"); si no, le roban.
  - Las protecciones bajan la chance de que llegue alguien.
  - Cualquier robo o pelea cuenta como algo violento (`flags.violencia`) y despierta a PLOMO 2.

## Coleccionable: los pedazos de la foto (uno solo, 7 pedazos)

- **Dónde están:** 4 en el barrio (uno lo encuentra solo Lukas), 1 en el centro y 2 en el Parque (uno con Lukas).
- **Comportamiento:**
  - Una vez agarrado, no vuelve nunca.
  - No se pierde ni se lo roban.
  - Cada pedazo trae una frase que acerca la revelación (n/7).
- **Al juntar los 7:** arma la foto con cinta y se ve la cara: es **Mauricio**, joven y riéndose, y la letra de atrás es la de él. Queda `flags.foto_armada` (para usar en la final del torneo).


## "Es él": cómo lo ve la gente

- **Los extraños** casi siempre lo reconocen: *"Mírelo. Es él."*, *"No lo mire. Dicen que fue él."*, *"Pobre la niña."*, o se persignan.
  - Lo dicen con asco y con lástima, pero nunca explican nada.
  - **Él no sabe por qué**, porque nadie se lo dijo nunca, y el jugador tampoco lo sabe. Él se queda pensando: *"¿Él quién? Me doy vuelta. Detrás no hay nadie."*
  - Baja el ánimo y a veces sube la locura.
  - **Es un misterio a revelar más adelante.**
- **Los que lo conocen** (Germán, Marta, Rosa, Wilson, Samuel, el Padre, Fabiola, Aurelio, Leonor, Efraín y el Mono) lo quieren. Una vez por día le dicen algo propio:
  - le avisan de un peligro (la policía, el de negro, alguien rondando el cambuche),
  - le siguen el humor negro,
  - o le dicen que no haga caso de lo que dice la calle, sin preguntarle nada.

Código: `Passerby.WHISPERS` y `WHISPER_REPLIES`; `Conversations.FRIEND_LINES` y `_friend(id)`.


## Torneo de lucha libre: "RAW DE DOMINGO" (reemplaza al boxeo)

Es un sueño por pelea, en noches seguidas, con "anteriormente" y "continúa el próximo domingo". Pasa en el coliseo del barrio: público, pantalla gigante y foco. El árbitro es **Lukas**, vestido de juez (camiseta a rayas, corbatín y pito), que cuenta con la pata. Comentan **Don Tito y La Mona**, con humor negro de transmisión.

**Controles:**
- Flechas: moverse.
- E: golpear.
- X cerca del rival: agarre. Se gana machacando E, y con las flechas se elige la llave: ← suplex, → lanzarlo a las cuerdas (E al volver: clothesline), ↑ DDT, ↓ slam. Con la barra del especial llena, ↑ hace **EL PORTAZO**.
- X lejos del rival: correr a las cuerdas; E en carrera: clothesline.
- X sobre el rival caído: la cuenta.
- En la esquina, con el rival en el piso: ↑ sube, E salta.
- F: provocar al público, que llena el especial.
- Cuando te están contando: machacar E para levantarte.

**Primera pelea = tutorial.** Lukas levanta un cartel con cada mecánica y espera a que el jugador la haga: golpe, provocar, clothesline, agarre con llave, cuenta y salto desde la esquina. Después Raúl muestra lo suyo (no se deja levantar y aplica el chokeslam) y el jugador tiene que levantarse de la cuenta. Después empieza la pelea en serio. Queda `flags.lucha_tutorial`, así que no se repite en la revancha.

**Los rivales.** Al sonar la campana, los comentaristas presentan el truco de cada uno y él lo muestra:

| Rival | Estilo | Truco |
|---|---|---|
| Raúl, "El Millonario" | Big Show | Gigante; no se deja levantar hasta tener menos de la mitad de vida. Chokeslam. |
| Alvarito, "El Corazón" | Eddie Guerrero | Se hace el lesionado; si uno se acerca, roll-up. A veces te ayuda a levantarte. Frog splash. |
| El Pecas, "El Lambón" | — | Mauricio, desde el delantal, te agarra el pie si te acercás a las cuerdas. DDT. |
| Mauricio, "El Enterrador de Domingos" | Undertaker | Luces apagadas y gong. No pierde hasta que **se sienta**; después viene la fase 2: sobrio, sin chaleco, más rápido. Tombstone. |

Código: `scripts/dreams/Lucha.gd`, escenas `Lucha1..4`, ids de sueño `lucha1..4`; Paso Firme se aprende en `lucha4`. El arte de Lukas árbitro está en `tools/art/draw_lucha.py`.

**Los luchadores tienen muñeco propio** en el estilo del beat 'em up (`tools/art/draw_luchadores.py` → `assets/dreams/luchador_<id>.png`). Salen de las hojas de los matones del prólogo, vestidos como en el rediseño:
- **Raúl:** canoso, guayabera dorada y pantalón caqui.
- **Alvarito:** pelo café, chaqueta de jean y pantalón negro.
- **El Pecas:** pelirrojo, camiseta naranja y jean.
- **Mauricio:** canoso, chaleco de cuero café abierto y jean. En la fase 2 cambia a `luchador_mauricio2.png`, sin chaleco (`Lucha._vest`).

El boxeo viejo (`Boxeo.gd`, escenas `Boxeo1..4`) se movió a `_old/boxeo/`.


## Sigilo: La Empresa (hecho)

Vista desde arriba, una pantalla por nivel, un nivel por sueño. La Empresa es donde trabajaba: José Mario le contó a todos lo de las drogas (que él ya había dejado hacía dos años).

**Mecánicas:**
- **Guardias con cono de visión:** la sospecha se llena de amarillo a rojo, con "?" y "!". Lleno: lo sacan del edificio y se reintenta el nivel.
- **Lo que hace él:**
  - Esconderse en lockers y plantas (verde oscuro); el escondite tapa la vista.
  - Tirar una taza (X) para distraer: los guardias cercanos van a mirar.
  - Dormir a un guardia por la espalda (E).
- **Documentos (amarillo):** abren la oficina del jefe.

**Los jefes:**

| Nivel | Jefe | Truco |
|---|---|---|
| 1 | Walter (el de los chismes) | Se para a comer y ahí no mira. Tres veces por la espalda: el post-it "SOY EL SAPO DE JOSE MARIO". |
| 2 | Nicolás (habla duro) | Cuando grita, los guardias lo miran a él: ahí se pasa. |
| 3 | Eddy (gafas, quiere el puesto de todos) | Anda por todo el piso y revisa los escondites: no hay que quedarse mucho en uno. |
| 4 | José Mario | Ahí no hay documentos: hay cámaras. Mientras quede una prendida, él lo sigue con la mirada. Con los tres tableros apagados, mira su pantalla. La confrontación final: el carné con la foto de cuando sonreía. |

Enseña Rebusque (en el sigilo 1).

## Calendario final simulado (partida típica)

| Día | Sueño |
|---|---|
| 3 | PLOMO 1 |
| 5 | PLOMO 2 |
| 7 | Carrera 1 |
| 9 | Sigilo 1 |
| 11 | Brenda |
| 13-16 | Lucha 1-4 (noches seguidas) |
| 18 | Sigilo 2 |
| 20 | Sigilo 3 |
| 22 | Sigilo 4 |
| 24 | Carrera 2 |
| 25 | Carrera 3 (la noche siguiente) |
| 26 | PLOMO 3 (la noche siguiente) |
| 28 | Carrera 4 |
| 29 | Final de Lilato (por hacer) |
| 30 | El cumpleaños de Victoria (por hacer) |

- Las series esperan dos días entre episodios.
- Van en noches seguidas: el torneo, la Carrera 3 y el PLOMO 3.
- El menú SUEÑOS tiene 21 entradas y se desplaza.


## Brenda: un solo sueño largo (hecho)

Lo dispara la llamada a la mamá. La terminal, el bus y después Ibagé, la casa de ella. Es un beat 'em up.

- **Fase 1:** ella huye y le tira maletas.
- **Fase 2, "La de mil caras":** cuando la alcanza, se arranca la cara como una máscara.
  - Quedan cuatro figuras: ella y tres copias con caras de gente que lo quiere (Don Germán, Doña Rosa, Samuel, Marta).
  - Hablan de a una, con la frase arriba. Las copias dicen lo que esa persona diría de verdad; **la verdadera es la única que pide plata o miente** ("Yo le mandaba plata. Todos los meses.").
  - Cada 6 segundos cambian todas de cara.
  - Pegarle a una copia la deshace y duele: *"Le pegué a la cara de Don Germán. Era de mentira. Igual dolió."*
- **Final:** cuando la verdadera se sienta, abrazarla o dejarla ir. Después, la olla de sopa. Enseña Cocinero.


## Motivos para la vida real (hecho)

### Victoria: la meta grande
- **El colegio** (en el centro): sale a las 12, menos los domingos, y Lilato la viene a buscar. En **la reja** se puede:
  - **Mirarla:** suma ánimo y, de a poco, vínculo.
  - **Saludarla:** si Lilato te ve, amenaza con la policía y hay tres días de veda. Las quejas suman en contra en la Defensoría.
  - **Dejarle algo:** una flor, la pelota, la estampita, Gloria o el casete. Al día siguiente hay un **dibujo** en la reja: "EL DEL PERRO".
- **Con vínculo 3,** a veces Lilato llega tarde y se puede hablar con Victoria: *"Los señores malos no tienen perros así de contentos."*
- **La Defensoría de Familia** (en el centro) pide:
  - cédula,
  - una dirección,
  - $50.000,
  - 3 días trabajados (cualquier trabajo cuenta),
  - estar bien (locura baja, sin recaída),
  - vínculo con la niña de 2 o más,
  - pocas quejas de la mamá.
- **Audiencia** a los 3 días. Después, **visitas supervisadas** los domingos de 10 a 12 en el Parque.

### Trabajos con minijuego
- **La obra:** es el trabajo fijo; Germán lo ofrece de 6 a 10, menos los domingos. Se suben ladrillos con equilibrio, en tres viajes. Paga hasta $25.000. Paso Firme ayuda.
- **Rapidito:** Yeison está en la plaza desde el Día 4. La bici cuesta $2.000. Cada pedido contra reloj paga $5.000 más propina. Hasta 3 por día.
- **La ruta de reciclaje con Wilson:** una vez por día, 90 segundos de latas por el barrio, pagadas al doble.

### Lukas: trucos y salud
- **Trucos,** con menú propio; se aprenden en 3 sesiones, una por día:
  - **Sentarse:** al pedir, el número de Lukas paga más.
  - **Dar la pata:** las señoras no se resisten.
  - **Hacerse el muerto:** el ladrón del cambuche se asusta.
  - **Saludar:** los transeúntes son más amables.
- **Enfermedad:** puede enfermarse por no comer ni tomar agua, por mojarse sin techo o por el aguacero. Enfermo no busca.
- **La veterinaria del Parque:** la consulta cuesta $20.000; la jornada de los domingos de 9 a 12 es gratis. Lukas nunca se muere.

### Misterios (el tablero del cambuche)

| Caso | Pistas | Qué se descubre |
|---|---|---|
| ¿Quién es "él"? | 3 recortes (barrio, centro, Parque) + Marta + Wilson | El operativo por la denuncia de Diana Carolina; en la página 14, que no hubo cargos. Después él les contesta a los que murmuran. |
| La casa de tejas | La carta de Madrid + Samuel + Germán | El hijo de doña Inés, encerrado. |
| El señor de negro (Fercho) | Rosa + Aurelio + el Padre | El barrio lo espera en la primera banca y se acaba la vacuna. |

### Eventos del día
El 70% de los días pasa uno, a una hora al azar, y dura una hora y media:
- **Redada:** con cédula, susto; sin cédula, te quitan algo.
- **Aguacero:** hay 20 minutos para meterse bajo techo; si no, te mojás, baja el ánimo y Lukas puede enfermarse.
- **Pelea en la calle:** separarlos, mirar o irse. Es algo violento.
- **Alguien que necesita ayuda:** el señor desmayado o la niña perdida.


## El final (hecho)

**Lilato es la villana final.** No pide plata ni comida. La denuncia del operativo la puso Diana Carolina, pero **Lilato les dio a la policía la dirección, la foto y el testimonio falso** ("está armado") para quedarse con la niña. Al final del juego se la destruye.

### Vida real: se cae su mentira
1. Se resuelve "¿Quién es él?" en el tablero.
2. El Padre avisa: un policía quiere hablar.
3. En la iglesia, en la última banca, **el agente del operativo confiesa** y se ofrece a declarar (`flags.testigo`).
4. En la Defensoría, con visitas ya ganadas: "Presentar las pruebas". La página 14 y el testigo hacen caer la mentira (`flags.lilato_mentira_caida`): visitas sin supervisión y el cumpleaños con el papá.
5. **Día 30, el cumpleaños de Victoria** (29 de octubre; cumple doce años):
   - **Con visitas:** en el Parque, de 10 a 14. La torta de Fabiola, los amigos cantando, el regalo según la alcancía (con $150.000, la bicicleta rosada) y *"¿Puedo decirle papá?"*.
   - **Sin visitas:** el regalo queda en la reja del colegio y ella lo saluda de lejos.
   - Después: "BE A MAN. FIN." y vuelta al título.

### El último sueño: "LA SERPIENTE"
Se sueña cuando se cae la mentira, o el día 29. Es una **galería de revanchas** con giros; si perdés, se repite esa pelea y no hay despertarse:

| # | Revancha | Giro |
|---|---|---|
| 1 | Brenda | Directo en "La de mil caras", y las caras se mezclan cada 3,5 s. |
| 2 | Guillermo, mano a mano | "Guillermo de Oro": más vida, más rápido, dorado. |
| 3 | La carrera de los dos | Arrancan ya transformados (La Devoradora y el marrano). |
| 4 | José Mario, sigilo | Las cámaras giran el doble de rápido. |
| 5 | Mauricio, lucha | Sobrio y en fase 2 desde la campana, con el Pecas ayudando desde el delantal. |
| 6 | Lisandro, PLOMO | Él ya con armadura; Lisandro "en subida para siempre" (más rápido); vuelven Camila y Guillermo. |

**Después, Lilato, en tres fases:**
1. **El callejón del prólogo:** policías y el sargento, mientras ella mira desde un balcón.
2. **PLOMO "El operativo":** policías, soldados y el capitán; ella grita por el megáfono y dispara denuncias.
3. **Bajo el puente:** Lilato, el súper cuchillo y la serpiente. La serpiente se deshace en papeles, y abajo de todo está la página 14. Lilato se vuelve humo y no vuelve a ningún sueño.

**Código:**
- `scripts/dreams/FinalRush.gd` maneja el orden, `is_step`, `next` y `retry`.
- Las escenas del final son `FinalCallejon`, `FinalOperativo` y `FinalSerpiente`.
- En el menú SUEÑOS: "FINAL: LA SERPIENTE".


## Jugar todo encadenado (y probar rápido)

- **Partida completa:** NUEVA PARTIDA. Va del prólogo (Día 0) a los 30 días, con los sueños cuando pasan sus hechos, el sueño final la noche del día 29 y el cumpleaños el día 30. Después, FIN.
- **Menú de prueba: F4.** Solo en el editor (debug); no existe en el juego exportado. Opciones:
  - dormir ya;
  - +$50.000;
  - día +1 o +5;
  - disparar los hechos: cédula/obra/centro, la llamada a mamá, el papá en la plaza;
  - Victoria con vínculo 3 y visitas;
  - todas las pistas de los misterios;
  - soñar ya el próximo sueño.
- **F2** (en debug): salta la escena actual en los minijuegos que lo tienen.
- **Sueños sueltos:** menú SUEÑOS del título.


## Lukas se muere casi al final (hecho)

Esto reemplaza lo de "Lukas nunca se muere": las enfermedades comunes se siguen curando en la veterinaria, pero esta no.

**La enfermedad larga** (el corazón; está viejito) empieza el **día 17** y avanza sola, cada mañana con su línea y un poco menos de ánimo:

| Etapa | Días | Cómo está |
|---|---|---|
| 1 | 0-2 | Tose de noche. |
| 2 | 3-5 | Come la mitad, camina más lento, ya no aprende trucos ni busca. |
| 3 | 6 en adelante | Duerme casi todo el día, respira rápido, ya no hace guardia. |

- **La veterinaria** lo dice claro: el corazón, no tiene cura. Las gotas ($15.000, o fiadas) son para que no le duela.

**Cuándo se muere.** La noche después de conseguir al **testigo** (lo que lo deja a un paso de lo de Victoria), o a más tardar el **día 26**. Siempre con al menos cinco días de enfermedad antes. Esa noche no hay sueño:
- Se acuesta en el pecho y respira despacio. "Ya casi, Lukas. Ya casi la vemos." Mueve la cola una vez.
- Samuel llega con una pala. Lo entierran en el Parque, bajo el árbol de flores amarillas: Leonor deja un clavel y el Padre dice que sí, que los perros tienen alma.
- Él se queda con el **collar**. Sin chistes: es lo primero que ni siquiera lo intenta.

**Después:**
- No aparece en la vida real, y las noches se cuentan solo.
- Lo que antes encontraba él olfateando queda a la vista.
- Al pedir, el lugar de Lukas está vacío; en el cuenco, "ya no tiene para quién".
- Victoria pregunta "¿Y el perro?" y lo dibuja: "los dibujos no se mueren". Las visitas son en su tumba, y en el cumpleaños hay una vela de más.
- En los sueños sigue apareciendo, porque es memoria; en la revancha de lucha sigue de árbitro.


## Él se muere (el final verdadero)

**Después de Lukas, se va apagando.** En los días que siguen a su muerte:
- **El mundo pierde el color:** es el parámetro `grief` del shader, que desatura hacia un gris frío un poco más cada día (`GameState.grief()`).
- **Le cuesta caminar:** `walk_factor`, hasta un 45% más lento.
- **Se ve pálido y borroso.**
- **Ya no le da hambre** y no se desmaya. Cada mañana tiene una línea: *"No tengo hambre. No me acuerdo cuándo comí. No importa."* ... *"El mundo se va quedando sin colores. Ya casi no me duele. Eso es lo que me preocupa."*

**El último sueño** se sueña la noche del día 29, o antes si ya pasaron 3 días desde Lukas y soñó todo lo demás:
- Después de destruir a Lilato viene **el gran sueño**: sale el sol, del otro lado del río lo espera Lukas al lado de la Renegade, y se van. *"Esta vez no tiene que llegar a ninguna parte."*
- **No se despierta.** Samuel lo encuentra al amanecer con el collar de Lukas en la mano.

**Epílogo** (`scenes/world/Epilogo.tscn`; también se puede ver desde el menú SUEÑOS):
1. **El entierro**, al lado de Lukas, bajo el árbol amarillo: Samuel, Germán, Rosa, Marta, Wilson, el Padre, Fabiola, Leonor, Efraín con Gloria y el Mono con un bolero. *"Once personas. Ninguna de su familia. Todas, su familia."*
2. **Los demás, sin enterarse:**
   - Brenda cocinando para otro niño;
   - Mauricio y el Pecas con la moto un domingo;
   - Lilato pintándose las uñas por teléfono;
   - José Mario ascendido, con Walter, Nicolás y Eddy;
   - Lisandro en una esquina nueva;
   - Camila con la tarjeta de Guillermo, y Guillermo lavando la camioneta;
   - Diana Carolina en otra ciudad;
   - Raúl y Alvarito en la cantina: Alvarito brinda "por los que no vinieron" y no sabe por qué.
3. **Victoria, el día de su cumpleaños:** Germán le trae la bicicleta con la tarjeta "El del perro". Ella toca el timbre dos veces junto al árbol y saluda a nadie hacia la reja.
4. **FIN.**

(El cumpleaños en persona del día 30 queda fuera de la partida normal: él ya no llega.)


## 45 días (antes 30)

La partida dura 45 días. Victoria cumple el 45, pero él ya no llega. El reloj sigue igual (1,8 min por segundo), así que la partida queda en unas 6,5 horas.

**Sueños:**
- Una noche libre extra entre sueños (`DREAM_GAP` 3).
- Las series (carreras, sigilo) van cada 3 días.
- PLOMO 2 llega por violencia o, si no, a los 4 días de PLOMO 1.
- El final cae a más tardar la noche del día 44, o 4 días después de Lukas si ya soñó todo lo demás.

**Lukas:**
- Se enferma desde el día 25.
- Pasa a la etapa 2 a los 4 días y a la 3 a los 8.
- Muere con el testigo (si lleva al menos 8 días enfermo) o a más tardar el día 38.

**Otros ajustes:**
- La dificultad llega al máximo cerca del día 18.
- Lo del papá (sin la carta) se dispara desde el día 12.


## Encargos del día (`scripts/systems/DayTasks.gd`)

Algunos días tienen un encargo propio:
- Se anuncia en el resumen de la mañana y queda en la lista como "Hoy: ...".
- Si no se cumple, a la mañana siguiente se nota: baja el ánimo y sale una línea.
- El calendario está en `DayTasks.CALENDAR`.

| Tipo | Días | Qué |
|---|---|---|
| Zaida | 8, 15, 22, 30, 37 | Aparece en el centro, la plaza o el Parque. Ofrece ayuda que se cobra. |
| Lukas a la veterinaria | 7, 27, 33 | Vacunas; control del corazón; las gotas ($8.000, o la Dra. Pilar fía). Faltar: ánimo -10. |
| Metas personales | 4, 10, 14, 19, 24, 34, 42 | Comer 3 veces, $10.000 a la alcancía, un truco nuevo, no pedir, trabajar, bañarse, el árbol amarillo (si Lukas ya no está). |
| Amigos | 5, 12, 17, 20, 26, 31, 40 | Rosa (cuidar el puesto), Samuel (aguapanela), Wilson (latas), Germán (una flor por su cumpleaños), el Mono (su público), Marta (el cobrador), Efraín (un Lukas tallado). |
| El tramo final | 35-48 (todos los que no tenían) | Cada día algo, alrededor de lo que se viene: $15.000 a la alcancía (35); el carrito nuevo de Wilson (36); la Dra. Pilar le oye la tos a él, con el estetoscopio de Lukas, y le da jarabe para perros grandes (38, tos -5); el Mono, segunda temporada: él hace de poste (39); la puerta del garaje de Germán, con su rincón seco "para una bicicleta" (41); Samuel le trae su cobija (43: si el cambuche no tenía, ya tiene); Doña Rosa le enseña a envolver un regalo (44, `papel_regalo`); Marta, un tinto y $5.000 para la bicicleta (45); Efraín, lo de la bicicleta (46: si no la ha comprado, se la guarda hasta el 29); bañarse y la barba (47); completar la alcancía (48). Si la bicicleta ya está, lo de la alcancía se vuelve "comer tres veces". |

**Zaida** lleva la cuenta de cuántas veces le aceptó (`zaida_deuda`):
1. Le ofrece $20.000 "sin cobrar".
2. Ofrece hablarle a Lilato. Si acepta: una queja más y "preguntaron por mí en el puente".
3. Un paquete por $30.000. Si acepta: locura +1 y algo violento.
4. Ofrece ir de testigo:
   - con 2 o más deudas, hunde la imagen en la Defensoría;
   - si no, confiesa que una vez dijo lo del arma.
5. La cuenta:
   - con 2 o más deudas, cobra $40.000 (de la alcancía si falta). Si no se le paga, vende dónde duerme: intruso esa noche y una queja más;
   - con menos, deja $25.000 para Victoria.


## Todos iguales (de a poco)

**La idea:** al principio cada persona se ve como es: colorida, con su cara y su ropa, fácil de reconocer. A medida que se le degrada la mente, sin que él lo sepa, los demás se le van volviendo iguales: un maniquí gris de saco, sin cara y sin color (`assets/characters/iguales.png`). Él a sí mismo se sigue viendo bien. Nadie lo dice nunca: el jugador lo nota solo.

**Cómo se ve** (`assets/shaders/iguales.gdshader`):
1. Primero se le apagan los colores, hacia un gris frío.
2. Después sus pixeles se cambian, uno por uno y siempre los mismos, por los del maniquí, hasta que no queda nadie. La cara se va a pedazos.

**Qué lo empuja** (`GameState.sameness(id, desconocido)`, de 0 a 1). El avance es `p = 0,5·(día-1)/40 + 0,5·locura/20 + 0,3·duelo`, donde el duelo es `grief()`, después de Lukas.
- **Los desconocidos** (transeúntes, la fila, pedir, el puesto, la fuente) se borran primero: entre `p` 0,05 y 0,5.
- **Los conocidos** se borran después: entre `p` 0,3 y 0,95. Los más queridos, todavía más tarde: +0,05 por cada punto de vínculo.
- **Nunca se borran** Victoria y Lukas: son lo único que él ve de verdad.
- **Tampoco se borran** los sueños ni el epílogo, porque él ya no está y el mundo vuelve a tener caras.
- **El señor de negro** se borra como los demás, pero conserva su tinte negro, porque es pista.

En una partida típica, con poca locura: el día 3 todos están enteros. El día 18 los desconocidos ya van por la mitad y los conocidos apenas se apagan. Hacia el día 32 casi todos son el maniquí.

**Modos** (`flags.iguales`, se cambia en F4 y recarga la escena): `gradual` (el juego, por defecto), `siempre` y `no`. En F4 también está "Locura +5" para probar.

**Código:**
- `CharacterFrames.dress(sprite, fila, id, desconocido)` le pone la hoja y el shader a cada persona.
- Los desconocidos usan `transeunte_0..5`, según su fila de Kenney.
- `GameState.same_tint` apaga también los tintes.


## Personajes adultos (redibujo)

Los chibis de 16 px se van reemplazando por personajes en proporciones adultas (~25 px de alto, celdas de 16x26), como el protagonista.

| Quién | Hoja | Script | Estado |
|---|---|---|---|
| El protagonista | `protagonist_adult.png` | `draw_protagonist_adult.py` | hecho |
| Los "iguales" | `iguales.png` | `draw_iguales.py` | hecho |
| Lukas | `lukas.png` (celdas de 20x16) | `draw_lukas.py` | hecho: beagle de proporciones reales (~11 px de alto) |
| Samuel | `samuel.png` | `draw_samuel.py` | hecho: gorro rojo, barba gris, abrigo largo, costal |
| Germán, Rosa, Marta, Wilson | `german.png`, `rosa.png`, `marta.png`, `wilson.png` | `draw_vecinos.py` | hecho. Germán: calvo, canas, bigote, delantal con harina. Rosa: bajita, moño, delantal de cuadros rojos, falda. Marta: cola de caballo, blusa mostaza, delantal negro, jean. Wilson: gorra verde, chaleco naranja reflectivo, guantes, botas |
| La gente del Parque | `padre`, `fabiola`, `aurelio`, `leonor`, `efrain`, `mono`, `viejos` (Don Octavio), `viejo2` (Don Ramiro) | `draw_parque_gente.py` | hecho. Padre: sotana, alzacuellos, gafas. Fabiola: pañoleta azul, delantal verde. Aurelio: bigote, delantal café. Leonor: moño blanco, chal rosado, un clavel. Efraín: sombrero, gafas, chivera, chaleco. El Mono: rubio, barba, guitarra. Octavio: boina vino, saco gris. Ramiro: sombrero aguadeño, ruana |
| El celador y el resto del epílogo | `celador`, `brenda`, `mauricio`, `pecas`, `lilato`, `josemario`, `walter`, `nicolas`, `eddy`, `lisandro`, `camila`, `guillermo`, `diana`, `raul`, `alvarito` | `draw_gente.py` (armados por partes: cabeza, gafas, bigote, barba, gorra + saco, chaleco o vestido) | hecho. Los colores siguen a los sueños: José Mario de gris, Brenda (ver abajo), Mauricio bajito con chaleco de cuero, Lisandro de traje blanco con gafas oscuras, Camila de dorado con bolsas, Guillermo con gafas oscuras y cadena |
| Los niños (Victoria, el niño de Brenda, el pelado de Lisandro) | (Kenney) | — | se quedan chiquitos a propósito: al lado de los adultos se leen como niños |
| Los desconocidos | `transeunte_0..5` | `draw_gente.py` | hecho (uno por cada fila de Kenney que usaban) |
| Camila y Guillermo (rediseño) | `camila.png`, `guillermo.png` (ciudad/epílogo) y `assets/prologue/camila.png`, `guillermo.png` (beat 'em up) | `draw_gente.py`, `draw_camila_guillermo.py` | hecho. **Camila:** enana, peinado de honguito pintado de mono (con la raíz oscura), muy tetona, vestido fucsia, uñas rojas. **Guillermo:** gordo, muy gordo, mono, gafas oscuras, cadena de oro, polo verde. En el beat 'em up, lo gordo lo pone el juego: el tipo de enemigo lleva `"scale": Vector2(1.4, 1.05)` (`Brawler.body_scale`). En las carreras también (`draw_carreras.py`): Camila chiquita con el honguito y de fucsia, de copiloto y en el platón; Guillermo como una espalda verde enorme con la nuca mona; La Devoradora con el honguito y el busto reventando el vestido; el marrano con copete mono |
| Lisandro, Lilato y Brenda (rediseño) | `lisandro.png`, `lilato.png`, `brenda.png` (ciudad/epílogo), `assets/prologue/lilato.png`, `brenda.png` (beat 'em up), `assets/shooter/lisandro_*`, `kid_lisandro_*`, `lilato_*`, `kid_lilato_*`, `dface_*`, `saliva.png` (PLOMO) | `draw_gente.py`, `draw_lilato.py`, `draw_episode3.py`, `draw_shooter*.py` | hecho. **Lisandro:** gordo y bajito, gafas oscuras, engominado, traje blanco, camisa roja, cadena; un hijo de puta (en PLOMO, ancho y petiso: `SCALE` (ancho, alto)). **Lilato:** chiquita, cara linda (ojazos, pestañas, cachetes, boca pintada), pero balas de saliva e ignorancia: en el beat 'em up el zarpazo es una ráfaga de saliva; en PLOMO escupe en abanico (`"fan:saliva"`); habla con disparates ("dominio púbico"). **Brenda:** negra y alta (la más alta de todos), afro corto con canas, saco mostaza, falda gris |
| Los guardias del sigilo | `guardia_0..2` | `draw_gente.py` | hecho: uniforme azul oscuro, gorra, corbata negra. Los jefes (Walter, Nicolás, Eddy, José Mario) usan su hoja, por el `id` del nivel |

- `CharacterFrames.OWN` lista quién tiene hoja propia; `CharacterFrames.named(fila, id)` usa esa hoja o, si no tiene, la de Kenney. A los que tienen hoja propia no se les aplica tinte.
- En el epílogo, la gente puede llevar un id (7.º campo) para usar su hoja.
- `Lukas.cell(col, fila)` da un cuadro de Lukas (la fila, el puesto, pedir y el título usan `Lukas.cell(3, 0)`, sentado).


## Diálogos: voz por dentro y tono de guion (2026-10-08)

**El pedido:** los diálogos se sentían robotizados. El tono de referencia sale de tres guiones: *American Psycho*, *Pulp Fiction* y *Deadpool*.

**Él sigue mudo afuera.** Los demás creen que no habla. Pero el jugador oye lo que piensa: es `["ÉL", "..."]`, sin raya. Sale con el nombre "ÉL (POR DENTRO)" y en azul (`Dialogue.INNER`).

**Reglas:**
1. **Cada uno con su voz:**
   - Germán: digresiones de viejo, su señora, el pan.
   - Wilson: negocio, cifras, fe en la multiplicación.
   - Samuel: frases cortas de calle, verdades que duelen sin anunciarse.
   - Rosa: pregón y regaño cariñoso.
   - Nadie usa la misma muletilla.
2. **Digresiones sobre cosas mínimas y muy específicas** (Pulp Fiction): marcas, precios exactos, horarios y manías. Por ejemplo, la lata de Pony Malta a $300, el camión de las 7:15 o el sushi de Rapidito. Lo trivial va antes de lo grave.
3. **La voz por dentro contradice o completa lo de afuera** (American Psycho):
   - lee a la gente como un inventario: ropa, manos, armas;
   - es educada afuera y ácida adentro;
   - nombra lo terrible con calma ("aquí el clima tiene moto y cobra los lunes").
4. **El chiste es su escudo** (Deadpool). De vez en cuando le habla al jugador o al juego ("aquí el juego me enseña a cargar cosas"), pero poco. En los golpes fuertes no le sale el chiste.
5. **El pasado asoma sin explicarse:** la mano que se le va a la cintura buscando un arma, el reloj que vendió, "alguien siempre está mirando".
6. **Nada de tutorial disfrazado:** la instrucción va metida en el chiste o en la manía del personaje.
7. **Malas palabras como puntuación**, no como relleno.

**Reescrito:**
- todo `Conversations.gd`: los vecinos, las ventas, la cédula, Zaida, el Parque, los amigos, Victoria, la Defensoría, la veterinaria, los misterios, los eventos y el final;
- los encargos del día (`DayTasks.gd`);
- el puesto de Rosa, la fila, la obra y la ruta de Wilson.

**Se sacó la muletilla "usted no habla"** como remate repetido. Ahora cada uno tiene su tema:
- Germán: la Mercedes, el pan de ayer, el camión de las 7:15.
- Marta: su hijo, la casa de tejas, el voseo paisa.
- Wilson: la Pony Malta, la fe en multiplicar.
- Samuel: el río, la equis de su firma.
- Rosa: el azúcar, los billetes de dos mil.
- El Padre: Dios con presupuesto apretado.
- Fabiola: el reglamento de la olla.
- Aurelio: las deudas con cifras.
- Leonor: las cintas de las flores.
- Efraín: los objetos que vuelven.
- El Mono: los boleros de tres minutos.
- Octavio y Ramiro: treinta años de caballo del rey.

**En lo de la familia, Victoria, Lukas y el final,** la voz por dentro intenta el chiste y no le sale; queda cortada ("Ella...", "Ya no..."). En el cumpleaños dice "Sí." y "Feliz cumpleaños, Victoria." por dentro.

**Sueños (revisados también).** En los sueños él sí habla en voz alta. Su nombre en pantalla es **"YO"** (en la lucha, **"EL PELADO"**, como en el marcador). "ÉL (POR DENTRO)" sigue siendo lo que piensa.
- **Lucha:** Don Tito y La Mona tienen voces distintas.
  - Don Tito: narrador de la vieja escuela, exagerado, menciona patrocinadores ("Colchones El Descanso"), se acuerda del Santo.
  - La Mona: seca, con datos ("Golpe número doce. Once en la cara. Uno en el orgullo.").
  - Los rivales: cada uno con su tema. Raúl: kilates y la finca en Melgar. Alvarito: "tío Alvito". El Pecas: la gasolina. Mauricio: Efecty y la chapa.
- **Sigilo:** sátira de oficina.
  - Las tarjetas de presentación, el mug WORLD'S BEST BOSS de Nicolás, la Moleskine y la kombucha de Eddy.
  - José Mario y su escritorio vacío y su agua de Noruega.
  - El correo que dejó en la pantalla de Walter a las 11:39, porque Walter almuerza a las 11:40.
- **Carreras:**
  - Camila y el perfume de la botella dorada que pagó él.
  - Guillermo, la Hilux financiada y Titanic dos veces en cine.
  - Diana y el helicóptero que "puso el Estado".
- **Brenda, Guillermo y el final:** el mismo tono serio, pero con detalles concretos (la crema Nivea, la sopa con cilantro, la camiseta del Mundial). Él habla como YO.
- **Al despertar:** algunos sueños dejan un remate.
- **La revancha de la lucha:** si pierde, espera dos noches (`flags.lucha_revancha_dia`).

**Técnico:** `Dialogue` parte solo las frases que no entran en el cuadro (más de `PAGE_CHARS`, 94 letras), por oraciones, y cada página conserva a quien habla. Antes, las frases largas se salían del cuadro.

## El celular y las llamadas de Lorena

- **Lorena** es el nombre real de su ex; **Lilato** es como aparece en los sueños. En la ciudad, el recuerdo de la moto y el epílogo se llama Lorena.
- **El celular de flecha** lo vende Don Efraín ($9.000). Con él en la mochila, en la ciudad (City, Centro, Parque), cada tanto entra una llamada (`autoload/Phone.gd`): el celular salta abajo a la derecha, vibra y suena con el nombre en pantalla. Acción contesta, atrás cuelga.
- **Lorena** llama para pedir plata o para molestar. Son **los diálogos más chistosos del juego**: él es mudo, así que solo puede `(Respirar)`, `(Respirar dos veces)` o `(Colgar)`, y ella interpreta. Diez llamadas en orden (el número, los tenis, el horóscopo, la tutela, el coaching ontológico, Miami, el perro, el aguacate, la ansiedad, el cumpleaños) y después unas al azar. Malapropismos siempre ("dominio púbico", "apostillada viene de apóstol", "Isaac Nielsen").
- Si le cuelgan, **vuelve a llamar** ("¿ME COLGÓ?"). A veces llama de otro número: aparece como DESCONOCIDO, así que cuando suena uno nunca sabe si es ella. Los desconocidos que no son ella: créditos preaprobados, Pollos Mario, Rapidito, una encuesta, el "mami, soy yo".
- La gracia es la expectativa: cuando suena el celular, que el jugador quiera que sea Lorena.

## Diálogos estilo Dredge

- Bohemio, serio: el que habla aparece de pie en el medio, detrás de un cuadro negro con letra blanca; el nombre centrado entre dos líneas finas (y lo que es, más apagado: "la panadería", "su hija"), y comillas.
- Retratos (`tools/art/draw_retratos.py` → `assets/portraits/`, 96x112): caras serias y gastadas (ceño, párpados caídos, ojeras, barba de días, comisuras para abajo), luz dura por planos y facetas tipo low-poly, colores apagados. Algunos "destruidos" (ojos rojos, más barba): él, Samuel, Wilson, Mauricio, Efraín...
- Quién tiene retrato: `Dialogue.SPEAKERS`. Lo que él piensa: en azul, "ÉL por dentro".
- Todos iguales también en los retratos: a la gente de la ciudad se le va apagando la cara (`assets/shaders/retrato_iguales.gdshader`). Victoria y Lukas nunca.

## Pasar el rato, la calle y la soledad

- **Ver tele desde la calle:** la vitrina de TV RADIO (entre el café y la calle del este, en la vereda). Lo que dan depende de la hora: programa de la mañana, noticiero, telenovela, fútbol. Los domingos en la mañana, la Fórmula 1 (y a veces la repetición en la tarde). "Ver un rato" (1 hora) o "Quedarse la tarde" (3 horas; a veces Don Jairo, el dueño, lo corta). Pasa el tiempo y sube un poco el ánimo (hasta +6 por día). De 20 a 8, la reja abajo. `Conversations._vitrina_tv`, arte en `tools/art/draw_vitrina.py`.
- **Tráfico:** carros, taxis, la buseta, bicis y motos pasan de vez en cuando por la avenida y por la calle principal (hasta el puente). De noche, menos. Si él o Lukas están en el carril, frenan y pitan. `scripts/world/Traffic.gd`, arte en `tools/art/draw_trafico.py`.
- **Soledad (barra de compañía, arriba):** sube sola con las horas (más despacio con Lukas vivo, más rápido sin él). Baja cuando alguien le habla, acariciando a Lukas, gritando un gol con desconocidos frente a la vitrina, y sobre todo **hablándole a Lukas** (menú de Lukas → Hablarle): afuera es mudo, pero a Lukas sí le habla en voz alta. Arriba de 70, el ánimo se va cayendo. `GameState.loneliness`.

## Lo bueno del barrio (estar despierto también vale la pena)

Misión opcional desde el Día 1: "Lo bueno del barrio (n/6)". Cosas agradables, sin plata ni sueños, que suben el ánimo, la compañía o la calma (`Conversations`, sección "Lo bueno del barrio"):
- **Pescar** en la orilla, al lado del campamento: alguien deja una línea de nylon en una lata, "PARA EL QUE LLEGUE". Minijuego tranquilo (`scripts/ui/Pesca.gd`): tres lanzadas, el corcho mordisquea, cuando PICA se le da a la acción. Sale bocachico (comida), latas, botellas o una bota.
- **El atardecer** desde el puente (de 17 a 19): el cielo se pinta; pasa el tiempo hasta las 19; mucho ánimo.
- **Los pelados del fútbol** en el lote del parquecito (de 9 a 18): de arquero, cinco penaltis (izquierda, medio, derecha). Si ataja 3, le regalan un bombón. Mucha compañía.
- **La banca** del parquecito: ver pasar el barrio (escenas chiquitas, buenas).
- **El columpio**: un recuerdo del papá; mecerse.
- **El perro del barrio**: Lukas se hace amigo; él le pone nombre.
Al completar las seis: "Fue un buen día. No sabía que todavía se podía."

## La libreta (lo que se gana y lo que falta)

L (Select en el control, el librito en el celular, o L desde la mochila). Páginas con izquierda/derecha, arriba/abajo elige, el detalle abajo (`scripts/ui/Libreta.gd`):
- **Habilidades:** las que tiene (de día / soñando) y las que no ("???", con dónde se aprenden).
- **Sueños:** cuántos soñó (cuadritos por serie) y qué despierta cada serie (la cédula, la obra, llamar a la mamá, el papá en la plaza...).
- **El cambuche:** nivel, caja, robos, ánimo de noche, lo puesto, y qué falta para el siguiente.
- **Lukas:** salud, días juntos, trucos (sesiones 0/3) y cómo enseñarlos.
- **La gente:** cada favor y qué abre (pan gratis, baño del café, menos robos, fiado).

**Ningún texto encima de otro:** todo texto de pantallas va en cajas fijas con máximo de renglones; los avisos (Narrator) esperan si hay un diálogo, una llamada o una pantalla abierta (y si estaban a la vista, vuelven después); en el celular las pantallas dejan libre la franja derecha (x > 286) y los botones se ponen en fila ahí, la palanca no se dibuja mientras hay una pantalla abierta, y los avisos de abajo van angostos entre la palanca y los botones. La mochila dice lo que pasa (comió, tiró, armó) en su propia caja.

## Controles en pantalla y minijuegos sin textos encima

- **Opción en el título:** CONTROLES EN PANTALLA: AUTO / SÍ / NO.
  - AUTO muestra los controles solo con pantalla táctil.
  - Se guarda en `user://ajustes.cfg` (`Controls.touch_pref`).
- **Tres disposiciones de los botones (`TouchControls`):**
  - Caminando por la ciudad: todo en su lugar de siempre.
  - Pantalla abierta (diálogo, mochila, libreta, mejoras): la palanca no se dibuja y los botones van en fila en la franja derecha (x > 286).
  - Minijuego o sueño: los botones que sirven van en la franja derecha, y la palanca solo se ve mientras se toca.
- **Todo donde cae el dedo (2026-10-21):** en el beat 'em up el pulgar en la palanca fija tapaba al protagonista.
  - La palanca nace donde cae el dedo, en cualquier parte de la mitad izquierda, y lo sigue si se va lejos (para devolverse no hay que recorrer media pantalla). Caminando se sigue viendo en su sitio mientras nadie la toca.
  - En un minijuego o sueño, tocar la mitad derecha donde no hay botón trae los botones al pulgar: A debajo, B a la izquierda, X arriba, la huella arriba a la izquierda. Ese toque no aprieta nada (un toque perdido no dispara ni salta un menú); se quedan ahí hasta que cambia la escena o se vuelve a la calle.
  - En PLOMO no: la mitad derecha es para girar arrastrando (la escena tiene `touch_drag_right`).
- **Regla para los textos de un minijuego:**
  - No pasan de `Controls.right_edge()`: 286 con controles en pantalla, 320 sin ellos.
  - Los letreros de instrucciones de abajo entran al grupo `under_dialogue`; el diálogo los esconde mientras habla alguien.
- **Narrador y caja de diálogo:**
  - El aviso del narrador mide su alto con los renglones reales del Label.
  - Si cambia la escena, el aviso viejo se va.
  - La caja del diálogo es opaca.

## El protagonista de los sueños de pelea

- Lo genera `tools/art/heroe_suenos.py`, a partir de los originales y con `vestir_protagonista.dress(sleeves=False)`.
- Es él como se sueña:
  - canas, barba, saco gris sin mangas, corbata roja y jean;
  - más alto (2 filas de pecho y 2 de piernas) y más ancho de hombros (2 columnas);
  - la cabeza del mismo tamaño;
  - brazos al aire, con sombra de músculo.
- **El colgado del camión** (sueño 1, parte 2) lo dibuja `tools/art/draw_colgado.py`. Es el mismo héroe, con cuadros de 40x48.
- **Cómo se juega esa parte:**
  - Cuelga del borde del techo de la caja.
  - Izquierda/derecha: se mueve mano sobre mano.
  - Arriba: encoge las piernas. Así se estabiliza y esquiva las carretillas y canecas parqueadas, que también tumban a las motos.
  - A/E: patada; dos seguidas, patada y puño, hacia donde mira.
  - Hay 22 motos que vienen por los dos lados. Los que tiran botellas se quedan lejos: moverse las esquiva.
  - Umbral de la patada: 42 px (el puño, 36). Más lejos, el botón le tira una bolsa de harina del camión: le quita 1 de vida y lo hace tambalear.
  - Cuando la patada o el puño conecta, el golpeado se acomoda contra el pie o el puño (FOOT/FIST) y después sale para atrás.
  - Los "¡TOMA!", "¡PAF!" y "¡PUF!" van quietos en la franja entre el medidor y el techo, nunca sobre el letrero del camión.

## Que todo pida algo del jugador (revisión de jugabilidad)

`tools/bot_jugar.gd` juega cada escena con dos políticas:
- `idle`: no hace nada.
- `mash`: machaca el botón.

Si `idle` gana, esa parte no pide nada. Si `mash` gana fácil, es plana.

**Reglas que salieron de la revisión:**
- **El botón hace lo que tiene sentido según dónde está el otro:**
  - Callejón: si el único a tiro está atrás, se da vuelta. Con un matón encima, pega en vez de agarrar el arma del piso. La botella se rompe en la cabeza del que está al lado y se tira al que está lejos.
  - Camión: igual. Si todos están atrás, se voltea. Mientras saca otra bolsa no patea al aire.
- **Caer cuesta:** en el beat 'em up, sin vida queda tirado: "¡LEVANTATE!", machacar el botón y −1000 puntos.
- **Las reglas que se anuncian se cumplen:**
  - Fuente: moverse con el "!" te pilla. Meter la mano donde no hay moneda hace que el celador se dé vuelta antes.
  - Sigilo: E de frente avisa ("por la espalda") y el guardia sospecha.
- **Carreras con rivales:** E ya no acelera.
  - Rival al lado: patada, con la pierna dibujada. Lo frena, lo corre de carril y deja de tirar cosas.
  - Rival adelante: botella. Hay 3, y se recarga una cada 10 s.
  - Los rivales alcanzan menos al que va adelante.
- **Pedir:**
  - El tipo de persona no se escribe hasta que se lo conoce. Se lee por la ropa y por cómo camina: el apurado va rápido.
  - Lukas se cansa si se repite el truco.
- **Plomo:** ayuda para apuntar (como Doom), más generosa en el celular.
- **Lo bueno del barrio:**
  - Pelaos: penales (`Penal.gd`), mirándole el cuerpo al que patea.
  - Columpio, atardecer y perro: un toque de ritmo (`Ritmo.gd`).
  - Banca: se elige qué mirar.
- **Teclas en el celular:**
  - `Controls.keys_in()` cambia "E", "Q", "F" por "A", "B", "huella" en diálogos, avisos y carteles.
  - Hay botón táctil C (armar) con la mochila abierta.

**Segunda ronda (la vara es UnMetal: todo responde, jefes que se leen):**
- **Un solo letrero, una sola acción (`Focus.gd`):** de todo lo que el jugador tiene al lado (persona, puerta, servicio, algo para agarrar, lugar para dormir), solo lo más cercano muestra su letrero y responde a E. Antes podían salir dos letreros encimados y agarrar dos cosas con un botón.
- **Jefes del callejón (El Tuerto, Guillermo):** la embestida corre hasta pegarle a alguien o estrellarse contra el borde. Si se estrella, queda mareado 1.8 s: no se cubre y los golpes le entran doble. Esquivar es la forma de ganarle.
- **Lucha libre:**
  - E con el rival atrás: se da vuelta y le pega.
  - E con el rival en el piso: codazo (antes, golpe al aire).
- **Brenda, las mil caras:** sin volteo automático (pegarle a la de atrás puede ser pegarle a una copia). Cada nombre va a su altura, para que no se encimen.
- **La fila:** E mientras se espera muestra algo que mirar, con su comentario.
- **Los bultos de Germán:** alzarlo con las piernas (un toque de ritmo); mal alzado, camina más lento con ese bulto.

## PLOMO, el Dealer: más a lo Doom, y Lisandro de cerca (2026-10-09)

**Cómo se ve** (el motor es opcional por episodio; lo usa el Dealer, los demás quedan igual):
- **Paredes de 64x64** con relieve, mugre que sube del piso y grietas (`tools/art/draw_plomo_doom.py`, `wall_dd_*`):
  - ladrillo, concreto con el dibujo del niño tachado, persianas de local con la L de Lisandro;
  - bloques con franjas de peligro, cajas de la bodega, baldosa de la cocina con humo verde;
  - mármol y oro de la casa (con su L), y puertas de metal con franjas.
  - La puerta con llave tiene luz roja y candado de oro; la SALIDA es un aviso rojo que alumbra.
- **Pisos y techos con textura** (shader `assets/shaders/plomo_piso.gdshader`, atlas `dd_suelos.png`):
  - asfalto con charcos, andén, madera, baldosa a cuadros, mármol con oro;
  - techos de la cocina y de la casa; en la calle y el callejón, cielo con estrellas.
- **Luz por casilla:** el callejón es oscuro. Los faroles y las canecas con fuego alumbran alrededor; el fuego titila, igual que un farol que se está muriendo y el tubo de la cocina.
- **Decorado** que estorba: faroles, canecas con fuego, carros quemados, bolsas de basura, y en la casa una estatua dorada de Lisandro (más alta y más flaca que él) y un espejo.
- **Mapa nuevo:** callejón con recodos, calle con locales y kioscos, cocina con cajas y mesón, casa con columnas. Las zonas y las puertas son las mismas de siempre.
- **Armas nuevas en primera persona:** pistola y escopeta de oro con anillos (Lisandro), acero con guante verde (él).

**Lisandro: despreciable, pero uno le toma cariño antes de matarlo.** Se le maneja los tres capítulos:
- **Es un hijo de puta:**
  - hace chistes cuando mata ("Mándenle flores a la mamá. Las pago yo. Con la plata de él.");
  - al pelado que le pide trabajo lo pone de campanero, o le da un billete falso "con cariño";
  - le miente a la mamá.
- **Lo que lo hace querible:**
  - La mamá lo llama al teléfono público del callejón, una vez por capítulo:
    - "¿ya comió?" / "Estoy en el banco, amá. Gerente.";
    - "Usted no es gente mala, ¿cierto?";
    - "vino un señor verde, muy educado".
  - **Billete (capítulo 2):** un perro flaco al que le da pan, o le pega una patada y vuelve igual: "por fin uno que me sigue sin que le pague".
    - Lo sigue y gruñe cuando hay alguien escondido ("Billete gruñe a la izquierda").
    - Se acuesta cuando él se mete una bolsita.
  - **Capítulo 3:** una foto de los dos de pelados en la misma esquina. De ahí viene la envidia: "él siempre tenía con quién jugar; yo tenía la pistola".
- **El giro:** Billete corre para el lado de Lisandro.
- **La pelea con Lisandro es un acertijo** (ya no es esponja; 700 de vida):
  - Tiene el maletín de plata adelante y le entra el 30%.
  - Cada 6 s grita "¡mi bolsita!" y corre a una de las 4 bolsitas del piso.
    - Si se la toma: 6 s de subida (rápido, le entra el 8%), y después el bajón: suelta el maletín y le entra el 125%. Ahí llama a la mamá y a Billete.
    - **Si uno le revienta la bolsita de un tiro antes de que llegue:** el bajón es inmediato y más largo ("¡Esa era la última de la cuadra!").
  - Sin bolsitas, "es un señor gordo con una pistola".
- **Al morir:** "¿Llamó mi mamá?... dígale que estaba en el banco"; Billete le lame la cara un rato largo.
  - "Lo maté. Lo odiaba. Le había tomado cariño. El sueño sabía las dos cosas y no me avisó."
  - Billete no viene: se queda con él.
  - El final cambia según lo del pelado (`flags.lis_pelado`).
- **En la revancha** (el sueño final): arranca en subida y el acertijo es el mismo.

## PLOMO: lo que encontró el bot (2026-10-09)

- Los avisos de arriba van por turnos (`_say(texto, prio)`): 0 = comentario (gruñido de Billete, ¡TAC!, chistes al matar; si hay otro aviso, se pierde), 1 = normal (espera), 2 = urgente (el giro, la bolsita, la subida y el bajón). Antes se pisaban: en el capítulo 3 se perdían 15 de 37.
- Al reaparecer: 2 s sin daño, los enemigos se alejan sin atravesar paredes (antes mandaba a Lisandro a la cocina y la pelea no se acababa) y, en la pelea con Lisandro, con chaleco.
- Si se quedó a puño porque no tenía balas, al recoger munición (o al reaparecer) vuelve solo al arma.
- Lisandro busca la bolsita por la grilla (antes se trababa en una columna de mármol). Al bajón se le abre el maletín y se riegan balas; con poca munición aparece una caja lejos de él. Sin bolsitas queda lento ("un señor gordo con una pistola") y le entra más.

## PLOMO: los jefes de los capítulos 1 y 2, como acertijos (2026-10-09)

Antes eran esponjas de daño (caían en ~7 s). Ahora cada uno tiene su mecánica, distinta a la de Lisandro (a él se le quita la carnada):

- **Don Lucho (cap. 1), las arañas.** Viejo bajito de sombrero aguadeño y ruana, con chaleco de los ochenta: casi no le entra nada (0,1). Le gusta pararse debajo de la luz ("un capo que no se ve no es capo") y va de lámpara en lámpara; si no lo ve a uno desde ahí, sale a buscarlo un rato. Cada araña está amarrada a un gancho en la pared: con él debajo, uno le dispara a la cuerda (no a él) y queda aplastado 3,5 s (le entra 0,7). Si cae sin él debajo: "¡Esa era de Murano, animal!". Cada araña que cae oscurece la casa; sin arañas, "a oscuras el viejo no ve" (le entra 0,6).
- **El Coronel (cap. 2), las cajas fuertes.** El uniforme lo protege (0,1). Uno le revienta una caja fuerte y el fajo que cae lo hace correr ("¡Eso es evidencia! ¡La decomiso!"); contando ("uno... dos... se lame el dedo") no se defiende 3,5 s (0,8). Si uno se guarda el fajo primero, lo pierde. Sin cajas: "esto ya es personal" (0,7). Aquí uno pone la carnada.
- Con el bot: con el acertijo, Don Lucho cae en ~20 s y el Coronel en ~35 s; a lo bruto, 80-180 s y varias muertes.
- Motor: `Ent.pose` (poses especiales: "stun", "count"), `_ray_hook(..., wall)`, `_aim_object()` (si la mira está sobre un gancho, una caja o una bolsita, la ayuda para apuntar no se lleva el tiro hacia un enemigo). Sin munición pasa a la mejor arma que tenga balas (antes iba al puño aunque tuviera cartuchos). Las paredes ya no se ven al revés (las letras de SALIDA y la L de Lisandro).
- Arte: `tools/art/draw_plomo_jefes.py` (Don Lucho, el Coronel, arañas, ganchos, cajas fuertes, fajos).

## Beat 'em up: que machacar no alcance (2026-10-10)

- **Los matones se cubren.** Después de dos golpes seguidos (el grandote, desde el primero) levantan el brazo: "GUARDIA". De frente ya no les entra nada; por la espalda, sí. Probabilidad: grandote 100%, normal 60%, flaco 30% (`TYPES[...]["guard"]`, `"guard_after"`).
- **Contragolpe.** Tres golpes contra la guardia (lo que hace el que machaca) y contragolpea fuerte: lo tira al piso ("¡CONTRA!").
- **Ataque nuevo: la patada giratoria.** Mantener el botón y soltarlo (cuenta desde que se aprieta: el primer golpe sale igual). Brilla cuando está cargada. Pega adelante y, en la vuelta, atrás; tira al piso y rompe la guardia ("¡CRAC!"). Machacando nunca se carga. Ya estaba dibujada en la hoja del protagonista (fila 5) y nunca se usaba; la guardia y el contragolpe de los matones también (fila 6).
- También rompen la guardia: la botella (tirada o en la cabeza) y el caño. El cuchillo no.
- Avisos una vez por escena (arriba): cómo se rompe la guardia y que machacar sale caro. Los letreritos (GUARDIA, ¡TOC!, ¡CRAC!, ¡CONTRA!) se apilan para no encimarse entre ellos ni con el ¡LEVANTATE!.
- Con bots (150 s por nivel): el que machaca recibe 1-4 contragolpes y muere en 2 de 4 niveles; el que reacciona a la guardia con la giratoria no recibe ninguno y no muere. `tools/bot_jugar.gd` tiene las políticas `ritmo` y `machaca`, y la arena cuenta `stats`.

## La obra y el puesto: sin tramos pasivos (2026-10-10)

- **La obra.** Antes él caminaba solo: sin tocar nada el turno terminaba igual (con menos ladrillos). Ahora: **E mantenido = caminar**, soltarlo = afirmarse; flechas = equilibrar. El turno tiene reloj (110 s): sin caminar no se sube nada. Más ladrillos en la pila = más inestable. Una cosa nueva por viaje: (1) **el ladrillo de más** que tira el maestro: ARRIBA a tiempo = atajarlo (pila de 7, paga más); si no, "¡TOC!, el casco suena"; (2) **el ventarrón**, avisado con flechas de qué lado viene; (3) **la paloma** que se le para encima (la pila baila; se va si él se queda quieto) y **el charco de mezcla** (no frena en seco). El maestro se queja si se queda quieto.
  Con bots (a 60 cuadros por segundo): quieto, 0 de 18; con reacción lenta, 13-19; atento, 19 (con el de más).
- **El puesto de Doña Rosa.** Pagaba $10.000 fijos (quieto, lo mismo que atendiendo). Ahora: $2.000 por cuidar el carrito y $1.000 por venta. En la segunda mitad (después del señor de negro): **pedidos dobles** ("una empanada y una aguapanela", "dos arepas"), en orden; y **Wilmer**, que pide fiado ("soy amigo de Rosa"): ABAJO = no fiar (señalar el letrero "HOY NO SE FÍA, MAÑANA SÍ"). Si se le da algo, Rosa lo descuenta ("Wilmer no paga ni el bus"). La burbuja del cliente va a la izquierda (no tapa el carrito ni a él) y crece para arriba.
  Con bots: atento $12.000-12.500; quieto $2.000; al azar, $0 (le fió a Wilmer).
- Ojo con las pruebas sin pantalla: los cuadros van mucho más rápido que la física, y lo que se mueve al azar se promedia (todo parece fácil). Correr con `--fixed-fps 60`.

## PLOMO, el Dealer: lo horrible del mundo de las drogas (2026-10-10)

Esta parte tiene que mostrar cómo es vivir ahí (no un shooter genérico). Con humor negro, sin gore gratuito.

- **La olla** (el callejón): paredes de hollín (`H`), "SAPO = MUERTO" en unas pocas (`O`), gente fumando sentada contra las paredes (decorado: no pelean, son los clientes), colchones. Más oscuro.
- **El mural** de un pelado muerto (`R`: Q.E.P.D. 2005-2021, con un altarcito de velas al pie), al lado del teléfono donde llama la mamá.
- **Desaparecidos** (`X`) en la calle. Capítulo 3: la señora que pega los carteles le pregunta a Lisandro por Brayan, diecisiete años. Él lo conoce ("el martes; le debía cuarenta mil"). "En la pared hay cuarenta carteles. Lisandro conoce a once."
- **La esquina del farol: Camila y Verónica**, que trabajan para Lisandro (decorado: los tiros no les hacen nada). Verónica (mona, ojos azules, más alta) fue la novia de él, el protagonista; Camila, por celos, se metió en la mitad, y después de eso terminaron las dos en esa esquina. Capítulo 2: Lisandro les cobra la cuota (cobrar igual: balas, "todo se convierte en balas"; o dejarlo para la otra semana "con intereses"). Verónica tiene un morado debajo del ojo azul. En el final: la deuda cambia de dueño, y Verónica lo mira a él.
- **Enemigos:** los clientes (adictos: lentos, piden "una sola, se la pago mañana", arañan; lo que dice Lisandro al matarlos es lo peor de él), los de la otra banda (capucha y cuchillo), los sicarios de moto (casco, mini-Uzi), los tombos. **Los campaneros son pelados de doce años y no se pueden matar:** se tiran al piso antes del tiro ("ya saben") y no cuentan en las bajas.
- **Armas de Lisandro:** el puño con anillos, la pistola de oro y la **mini-Uzi de oro** del sicariato (rápida, gasta balas; la pistola rinde más). Los cartuchos que caen son balas. Cuando uno pasa a ser él (el protagonista), vuelve la escopeta; letrero grande: "AHORA ES ÉL".
- **El acertijo de Lisandro ahora rinde:** con el maletín le entra 0,12; en el bajón 1,6. Si alcanza la bolsita, **se cura** (+90, "la vida, prestada") y el bajón es corto; si se la revientan antes, el bajón es largo. Con bots: capítulo 3, 51-58 s con el acertijo y 82-83 s a lo bruto; revancha, 81 s (2 muertes) contra 131 s (5 muertes).
- Arte: `tools/art/draw_plomo_olla.py`.

## El camión del prólogo: que machacar no alcance (2026-10-10)

Con bots (`tools/bot_jugar.gd`, política nueva `camion`), antes: machacando se tumbaban las 22 motos en ~60 s,
y 13-14 las tumbaban las carretillas solas. Perder daba igual (caerse también llevaba a Lilato).

- **Los de casco se cubren** (goon, thug): solo se destapan cuando cargan el golpe (rojos) o tambalean.
  Pegarles antes: ¡CLANC!, se desbalancea, 0,75 s sin poder pegar, y le contraatacan. Los punks caen con lo que sea.
- **Patear al aire cuesta**: balanceo, 0,4 s sin pegar, y los de cerca se le tiran encima ("¡FIU!").
- **La harina se acaba**: 6 bolsas; cada uno tumbado a golpes devuelve una (máx. 9). Con harina no se recarga.
- **Las motos saltan las carretillas**, salvo las que están cargando o tambaleando: patearlas justo antes
  de que pase la carretilla es la jugada (¡JA!).
- **Caerse rebobina el sueño** (como UnMetal): "—No. Así no fue. Yo no me caí." Vida llena, las motos que
  faltaban. A la tercera: "Bueno, sí me caí. Pero rodé hasta el puente. Con estilo." (va a Lilato igual).
- Botellas un poco más espaciadas (2,4-3,4 s) para que el primer nivel no sea un muro.

Resultado: machacando, 2-3 caídas y la mitad de las veces no termina (110-160 s); jugando bien, 70-90 s con
0-2 caídas (el bot casi no esquiva botellas; una persona sí).

## Beat 'em up: que caerse cueste (2026-10-10)

Antes, quedar sin vida no costaba nada (machacar para levantarse, media vida, -1000 puntos): machacando se
ganaba todo, solo 1,5 veces más lento. Con bots (`machaca` contra `ritmo`), el que machaca caía 3-8 veces;
el de ritmo, 1-2.

- **Tres caídas en la misma oleada rebobinan el sueño** (como el camión y como UnMetal): "—No. No, no. Así
  no fue. A mí no me tumbaron tres veces." La oleada vuelve entera y él, con la vida llena. Dos veces por
  oleada; a la tercera lo acepta ("Sí me tumbaron. Pero me levanté."). Solo en oleadas de matones, no de jefe.
- **El contragolpe pega más** (daño +8 en vez de +5): machacar contra la guardia tumba.

Resultado: ritmo, 77-152 s, 0-2 caídas, sin rebobinar; machaca, 111-287 s, 3-13 caídas, hasta 2 rebobinadas
por escena. El prólogo sigue suave (el que machaca cae 3-4 veces y casi no rebobina).

## Trabajos de la ciudad: que el día 5 no se juegue igual que el día 1 (2026-10-10)

Lo que aburría en los trabajos no era cada turno: era que se repetían idénticos todos los días.

- **La Obra, un giro por turno** (`obra_turnos`), encima de los tres eventos de cada viaje:
  1. normal; 2. **LLUVIA** (todo resbala; bono de $3.000 si sube 14 o más);
  3. **EL INGENIERO** (casco blanco, "o_o" o "(cel)": si mira, botar ladrillos cuesta $2.000 y quedarse
     quieto $1.000; en el celular, afirmarse es gratis); 4. **WÍLINTON**, el cuñado de Germán, camina
     adelante y se para de golpe a contestar el celular ("¿Aló? ¡Mamá! Sí, sí comí."): frenar a tiempo o
     tumbarlo (y tumbarse). Del 5 en adelante se turnan.
  - Arreglado: los textos largos de abajo salían cortados (sobre todo en el celular): ahora la caja crece para arriba.
- **Rapidito, cada pedido se juega distinto** (los cuatro primeros en orden, `reparto_n`):
  hamburguesa (normal); **sushi FRÁGIL** (cada golpe cuesta el triple, más tiempo); **medicamentos URGENTE**
  (58 s, propina de $6.000 si llega en menos de 47); **torta NO CORRA** (más del 80% de velocidad un rato y
  la torta se ladea: "Ahora dice 'Feliz cumpl'"). El cliente reacciona según cómo llegó.
  Una vuelta limpia: ~43 s a fondo, ~54 s con la torta.

## Pedir: que no sea una tabla aprendida (2026-10-10)

El problema: cuando ya se conocen los siete tipos, pedir se vuelve buscar en una tabla. Lo que cambió (`scripts/world/Pedir.gd`):
- **Un especial por vez.** No sigue la tabla: al entrar dice una frase y hay que leerla. Los seis primeros salen en orden; después, al azar.

| Especial | Frase al entrar | Lo que funciona |
|---|---|---|
| El gringo | "Oh my God, a beagle! Is he famous?" | Lukas ($5.000, una foto). El chiste: "No Spanish. But I feel judged." |
| El colega | "(Viene uno con un vaso igualito al suyo.)" | El cartel. Pedirle: "¿Me pide a mí? Somos competencia." |
| La influencer | "¡Hola, mi gente! Aquí en la calle, re real..." | El cartel ($3.000, #humildad). Callarse también se castiga: "Ni para contenido sirve." |
| El predicador | "¡Hermano! ¿Usted ya conoce la Palabra?" | Quedarse callado y escucharlo ($2.000). |
| El borracho | "¡Feliz cumpleaños! ... ¿No es? ¡Igual!" | Pedir ($3.000), casi cualquier cosa. |
| El del banco | "(Es el del banco. El que le negó el crédito.)" | Pedir paga ($2.000); no pedirle nada sube el ánimo (+3): "Frente en alto. Panza en el piso." |

- **El día cambia la calle:**
  - **Quincena** (días 15, 30 y 45): todo paga el doble.
  - **Domingo:** salen de misa y hay más señoras.
  - **Lunes:** todo rinde un 25% menos.
- **Racha:** tres aciertos seguidos dan $1.000 de más, con su línea.
- **El globo de lo que dicen** crece hacia arriba desde el cartelito del tipo (antes se le montaba encima) y tiene fondo oscuro, para que se lea sobre los letreros.

## La ruta de Wilson y los eventos del día: que no se repitan (2026-10-10)

**La ruta de reciclaje** (`QuestDirector`, sección de la ruta): cada ruta trae su giro. Las cuatro primeras salen en orden; después, al azar entre los tres giros. Wilson lo anuncia antes de arrancar y lo comenta al pagar.

| Giro | Qué cambia |
|---|---|
| Normal | Como antes. |
| Don Chepe | Un señor de setenta años con carreta también recoge. Arranca a los 8 s, va a 30 px/s (él va a 60) a la lata más cercana y se demora 4 s en cada una. Solo se lleva 7 u 8 de las 12. Hay que ganársela o quitársela en la cara ("¡En la cara! ¡Me la quitó en la cara!"). No ve la dorada. |
| La lata dorada | La lata a la vista más lejos de Wilson brilla dorada y vale por diez. "Esa no la vendo. Esa la enmarco." |
| El camión temprano | 60 s en vez de 90, pero Wilson paga al triple. |

El reloj de la ruta subió a y=29, entre la lista de encargos y los avisos de arriba. Antes los avisos ("Recoge: lata", Chepe) lo tapaban.

**Los eventos del día** (`Conversations`, sección de eventos): cada uno tiene varias versiones. Las primeras salen en orden, cada una una vez; después, al azar (`_ev_variant`).
- **Redada:**
  - La de la cédula (la de antes).
  - **El patrullero nuevo,** que lee el procedimiento en el celular. Señalar a Lukas: "Caninos: no aplica. Que tenga buen día, señor perro". Quedarse callado: "No hay paso seis".
  - **Control de caninos:** mostrar el collar (antes del día 8, multa), esconder a Lukas detrás de la caneca ("esa caneca está moviendo la cola") o hacerse el muerto ("Canino: fallecido. No aplica"). Sin Lukas: el lazo vacío.
  - **La redada a otro:** grabar con el celular de flecha (no graba, pero ellos no lo saben), pararse al lado en silencio o irse.
- **Pelea:**
  - La del cuchillo (la de antes).
  - **Las señoras y el último pandebono:** partirlo, que se lo coma Lukas ("se lo comió el juez") o mirar.
  - **Los borrachos del Medellín y el Nacional,** que terminan abrazándolo.
  - **El que agarra a la muchacha del brazo:** meterse sin pegar, que Lukas ladre o silbar, o irse ("Eso sí lo oí. Eso sí cuenta.").
- **Ayuda:**
  - La niña perdida y el señor diabético (las de antes, ya no según el día par o impar).
  - **Las naranjas de la señora contra la buseta:** once de doce, porque Lukas tiene una.
  - **El gringo perdido** (él es mudo): señalar el norte lo manda al motel; el mapa en el andén da $5.000; que Lukas lo lleve da $8.000 ("five stars").
  - **Princesa, la perrita del norte:** recompensa de $10.000 y una puerta en la cara.

Probado: cada versión de cada evento con cada opción, sin errores. La ruta con Chepe y con la dorada, con capturas.

## Sentarse, las puertas que empujan, él mudo del todo y la ciudad de noche (2026-10-10)

**Sentarse** (`Player.sit()` y `stand_up()`; `Conversations._sit_bench`, `_sit_swing`, `_sit_ground`):
- Camina al asiento, se agacha y se sienta. En la banca y el columpio, de frente; en el piso, de espalda (la tele de TV RADIO, el atardecer, el río con Samuel, el kiosco de noche).
- Respira (baja la cabeza a ratos) y parpadea. Se para solo cuando el jugador lo mueve.
- Lukas se acomoda al lado (`Lukas.settle()`): va, se sienta, da la vuelta de perro, se echa y al rato se duerme. Se levanta cuando él se para.
- Arte: fila 4 del protagonista (`draw_protagonist_adult.py`); Lukas echado y dormido en la fila 4 de su hoja (`draw_lukas.py`).

**Puertas que empujan** (`Door.shove`): tres casas del barrio (NO DAMOS NADA, la de los tres candados y la del "Andate") abren y lo sacan a empujones. Sale volando hacia atrás, cae sentado y se levanta (`Player.shoved()`). Quien abre grita, y su dibujo coincide con su voz. Le baja el ánimo (-3). Los textos de las otras puertas pasaron a tercera persona.

**Él no habla, ni por dentro.** Se quitaron todas sus líneas ("ÉL" y "ÉL, A LUKAS") de la vida real y de los sueños, unas 250. Lo que llevaba información quedó como narración en tercera persona:
- el rayón de la moto lo hizo él;
- lo de la Clínica Eiren no lo sabe nadie;
- el clavel es para Victoria, que cumple doce el 29 de octubre;
- la mano es la misma de su papá;
- el paquete de Zaida no era harina.

Hablarle a Lukas ahora se narra ("le habla bajito, al oído"). En el juego de miradas, sus turnos son narración con su retrato prendido. Los avisos, los objetos, la moto, Pedir, Rapidito y la Obra pasaron a tercera persona. Solo va a hablar donde se decida después. Las líneas "YO" de los sueños (donde habla en voz alta) quedaron como estaban, pendientes de decisión.

**La ciudad de noche** (`scripts/systems/NightLife.gd`, de 20:00 a 5:30, en los lugares de afuera):
- **Se van:** los pelados del fútbol, las palomas, Fabiola, Leonor, Efraín, Aurelio y los del ajedrez.
- **Salen** (`Conversations._noche`):
  - el celador con linterna, que hace la ronda;
  - el de los perros calientes, en el carrito con bombillo (vende);
  - dos con un parlante en el kiosco (se puede sentar con ellos una hora: compañía);
  - una pareja en la banca;
  - el que fuma en la puerta del billar;
  - la señora del tinto en el Parque (vende).
- **Se apagan:** la panadería (21), el café (22), la tele de TV RADIO (20), la tienda, las flores y Foto Express. La vidriera queda oscura.
- **Se prenden:**
  - ventanas en las casas, que se van apagando entre las 22:30 y la 1:30 (cada casa a su hora);
  - el letrero BILLAR EL GUAYABO, rosado y titilando (de día es un letrero gris que nadie mira);
  - el bombillo del carrito.
- **Gente de a pie:** de noche pasa menos, y después de las 23, casi nadie.

## La moto: llegar a tiempo, Lorena atrás, música de motero (2026-10-10)

- **La ida a la casa de ella tiene reloj** (`MotoRide.TIME_LIMIT`, 60 s; la vuelta limpia a fondo dura unos 43 s). Arriba dice QUEDAN y titila en rojo los últimos 10 s. Si se acaba: "TARDE", la puerta cerrada, y el recuerdo se rebobina ("No. Así no fue. Llegó a tiempo.") y se vuelve a empezar desde la salida. Las carreras de los sueños y Rapidito heredan de MotoRide sin reloj (`time_limit = 0`).
- **La casa de ella:** cuatro pisos de ladrillo, placas, balcón con reja, el tanque azul y las varillas. Está al lado de la meta y en la imagen de la llegada (`draw_moto.py`: `casa()`, `casa_ella()`, `llegada()`).
- **Lorena tiene el pelo castaño** en todas sus hojas: la ciudad (`draw_gente.py`), el retrato, la jefa del sueño (`draw_lilato.py` + `apply_palette` solo de su hoja), los dos shooters y la llegada.
- **Los árboles de la pista son verdes.**
- **La primera vuelta** (`scripts/world/MotoLorena.gd`, escena `MotoLorena.tscn`; también en el menú de pruebas):
  - Después de la llegada, ella se sube atrás y se dibuja encima de él (`lorena_atras(_risa).png`). No hay reloj.
  - Ir a más del 72% un rato hace que lo regañe (diez frases).
  - Ir tranquilo (del 30 al 62%) unos 5 s la hace reír, y rebota.
  - Ir demasiado lento la hace burlarse. Si se estrella: "¡¿VIO?! ¡SE LO DIJE!".
  - Al final, en el mirador: cuántas veces se rió y cuántas lo regañó, y dos finales según cuál ganó. Él ya no habla: señala el puesto de atrás.
- **La música:** `moto_ride` ahora es blues-rock de motero (`compose.py: outlaw_song`): shuffle en mi, doce compases, guitarra saturada con el boogie, bajo, slide arriba y una batería que pisa fuerte.

## Pedir de noche y la plata en el bolsillo (2026-10-10)

- **Pedir se puede hasta las 23.** De 19 en adelante pasa otra gente: siete personas, la vereda a oscuras y por lo menos un ladrón.
  - **El ladrón:** "—Uy, qué vasito tan lleno".
  - **Los de la esquina.**
  - **La enfermera** que sale del turno.
  - **El celador.**
  - **El borracho** y **la policía.**
- **Se suma [E] pararse (defenderse).**
  - Contra el ladrón: pararse lo espanta el 65% de las veces y el ladrido de Lukas el 80%. Si sale mal, se lleva el 60% de lo juntado y además hay golpe (ánimo -6, temblor de pantalla).
  - Quedarse quieto, pedirle o hacerle un chiste es entregarle la plata.
  - Pararse frente a gente que no viene a robar la asusta.
- **Antes de dormir en el cambuche:** con $2.000 o más en el bolsillo, pregunta si la guarda en la alcancía (`SleepSpot._pocket_check`).
- **Dormir con plata encima en el cambuche**, aunque gane la defensa de la noche, tiene riesgo de despertar "con el bolsillo rajado" (la mitad). Lo de la alcancía no se toca. No cuenta como algo violento. Afuera del cambuche, el robo de siempre.

## Misiones con detalle, recuerdos, desmayo y pausa (2026-10-10)

- **El detalle de las misiones** (`InventoryUI`, `Quests.detail`):
  - En la mochila (Tab), ARRIBA desde la fila de arriba sube a las misiones. Arriba y abajo eligen; bajando de la última, se vuelve a la mochila.
  - Si hay más de cuatro misiones, la lista corre y arriba dice cuál es (7/12).
  - La elegida muestra, en el lugar de la mochila, su tipo (PRINCIPAL, SECUNDARIA, OPCIONAL) y qué hacer, dónde, a qué hora y qué se gana.
  - Las 64 misiones tienen su `detail`. Algunas suman el estado en vivo: los requisitos de la cédula y de la Defensoría con [X]/[ ], el día de la audiencia o de recoger la cédula, la plata de la alcancía.
- **Los recuerdos** (`scripts/systems/Recuerdo.gd`, arte en `tools/art/draw_recuerdos.py`):
  - Una foto sepia aparece con un destello, con la cajita de música. Se narra en tercera persona, se voltea y atrás hay algo escrito a mano. Cada una sale una sola vez.

| Recuerdo | Cuándo sale |
|---|---|
| La Renegade, el primer día (él sin barba) | Antes de arrancar el recuerdo de la moto |
| Lorena atrás en la moto, riéndose | Al final de la primera vuelta, en el mirador |
| Victoria recién nacida, 29 de octubre | La primera vez que la ve en la reja del colegio |
| Lukas cachorro en una caja de zapatos (talla 42) | La primera vez en la veterinaria |
| La oficina: EMPLEADO DEL MES ("El único mes") | Al terminar la obra, cuando el maestro le pregunta qué hacía antes |

- **El desmayo** (`Survival.gd`):
  - Con el hambre en cero ya no se cae de una: cuenta de 10 a 1 en rojo, con latido y la cámara meciéndose. Él corre al 1,9x.
  - Si llega a su cambuche (si está en esa escena), se desmaya adentro, protegido, y no le falta nada.
  - Si come algo, se le pasa.
  - Si la cuenta llega a cero en la calle, despierta horas después en la plaza y le robaron: una o dos cosas de la mochila y, la mitad de las veces, la mitad de la plata del bolsillo.
  - En un minijuego, se desmaya directo.
- **El menú de pausa** (`autoload/PauseMenu.gd`):
  - Se abre con P o Esc, con Start del control, o con el botón de dos rayitas en el celular. Para el juego, y solo se abre con nada abierto.
  - CONTINUAR.
  - CONTROLES: AUTO / SI / NO (los mismos del título).
  - SALIR POR AHORA, con confirmación: en la vida real guarda ahí mismo y se sigue en la entrada de ese lugar; en un sueño no se guarda y se sigue desde el último cuenco.

## Las viñetas de la noche y los secretos de PLOMO (2026-10-10)

**Las viñetas** (`tools/art/draw_vinetas.py`, `NightSequence._vignette`): cuadros de 240x100 arriba del texto de la noche. Tienen degradados tramados, luz de lado y siluetas con borde de luz. Entran despacio y se acercan un poquito mientras se lee. Los personajes no son muñecos: él y la gente tienen proporciones de adulto, armados sobre un esqueleto (`vinetas_motor.figure`), y Lukas es un beagle de su tamaño (ver el motor).
- **acostarse:** el farol con la lluvia fina; él sentado en el cartón contra el pilar del puente, y Lukas dando la vuelta antes de echarse.
- **despierta:** el amanecer por el arco del puente; él dormido de lado con Lukas hecho un ovillo contra el pecho, y el primer rayo de sol encima.
- **despierta_lluvia:** el mismo amanecer, gris y lloviendo (las mañanas que "Llovió toda la noche").
- **despierta_solo:** sin Lukas, el hueco en el cartón, el collar en la mano y el color lavado.
- **golpeado:** contra la pared, la mano en la cara, la caja volteada y las latas regadas; Lukas le lame la mano. Sale con un sueño perdido, un robo o la defensa de la noche perdida.

**Los secretos de PLOMO** (`Plomo.gd`: `add_secret`, la pared "S"; mínimo uno por nivel):
- La pared falsa imita la de al lado, un poco más oscura. De frente se abre como una puerta y aparece "¡SECRETO! (1 de 1)". El resumen del nivel cuenta SECRETOS x/y.

| Nivel | Dónde | Qué hay |
|---|---|---|
| PLOMO 1 (él de niño) | Un cuartito en la esquina de arriba del callejón | El afiche del Mundial 94 y la pelota de trapo; chaleco y comida |
| PLOMO 2 (la oficina) | El mismo lugar | El cuarto de las fotocopiadoras, la caja con su nombre, el cactus |
| PLOMO 3 (el hospital) | El mismo lugar | Su historia clínica: "Paciente colaborador. Habla poco." |
| El operativo (sueño final) | El mismo lugar | El dibujo de Victoria: "EL DEL PERRO" |
| Dealer 1 | En el bloque de la calle | Martín, el hijo de Lisandro (9 años), jugando Switch: Mario y la luna del sombrero. Sentarse a jugar con él (vida llena; "No le cuente a nadie. Que el Gato juega Mario.") o irse a trabajar ("Eso dijo ayer."; balas) |
| Dealer 2 | En el bloque del callejón | El escondite de Lisandro: la plata de verdad y la carta de la mamá sin abrir |
| Dealer 3 | En el bloque de la calle | El colchón y la pistola de agua de la foto |


## Alejandro, el pelao de la calle (el espejo de su infancia)

Código: `scripts/systems/Nino.gd` (lo agrega `Location` en los lugares de afuera). Arte: `tools/art/draw_nino.py`.

- **Quién es:** un niño de unos ocho años, de la calle. Nadie lo quiere. Es lo que el protagonista fue a esa edad.
- **Cuándo sale:** desde el día 2, algunos días (85% hasta conocerlo, después 60%), a una hora y en un lugar al azar del barrio o del Parque, por tres horas. Un aviso del narrador dice que algo pasa cerca.
- **Le hacen daño** (en orden la primera vez, después al azar): el tendero a escobazos, un señor con la correa, solo y golpeado ("me caí"), los grandes que le quitan las chanclas, el celador que lo saca de una oreja, el balde de agua de noche.
  - Él se mete sin hablar (se para en medio, agarra la correa por la hebilla, suelta a Lukas, se sienta al lado, le pone el saco) o sigue de largo (baja el ánimo).
- **El niño lo ayuda a él** (desde la primera vez que se ayudaron): medio pan y el dato de la caneca, una moneda devuelta, el aviso (esa noche no le rajan el bolsillo), una botella de agua.
  - Además, con dos o más encuentros: si se desmaya en la calle, 60% de que el niño le cuide la mochila y no le roben.
- **El tono:** nada de lástima directa. El niño es canchero y rápido, como él: negocia, se burla y nunca se queja. Lo triste está en el detalle que se le escapa, y la lástima la pone el jugador.
- **El espejo:** cada encuentro cierra con una línea de la infancia de él, en tercera persona (la correa de Mauricio, dormir en el patio, "me caí", la lonchera). La primera vez sale el recuerdo `infancia`: la foto del colegio, de manga larga todo el año.
- **El nombre:** a la tercera vez dice que se llama Alejandro ("Completo. Alejo es para los amigos, y usted todavía está en periodo de prueba").
- **Qué es:** la proyección de él a los ocho años, con sus traumas. Se llama igual. Nunca se dice: se entiende en la despedida.
- **El final:** después de que muere Lukas y unos días antes de que se muera él. Desde el día siguiente a la muerte de Lukas, Alejandro lo espera en el barrio, vestido como él en la foto del colegio (`Nino._final`). "Vengo a entregar el puesto." Dice que va a tener un perro que llega en una caja de zapatos, talla 42. Le dice "Alejo". Le deja la foto, con "Sí aguantó" escrito a lápiz. Don Germán cuenta que lleva semanas viéndolo sentarse solo en ese andén.
  - El último sueño (y su muerte) espera a que pase la despedida, salvo el día 44 (`NightSequence._dream_when`).
  - Ya no existe el final con el Padre (`nino_hogar`): contradecía que el niño es él.
- Misión secundaria `nino` ("El pelao de la calle"), con el conteo de veces que se ayudaron.


## La policía es la que lo tiene en la calle (la ficha)

- **Qué pasó:** después del operativo no hubo cargos y la denuncia se retiró, pero la ficha quedó abierta. El sargento firmó que estaba armado; si él consigue casa, trabajo o abogado, alguien pregunta por esa firma.
- **La orden:** que no se quede quieto en ningún lado, que no tenga dirección. Esa noche le sellaron la casa y le guardaron la cédula en un cajón de la estación (por eso tiene que sacar el duplicado).
- **Dónde se ve:**
  - la redada `ficha` (`Conversations._redada_ficha`): no le piden papeles a nadie más; lo reportan por radio y lo mueven;
  - el cambuche del Parque: la policía se lleva solo el de él;
  - el tablero de "¿Quién es él?": dos líneas nuevas al resolverlo;
  - el agente del operativo lo confiesa en la iglesia;
  - Alejandro vio su foto en la estación, con un letrero que dice "que circule" (`Nino.gd`, ayuda `tombos`).
- **Cómo se acaba:** en la Defensoría, con la página 14 y el testigo, la defensora oficia a la estación (`flags.ficha_cerrada`). Desde ahí las redadas no son con él y la policía no le toca el cambuche.


## El gallo y los vicios de la noche

- **El gallo:** cuando se hace de noche (20:00) canta un gallo (`assets/audio/gallo.wav`, `tools/audio/gallo.py`) y el narrador lo dice. Es la señal de que sale la otra gente del barrio.
- **Quiénes salen** (`NightLife.NIGHT_PEOPLE`, lo que dicen en `Conversations._noche`): las muchachas del poste (Verónica, Mitchelle y Dayhana; Verónica es la de los ojos azules, la ex de él: no ofrece, lo mira), los de la esquina (el Flaco), el jíbaro; además de los que ya estaban (los de la cerveza, el billar con su neón).
- **La regla:** él pelea esos vicios siempre, y los quiere siempre. Cada tentación deja ceder o aguantarse:
  - aguantarse baja un poco el ánimo (las ganas se quedan) y la narración muestra que quiere (`_vicio_no`);
  - ceder da algo ya y cobra después (`_vicio`): la pola (compañía y ánimo; al otro día, guayabo), apostar en el billar ($2.000; 45% de ganar $5.000), un rato de compañía ($10.000: ella habla una hora), llevar la caja de los de la esquina ($15.000; despierta a PLOMO).
- **La droga, nunca:** con el jíbaro no hay opción de recibir, por más que insista (cinco intentos que suben: gratis, "usted compraba", "¿para quién se cuida?", los saludos del Gato; al final se rinde él). Las dos opciones son seguir de largo.
- Cuenta en `flags.vicio_si` / `flags.vicio_no` (todavía no cambia nada más: sirve para el final o el resumen).


## El prólogo nuevo: la huida a pie (reemplaza al beat 'em up)

Código: `scripts/prologue/Huida.gd`, escena `scenes/prologue/Huida.tscn`. Todo se dibuja por código (techos, puente, luz del helicóptero); usa los muñecos de lado del prólogo, a Lukas y a dos policías.

- **La trama:** Diana Carolina lo denunció por lo del aborto (que él la obligó; armado y peligroso). Lorena confirmó la dirección, mandó la foto y agregó lo del arma. Llegaron a las 21:40 y dispararon sin preguntar. Él estaba haciendo arroz.
- **Tramo 1, los techos** (unos 45 segundos): corre solo. Saltar muros y huecos, agacharse bajo la ropa tendida, y esconderse detrás de un tanque cuando barre la luz del helicóptero (tres veces).
- **Tramo 2, el puente** (unos 15 segundos): más rápido; las patrullas atrás le comen la ventaja sola. Conos (saltar) y ráfagas (agacharse). Al final, el retén: hay que saltar por el pedazo de baranda roto, al río.
- **Una sola barra, la VENTAJA:** tropezar, caerse o que lo alumbren la baja. En cero lo agarran y el narrador se corrige ("Así no fue. Si lo hubieran agarrado, no habría Día 1"): se repite desde el último tanque. No hay game over.
- **El final:** el río, negro, y despierta debajo del puente. Día 1, 06:17. Aprende *Aguante*, como antes.
- **El beat 'em up de Lilato** ya no es el prólogo. Sigue completo en el menú SUEÑOS ("CALLEJON: LILATO"); falta decidir en qué noche entra como sueño de la historia.


## El calendario de 50 días y el beat 'em up como tres sueños (2026-10-11)

**Esta sección manda sobre las fechas que aparecen más arriba en el documento** (donde diga día 25, 38, 44 o 45).

| Hecho | Antes | Ahora |
|---|---|---|
| Lukas se enferma | día 25 | día 30 |
| Lukas muere, a más tardar | día 38 | día 43 |
| El último sueño, sí o sí | noche del 44 | noche del 49 |
| El cumpleaños de Victoria | día 45 | día 50 |

- La primera mañana dice "en siete semanas" (antes "en mes y medio").
- **El beat 'em up** dejó de ser el prólogo y son tres sueños de la historia, cada uno una sola escena:
  - `callejon1` (el callejón): la segunda noche;
  - `camion` (el camión de harina): tres días después;
  - `lilato1` (Lilato y la serpiente, en el puente): tres días después.
- Al salir de cada escena, `SceneRouter.go` desvía lo que seguía en la cadena vieja (camión, Lilato, CONTINUE?) y vuelve a la noche (`flags.sueno_suelto`). Desde el menú SUEÑOS la cadena completa sigue igual.
- En la libreta salen como la serie "El callejón (Lorena)".

## El narrador, el prólogo con láminas y lo nuevo del barrio

- **El narrador:** lo que no dice nadie (quién = "") lo cuenta EL NARRADOR, con su placa. Alguien está contando la historia de él: por eso él no habla. La narración se sigue escribiendo como acotación, entre paréntesis; `Dialogue` se los quita al mostrarla.
- **La música se apaga:** MUSICA: SI / NO en el título y en la pausa (`MusicDirector.set_enabled`, se guarda en `user://ajustes.cfg`). Calla solo el bus de música.
- **El prólogo, antes de correr:** cada texto trae su lámina (`scripts/prologue/Laminas.gd`), que se dibuja sola, raya por raya, sobre el negro. Suena "panico" (un corazón, un reloj, una sirena lejos) y se acelera con cada texto. Al correr entra "huida". Los dos temas salen de `python tools/audio/compose.py prologo`.
- **El prólogo, corriendo:** además de saltar y agacharse hay balas, de atrás y de frente: avisan en el borde y pasan; las altas, agacharse; las bajas, saltar. La primera vez que lo van a agarrar, Lukas se devuelve y los muerde: la ventaja vuelve a la mitad. Una sola vez.
- **El fútbol (`Penal.gd`):** una tanda de seis, por turnos: unas veces tapa él, otras patea (la mira va y viene; después, la fuerza). Marcador él contra los pelados. Pasa una hora.
  - La pelota va por una curva: con las flechas mientras sube la fuerza, le pega con efecto (sale para un lado y se tuerce al otro; el pelado se tira para donde parece que va, pero el tiro va menos preciso). Pega en los palos y en el travesaño (suena, tiembla y a veces entra), rebota en las manos del que ataja y se queda en la red, que se infla.
  - La barra del supertiro: cada gol y cada atajada la llenan (dos). Llena, con F: pateando, el supertiro (un cañonazo de fuego que va adentro sí o sí; si el pelado adivina, se mete al arco con pelota y todo); tapando, la superatajada (cámara lenta, el cuerpo del pelado ya no miente y él se estira hasta la zona de al lado).
  - Los pelados también tienen barra: llena, tiran la hoja seca (sube por encima del travesaño y baja al ángulo, con el cuerpo diciendo mentiras).
  - Los sonidos: `tools/audio/futbol_audio.py` (la patada, el palo, la atajada, la red, el fuego).
- **La veterinaria:** con Lukas sano, la Dra. Pilar tiene una coca de concentrado: Lukas come ahí una vez al día, y de visita en visita ella le va cogiendo confianza (`_vet_coca`, `flags.pilar_n`). A la cuarta le regala una bolsa.
- **La tienda de videojuegos** (`scripts/systems/Vecindario.gd`, City, al lado del billar; abre de 10 a 8): el que atiende es el único amigo que tiene. No tiene nombre: ninguno de los dos se lo ha preguntado al otro. Charlar o jugar en la consola de exhibición (`_amigo`).
- **Los otros perros** (`Vecindario.gd`): cuando Lukas pasa cerca de un perro de la calle, juegan o pelean. Sin comer, casi siempre pelean (65%); comido, casi siempre juegan. Una vez al día por perro.
- **La moto:** [Q] sostenido, yendo rápido: en una rueda. Aguantar un segundo da un empujón; estrellarse así cuesta más. Con Lorena atrás, cada queja la mueve: unos segundos con la dirección casi al doble de nerviosa.
- **La primera memoria:** el que patea la pelota es él de niño (el mismo dibujo de Alejandro).

- **El billar El Guayabo, por dentro** (`scenes/world/Billar.tscn`, `scripts/world/Billar.gd`): solo de noche, por el guardia de la puerta, que mide lo que mide la puerta. Solo, entra. Con Lukas hay que darle $5.000 esa noche o hacerle un favor (cargar las canastas, contestarle a la mamá, tenerle la puerta); al tercer favor, Lukas es de la casa. Adentro: la tarima con dos tubos, la barra, las mesas (la apuesta de siempre) y un borracho. Son vicios: cuentan en `vicio_si` / `vicio_no`.
- **Las viñetas de la noche** (`tools/art/draw_vinetas.py`, motor en `tools/art/vinetas_motor.py`): ningún texto de la noche va sobre negro solo. Una hoja por lugar donde duerme (`assets/ui/vinetas_<lugar>.png`), con una fila de cuatro cuadros por momento: cómo quedó dormido, el sueño, cómo despierta (al alba o de noche), golpeado y el último amanecer; cada una con y sin lluvia, con y sin Lukas. Y una hoja de momentos: el intruso, la noche de Lukas, el entierro, el collar. Si llueve esa noche se decide al acostarse, para que se vea llover. Con el texto en el centro (el resumen, la pelea), la viñeta queda detrás, apagada.
  - El acabado (`vinetas_motor.POLISH`, lo prenden las viñetas y las de la tele; los retratos no): los actores llevan un contorno oscuro solo del lado de la sombra (los despega del fondo); las superficies grandes (paredes, muros, pisos, desde 1500 píxeles) llevan manchas de desgaste tramadas en manchitas de 2x2; donde la pared se junta con el piso, una sombrita de contacto; de noche, lo que brilla (ventanas, faroles, letreros, la tele) suelta un resplandor de su color; y las esquinas se oscurecen un poco (tramado).
- **[B] en un menú con "Salir":** elige esa opción (si no hay, la última, como antes).
- **Lo que se ve al actuar** (`Conversations`): pagar (`_pagar`: los billetes van de su mano al otro; uno, tres o el fajo), bañarse (`_bano_anim`: entra a la caseta, cae el agua, Lukas ladra afuera con una oreja parada) y el columpio (se mece mientras se impulsa).
- **Los bultos de Don Germán** (`CarryJob.LIFTS`): cada bulto cuesta más: el verde más angosto, la raya más rápida, y los dos últimos piden dos aciertos. Camina más lento con cada uno.
- **Parar el tráfico** (`Traffic._bust`): doce segundos seguidos con carros frenados por él (o por Lukas) traen a un agente: lo saca al andén y cobra $2.000, o un comparendo "pedagógico" si no tiene. Una vez por hora.
- **Moto, sin manos:** [X] sostenido, yendo rápido. No puede girar; si aguanta 1,2 segundos, gana el empujón.
- **El palo de guayaba** (`Vecindario`, `_frutas`): comida gratis en el primer árbol con hojas de cada lugar. Quita 10, 6 y 3 de hambre; a la tercera se hostiga y no puede con otra hasta mañana.
- **El cambuche en el kiosco viejo:** también se puede armar ahí (es el único lugar con techo de verdad).
- **El colegio de Victoria:** queda en el centro, el edificio amarillo del fondo, arriba a la derecha, pasando la Defensoría. La misión y el narrador lo dicen.
- **El prólogo:** los textos entre tramos (los techos, el río, "así no fue") también tienen lámina.
- **Dónde se arma el cambuche** (manda sobre lo anterior): donde lo armaría alguien que vive en la calle: lugares solos, o un parque. Debajo del puente (`rio`), el lote del fondo junto al río (`lote`: un carro quemado, un palo seco, no pasa nadie; es donde menos roban), el parque y el kiosco viejo. En el callejón de las bodegas ya no: queda al lado del billar. Ahí se puede dormir, pero es donde más roban. Las partidas con cambuche en el callejón lo pasan al lote.
- **Todo el que habla tiene retrato** (`tools/art/draw_retratos.py`, `Dialogue.SPEAKERS`): 35 retratos nuevos para los de paso (el guardia, el de la tienda, los agentes, las muchachas, los pelados del lote, señores y señoras, el borracho, el jíbaro...). Sin retrato solo quedan las voces sin cuerpo: una radio, un megáfono, un letrero.
- **Ningún texto va sobre negro solo** (`scripts/ui/Vineta.gd`): además de la noche, los carteles de cambio de escena (`SceneRouter._pic_for`) llevan su viñeta arriba y el título debajo: "DIA 0" (la noche del operativo), "DIA N" (cómo amaneció donde durmió, con la lluvia de anoche), un sueño (dormido donde durmió, con lo que sueña saliéndole de la cabeza), "BILLAR EL GUAYABO", "..." (el desmayo), "ANTES" (la moto) y "FIN" (la reja del colegio). El título del juego tiene de fondo a los dos dormidos debajo del puente; la pantalla de CONTINUE?, lo mismo, apagado; el rebobinado del sueño muestra la cinta. Los textos entre tramos del prólogo usan las láminas (`Laminas.gd`).
- **Los retratos, redibujados** (manda sobre lo anterior): `tools/art/draw_retratos.py` ya no hace bustos facetados. Usa el motor de las viñetas (`vinetas_motor.py`): pixel art nítido, tres tonos por material, tramado en el borde de la sombra, contorno de tinta y, por la izquierda, un borde del color de cada uno. Cada cara se arma por partes con el mismo reparto (`CAST`): forma (hombre, mujer, gordo, viejo, niño), pelo, barba, gafas, sombrero, ropa y gesto. Los bajitos se dibujan a escala (no se encoge la imagen). Lukas sale del mismo archivo (`lukas.png`, `lukas_ladra.png`: ladrando, con una oreja al aire); `draw_retrato_lukas.py` ya no existe. `python tools/art/draw_retratos.py --hoja salida.png [id ...]` hace una hoja para mirarlos.
- **El último trabajo: José Mario Camilo** (`Conversations._ultimo_trabajo`, lo pone `Vecindario.gd`): es la estocada: el mundo cobra cuando uno está más débil. Su jefe de antes, el del correo abierto, sale en el centro, en la puerta del edificio de vidrio, desde el día siguiente a la muerte de Lukas (de 7 a 6). Le ofrece un trabajo de un día por $40.000 (justo lo que le completaría el regalo de Victoria): sacar cuatro cajas del archivo, las de la gente que ya no trabaja ahí (Walter, Nicolás, Eddy). La cuarta es la de él: un pocillo, una planta de plástico y el carné con la foto en que sonríe. Al final le descuenta todo (la retención, el parqueadero de la caja, el carné, el uniforme): le quedan $2.800, "para el bus" (menos $500 por caja que se le caiga). Firma que recibió a satisfacción y que no vuelve, y lo sacan por la puerta de servicio. Deja el carné encima de la caja, con la foto para arriba. Después de este, nadie más le da trabajo (`_sin_trabajo`, `_job_today`): Germán metió a un sobrino, la obra no recibe mayores de cuarenta, la app bloqueó a Yeison, la ruta de Wilson tiene dueño; los demás ya no ofrecen. Vender latas, pedir y el plato de la olla siguen. El último sueño espera a que lo tome, menos la noche del 49.
- **Cómo es José Mario Camilo:** medio calvo; se hizo implantes y le están saliendo a parches. Chivera. Dientes torcidos. Tira la piedra y esconde la mano: nada lo decide él (lo dice nómina, seguridad, el inventario, el protocolo), y "si alguien pregunta, yo a usted hoy no lo vi". Su retrato lo muestra así; el muñeco del mapa todavía es el de antes.
- **El buhonero, el que solo ve él** (`Conversations._buhonero`, lo pone `Vecindario.gd`): "Me dicen el Lobo. Yo no vendo: yo soluciono." Desde el día 3 sale algunos días en un sitio solo del barrio (30% al principio; 5% más por cada vez que lo ha visto, hasta 75%). Le "hace" favores: el hambre, $15.000, que esa noche no lo toquen, la fiebre de Lukas. No recibe plata: verlo cuesta 1 de locura y un trato 3, y con la locura se le borran las caras a los demás (`GameState.sameness`). Entre más lo busca, más sale y más solo queda. Lo de Lukas viejo no lo arregla: "eso no es un problema, eso es el tiempo". Los favores van entre comillas: después de cada uno queda una pista de quién lo hizo de verdad (el almuerzo era de alguien, a Germán le faltan quince mil en la caja, queda un palo del tamaño de su mano, una jeringa de la Dra. Pilar en el bolsillo). Nunca se dice.
- **Tom Queen no habla** (manda sobre lo anterior; lo pidió el usuario el 19 de octubre: "no debe hablar si no hasta que yo lo diga"): pelo y bigote blancos, siempre de vestido y sombrero negros. Todo lo que hace lo cuenta el narrador, con los dos frente a frente (`Dialogue.face_off`, los dos callados): la venia con el sombrero, el saco abierto como una vitrina, el dedo que niega la plata y le señala la sien. Ya no dice "ahijado" ni "algunos me dicen el Lobo". En el mapa tiene su muñeco (`draw_gente.py`, `tomqueen.png`): el más alto, con el sombrero, y a él no se le borra la cara.
- **Él habla una sola vez en todo el juego, y es para Victoria** (manda sobre todo lo anterior; lo pidió el usuario el 19 de octubre: "que no hable el protagonista. quiero que sea especial para victoria"). Ni en los sueños: lo que decía en la lucha libre ("EL PELADO") y en PLOMO ("EL QUE NO SE MUERE") ahora lo cuenta el narrador. La única palabra es en el cumpleaños, en persona (`Conversations._cumpleanos`), los dos frente a frente: ella pregunta "¿Puedo decirle papá?", el narrador dice "Abre la boca. Esta vez sí sale." y él dice "—Sí." La placa, por única vez, dice PAPÁ. La palabra la escogió el usuario.
- **El buhonero es Tom Queen, el padrino**: alto, bigote blanco, sombrero negro, todo de negro. Le dice "ahijado"; se presenta como su padrino ("los padrinos aparecen cuando hay problemas") y "algunos me dicen el Lobo". En el mapa sale más alto y oscuro que los demás; su retrato es `tomqueen.png`, con la placa "el padrino".

## Tanda de arreglos (pedidos del 15 de octubre)
- **La tienda se llama LA CAVERNA DEL GAMER** (el canal de un amigo del usuario). El que atiende es Álvaro, pero le gusta que le digan **Al**.
- **El pan:** $600 (el de ayer, "duro pero honrado").
- **Victoria:** nació con 2.810 gramos y 51 centímetros. Le gusta el morado con negro; lo rosado es de Lorena.
- **Zaida:** pelinegra (como Diana Carolina; las únicas castañas son Lorena y Victoria), gordita, blanca, de ojos grandes (como Lorena).
- **La clínica se llama Eiren.**
- **El puesto de doña Rosa:** el encargo del día también lleva al minijuego (antes solo se contaba).
- **Horarios:** la panadería abre de 6 a 9 de la noche y el café de 6 a 10; cerrados, la puerta no abre. Doña Rosa recoge el puesto a las ocho.
- **Verónica:** si él insiste (la quinta vez), le dice una vez "David Lisandro". Una vez, y ya.
- **La veterinaria:** la coca de Lukas también con Lukas enfermo, antes de lo demás.
- **Las canecas:** se esculcan una vez al día: comida, monedas, nada... o una rata (15%).
- **La esquina:** sin postes en la avenida; semáforo (verde, amarillo, rojo) y cebras. Los carros frenan en la raya. Si uno se les atraviesa, pitan con groserías.
- **El tiempo jugado** se cuenta (`GameState.play_time_text`) y sale al final, con el FIN.

## Viñetas más grandes y nuevas
- Las viñetas de la noche y de los carteles de escena salen 1.2 veces más grandes (de 16 a 304 de ancho); el texto va debajo.
- **El prólogo** ya no es tiza: cada texto de la huida tiene su viñeta del mismo motor (`vinetas_prologo.png`, `scripts/prologue/Laminas.gd`).
- **Mirar desde el puente:** de día y al atardecer sale lo que él mira (el río, los cerros; él y Lukas de espaldas). `Vineta.show_over()` pone una viñeta grande encima del juego mientras dura el diálogo.
- **Lisandro en el espejo:** antes de cada capítulo del Dealer, Lisandro se mira en el espejo (en el capítulo 3, con la bolsita). En la revancha no: ahí él es él.
- **Las caras de Lukas:** cada acción de Lukas sale con su retrato al lado del aviso (`Narrator.say(texto, arriba, cara)`): feliz, come, pelota, escucha, triste, huele, enfermo, truco, ladra.

## El cambuche por dentro, y armar
- **Se arma en el cambuche, no en la mochila.** Las mejoras con receta (toldo, cocinita, alarma, trampa) se arman en Mejorar con los ingredientes; lo que va a la mochila (cama de cartón, pelota de trapo) en Armar. La tecla C solo recuerda que se arma en el cambuche.
- **Cartón y estibas:** piso de cartón (4 cartones: menos hambre de noche, +2 ánimo), cama de estibas (2 estibas: la lluvia no lo empapa, +2 ánimo), repisa (estiba + clavos: la caja guarda 2 más). La lista de Mejorar se corre cuando no cabe.
- **La casita:** con toldo, el cambuche tiene un adentro que se camina (`scenes/world/CambucheInside.tscn`): la cama (dormir, o una siesta al día), la caja (y en la repisa lo guardado), la alcancía, el tablero, la cocinita y la tabla con la piedra para armar. Lo que tiene se ve puesto; la foto y el dibujo de Victoria van colgados. Se sale por la cortina al mismo sitio.
- **La mochila con Wilson:** con camiseta, plástico y cuerda, Wilson le cose dos bolsillos: 10 casilleros en vez de 8 (los dos de más se ven oscuros hasta entonces).

## Peleas y PLOMO
- **Beat 'em up:** además de pegar (A) y la patada cargada (mantener A y soltar), **B tapa** (de frente entra una quinta parte y no tumba; apretado justo antes del golpe, **contragolpe**) y **X empuja** (abre la guardia del que se cubre). A él le pegan un 25% menos. Los tres botones se explican una vez por pelea.
- **PLOMO, sonido:** disparo de pistola, escopeta y puño; la bala de los malos; un quejido distinto por cada muerto (y uno largo para los jefes); el "ay" de los heridos; el dolor de él cuando le pegan. Se generan con `tools/audio/plomo_sfx.py` (`assets/audio/plomo/`).
- **PLOMO, controles de ahora:** la palanca izquierda / WASD camina adelante, atrás y de lado; la derecha / flechas / mouse gira; en el celular, arrastrar el dedo en la mitad derecha gira.
- **PLOMO, la cara:** entre menos vida, más sangre le baja por la cara (chorros que bajan despacio; con poca vida, la boca y un ojo hinchado).
- **Don Lucho, en orden:** primero las lámparas (la casa a oscuras), después el chaleco (a oscuras, de cerca y a puño: tres golpes) y ahí sí, duro.

## Aguaceros, perros por turnos y el ajedrez
- **El aguacero** (`scripts/systems/Weather.gd`): algunos días (uno de cada cuatro, más o menos) llueve un rato de día, igual en todos los lugares de afuera. Lluvia en pantalla, cielo gris, sonido de lluvia, charcos que crecen y se secan, rayos con trueno. La gente corre a escamparse bajo los aleros, la parada del bus y el kiosco, y sigue cuando escampa. Él se moja (baja el ánimo de a poquito, si no está debajo de algo). Sonidos: `tools/audio/clima.py`.
- **Lukas contra los perros, por turnos** (`scripts/ui/PeleaPerros.gd`): cuando se agarran, la pelea es como en Pokémon. Lukas tiene nivel (1 a 5) y experiencia; aprende Revolcón (2), Ojitos (3) y Aullido (4); los trucos que sabe también sirven (sentarse, la pata, saludar, hacerse el muerto). Con hambre pelea peor; si le dan duro, sale cojeando ese día. Si se gana al otro perro (la barra de amistad), queda de **amigo**: cada vez que se ven juegan y Lukas se alegra. Si lo vence a mordiscos o pierde, queda de **enemigo**: gruñe y no los deja pasar cerca.
- **El ajedrez de los viejos** (`scripts/ui/Ajedrez.gd`): una partida de verdad entre Don Ramiro (blancas, siempre el caballo del rey) y Don Octavio. Sigue corriendo aunque él no esté (una jugada cada 4 minutos del juego): llega y la partida va por donde va. Se puede mirar (comentan las jugadas) o jugar por Don Ramiro, que se va al baño; si le gana a Octavio, Ramiro le da $2.000.

## Los lugares por dentro
- **Interiores** (`scenes/world/Interior.tscn`, `scripts/world/Interior.gd`): la iglesia, la veterinaria, la pensión, el baño público, la Defensoría, la Registraduría, el estudio de fotos y **La Caverna del Gamer** se entran (de día, en su horario; cerrados, la puerta dice lo de antes). Adentro: los muebles, quien atiende (con la misma conversación de siempre) y gente haciendo su vida (`scripts/npc/Vecino.gd`: rezan, barren, hacen fila, ven novela; si uno les da [E], dicen algo en una burbuja). En La Caverna, Al atiende detrás del mostrador; el gato duerme en la repisa.
- **El colegio no se entra**: él es el de la reja. Ahí pasa lo de Victoria.
- **La gente de afuera** que no camina, de vez en cuando mira para otro lado y dice algo suyo (en burbuja): Germán, Rosa, Marta, Wilson, Samuel, los viejos, el celador, el padre.

## La feria (detrás del billar)
- En el lote de atrás del billar: el arco con bombillos y, al fondo, la rueda de Chicago (de día quieta y apagada). Abre de cuatro de la tarde a medianoche (`scenes/world/Feria.tscn`, `scripts/world/Feria.gd`), con su cumbia (`assets/music/feria.wav`, `tools/audio/compose.py feria`).
- Los juegos (`scripts/ui/FeriaJuegos.gd`): **carros chocones** ($2.000: 30 segundos manejando y chocando), **carrusel** ($1.000: Lukas le ladra en cada vuelta), **montaña rusa** ($3.000: [E] manos arriba en las bajadas), **dardos** ($1.000: con dos globos, peluche), **la garra** ($500: la garra floja de siempre) y **la rueda de Chicago** ($2.000).
- **Arriba de la rueda, el recuerdo:** una fiesta de diciembre de antes, él sin barba. Fondo blanco al ritmo (aguardiente) y tres caladas (mantener y soltar en lo verde; si se pasa, tose). Baja con ganas de un trago y no se lo toma.
- **El peluche** (un oso morado con corazón negro) se le puede dejar a Victoria en la reja: le gustan esos colores.

## La huida, rehecha (frenética)
- **Ya no se agacha: se tira al piso y pasa apretado** por debajo, acostado boca arriba con los dientes apretados y la corbata en la cara (`player_slide.png`, cuadros 3 y 4). Lo de pasar por debajo viene en dos capas (atrás y adelante): él pasa por en medio de las patas. Cada cosa sale una sola vez: en los techos, **el tanque negro elevado** (gotea encima), **el palomar** (salen las palomas), **la mesa del cumpleaños** con la familia (la tía grita; las velas se apagan) y **la placa apuntalada con guadua** (larga: mantener abajo); en el puente, **el tráiler de la mula** sin cabezote y **el poste de la luz caído** (chispas). Si no se tiró, se da en la frente y pasa arrastrado, pero le cuesta.
- **Lo que se salta:** el murito con vidrios de botella, la pipeta de gas, el arrume de ladrillos, los huecos y, en el puente, los conos y los taxis del trancón. **Los techos no son parejos:** hay que subir al de al lado (si no salta, se estrella) y caer al de abajo.
- **El helicóptero, siempre encima:** la luz (esconderse detrás del tanque), **la ráfaga que barre el techo** de frente o de atrás (saltarla cuando pasa) y **la mira** (lo sigue, se queda quieta donde él va a estar y disparan: tirarse lo adelanta y se le sale).
- **Los vecinos, desde sus terrazas:** la de los rulos, el de la barriga en esqueleto, la rezandera y el pelado que transmite en vivo. Gritan lo del aborto, sin piedad y cada uno a su manera (sin repetir), en un globo al lado de la cabeza; algunos tiran chancla, huevo (se le queda en el pelo), matera o biblia: al piso. En el puente gritan los taxistas.
- **Alzar a Lukas:** hay una calle muy ancha para él. Lukas se para en el borde; con [E] lo alza y corre con él en brazos un rato (sin poder tirarse al piso), hasta que lo pone en el suelo.
- **Más largo y más rápido:** unos 75 segundos de techos (la velocidad sube) y 25 de puente. Las amenazas están puestas para no pisarse entre ellas; un bot la terminó entera con uno o dos tropiezos.
- Arte: `tools/art/draw_huida.py` (→ `assets/prologue/huida/`). Sonidos: `tools/audio/huida_sfx.py` (rotor, ráfaga, aleteo, ploc, chispa).

## Arreglos sueltos
- **Pantalla llena:** el juego escala a cualquier tamaño (no solo múltiplos enteros); las láminas del prólogo llevan detrás la misma viñeta, grande y oscura.
- **Pelo:** Zaida y Diana Carolina son pelinegras; las únicas castañas son Lorena y Victoria.
- La tienda se llama **La Caverna del Gamer**. Al salir de ella (o de la feria) se queda en su puerta, no en el puente.
- **La feria por fuera** (`tools/art/draw_feria_lote.py`): por encima de la reja se ve todo: la montaña rusa con su carrito que da la vuelta, el carrusel con los caballitos que suben y bajan, los chocones moviéndose (con chispas en la malla), la garra, los dardos y el carrito de las obleas; de noche, las guirnaldas de bombillos. Cerrada, todo quieto. No se camina por encima: se entra por el arco.

## Lukas y la gente
- **Lukas huele a la gente:** cuando él le habla a alguien, Lukas va y lo huele. Según quién (`Lukas.GREET`), se queda a que lo consientan (corazoncitos) o se devuelve bravo (resopla) y se le sienta de espaldas.
- **La pelota de los pelados** (`scripts/ui/PelotaLukas.gd`): después de los penaltis, Lukas se roba la pelota y se la lleva por el lote conduciéndola con el hocico (la pelota tiene su física: rueda, brinca, el pasto la frena, rebota en el muro, en las orillas y en los morrales). Hay que quitársela y meterla entre los dos morrales: tocarla es pegarle, hacia donde va corriendo (o al arco, si está quieto). Lukas hace el quiebre cuando lo tienen cerca y se cansa con los segundos; los tres pelados corren detrás de la pelota y le pegan para cualquier lado. La barra del pique se llena con el tiempo y con cada patadón; llena, con F, sale como un rayo un momento y el patadón sale con fuego. 25 segundos; si Lukas se la mete solo, cuenta igual. Al final se tiran todos al pasto.
- **Las peleas de Lukas se sienten otro juego** (`PeleaPerros.gd`): entran con tres destellos y barras negras, suena su propio tema ("perros", `compose.py perros`), los perros entran cada uno por su lado y el fondo es de juego de bolsillo (cielo, nubes, pasto).

## Lo interactivo
- **El columpio** (`scripts/world/ColumpioRide.gd`): se mece de verdad, como un péndulo, visto de frente. Abajo cuando va para adelante, arriba cuando va para atrás: se impulsa. E: frena con los pies. Lukas le ladra en cada ida.
- **La tele de la vitrina:** cada programa trae su viñeta (`tools/art/draw_vinetas_tele.py`, 17): el televisor grande con el programa animado adentro, los otros con el mismo canal, y él y Lukas en la vereda con la luz de la pantalla en la espalda.
- **La moto** (con Lorena o solo): al llegar no frena; la cámara se queda y la moto se pierde en el horizonte con sus pasajeros.
- **Después de una alucinación** (la moto, el padrino) se levanta desconcertado: del piso, mira a los lados, sacude la cabeza, un "?" al lado de la cabeza (`Player.wake_confused`).
- **El cambuche a la intemperie:** con solo toldo (niveles 1 y 2) no hay paredes: el andén alrededor, la gente que pasa (y a veces se para a mirar), el toldo que se mueve y gotea si llueve, el poste de luz, la luz de la hora. Con estibas (3) se cierra.

## El beat 'em up
- Abajo, siempre: **E pegar · Q taparse · X empujar**.
- **Taparse** tiene su dibujo (los antebrazos delante de la cara, como un boxeador; `heroe_suenos.py`, fila 9) y un cuadro de aguante cuando le entra el golpe.
- Los sueños ya no dicen "SUEÑO 1": cada uno es una sorpresa.

## La denuncia se cae, y Carolina pide perdón
`scripts/systems/Carolina.gd`. Una cosa por día, en la ciudad: la ve en la esquina (día 5); una llamada en silencio y un "perdón" (o una nota, sin celular; día 10); el recorte de la página 9, "la denunciante rectifica" (día 15); su carta debajo del cartón (día 20); habla con él, por teléfono o en persona al lado del puente (día 25: Lorena la llevó, lo del arma lo puso Lorena, la decisión fue de ella); y la denuncia queda retirada (día 30): ahí aparece la página 14 en el parque. La ficha de la policía sigue abierta hasta la Defensoría.

## Lombardía de noche
El barrio se llama **Lombardía**. Una noche (desde el día 8, una sola vez) lo despierta el frío: Lukas no está. Sale a buscarlo a la una y diez, por el barrio de noche (los del kiosco, las muchachas del poste, el celador, el billar). Lukas está sentado frente al carrito de los perros calientes, con media salchicha adentro. Al acostarse otra vez sigue la misma noche.

## El final de la bicicleta, la tos, Lorena, todo animado y la feria (2026-10-22)

**Esta sección manda sobre lo anterior del final y del cumpleaños.** Lo pidió el usuario después del recorrido de los 50 días: "la idea es que el protagonista alcance a comprar la bicicleta para el cumpleaños de Victoria pero no alcance a entregársela porque la muerte de Lukas ya lo degradó".

- **El final:**
  - Con $150.000 en la alcancía sale el encargo "La bicicleta de Victoria": Don Efraín, en el Parque, la consigue (`Conversations._comprar_bici`). Es verde agua, con canasta y timbre: el color que ella le explicó en una visita. Sale empujándola del manubrio y queda envuelta en bolsas negras, con un moño de cinta de casete, al lado del cambuche (`assets/barrio/bici_envuelta.png`, `SleepSpot`).
  - El último sueño es siempre la noche del 49 (`NightSequence._dream_when("final")`), y esa noche él no se despierta. Si hay tos, a las cuatro de la mañana se le calla. Samuel lo encuentra con el collar de Lukas y, si la compró, con la bicicleta al lado.
  - **El "—Sí." pasa en la última visita** (domingo 49, la víspera del cumpleaños; `Conversations._ultima_visita`): ella llega con un gorro de cumpleaños de papel "para practicar", le pone la mano en la frente ("está caliente"), le pregunta si mañana viene y "¿Puedo decirle papá?". Sin visitas, no habla nunca.
  - En el epílogo, Germán le lleva lo que él alcanzó a dejar: la bicicleta, o los colores, o el clavel con el dibujo. Si él le dijo que sí, ella pregunta "—¿Y mi papá? Ayer me dijo que sí."
- **La tos** (`GameState._tos_noche`, `tos_stage`):
  - Sale de dormir en la calle y crece cada noche: más si se mojó, si no tiene cobija o si tiene hambre; menos en la pensión o si comió algo caliente. No se quita nunca.
  - Con Lukas vivo no pasa de la tos de pecho (65). Cuando Lukas se muere, él deja de cuidarse y sube 7 por noche: fiebre, sangre en el pañuelo.
  - Se ve y se oye: le dan ataques en la calle (se para, se dobla, tose; Lukas se sienta a mirarlo), hay líneas en la mañana y el resumen de la noche dice "Pecho: tranquilo / tose / le silba / le duele". Lorena se entera y lo llama por eso también.
- **Lorena** (`scripts/systems/LorenaLlamadas.gd`): 46 llamadas en orden, todas distintas, más 10 que se cuelan cuando pasa algo (la cédula, el trabajo, las visitas, la denuncia, Lukas enfermo, el torneo, la tos, Lukas muerto, la bicicleta, la víspera). Todas buscan joderle la vida y nunca traen nada bueno. Algunas tienen consecuencias:
  - la foto en el grupo del barrio: ese día pedir rinde la mitad;
  - la llamada al cuadrante: ese día hay redada;
  - la llamada a la panadería: ese día Germán no le da trabajo;
  - la de las visitas: el domingo siguiente son veinte minutos y con libreto.

  Si él cuelga, ella vuelve a llamar, cada vez con otra (23); cuando se le acaba el repertorio, deja de llamar. Ponerle el celular a Lukas sirve en todas mientras Lukas viva (10 reacciones distintas).
- **Todo animado** (`tools/art/draw_protagonist_acciones.py`, `Player.act()`):
  - **La plata:** recibirla (la mano, el billete, el bolsillo, "+$5.000" en dorado y el número que rueda) y pagar.
  - **El cuerpo:** el golpe, caerse y levantarse, toser, recoger, comer, beber, darle de comer a Lukas, acariciarlo, el celular en la oreja, las manos arriba (la requisa), sacudirse el agua.
  - **Los gestos:** asentir, negar, señalar y encogerse de hombros salen solos cuando el narrador los cuenta.
  - **La calle:** la moto que lo tumba si se le atraviesa (los carros frenan y pitan), el cobrador del gota a gota que llega caminando, los escobazos con escoba de verdad, la lluvia que lo deja escurriendo.
- **Ningún texto encima de otro, también en la calle:** lo que flota en el mundo (lo que dice la gente, HABLAR, los pitos, "+$5.000") se esconde mientras quede debajo de la barra de arriba, del aviso, del narrador, del diálogo o del celular (`Hud._hide_world_texts`, grupo `texto_mundo`).
- **La feria, redibujada entera** (`tools/art/draw_feria_juegos.py`):
  - **Por dentro, donde se camina:** el carrusel con techo de franjas y caballitos, el pabellón de los chocones, la montaña de madera con su carrito, la rueda con cabinas, los puestos y el arco de la entrada.
  - **Chocones:** pista de lámina antideslizante; los otros carros manejan solos y el niño de la cachucha lo persigue.
  - **Carrusel:** la sortija, que se agarra al pasar por el brazo.
  - **Montaña:** subida con cadena, carrilera, soportes de madera y la ciudad de fondo.
  - **Dardos:** el puesto completo, con los globos que revientan y el dardo que queda clavado.
  - **Garra:** la máquina con vidrio, peluches y el hueco; a veces el premio se resbala.
  - **Rueda:** el barrio desde la cabina, él de espaldas y la terraza de la fiesta de antes.

## Los espacios vacíos, llenos (2026-10-22)

`tools/art/draw_relleno.py` dibuja y `scripts/systems/Relleno.gd` pone, al cargar el lugar (las escenas no se
regeneran):
- **La calle (City):**
  - el lote: la cancha de cal con morrales de arco, llantas de gradería, gallinas que se espantan y el
    NO BOTE BASURA; el columpio se corrió a la esquina;
  - el potrero: Relámpago, el caballo del zorrero, y la zorra; si ya está el coliseo, el lote "se vendió";
  - las casas: caminitos, matas en tarros, pipetas, plátanos, la ropa colgada y la mesa de la tienda;
  - la esquina: el chance (se juega a mil, una vez al día), el de los minutos y las arepas;
  - el río: juncos, la garza, el carrito hundido, la basura que baja y la corriente;
  - la plaza: la fuente con chorrito, palomas que vuelan cuando él pasa, materas, el busto con su paloma,
    el lustrabotas y el paletero.
- **El Centro:** la fila de edificios de atrás con la valla del abogado ("¿LO DENUNCIARON? LO SACAMOS"),
  la dulcera, el tintero (el tinto se toma ahí: cuenta como algo caliente para la tos), el lustrabotas,
  el de los minutos y las palomas.
- **El Parque:** la carpa de la Olla Comunitaria con su fogón (el letrero flotante se quitó), el gimnasio
  del parque, el pelado de la cometa y el laguito con patos (a los que se les puede dar pan).
- Los vendedores solo están de 6 de la mañana a 7 de la noche. Todo lo que se toca responde con su
  chiste, y él no habla.


## El epílogo, dibujado (2026-10-23)

Los diez lugares del epílogo eran rectángulos de colores. Ahora cada uno es un cuadro a pantalla entera
(`tools/art/draw_epilogo.py` → `assets/ui/epilogo/<lugar>.png`, 4 cuadros que `Epilogo.gd` pasa despacio),
hecho con el motor de las viñetas (luz, manchas, tramado). La gente sigue encima, como antes.

- **El entierro**: el Parque de San Judas con la iglesia al fondo, el guayacán, las dos cruces (la de
  Lukas, chiquita, con el collar colgado). Lo que le dejaron se ve: el clavel medio caído, el pan de Don
  Germán, la lata de Wilson, la ollita de sopa de Doña Fabiola y Gloria, la muñeca sin un ojo.
- **La cocina de Brenda** (Ibagué): el Nevado del Tolima por la ventana, la radio con el bolero, la cebolla
  partida en la tabla (la culpa es de ella), la sopa con su vapor, el Sagrado Corazón, el almanaque.
- **El garaje**: la moto (el brillo le pasa por el tanque), el partido en el televisorcito, el tablero de
  herramientas, la calle de domingo por la puerta.
- **Lo de Lorena**: rosado; lluvia en la ventana; el aro de luz para las fotos; LIVE LAUGH LOVE; los
  esmaltes; una foto de Victoria chiquita y una de ella misma, más grande.
- **La oficina**: los cerros y Monserrate por el vidrio, la silla del gerente (la que mide Eddy), la
  carpeta en el computador, el cuadro de EQUIPO con un remero solo.
- **La esquina**: de noche, la luz de sodio con sus polillas, la persiana con grafiti, el charco.
- **La casa de Guillermo**: la camioneta enjabonada, la manguera con el chorro, las bolsas de tres almacenes.
- **Otra ciudad**: el amanecer, el lago, uno que pasea un perro (que no es Lukas).
- **La cantina**: la rockola prendida, las luces de navidad de todo el año, el partido repetido.
- **El cumpleaños**: la reja del colegio con la bandera, la banca verde con globos, el guayacán con las
  dos cruces chiquitas debajo; la bicicleta verde agua (si la compró) o el regalo envuelto en la banca.
- **El FIN** ya no va sobre negro: el guayacán al atardecer, las dos cruces, la huella de una rueda.

Las flores que caen del guayacán las pinta `Epilogo.gd` (de a una, continuas). Ajustes de posición: en el
garaje Mauricio y el Pecas se abren para que se vea la moto; Victoria, un poco más grande y más arriba (la
caja de diálogo la tapaba).


## Textos que ya no se repiten, y dos fondos nuevos (2026-10-23)

- **El gallo** (`NightLife.gd`, `GALLO`): catorce líneas, una por noche, en orden.
- **"Oscurece"** (`QuestDirector.gd`, `OSCURECE`): trece maneras de decir que hay que buscar dónde dormir,
  una por día.
- **Alejandro** (`Nino.gd`): la primera vez de cada situación es como estaba. Desde la segunda: otra
  entrada (`OTRA_VEZ`, tres por situación), lo que hace él en corto (`HACE_OTRA_VEZ`) y un remate del niño
  que va rotando (`REMATES`); los avisos de "cerca, algo pasa" también rotan. El recuerdo de él de niño
  solo sale la primera vez.
- Los títulos de misión con voseo que se leía como primera persona ("Conseguí algo para comer") quedan en
  infinitivo ("Conseguir algo para comer").
- **La obra** (`Obra.gd`) y **la fuente** (`Fuente.gd`) tienen fondo dibujado (`tools/art/draw_fondos.py`):
  la obra con la grúa, el edificio a medio hacer con la polisombra, el andamio, la mezcladora que gira y el
  perro de la obra dormido en los bultos (en la lluvia: cielo cerrado, barro, charcos, la carpa encima de
  los bultos). La fuente, desde arriba: la plaza de piedra, el borde de bloques, las baldosas del fondo
  torcidas por el agua, el chorrito del centro. Los brillos del agua son hilos, no puntos (los puntos se
  confundían con las monedas). La mano es la de él: la manga del saco, el puño de la camisa; se cierra al
  agarrar.

- **El sueño de sigilo** (`Sigilo.gd`) ya no son cuadros de colores: la Empresa en baldosas de 16x16
  (`tools/art/draw_oficina.py`): alfombra gris azul con su mancha de café y algún papel en el piso, la pared
  de frente con ventanas, el afiche de la montaña y el reloj (siempre las 7:58), escritorios con computador,
  pocillo, papeles, la foto de la familia o el cactus y la silla metida. Se lee igual que antes: los
  escondites son verde oscuro (la mata de plástico, el locker), los documentos son la carpeta manila con el
  sello de CONFIDENCIAL (brilla), el tablero tiene su luz.
- **Los techos de la huida** (`Huida.gd`, `_slab`) ya no son bloques lisos: fachada que se repite
  (`techo_0/1.png`, de `draw_fondos.py`): ladrillo, o pañete pintado y descascarado, con el remate de
  concreto y la humedad que baja. Va pegada al mundo (al correr, la pared pasa; no se desliza encima).
- **Los interiores** (`Interior.gd`): cada uno es una imagen (`tools/art/draw_interiores.py` →
  `assets/interiores/<id>.png`) que se arma leyendo `PLACES` de `Interior.gd` (tamaño, colores, cada mueble
  con su posición): el dibujo y los choques no se pueden correr. Para cambiar un mueble de sitio: se cambia
  en `PLACES` y se vuelve a correr el generador. Detalles: la iglesia de piedra con vitrales, el altar con
  floreros, el misal olvidado en una banca, la alcancía de las limosnas; la veterinaria con un perro, un
  gato y un conejo en las jaulas y el afiche de VACUNE; la pensión con papel de colgadura despegado, las
  puertas 1, 2 y 4 (el 3 es de mala suerte) y dos llaves que no están; el baño con lo que escribieron en la
  puerta y el espejo manchado; la Defensoría y la Registraduría con la franja institucional, el cordón de
  la fila y la cabina de FOTO; el estudio con el telón de nubes; la Caverna con la alfombra de confeti,
  las maquinitas y el gato de Al. Encima, `Interior.gd` pinta solo lo que se mueve (las llamas, el
  televisor, las pantallas, el turno).
- **Victoria tiene dibujo propio** (`assets/characters/victoria.png`, de `tools/art/draw_nino.py`): niña
  de doce, más alta que Alejandro y más bajita que los grandes; pelo largo castaño con el moño morado
  (como en su retrato), el saco morado del colegio con el cuello blanco, la falda gris, medias blancas y
  zapatos negros. Ya no se tiñe ni se encoge. Sale así en la salida del colegio, en las visitas y en el
  epílogo. En el Parque, el sitio de la visita pasó delante del árbol (detrás, solo se le veía la cabeza).


## Se va quedando calvo (2026-10-23)

Decisión del usuario: él se va quedando calvo a medida que pasan los días (como la tos: lo que la calle le
va quitando). Cuatro etapas (`scripts/systems/Calvicie.gd`): días 1-12 el pelo de siempre, 13-25 las
entradas, 26-38 la coronilla pelada con la franja a los lados, 39-50 calvo. La barba se queda.

- **Las hojas de pixel** (el muñeco del barrio, sus acciones, el de los sueños y sus armas, el colgado del
  camión, él en la feria, él en el tenis): `tools/art/calvicie.py` saca de cada una `_c1/_c2/_c3`. Busca el
  color de su pelo; cada mancha conectada es una cabeza y la pela desde arriba, dejando los lados. En el de
  los sueños el pelo es del color del contorno: ahí busca la cara y recorta la cresta (cabeza redonda).
  Después de regenerar cualquiera de esas hojas, se vuelve a correr.
- **El retrato** (`draw_retratos.py`): `el_c1/_c2/_c3` con la misma cara; las entradas, la coronilla, la calva.
- **Las viñetas** (`vinetas_motor.BALD`): `CALVO=2` y `CALVO=3 python tools/art/draw_vinetas.py` (y
  `draw_vinetas_tele.py`) sacan las hojas `_c2/_c3`; los días 13-25 usan las de siempre (a ese tamaño las
  entradas casi no se ven). El de antes (la moto: `clean`) sigue con pelo.
- El juego carga todo por `Calvicie.tex()/path()`: si no hay hoja de esa etapa, usa la más cercana para atrás.
- El prólogo (antes del día 1) y él de niño (Alejandro, la foto del colegio) tienen pelo.

También: lo de Alejandro avanza aunque él pase de largo (antes, si no se le hablaba, todos los días salía la
misma escena de la escoba con el mismo aviso: 28 veces en el recorrido de prueba).

## El día que manda Lukas (2026-10-23, experimento)

Si él se acuesta con el hambre en 0 o 1 (de 10), al otro día no se levanta: se queda tirado, tapado con el
cartón, y el jugador maneja a Lukas (`scripts/systems/LukasManda.gd`). Con E, Lukas le pide a la gente:
Doña Rosa (arepa), Marta (empanada), Samuel, Doña Fabiola y el Padre (pan) le dan algo; los demás, un
chiste. Lukas lo lleva en la boca (se ve) y se lo pone al lado de la cara; él se sienta, come, le da el
último pedazo y se levanta. A mediodía se levanta solo, con o sin comida.
- Lo marca `GameState.new_day` ("no_se_levanta"): como mucho uno cada seis días (con hambre todas las noches salían nueve en 50 días; así, siete), nunca un domingo de
  visita ni del 48 en adelante, y solo con Lukas vivo.
- Mientras tanto `GameState.input_blocked()` es verdad (bandera "lukas_manda"): él y lo que se toca con E se
  quedan quietos; Lukas lee los controles directo y la cámara lo sigue a él.
- Que no se repita: la primera vez la entrada es larga y explica; las siguientes, corta y distinta. Al que ya
  le dio otro día le toca otra línea (`REPITE`); al que ya dijo que no, "los perros no creen en antecedentes".
