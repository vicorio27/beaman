class_name Items
## Base de datos de objetos. Cada uno: nombre, descripción, tipo, cuánto se apila,
## y según el tipo: cuánta hambre cura (comida) o si se puede tirar.
## Tipos: "comida", "material", "venta", "especial", "ingrediente" (se cocina en el cambuche),
## "lukas" (comida de Lukas), "juguete" (para jugar con Lukas).

const DB := {
	"foto": {"name": "Fotografía antigua", "desc": "De chico, con alguien. La otra cara está cortada.",
		"type": "especial", "stack": 1, "fixed": true},
	# El celular de flecha (Don Efraín): con él entran llamadas (autoload Phone). Lorena tiene el número.
	"celular": {"name": "Celular de flecha", "desc": "Indestructible. Lo único que lo mata es que alguien lo llame. Alguien lo va a llamar.",
		"type": "especial", "stack": 1, "fixed": true},
	"camiseta": {"name": "Camiseta vieja", "desc": "Huele a humedad. Es ropa, toalla y pijama.",
		"type": "material", "stack": 1},
	"pan": {"name": "Pan", "desc": "Del día anterior. Duro.", "type": "comida", "stack": 3, "food": 25},
	"fruta": {"name": "Media manzana", "desc": "Media manzana. La otra mitad la mordió alguien.", "type": "comida", "stack": 3, "food": 15},
	"sandwich": {"name": "Sándwich", "desc": "Jamón y queso.", "type": "comida", "stack": 2, "food": 40},
	"sopa": {"name": "Sopa caliente", "desc": "Cura el hambre y el frío.", "type": "comida", "stack": 1, "food": 60},
	"tinto": {"name": "Tinto", "desc": "Más agua que café. El vaso calienta las manos.", "type": "comida", "stack": 1, "food": 5},
	"lata": {"name": "Lata vacía", "desc": "$300. Cinco latas, un pan.", "type": "venta", "stack": 10},
	"botella": {"name": "Botella", "desc": "$200.", "type": "venta", "stack": 10},
	"carton": {"name": "Cartón", "desc": "Colchón, cobija y pared.", "type": "material", "stack": 5},
	"pedido": {"name": "Pedido de Marta", "desc": "Una bolsa de papel caliente. Para la casa de techo de tejas, en la esquina del barrio.",
		"type": "especial", "stack": 1},
	"plastico": {"name": "Plástico", "desc": "Techo si llueve, cobija si hace frío.", "type": "material", "stack": 2},
	# Comida de la calle (Doña Rosa).
	"empanada": {"name": "Empanada", "desc": "Con ají. Pica.", "type": "comida", "stack": 3, "food": 20},
	"arepa": {"name": "Arepa con queso", "desc": "Caliente, con queso.", "type": "comida", "stack": 2, "food": 35},
	"aguapanela": {"name": "Aguapanela", "desc": "Agua con panela. Caliente.", "type": "comida", "stack": 1, "food": 10},
	# Para cocinar en el cambuche.
	"arroz": {"name": "Arroz", "desc": "Crudo no. En la cocinita del cambuche se vuelve sopa.", "type": "ingrediente", "stack": 3},
	# Lukas.
	"concentrado": {"name": "Concentrado", "desc": "Comida de perro. Es de Lukas.", "type": "lukas", "stack": 3},
	"pelota_trapo": {"name": "Pelota de trapo", "desc": "Una camiseta hecha bola. Para jugar con Lukas [F].", "type": "juguete", "stack": 1},
	# Materiales y mejoras del cambuche.
	"cama_carton": {"name": "Cama de cartón", "desc": "Tres cartones amarrados. Para armar un cambuche donde sea.", "type": "material", "stack": 1},
	"cuerda": {"name": "Cuerda", "desc": "Sirve para atar, colgar y amarrar.", "type": "material", "stack": 3},
	"vela": {"name": "Vela", "desc": "Luz. Para él y para las ratas.", "type": "material", "stack": 3},
	"toldo": {"name": "Toldo", "desc": "Plástico con cuerda. Techo para el cambuche.", "type": "material", "stack": 1},
	"cocinita": {"name": "Cocinita de lata", "desc": "Lata con vela. Cocina. Va en el cambuche.", "type": "material", "stack": 1},
	"candado": {"name": "Candado", "desc": "Para la caja del cambuche.", "type": "material", "stack": 1},
	# Favores (no se tiran ni se los roban).
	"anillo": {"name": "Anillo de matrimonio", "desc": "De oro, finito, gastado. Adentro dice: G y M, 1979. Es de Don Germán.",
		"type": "especial", "stack": 1, "fixed": true},
	"carta_samuel": {"name": "Carta de Samuel", "desc": "Una hoja doblada en cuatro. La letra es suya; las palabras, de Samuel.",
		"type": "especial", "stack": 1, "fixed": true},
	"collar_michi": {"name": "Collar rojo", "desc": "Con una campanita. Dice MICHI. Estaba frente a la casa de tejas.",
		"type": "especial", "stack": 1, "fixed": true},
	# El trámite de la cédula (no se tiran ni se los roban).
	"foto_doc": {"name": "Fotos tipo documento", "desc": "Cuatro fotos tipo documento. Cara de sospechoso. Para la cédula.",
		"type": "especial", "stack": 1, "fixed": true},
	"carta_german": {"name": "Dirección de Germán", "desc": "Anotada en una bolsa de pan: calle 9 # 14-32. Huele a mogolla.",
		"type": "especial", "stack": 1, "fixed": true},
	"direccion_zaida": {"name": "Dirección de Zaida", "desc": "En una tarjeta perfumada, con un corazoncito.",
		"type": "especial", "stack": 1, "fixed": true},
	"cedula": {"name": "Cédula", "desc": "Duplicado. Su cara, su nombre, su número.",
		"type": "especial", "stack": 1, "fixed": true},
	# Para ampliar el cambuche (Rancho, Ranchito).
	"estiba": {"name": "Estiba", "desc": "Madera de bodega. Cuatro hacen paredes.", "type": "material", "stack": 4},
	"clavos": {"name": "Clavos", "desc": "Una bolsa de clavos. Martillo no hay: hay una piedra.", "type": "material", "stack": 3},
	"zinc": {"name": "Lámina de zinc", "desc": "Techo de verdad. Cuando llueve suena como aplausos.", "type": "material", "stack": 2},
	"radio": {"name": "Radio vieja", "desc": "Agarra dos emisoras: una de boleros y una de pastor evangélico.", "type": "material", "stack": 1},
	# El Parque: la flor de Doña Leonor y los cachivaches de Don Efraín ("rareza": al usarla, le habla;
	# lo que dice depende de qué tan loco esté, ver GameState.locura_level()).
	"flor": {"name": "Flor", "desc": "Un clavel rojo.", "type": "especial", "stack": 1},
	"reloj_sin_agujas": {"name": "Reloj sin agujas", "desc": "Un reloj sin agujas.", "type": "rareza", "stack": 1,
		"use": ["Lo miro. Ninguna hora. Me parece justo.", "Lo miro. Son las nunca. Llego tarde.", "Lo miro y hace tic-tac. No tiene pila. Hace tic-tac igual."]},
	"estampita": {"name": "Estampita de San Judas", "desc": "San Judas, patrono de las causas perdidas. De segunda.",
		"type": "rareza", "stack": 1, "use": ["Le rezo. Por si acaso. No sé rezar, así que le cuento el día.",
			"San Judas tiene cara de cansado. Lo entiendo: le tocamos todos nosotros.", "Me contesta. Dice que coma algo. Tiene razón, pero igual me da miedo que conteste."]},
	"muneca": {"name": "Muñeca sin un ojo", "desc": "Una muñeca sin un ojo. Se llama Gloria.", "type": "rareza", "stack": 1,
		"use": ["Gloria me mira. Yo la miro. Empate.", "Gloria cree que debería llamar a mi mamá. Gloria no sabe nada de mi mamá.",
			"Gloria y yo ya no nos hablamos. Ella sabe por qué."]},
	"dentadura": {"name": "Dentadura postiza", "desc": "De alguien que ya no la necesita.", "type": "rareza", "stack": 1,
		"use": ["La hago sonar. Clac clac. Lukas la odia.", "Clac clac. Suena como alguien riéndose de mí. Bajito.", "Clac clac. Ya sé de quién era. Mejor no digo."]},
	"casete": {"name": "Casete de boleros", "desc": "Lado A: amor. Lado B: más amor, pero borracho.", "type": "rareza", "stack": 1,
		"use": ["No tengo con qué ponerlo. Me lo sé de memoria igual: lo canto bajito.", "Lo canto. Lukas aúlla en el coro. Somos un dúo.",
			"Lo escucho. Sin radio. Clarito. Lado B."]},
	# Victoria: lo que ella deja en la reja del colegio cuando él le deja algo.
	"dibujo_victoria": {"name": "Dibujo de Victoria", "desc": "Crayón. Un señor de palitos con barba y un perro café. Abajo dice: EL DEL PERRO.",
		"type": "especial", "stack": 5, "fixed": true},
	# Lukas, después.
	"collar_lukas": {"name": "Collar de Lukas", "desc": "El collar de Lukas. Amarrado a la mochila.",
		"type": "especial", "stack": 1, "fixed": true},
	# Pistas de los misterios (van al tablero del cambuche).
	"recorte_1": {"name": "Recorte de periódico", "desc": "Mojado: \"...OPERATIVO EN EL SUR: buscan a hombre denunciado por su expareja...\" Lo demás no se lee.",
		"type": "pista", "stack": 1, "fixed": true},
	"recorte_2": {"name": "Recorte con foto", "desc": "\"...con apoyo del Ejército. El hombre escapó por el río...\" La foto es borrosa. Es él.",
		"type": "pista", "stack": 1, "fixed": true},
	"recorte_3": {"name": "Esquina de periódico", "desc": "Meses después, página 14, abajo: \"La denuncia fue retirada. No hubo cargos.\"",
		"type": "pista", "stack": 1, "fixed": true},
	"carta_ines": {"name": "Carta vieja", "desc": "Matasellos de Madrid, 2018: \"Mamá, el otro año voy. Te lo prometo.\" Estaba frente a la casa de tejas.",
		"type": "pista", "stack": 1, "fixed": true},
	# El coleccionable (uno solo, siete pedazos): la foto rota, regada por la ciudad. No se pierde.
	"pedazo_foto": {"name": "Pedazo de foto", "desc": "Un pedazo de la foto rota. Encaja con la de la mochila.",
		"type": "coleccionable", "stack": 7, "fixed": true},
	"foto_entera": {"name": "La foto, armada", "desc": "Siete pedazos y cinta. Un hombre con la mano en el hombro de un niño, riéndose.",
		"type": "especial", "stack": 1, "fixed": true},
	# Para proteger el cambuche (se ponen con Mejorar).
	"alarma": {"name": "Alarma de latas", "desc": "Latas colgadas de una cuerda alrededor del cambuche. Si alguien se acerca, suenan.",
		"type": "material", "stack": 1},
	"trampa": {"name": "Tabla con clavos", "desc": "Una estiba con los clavos para arriba, escondida en la entrada. El que entra sin avisar, sale cojeando.",
		"type": "material", "stack": 1},
	"cobija": {"name": "Cobija", "desc": "De lana. Va en el cambuche: se duerme mejor.", "type": "material", "stack": 1},
}

## Recetas para combinar en la mochila [C]: resultado -> ingredientes {id: cantidad}.
const RECIPES := {
	"cama_carton": {"carton": 3},
	"toldo": {"plastico": 1, "cuerda": 1},
	"cocinita": {"lata": 1, "vela": 1},
	"pelota_trapo": {"camiseta": 1, "cuerda": 1},
	"alarma": {"lata": 2, "cuerda": 1},
	"trampa": {"estiba": 1, "clavos": 1},
}

## Mejoras que se ponen en el cambuche (se gasta el objeto).
const UPGRADES := ["toldo", "cocinita", "candado", "cobija", "alarma", "trampa"]


static func info(id: String) -> Dictionary:
	return DB.get(id, {"name": id, "desc": "", "type": "material", "stack": 1})


static func icon(id: String) -> Texture2D:
	return load("res://assets/items/%s.png" % id)


## ¿Alcanzan los ingredientes de la receta?
static func can_craft(result: String) -> bool:
	var need: Dictionary = RECIPES[result]
	for id in need:
		if GameState.count(id) < need[id]:
			return false
	return true


## "3 cartón" / "plástico + cuerda".
static func recipe_text(result: String) -> String:
	var parts := []
	var need: Dictionary = RECIPES[result]
	for id in need:
		var n: String = info(id)["name"].to_lower()
		parts.append(("%d %s" % [need[id], n]) if need[id] > 1 else n)
	return " + ".join(parts)


## Ampliaciones del cambuche: nivel al que lleva -> {"needs": {id: cantidad}, "flag", "line"}.
const EXPANSIONS := {
	3: {"needs": {"estiba": 4, "clavos": 1}, "flag": "paredes",
		"line": "Cuatro estibas, una bolsa de clavos y una piedra. Ahora tengo paredes. Y una puerta de cortina. Toc toc. ¿Quién es? Nadie, nunca."},
	4: {"needs": {"zinc": 2, "radio": 1, "clavos": 1}, "flag": "zinc",
		"line": "Techo de zinc, radio con boleros y una matera. Ya no es un cambuche: es un ranchito. Si me vieran en el barrio de antes... mejor que no."},
}
