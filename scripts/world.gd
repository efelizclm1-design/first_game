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
	{"name":"REINO CELESTIAL", "short":"CIELO", "color":"f6d77f", "boss":"El Gran Serafín", "enemy":"Ángel guardián", "tag":"Hasta los pianos tienen alas.",
	"levels":["Puertas del paraíso", "Puerto de las nubes", "Catedral de los ángeles", "El Gran Serafín"],
	"objects":["Pluma cuchilla", "Piano celestial", "Flecha angelical", "Campana del cielo", "Estrella fugaz", "Trompeta del juicio", "Columna de mármol", "Relámpago", "Pluma dorada", "Arpa desafinada", "Lanza del serafín", "Incensario", "Sol ardiente", "Cometa", "Reloj celestial", "Órgano de las nubes"]},
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
	"Las señales ! y sus líneas anuncian la trayectoria del peligro.",
	"Agáchate para pasar por debajo de los proyectiles altos.",
	"Puedes saltar dos veces. Guarda el segundo salto para el final.",
	"El impulso te vuelve invulnerable un instante. Úsalo con intención.",
	"Un borde rojo anuncia que el terreno va a desaparecer.",
	"En el infierno, las grietas amarillas avisan: sal antes de que sean lava.",
	"Dispara hacia delante. Gira hacia el enemigo antes de atacar.",
	"El escudo absorbe un golpe. La flor recupera un corazón.",
	"El reloj ralentiza los peligros; tus movimientos siguen igual.",
	"Los jefes cambian de patrón al perder la mitad de su vida."
]

const SCENES = [
 "Sendero del otoño", "Molino de los cuervos", "Cementerio de raíces", "Trono del roble hueco",
 "Lago de los espejos", "Observatorio sepultado", "Gruta de las agujas", "Palacio del cero",
 "Estación sin regreso", "Mercado de las sombras", "Reactor a medianoche", "Torre del apagón",
 "Puertas del paraíso", "Puerto de las nubes", "Catedral de los ángeles", "Trono del Gran Serafín",
 "Puente de las cenizas", "Forja de los condenados", "Ciudad de obsidiana", "Corazón del volcán"
]

# Each arena has its own inhabitants, sharing three readable combat roles.
const ENEMIES = [
 ["Duende de bellota","Jabalí de hojas","Cuervo otoñal"],
 ["Molinero espino","Espantapájaros","Cuervo del molino"],
 ["Sepulturero de raíces","Guardián de lápida","Polilla espectral"],
 ["Chamán del roble","Caballero corteza","Búho de la corona"],
 ["Pescador de escarcha","Foca de cristal","Frailecillo polar"],
 ["Astrónomo helado","Guardia del telescopio","Búho astral"],
 ["Mago de cuarzo","Gólem de agujas","Murciélago de hielo"],
 ["Mago imperial","Caballero glacial","Halcón de nieve"],
 ["Revisor mecánico","Vagón centinela","Dron de estación"],
 ["Mercader eléctrico","Autómata feriante","Dron de anuncios"],
 ["Técnico de plasma","Robot reactor","Dron nuclear"],
 ["Alguacil de neón","Guarda de la torre","Dron vigilante"],
 ["Ángel portero","Custodio de mármol","Querubín arquero"],
 ["Ángel marinero","Capitán de las nubes","Querubín del viento"],
 ["Ángel organista","Guardián de campana","Querubín del coro"],
 ["Ángel heraldo","Caballero serafín","Querubín solar"],
 ["Diablo de ceniza","Gólem de basalto","Murciélago de brasa"],
 ["Herrero infernal","Forjador de lava","Murciélago de hierro"],
 ["Brujo de obsidiana","Caballero volcánico","Murciélago de cristal"],
 ["Diablo del cráter","Titán de magma","Murciélago de fuego"]
]

static func enemy_name(index: int, role: int) -> String:
 return ENEMIES[clampi(index,0,19)][clampi(role,0,2)]

static func level(index: int) -> Dictionary:
 var i = clampi(index,0,19)
 var z = i / 4
 var part = i % 4
 return {"index":i,"zone":z,"part":part,"name":SCENES[i],"boss":part==3,
  "duration":48.0+i*1.3 if part!=3 else 78.0+i*1.3,
  "speed_start":145.0+i*12.0,"speed_end":193.0+i*17.0,
  "interval_start":3.3-i*.092,"interval_end":2.55-i*.077,
  "enemy_start":8.6-i*.19,"enemy_end":6.8-i*.18,
  "warning_start":1.45-i*.020,"warning_end":1.18-i*.017,
  "enemy_limit":mini(4,1+i/5),"boss_hp":100+i*8,
  "shrink":i>=2 and z!=4,"lava":z==4,"terrain_inset":100.0+i*6.0,"seed":75001+i*193}

static func pressure(index: int, elapsed: float) -> Dictionary:
 var data = level(index)
 var t = clampf(elapsed / data.duration,0,1)
 # Continuous, differentiable acceleration, with no zone resets or abrupt phases.
 var u = t*t*(3.0-2.0*t)
 return {"progress":t,"speed":lerpf(data.speed_start,data.speed_end,u),
  "interval":lerpf(data.interval_start,data.interval_end,u),
  "enemy_interval":lerpf(data.enemy_start,data.enemy_end,u),
  "warning":lerpf(data.warning_start,data.warning_end,u),
  "rate":lerpf(data.speed_start,data.speed_end,u)/145.0}

static func platforms(index: int) -> Array:
 if index==0:return []
 var layouts = [
  [Rect2(260,492,155,14),Rect2(835,463,155,14)],
  [Rect2(225,486,165,14),Rect2(850,486,165,14)],
  [Rect2(300,473,145,14),Rect2(720,442,155,14)],
  [Rect2(350,480,155,14),Rect2(815,456,155,14)]
 ]
 return layouts[index%4].duplicate()
