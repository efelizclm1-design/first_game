extends RefCounted
## Campaign data is kept separate so levels can be edited without changing gameplay.

const ZONES = [
	{"name":"BOSQUE ÁMBAR", "short":"ÁMBAR", "color":"f6ba70", "boss":"El Rey de la Hojarasca", "enemy":"Duende espino", "tag":"Hojas bonitas. Intenciones horribles.",
	"levels":["La primera hoja", "Cosecha peligrosa", "El bosque se cierra", "El Rey de la Hojarasca"],
	"objects":["Hoja cortante", "Bellota espinosa", "Rama rota", "Calabaza bomba", "Castaña", "Murciélago de otoño", "Tronco", "Zarza", "Hoja dorada", "Semilla explosiva", "Espina real", "Hongo iracundo", "Manzana maldita", "Cuervo", "Colmena", "Raíz ardiente"]},
	{"name":"GLACIAR DE CRISTAL", "short":"CRISTAL", "color":"87dce2", "boss":"La Emperatriz de Hielo", "enemy":"Centinela polar", "tag":"Mantén la calma. Y los pies calientes.",
	"levels":["Nieve afilada", "Lago de agujas", "Deshielo", "La Emperatriz de Hielo"],
	"objects":["Esquirla", "Bola de granizo", "Carámbano", "Bomba gélida", "Cristal roto", "Polilla polar", "Bloque de hielo", "Aguja azul", "Diamante helado", "Núcleo de nieve", "Lanza glacial", "Gólem pequeño", "Prisma", "Cuervo de escarcha", "Piedra congelada", "Géiser frío"]},
	{"name":"RUINAS NEÓN", "short":"NEÓN", "color":"e99dc9", "boss":"El Alcalde Cortocircuito", "enemy":"Dron chatarra", "tag":"La ciudad duerme. Sus trampas no.",
	"levels":["Luces de emergencia", "Hora punta", "Demolición", "El Alcalde Cortocircuito"],
	"objects":["Vidrio neón", "Engranaje", "Sierra", "Mina eléctrica", "Microchip", "Dron averiado", "Batería", "Chispa", "Cristal láser", "Tuerca magnética", "Cuchilla", "Robot bomba", "Placa corrupta", "Ala metálica", "Transformador", "Arco eléctrico"]},
	{"name":"CIELO ROTO", "short":"CIELO", "color":"c8b0eb", "boss":"El Heraldo de la Tormenta", "enemy":"Vigía del viento", "tag":"Lo que sube... intenta aplastarte.",
	"levels":["Islas errantes", "Vientos cruzados", "Sin suelo firme", "El Heraldo de la Tormenta"],
	"objects":["Pluma cuchilla", "Orbe tormenta", "Rayo sólido", "Nube rabiosa", "Piedra lunar", "Halcón de viento", "Columna caída", "Relámpago", "Pluma astral", "Esfera celeste", "Lanza del cielo", "Nube eléctrica", "Estrella rota", "Cometa", "Reloj celestial", "Trueno"]},
	{"name":"CALDERA INFERNAL", "short":"INFIERNO", "color":"ff9676", "boss":"Don Pánico", "enemy":"Diablillo de brasa", "tag":"El suelo está caliente. El jefe, peor.",
	"levels":["Bienvenido al horno", "Lluvia de brasas", "La última cornisa", "Don Pánico"],
	"objects":["Brasa", "Meteorito", "Obsidiana", "Calavera bomba", "Roca volcánica", "Murciélago infernal", "Ladrillo ardiente", "Llama", "Ceniza viva", "Núcleo de magma", "Diente demoníaco", "Calavera real", "Corazón de lava", "Ala de fuego", "Yunque infernal", "Pilar de magma"]}
]

const TAUNTS = [
	"Eres muy lento... ¡ja, ja, ja!", "¡Hasta esa piedra tiene mejores reflejos!",
	"El suelo te manda saludos.", "Tres corazones. Cero excusas.",
	"¿Esquivabas o estabas bailando?", "La gravedad: 1. Tú: 0.",
	"¡Bonita bufanda! Lástima los reflejos.", "Te ganó una bellota. Una bellota.",
	"Ese salto merecía un aplauso... casi.", "¡Pánico detectado! Habilidad pendiente.",
	"El jefe aún estaba calentando.", "¿Otra vez? Me estoy encariñando.",
	"La próxima intenta no abrazar el peligro.", "Tus enemigos piden una revancha fácil.",
	"¡Ja, ja! Parpadear era opcional.", "Buen intento. El peligro opina distinto.",
	"Tu botón de salto pide vacaciones.", "El escudo no era decorativo, ¿sabes?",
	"Respira. Salta. Repite. En ese orden.", "¡Ni el tutorial se esperaba eso!",
	"Tienes talento... para encontrar pinchos.", "No pasa nada. Bueno, pasó de todo.",
	"La cornisa era pequeña. El susto, no.", "Don Pánico te da las gracias. ¡JA, JA!"
]

const TIPS = [
	"Los círculos dorados anuncian caídas. Sal de su trayectoria.",
	"Agáchate para pasar por debajo de los proyectiles altos.",
	"Puedes saltar dos veces. Guarda el segundo salto para el final.",
	"El impulso te vuelve invulnerable un instante. Úsalo con intención.",
	"Un borde rojo anuncia que el terreno va a desaparecer.",
	"Dispara mientras te mueves: las luciérnagas buscan al enemigo.",
	"El escudo absorbe un golpe. La flor recupera un corazón.",
	"El reloj ralentiza los peligros; tus movimientos siguen igual.",
	"Los jefes cambian de patrón al perder la mitad de su vida."
]

static func level(index: int) -> Dictionary:
	var z: int = clampi(index / 4, 0, 4)
	var part: int = index % 4
	return {"index":index, "zone":z, "part":part, "name":ZONES[z].levels[part],
		"boss":part == 3, "duration":38.0 + part * 6.0 + z * 3.0,
		"interval":1.25 - z * 0.10 - part * 0.08, "speed":66.0 + z * 9.0 + part * 4.0,
		"enemy_interval":8.0 - z * 0.6, "shrink":part >= 1,
		"boss_hp":38 + z * 9}
