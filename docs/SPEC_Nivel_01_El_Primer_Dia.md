# SPEC — Nivel 01: El Primer Día

> **Proyecto:** videojuego narrativo 2D  
> **Motor:** Godot 4.x  
> **Lenguaje:** GDScript  
> **Estado:** Vertical Slice / Primer nivel  
> **Objetivo:** construir una primera experiencia jugable completa antes de ampliar el juego.
> **Versión:** 3 — el capítulo empieza con un **sueño**: un beat 'em up de arcade (callejón con jefe
> y camión en movimiento). Al terminar el sueño, el protagonista despierta bajo el puente.
> Cada sueño del juego es un género de videojuego distinto (ver sección 10.5).
> La versión 1 está en `docs/SPEC_Nivel_01_v1_original.md`.

---

## 1. Visión del nivel

El primer nivel debe hacer que el jugador **viva un día en la vida del protagonista**.

La premisa jugable es simple:

> **Tengo hambre. No tengo dinero. No tengo dónde dormir. Tengo que resolver el día.**

El capítulo arranca con un **sueño que es un videojuego**: un beat 'em up de arcade de los de antes.
Peleas, un jefe, armas, un camión en movimiento. Puntaje, vidas, "GO!".

El jugador cree que el juego es eso. Hasta que el sueño termina en una pantalla de
**CONTINUE?**, no hay créditos, y el protagonista se despierta bajo el puente: era él, el mismo
tipo sin plata, soñando que era el héroe de un arcade.

Después viene el contraste: amanece, la ciudad empieza su día normal, y el protagonista también
tiene que empezar el suyo, sin plata y con hambre.

> **El sueño te mete en el juego. El día te hace conocerlo.**

El nivel no debe explicar toda la historia del protagonista.

Debe generar preguntas:

- ¿Quién es este tipo?
- ¿Qué le pasó?
- ¿Quién aparece en la fotografía?
- ¿Por qué terminó viviendo así?
- ¿Qué había antes de todo esto?

El jugador no debe sentir que simplemente completó una lista de misiones.

Debe sentir:

> **"Pasé un día con este tipo."**

Y al terminar:

> **"Quiero saber qué le pasó."**

---

# 2. Dirección técnica

## Motor

- Godot 4.x
- GDScript
- Proyecto 2D
- Arquitectura simple y extensible
- Evitar sobreingeniería durante el vertical slice

## Perspectiva

- 2D top-down / 3/4
- Pixel art
- Mundo explorable
- Cámara siguiendo al protagonista

## Resolución propuesta

- Viewport base: `320x180`
- Escalado objetivo: `1280x720`
- Tile base: `16x16`

Estos valores pueden ajustarse durante el prototipo.

## Plataforma

Desarrollo inicial:

- PC

Objetivo posterior:

- Nintendo Switch

La arquitectura debe evitar depender exclusivamente de teclado y mouse.

---

# 3. Alcance

El primer nivel debe ser pequeño.

**No construir una ciudad completa.**

Solo se implementan las zonas necesarias para contar el capítulo:

```text
                     PARQUE
                       │
              ┌────────┴────────┐
              │                 │
           BARRIO          CAFÉ / PANADERÍA
              │                 │
              │                PLAZA
              │                 │
              └────────┬────────┘
                       │
                    PUENTE
                       │
                ZONA INDUSTRIAL
```

El mapa debe sentirse como una pequeña parte de una ciudad mayor.

El sueño usa además dos escenarios nocturnos de arcade, lineales:

```text
CALLEJÓN (beat 'em up + jefe)  →  AVENIDA (camión en movimiento)  →  CONTINUE?
```

No son zonas explorables: son niveles de videojuego.

---

# 4. Protagonista

El nombre definitivo todavía no está definido.

Durante el desarrollo utilizar:

```text
Protagonista
```

No establecer "El Flaco" como nombre definitivo.

## Situación inicial

El protagonista es un hombre joven que actualmente vive en situación de calle.

El juego no debe explicar inmediatamente cómo llegó a esa situación.

Eso se descubrirá progresivamente.

---

# 5. Estado inicial

Al comenzar el capítulo:

```text
Dinero: $0
Hambre: 80/100
Día: 1
Hora: 06:17
```

## Inventario inicial

- Fotografía antigua
- Camiseta vieja
- Mochila

El inventario debe ser pequeño.

---

# 6. Sistemas de supervivencia

Durante el primer nivel solo existe **una necesidad numérica**:

## Hambre

Rango:

```text
0 — 100
```

Interpretación:

```text
100 = completamente satisfecho
0   = hambre extrema
```

El hambre disminuye progresivamente durante el día.

No debe disminuir cada frame ni de forma exageradamente rápida.

Debe estar relacionada con el tiempo del juego.

### Ejemplo

| Hora | Hambre |
|---|---:|
| 06:17 | 80 |
| 10:00 | 65 |
| 14:00 | 45 |
| 18:00 | 30 |
| 22:00 | 20 |

Los valores son iniciales y pueden balancearse.

---

## 6.1 Efectos del hambre

El hambre debe comunicarse principalmente mediante:

- animaciones
- comportamiento
- pequeños diálogos
- feedback visual sutil

Ejemplos:

- animación del protagonista llevándose la mano al estómago
- idle más cansado
- movimiento ligeramente menos enérgico
- comentarios ocasionales

No utilizar mensajes constantes como:

```text
"Tienes hambre."
"Tienes hambre."
"Tienes hambre."
```

El objetivo es que el jugador **sienta** el estado, no que el HUD se lo repita.

---

# 7. Dinero

El dinero comienza en:

```text
$0
```

Es un recurso, no una barra de supervivencia.

El jugador puede conseguir pequeñas cantidades mediante:

- trabajos
- ayuda de NPCs
- exploración
- pequeñas oportunidades

La economía debe hacer que pequeñas cantidades tengan importancia.

Ejemplo:

```text
Trabajo en panadería
+ $20.000
```

El valor puede balancearse posteriormente.

---

# 8. Salud mental

## Estado del primer nivel

**NO implementar como sistema jugable todavía.**

No mostrar:

```text
Salud mental: 72%
```

No crear una barra visible.

Sin embargo, la arquitectura debe permitir agregar posteriormente:

```text
mental_health
```

como sistema.

En capítulos futuros puede relacionarse con:

- recuerdos
- ansiedad
- aislamiento
- sueño
- percepción
- relaciones
- decisiones
- acontecimientos del pasado

La salud mental debe poder convertirse en una mecánica narrativa, no necesariamente en una simple barra de 0 a 100.

---

# 9. HUD

El HUD debe ser minimalista.

Mostrar únicamente:

```text
🍖 ████████░░    $0
```

Opcionalmente mostrar la hora:

```text
06:17
```

No mostrar:

- sed
- higiene
- sueño
- temperatura
- felicidad
- energía
- salud mental
- cansancio como barra

Estas cosas pueden existir narrativamente.

---

# 10. Inicio del capítulo — Sueño 1: el arcade

El capítulo **no** empieza a las 06:17. Empieza con un sueño.

```text
DÍA 0 — 23:40
```

El sueño es un **beat 'em up de arcade**, todo de costado, de noche y con lluvia.
Como es un videojuego, tiene **HUD de arcade** (retrato, "1P", vida, puntaje, contador, barra del jefe).
En la vida real, el HUD vuelve a ser mínimo (sección 9).

El sueño **no tiene game over**: si el jugador se queda sin vida, cae y se levanta con media vida.
Dura entre **4 y 6 minutos**.

---

## 10.1 El callejón

Dos o tres tipos rodean al protagonista. Quieren la **mochila**. No se explica por qué.

> —Dámela y listo.

### Qué hace el jugador

Beat 'em up clásico:

- Moverse por la calle (a lo largo y en profundidad).
- **Combo**: golpe, golpe, patada (botón principal repetido). La patada tira al piso.
- **Armas**: pararse sobre una y apretar el botón la agarra.
  - **Botella**: se tira; se rompe contra el primero que agarra.
  - **Cuchillo**: estocada más fuerte y de más alcance; se gasta con el uso. Lo sueltan los matones armados.
  - **Caño**: cada golpe tira al piso; se gasta con el uso.
  - Si al protagonista lo tiran al piso, suelta el arma.
- **3 oleadas, 10 matones** (configurable). La cámara se traba en cada oleada hasta que no queda
  ninguno en pie; después aparece "GO" y se avanza.

### El jefe: El Tuerto

Cuarta oleada. Barra de vida propia arriba de la pantalla.

> —Esa mochila es mía.

- Aguanta: los golpes comunes casi nunca lo frenan; lo tiran los golpes fuertes (patada, caño, botella).
- Ataques: combo de piñas, patada y gancho que tiran al piso, y una **embestida** corriendo por la calle.
- A veces **se cubre**: de frente no le entra nada mientras tanto.
- El golpe final va en cámara lenta.

### Reglas

- Los matones quedan **fuera de combate**: caen, parpadean y desaparecen. Sin sangre.
- Sin armas de fuego.

---

## 10.2 La avenida y el camión

### La avenida (por qué y dónde se sube)

El protagonista sale del callejón a la avenida. Un **camión de reparto** está arrancando desde el
cordón, con humo en el escape. Atrás aparecen **más matones corriendo**:

> —¡Allá va! ¡Agárrenlo!

Son demasiados. Hay que huir: correr detrás del camión, que se va alejando despacio. Cuando está
cerca aparece **"¡E! SALTÁ"** y se tira a agarrarse de atrás. Si no salta, los matones lo alcanzan
y lo tiran para atrás (sin game over). Al agarrarse, el camión acelera y los matones quedan atrás.

> Detalle: es el camión de "Harinas El Sol", el que le reparte a la panadería de Don Germán.
> Nadie lo dice. De día, el jugador puede reconocerlo estacionado frente a la panadería.

### Colgado: el equilibrio

El cuerpo **cuelga de las manos y se balancea** como un péndulo, con una animación propia
(brazos arriba en la manija, piernas que se balancean, patada hacia atrás, una mano sola cuando
se suelta). El camión lo desequilibra todo el tiempo (viento, vaivén, baches, curvas) e
izquierda/derecha corrige.

- **No hay obstáculos que le peguen.** La lucha es sostenerse.
- **Medidor de equilibrio** (arco con aguja) sobre su cabeza: verde al centro, rojo en los extremos.
- Si la aguja llega al rojo **se suelta una mano**: hay que apretar el botón rápido para volver a
  agarrarse; si no, pierde vida.
- Baches con temblor de cámara, líneas de viento y el camión saltando venden la velocidad.

### Las motos

> —¡Las motos! ¡No lo dejen ir!

Los matones lo persiguen en **moto** (7 en total, de a dos). Se ponen al lado, avisan poniéndose
rojos y le pegan: lo desequilibran y le quitan vida.

- Botón = **patada hacia atrás**. Hay que tirarlos de la moto: la moto da vueltas y el que manejaba
  sale volando. Algunos aguantan más de una patada.
- Patear también lo mueve: hay que elegir el momento.

### El final del camión

- **Si tira a todos**: STAGE CLEAR; el camión frena en el puente y se baja.
- **Si se queda sin vida**: se suelta y rueda hasta el puente.

Las dos llevan al mismo lugar: **bajo el puente lo espera Lilato.**

---

## 10.2b Jefa final: Lilato

Bajo el puente, de noche, con lluvia. Es el mismo puente donde duerme en la vida real (están sus
cartones). Cada sueño termina con un jefe que es **uno de sus miedos** (ver
`DISENO_CIUDAD_Y_SISTEMAS.md`, sección 8). Lilato es **el miedo a confiar en alguien y que lo
traicione** (propuesta, a confirmar).

> —Otra vez vos.

### Fase 1: Lilato

Mujer de vestido lila, pelo largo, ojos rojos. Rápida.

- **Zarpazo** con garras y **giro** que pega a los dos lados (tira al piso).
- **Desaparece y reaparece detrás** de él cada tanto, y ataca enseguida.
- Habla entre ataques: *"—Yo te cuidaba. ¿Te acordás?"*, *"—Todos se van. Vos también."*

Al vencerla queda tirada y deja en el piso el **súper cuchillo** (dorado, brilla):

> —Tomá. Ya que te querés ir...

### Fase 2: la serpiente

Cuando él agarra el cuchillo, ella se transforma. **Los golpes comunes rebotan: solo el súper
cuchillo la lastima.**

- **Embestida**: avisa (echa la cabeza atrás y se pone roja) y cruza la pantalla en la línea del
  jugador. Hay que salir de esa línea.
- **Queda trabada** con la cabeza en el piso unos segundos después de embestir: **ahí se le pega**
  (y el golpe vale doble).
- **Veneno**: escupe charcos que quedan en el piso un rato y lastiman si se pisan.
- **Coletazo**: la cola barre la zona donde está.
- Si al protagonista lo tiran al piso, suelta el cuchillo y tiene que volver a agarrarlo.

Al matarla revienta segmento por segmento. **FINAL STAGE CLEAR → INSERT COIN** → CONTINUE?

---

## 10.3 CONTINUE?

Pantalla negra de arcade:

```text
SCORE 019800

CONTINUE?
9

CREDITS 0
```

La cuenta baja de 9 a 0. Si el jugador aprieta el botón: **"INSERT COIN"**. No hay créditos.

```text
GAME OVER
```

> El protagonista no tiene plata ni en sus sueños. El primer objetivo del día va a ser conseguir
> algo, y el jugador ya lo sintió antes de que nadie se lo diga.

---

## 10.4 Despertar

```text
DÍA 1 — 06:17
```

Amanece. **Registro cálido.** Pájaros, autos lejanos, la ciudad empezando su día.

El protagonista despierta debajo del puente. Es el mismo tipo del sueño, pero acá no hay puntaje
ni armas: hay cartones, hambre y $0.

> Otra vez ese sueño.

Debe existir una pequeña animación inicial (se sienta, se frota la cara, mira el río).

Después:

**el jugador obtiene el control rápidamente.**

No utilizar una cinemática larga de exposición.

No explicar:

- quién es
- por qué sueña con eso
- quiénes eran los del sueño
- dónde está su familia
- qué perdió

El jugador debe descubrirlo.

---

## 10.5 Sistema de sueños

Cada sueño del juego es **un género de videojuego distinto**. El sueño es como el protagonista
procesa lo que le pasa: en los sueños es el héroe de un juego; en la vida real no hay continues.

Ideas para capítulos futuros (no implementar todavía):

- **Carreras**: un juego de autos.
- **Sigilo**: entrar sin que lo vean.
- **Beat 'em up**: el de este capítulo.
- Otros géneros a definir.

Reglas:

- Cada sueño es corto, jugable y reconocible como "un juego".
- Puede tener HUD de videojuego; la vida real no.
- Puede tener ecos de la vida real (la mochila, el camión de la panadería, personas, lugares).
- Termina siempre volviendo a la realidad, sin explicar el sueño.
- La arquitectura debe permitir agregar sueños nuevos como escenas independientes.

---

# 11. Zona inicial

Alrededor del puente:

- cartones
- basura
- mochila
- banco
- grafitis
- vegetación
- objetos urbanos
- sonidos de ciudad
- pájaros
- vehículos
- personas comenzando su día

La ciudad debe sentirse viva.

La idea visual es importante:

> El mundo continúa normalmente mientras el protagonista intenta sobrevivir dentro de él.

---

# 12. Primera misión

Después de que el jugador tenga unos segundos para explorar:

```text
OBJETIVO

Consigue algo para comer.
```

No utilizar un tutorial gigante.

El jugador debe descubrir posibilidades mediante exploración e interacción.

---

# 13. Formas de conseguir comida

No existe una única solución correcta.

## Opción A — Trabajar

El protagonista puede acercarse a la panadería.

Puede preguntar:

> —¿Necesitas una mano?

El panadero puede responder:

> —Tengo unas cajas que descargar. Si querés ayudarme, te doy algo.

El jugador realiza una pequeña actividad.

Recompensa:

```text
+$20.000
```

Posteriormente puede comprar comida.

---

## Opción B — Pedir comida

El protagonista puede hablar con personas.

Algunas pueden ayudar.

Otras pueden negarse.

No utilizar una lógica moral simple:

```text
NPC bueno = comida
NPC malo = rechazo
```

Cada persona debe tener una personalidad.

---

## Opción C — Explorar

El jugador puede encontrar comida durante la exploración.

Posibilidades:

- fruta
- comida descartada
- alimento dejado por alguien
- pequeña oportunidad inesperada

Esto no debe sentirse como "la solución correcta".

Es simplemente otra forma de atravesar el día.

---

# 14. Comida

La comida restaura hambre.

Ejemplo inicial:

| Comida | Recuperación |
|---|---:|
| Fruta | +15 |
| Pan | +25 |
| Sándwich | +40 |
| Comida caliente | +60 |

Estos valores son provisionales.

La comida debe tener feedback visual/audio.

Ejemplo:

```text
Hambre: 35
↓
Come pan
↓
Hambre: 60
```

---

# 15. Panadería

La panadería es una de las primeras ubicaciones importantes.

Debe contener:

- exterior
- interior
- mostrador
- horno
- cajas
- alimentos
- zona de trabajo
- NPC panadero

Debe sentirse como un negocio real.

No debe parecer construido únicamente para entregar una misión.

---

# 16. NPC — Don Germán

Basado en Germán, un tendero que fue muy amable con él.

**Don Germán**

Edad:

```text
50–60
```

Personalidad:

- trabajador
- **muy amable**, de los pocos que lo tratan como a una persona
- observador
- le guarda pan del día anterior sin que se lo pida
- le da trabajo cuando puede (descargar la harina del camión)
- no lo trata con lástima: lo trata con respeto

En un barrio que da mal rollo, su tienda-panadería es el lugar más cálido. Que el jugador quiera
volver a verlo.

No debe ser un estereotipo.

Tiene su propia vida.

## Rutina aproximada

```text
05:30 — Se despierta
06:00 — Llega a la panadería
06:30 — Prepara el negocio
08:00 — Atiende clientes
12:30 — Almuerza
14:00 — Continúa trabajando
18:00 — Cierra
19:00 — Regresa a casa
22:00 — Duerme
```

Para el prototipo se puede simplificar.

---

# 17. NPC — Marta

Marta trabaja en el café.

Características:

- aproximadamente 30 años
- independiente
- tiene sus propios problemas
- tiene conversaciones opcionales
- no existe únicamente para entregar una misión

Ejemplo:

> —¿Ya desayunaste?

Protagonista:

> —Todavía no.

Marta:

> —Entonces deberías hacerlo.

No explicar toda la historia del protagonista.

---

# 18. NPC — Samuel

Samuel también vive en situación de calle.

No debe ser un estereotipo.

No debe existir únicamente para representar la pobreza.

Debe tener:

- personalidad
- rutina
- opiniones
- conocimiento de la ciudad
- objetivos propios
- historia propia

Ejemplo:

> —¿Dormiste acá?

> —Sí.

> —No te acostumbres.

Su relación con el protagonista puede desarrollarse en capítulos posteriores.

---

# 19. Sistema de tiempo

El mundo tiene un reloj.

Ejemplo:

```text
06:17
07:30
09:45
12:00
15:20
18:00
21:30
```

El tiempo avanza mientras el jugador juega.

Debe soportar:

- mañana
- mediodía
- tarde
- noche

Los NPC utilizan el tiempo para cambiar sus rutinas.

No implementar todavía un simulador extremadamente complejo.

---

# 20. Día y noche

La iluminación cambia progresivamente.

### Mañana

- luz cálida
- ciudad despertando
- sombras suaves

### Mediodía

- mayor iluminación
- actividad urbana

### Tarde

- luz más cálida
- actividad disminuyendo

### Noche

- iluminación artificial
- menos personas
- ambiente más silencioso

---

# 21. Evento de lluvia

Durante la tarde comienza a llover.

No debe aparecer un aviso:

```text
EVENTO: LLUVIA
```

Debe suceder naturalmente.

Primero:

- sonido de viento
- algunas gotas

Después:

- lluvia
- charcos
- cambios de iluminación
- NPCs buscando refugio
- ambiente sonoro diferente

La ciudad debe reaccionar.

---

# 22. Regreso al puente

Cuando cae la noche, el protagonista vuelve al lugar donde comenzó.

Pero su espacio está ocupado.

Otra persona está utilizando el lugar.

No debe convertirse en combate.

No debe existir violencia gratuita.

La persona dice:

> —Lo siento, hermano. Yo llegué primero.

El protagonista acepta la situación.

Esto cambia el objetivo.

---

# 23. Segundo objetivo

Mostrar:

```text
OBJETIVO

Encuentra dónde pasar la noche.
```

El jugador puede buscar diferentes alternativas.

Ejemplos:

- refugio
- banco
- otro lugar bajo el puente
- espacio alternativo
- lugar cercano a algún edificio

No implementar todavía un sistema completo de vivienda.

Solo necesitamos representar la decisión.

---

# 24. La fotografía

Durante la noche el protagonista revisa su mochila.

Encuentra una fotografía antigua.

La cámara se acerca.

La fotografía muestra al protagonista cuando era niño junto a otra persona.

El rostro de la otra persona está parcialmente oculto/cortado.

En el reverso:

> **"Para que nunca olvides de dónde vienes."**

El jugador todavía no sabe quién escribió la frase.

Esto genera el primer gran misterio.

---

# 25. Primera memoria

Al observar la fotografía se activa la primera memoria.

No debe ser únicamente una cinemática.

Debe ser una pequeña secuencia jugable.

## Memoria

El protagonista aparece de niño.

Está en un parque o patio.

Tiene una pelota.

La pelota rueda hacia otra zona.

El niño corre detrás.

Se escucha una voz:

> **"¡Vamos, campeón!"**

El niño continúa corriendo.

La memoria termina antes de explicar quién dijo la frase.

Volvemos al presente.

No explicar el recuerdo.

Solo agregar una pieza al misterio.

---

# 26. Sistema de memorias

Las memorias deben desbloquearse progresivamente.

Cada memoria puede introducir:

- persona
- lugar
- objeto
- frase
- acontecimiento
- emoción

No explicar el pasado completo en el capítulo 1.

Los objetos pueden adquirir nuevos significados después de desbloquear recuerdos.

Ejemplo:

```text
OBJETO EN PRESENTE
        ↓
     fotografía
        ↓
      memoria
        ↓
nuevo contexto
        ↓
el objeto cambia de significado
```

---

# 27. Final del nivel

El protagonista encuentra un lugar donde pasar la noche.

Se acomoda.

Mira la fotografía.

La guarda.

Cierra los ojos.

Fade out.

Mostrar:

```text
DÍA 1

Dinero conseguido: $XX.XXX
Comida conseguida: X
```

No mostrar estadísticas excesivas.

Después:

```text
FIN DEL CAPÍTULO 1
```

---

# 28. Recorrido completo

El recorrido esperado es:

```text
START
  ↓
SUEÑO (Día 0, 23:40): beat 'em up de arcade
  ↓
Callejón: 3 oleadas de matones, armas
  ↓
Jefe: El Tuerto
  ↓
Avenida: correr y saltar al camión que arranca
  ↓
Camión: colgado, mantener el equilibrio
  ↓
Matones en moto: tirarlos a patadas
  ↓
Bajo el puente: Lilato
  ↓
Súper cuchillo: la serpiente
  ↓
FINAL STAGE CLEAR → INSERT COIN
  ↓
CONTINUE? ... no hay créditos ... GAME OVER
  ↓
DÍA 1 (06:17, registro cálido)
  ↓
Despierta bajo el puente
  ↓
Explora
  ↓
HUD: hambre + dinero
  ↓
Objetivo: conseguir comida
  ↓
Conoce NPCs
  ↓
Consigue comida / dinero
  ↓
Come
  ↓
Continúa explorando
  ↓
Comienza la lluvia
  ↓
Regresa al puente
  ↓
Descubre que está ocupado
  ↓
Objetivo: encontrar dónde dormir
  ↓
Encuentra la fotografía
  ↓
Activa primera memoria
  ↓
Regresa al presente
  ↓
Duerme
  ↓
FIN DEL DÍA 1
```

---

# 29. Arquitectura mínima de Godot

```text
project/
├── scenes/
│   ├── player/
│   │   └── Player.tscn
│   │
│   ├── prologue/          (sueño 1: beat 'em up)
│   │   ├── Fight.tscn
│   │   ├── Truck.tscn
│   │   ├── Lilato.tscn
│   │   └── Continue.tscn
│   │
│   ├── world/
│   │   ├── City.tscn
│   │   ├── Bakery.tscn
│   │   ├── Cafe.tscn
│   │   └── Bridge.tscn
│   │
│   ├── npc/
│   │   ├── Baker.tscn
│   │   ├── Marta.tscn
│   │   └── Samuel.tscn
│   │
│   └── ui/
│       ├── HUD.tscn
│       └── DialogueBox.tscn
│
├── scripts/
│   ├── player/
│   ├── npc/
│   ├── systems/
│   ├── dialogue/
│   └── world/
│
├── data/
│   ├── items/
│   ├── dialogue/
│   └── characters/
│
├── assets/
│   ├── characters/
│   ├── tilesets/
│   ├── buildings/
│   ├── objects/
│   ├── ui/
│   └── audio/
│
└── autoload/
    ├── GameState.gd
    └── TimeManager.gd
```

---

# 30. GameState mínimo

El estado global debe ser pequeño.

Conceptualmente:

```gdscript
money
hunger
current_day
current_time
inventory
current_quest
memory_flags
```

Estado inicial:

```gdscript
money = 0
hunger = 80
current_day = 1
current_time = "06:17"
inventory = []
current_quest = "conseguir_comida"
memory_flags = []
```

La arquitectura puede prepararse para agregar posteriormente:

```gdscript
mental_health
relationships
memories
chapters
```

pero estos sistemas **no deben implementarse ahora**.

---

# 31. Estructura de interacción

El jugador debe poder:

- caminar
- interactuar
- hablar
- recoger objetos
- consumir comida
- comprar comida
- trabajar
- inspeccionar objetos
- activar recuerdos

Solo en el sueño (beat 'em up):

- pegar con combo golpe-golpe-patada
- agarrar, usar y tirar armas (botella, cuchillo, caño)
- mantener el equilibrio colgado del camión y patear hacia atrás

Interacción sugerida:

```text
A / botón principal = interactuar
B / botón secundario = cancelar
```

Los controles deben poder mapearse posteriormente a gamepad.

---

# 32. Sistema de diálogos

El sistema debe soportar:

- nombre del personaje
- texto
- múltiples líneas
- elecciones simples
- continuación
- condiciones básicas

Ejemplo:

```text
DON ERNESTO

—¿Necesitas algo?

[Trabajar]
[Comprar]
[Preguntar]
[Salir]
```

No construir todavía un sistema de diálogos extremadamente complejo.

Debe ser suficiente para el vertical slice.

---

# 33. Sistema de objetivos

El juego debe soportar objetivos simples.

Ejemplo:

```text
quest_id: conseguir_comida
title: "Consigue algo para comer"
status: active
```

Después:

```text
quest_id: encontrar_donde_dormir
title: "Encuentra dónde pasar la noche"
status: active
```

Los objetivos deben poder actualizarse mediante eventos.

---

# 34. Guardado

El primer vertical slice debe tener un sistema básico de guardado.

Debe poder guardar:

- día
- hora
- dinero
- hambre
- inventario
- objetivo actual
- memorias desbloqueadas
- estado de eventos importantes

No hace falta implementar múltiples slots todavía.

---

# 35. Prioridad de implementación

## Fase 1 — Base

- Crear proyecto Godot
- Crear escena principal
- Movimiento del jugador
- Cámara
- Mapa
- Colisiones

## Fase 1B — Sueño 1: beat 'em up

- Callejón: 3 oleadas, 10 matones, combo, armas, sin game over
- Jefe: El Tuerto
- Avenida y camión: equilibrio colgado, motos a patadas
- Jefa final: Lilato y la serpiente (súper cuchillo)
- CONTINUE? sin créditos y despertar en el Día 1 (06:17)

## Fase 2 — Interacción

- Sistema de interacción
- NPCs
- Diálogos
- HUD
- Inventario
- Dinero

## Fase 3 — Supervivencia

- Hambre
- Comida
- Consumo
- Compra
- Trabajo de panadería

## Fase 4 — Tiempo y clima

- Sistema de tiempo
- Día/noche
- Rutinas NPC
- Lluvia
- Cambios ambientales

## Fase 5 — Narrativa

- Objetivos
- Evento del puente
- Búsqueda de lugar para dormir
- Fotografía

## Fase 6 — Memoria

- Sistema de transición
- Primera memoria jugable
- Retorno al presente
- Flags de memoria

## Fase 7 — Persistencia

- Guardado
- Carga
- Estado del capítulo

## Fase 8 — Pulido

- Animaciones
- Audio
- Música
- Efectos
- Iluminación
- Feedback
- UI
- Ajustes de ritmo

---

# 36. Reglas de diseño

## NO

- No explicar toda la historia.
- No llevar el combate a la vida real: los géneros de videojuego viven en los sueños.
- No usar armas de fuego ni sangre en los sueños.
- No poner game over en el prólogo: si el jugador falla, la escena sigue.
- No hacer una ciudad enorme.
- No crear decenas de NPCs.
- No crear múltiples barras de supervivencia.
- No implementar salud mental todavía.
- No convertir cada NPC en un tutorial.
- No hacer que cada interacción sea una misión.
- No castigar constantemente al jugador.
- No convertir la pobreza en un sistema de "buenas/malas decisiones".
- No sobrecargar el HUD.
- No sobreingenierizar la arquitectura.

## SÍ

- Soñar que es otro (y despertarse).
- Explorar.
- Hablar.
- Comer.
- Conseguir dinero.
- Observar.
- Descubrir.
- Recordar.
- Tomar pequeñas decisiones.
- Vivir el día.
- Crear curiosidad.
- Hacer que el mundo parezca existir sin el jugador.

---

# 37. Dirección narrativa

El juego no debe decirle al jugador qué pensar sobre el protagonista.

No es:

> "Mirá qué triste es su vida."

Es:

> "Conocé a esta persona."

La historia debe revelar progresivamente:

```text
PRESENTE
   ↓
objetos
   ↓
personas
   ↓
recuerdos
   ↓
preguntas
   ↓
nuevas respuestas
   ↓
nuevo significado del pasado
```

---

# 38. Dirección visual

La estética debe utilizar:

- pixel art detallado
- colores cálidos
- iluminación suave
- ambientes acogedores
- pequeñas animaciones ambientales
- vegetación
- lluvia
- reflejos
- interiores cálidos

El contraste es fundamental.

El mundo puede verse hermoso mientras la situación del protagonista es difícil.

No utilizar una estética constantemente oscura o deprimente.

La belleza del mundo hace que la situación del protagonista destaque más.

---

## 38.1 La ciudad del Día 1: estilo EarthBound

El barrio se ve como **EarthBound**: perspectiva oblicua (fachada + techo), contorno oscuro grueso,
colores pasteles gastados. **Humilde, pero que da mal rollo**:

- casillas de chapa oxidada, ventanas tapiadas, grafitis, rejas de alambre, cercos caídos;
- pasto seco y tierra, asfalto roto con baches, veredas rajadas, río turbio;
- postes con cables combados y cuervos, un farol que parpadea, auto quemado, colchón tirado,
  carrito volcado, perros callejeros;
- puertas cerradas con respuestas que incomodan ("Una voz detrás de la puerta: —Andate.").

La **panadería y el café** son los únicos lugares cálidos: toldo a rayas, vidrieras iluminadas.
El contraste es intencional: es a donde el jugador va a querer ir.

# 39. Dirección sonora

Desde el vertical slice deben existir sonidos básicos:

- pasos
- viento
- pájaros
- ciudad
- vehículos
- puertas
- interacción
- comida
- lluvia

La música debe utilizarse con moderación.

El silencio también es parte de la experiencia.

La lluvia puede convertirse en uno de los primeros momentos atmosféricos importantes del juego.

---

# 40. Criterio de éxito

El nivel está terminado cuando podemos ejecutar el juego desde cero y realizar el recorrido completo:

- [ ] Jugar el sueño completo: callejón, jefe, avenida, camión, motos, Lilato, serpiente
- [ ] Ver CONTINUE? sin créditos y despertar
- [ ] Despertar bajo el puente
- [ ] Obtener control rápidamente
- [ ] Explorar
- [ ] Ver hambre y dinero
- [ ] Recibir objetivo de conseguir comida
- [ ] Hablar con NPCs
- [ ] Conseguir comida o dinero
- [ ] Comer
- [ ] Ver pasar el tiempo
- [ ] Experimentar la lluvia
- [ ] Regresar al puente
- [ ] Descubrir que está ocupado
- [ ] Buscar dónde dormir
- [ ] Encontrar la fotografía
- [ ] Activar la primera memoria
- [ ] Jugar la memoria
- [ ] Regresar al presente
- [ ] Dormir
- [ ] Finalizar el Día 1
- [ ] Guardar/cargar correctamente

---

# 41. Criterio emocional de éxito

Más importante que completar las funcionalidades:

El jugador debe terminar el capítulo pensando:

> **"Pasé un día con este tipo."**

Y después:

> **"Quiero saber qué le pasó."**

Si el jugador siente eso, el vertical slice funciona.

---

# 42. Instrucción para Claude

Claude debe implementar **únicamente este vertical slice**.

No construir todavía:

- capítulos posteriores
- sistema completo de relaciones
- salud mental
- ciudad completa
- economía avanzada
- árbol narrativo completo
- crafting
- combate fuera de los sueños
- otros sueños (carreras, sigilo...): solo el beat 'em up en este capítulo
- sistema de vivienda completo
- decenas de NPCs

Cuando una decisión técnica no esté especificada, elegir la solución más simple compatible con Godot 4.x y documentarla.

Prioridad:

```text
JUGABILIDAD
    ↓
NARRATIVA
    ↓
ATMÓSFERA
    ↓
ARQUITECTURA
    ↓
ARTE FINAL
```

Primero debe existir un juego pequeño que podamos jugar de principio a fin.

Después lo hacemos bonito.

Después lo hacemos grande.

---

# 43. Definición final

**El Primer Día** no trata de sobrevivir a una ciudad hostil.

Trata de sobrevivir a un día normal cuando tu vida dejó de ser normal.

El jugador no viene a salvar al protagonista.

Viene a conocerlo.

Y este primer día es apenas el comienzo.
