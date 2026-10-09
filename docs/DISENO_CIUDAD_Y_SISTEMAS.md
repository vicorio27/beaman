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
| **Clínica Irene** (salud mental) | Filtró sus datos | No poder confiar ni en quien lo tiene que cuidar |
| **Zaida** | Fue su amiga; intentó manipularlo | Ser manipulado. **Jefa ambigua** (ver abajo) |
| **Los rappitenderos** (app "Rapidito") | Los sentía siguiéndolo | Sentirse vigilado (ver abajo) |

### En qué sueño aparece cada uno **[A CONFIRMAR]**

| Sueño | Género | Jefe chico | Gran jefe |
|---|---|---|---|
| 1 | Beat 'em up | El Tuerto (callejón) | **Lilato → serpiente** |
| 2 | Carreras | Rappitenderos en moto (persecución) | **Lisandro** (te persigue para matarte) |
| 3 | Sigilo | José Mario Camilo (la oficina: que no te vean) | **Clínica Irene** (sacar tu expediente) |
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

La genera el código (`tools/audio/compose.py` → `assets/music/*.wav`): chiptune, guitarra pulsada, piano y cajita de música. Los loops empalman sin corte. La elige el autoload `MusicDirector` según la escena y la hora, con fundido cruzado.

| Escena | Tema |
|---|---|
| Sueño (beat 'em up) | `dream_fight`: chiptune rockero tipo Streets of Rage |
| Camión | `truck`: el mismo riff, más rápido, con doble bombo |
| Lilato | `lilato`: épica en re menor |
| La serpiente | `lilato_serpent`: lo de Lilato, desafinado, una octava abajo y con bits de menos |
| CONTINUE? | silencio |
| Ciudad de día | `city_day`: cumbia lenta lo-fi de guitarra |
| Ciudad de noche (18 a 6) | `city_night`: la misma, lenta y oscura, con lluvia y motos lejos |
| Panadería de Germán | `bakery`: un bolero en una radio AM vieja |
| Café de Marta | `cafe`: un vals en la radio |
| La noche | `night`: piano solo |
| La memoria | `memory`: cajita de música desafinada que se corta en seco |

Con hambre (debajo de 40) la música pierde agudos y baja de tono, igual que el filtro de imagen.

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
1. Armá tu cambuche: 3 cartones, [C] para combinar.
2. Dale de comer a Lukas [F].
3. Bañate en el baño de la plaza ($1.000).
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
  - **Zaida:** aparece "por casualidad" frente a la Registraduría. Sabe lo de la Clínica Irene y que necesita una dirección, aunque él no se lo dijo. Ofrece la suya y una cita sin fila para el día siguiente. Si aceptás, `flags.zaida_favor` queda como deuda para más adelante: *"Yo te encuentro. Siempre te encuentro."*

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
| (por hacer) | 6 | PLOMO | 3: Clínica Irene | (Zaida, ambigua) |

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
- **PLOMO 3: "Clínica Irene"**.
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
| 5, PLOMO 3 (Clínica Irene) | Lazo con Lukas |
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
