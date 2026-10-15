# Pixel Panic

**Versión inicial jugable · Godot 4 · Interfaz en español · Estética oscura**

Nilo, un pequeño guardián con una bufanda demasiado bonita para rendirse, debe
sobrevivir a veinte arenas de peligros, criaturas y jefes. El escenario permanece
fijo: tú te mueves, saltas, esquivas y disparas.

## Abrir y jugar

1. Descomprime **toda** la carpeta `PixelPanic` en una carpeta de tu computadora.
2. Abre **Godot 4.6.3 estándar**, sin necesidad de .NET. Esta es la versión probada.
3. En el gestor de proyectos pulsa **Importar** y selecciona `project.godot`.
4. Espera a que Godot importe los gráficos y sonidos. Pulsa **F5** para
   ejecutar el proyecto completo; también sirve el botón ▶ de la esquina superior.
5. Pulsa **Empezar la aventura**, selecciona el nivel 01 y entra.

No hay que instalar Python, complementos, paquetes ni servicios para jugar.
Los archivos de arte y audio ya están incluidos. No necesitas conexión a Internet.
No abras solamente los scripts: importa `project.godot` con toda su carpeta.
Godot 3 no es compatible. El proyecto usa funciones disponibles en Godot 4.3+,
pero la validación realizada es con 4.6.3.

## Controles

| Acción | Teclado | Pantalla táctil |
|---|---|---|
| Moverte | A/D o ←/→ | < / > |
| Saltar, doble salto | Espacio, W o ↑ | SALTO, dos pulsaciones |
| Agacharte | Mantén S o ↓ | Mantén ABAJO |
| Disparar | Mantén J o Z | Mantén FUEGO |
| Impulso invulnerable | Shift, K o X | IMPULSO |
| Pausa | Esc o P | II |
| Elegir nivel | ←/→ y Enter, o ratón | Tocar nivel y ENTRAR |
| Reintentar | R en pausa o derrota | Botón de reintento |

Puedes mover, saltar y disparar a la vez. Los disparos apuntan al enemigo cercano.
El ajuste **Disparo automático** permite centrarse en esquivar. Los controles
se muestran automáticamente en dispositivos táctiles; también puedes activarlos
manualmente en Ajustes. Juega en horizontal.

## Las reglas

- Cada intento comienza con **3 corazones**. Al perderlos, puedes reintentar
  inmediatamente; los niveles ya superados permanecen desbloqueados.
- Los niveles normales se completan sobreviviendo al contador. En un nivel de
  jefe debes agotar su barra de vida.
- Los avisos dorados anuncian objetos que caen. Las flechas laterales anuncian
  proyectiles. Los signos rojos en el suelo anuncian pinchos o columnas.
- Los peligros esperan entre 0,65 y 0,95 segundos antes de activarse. El terreno
  da un aviso de 1,25 segundos antes de perder sus bordes durante seis segundos.
- Los disparos altos se evitan agachándose; los bajos, saltando. Los avisos
  señalan peligros reales, y el impulso protege durante un instante.
- La velocidad y frecuencia aumentan durante cada arena. En el glaciar, el
  personaje tiene algo de inercia. Los jefes cambian de fase al perder media vida.
- Ayudas: **escudo** (absorbe un golpe), **corazón** (cura, máximo 3), **reloj**
  (6 segundos de ralentización) y **rayo** (7 segundos de disparo rápido).
- Las estrellas cuentan el daño recibido: 3 sin recibir golpes, 2 con uno o dos
  golpes, 1 con más. Curarte no borra los golpes del contador de estrellas.
- Hay 24 frases y una risa sintetizada al perder. Puedes desactivar ambas con
  **Burlas y risas**. No hay anuncios, compras ni conexiones a servidores.

## Campaña

| Zona | Niveles | Identidad | Jefe |
|---|---|---|---|
| Bosque Ámbar | 01–04 | Hojas, bellotas, zarzas y criaturas de otoño | El Rey de la Hojarasca |
| Glaciar de Cristal | 05–08 | Cristales, hielo, granizo e inercia | La Emperatriz de Hielo |
| Ruinas Neón | 09–12 | Chatarra, drones y circuitos | El Alcalde Cortocircuito |
| Cielo Roto | 13–16 | Plumas, rayos y enemigos voladores | El Heraldo de la Tormenta |
| Caldera Infernal | 17–20 | Lava, calaveras y obsidiana | Don Pánico |

Cada zona contiene 16 variantes de objetos (80 en total), con ocho siluetas base
y dos variantes de material por zona. Comparten cuatro familias de comportamiento:
caídas, proyectiles laterales, erupciones del suelo y disparos enemigos. Los veinte
niveles combinan duración, velocidad, aparición de enemigos, cambios de suelo y
cinco jefes con ataques propios; no son veinte mecánicas completamente distintas.

## Computadoras modestas

El juego dibuja a **640 × 360**, escalado con filtro de vecino más cercano.
Usa el renderizador **Compatibility**, sin shaders, luces dinámicas, texturas 4K
ni físicas complejas. Hay límites de 46 peligros, 6 enemigos, 36 balas,
5 ayudas y 90 partículas simultáneas. Las texturas de fondo se cargan una vez.

Si tu computadora va justa, activa **Modo ligero**: limita a 30 FPS, reduce
partículas y desactiva el temblor de cámara. Cierra el editor al jugar una
exportación: el editor de Godot consume más que el juego exportado.

**No se garantiza compatibilidad con cualquier dispositivo.** Godot 4 Compatibility
requiere soporte de OpenGL 3.3 en escritorio o OpenGL ES 3.0 en móvil. Una PC muy
antigua sin ese soporte necesita otro motor/renderizador. No se han probado tu PC
ni teléfonos físicos. Las pruebas aquí fueron en Linux con Godot 4.6.3, incluso
renderizado por software; eso no certifica una tasa de FPS en tu equipo.

## Exportar fuera de Godot

El ZIP contiene el **proyecto fuente**, no un EXE ni un APK instalable.
Hay configuraciones iniciales para Windows de 64 bits, Linux de 64 bits, Web y
Android. Para producir esos ejecutables:

1. En Godot, **Editor → Administrar plantillas de exportación**. Instala las
   plantillas de la misma versión exacta que tu editor.
2. Abre **Proyecto → Exportar** y elige la plataforma.
3. Crea la carpeta de destino indicada o elige otra ruta y exporta.

Android requiere además configurar Android SDK, JDK y firma según la documentación
de Godot. No se incluyen claves de firma. La exportación Web se sirve desde un
servidor HTTP/HTTPS; no se ejecuta correctamente abriendo el HTML con doble clic.
No se han generado ni probado esos paquetes de plataforma. Para iOS se necesita
un preset adicional, macOS y Xcode; no se incluye un paquete iOS.

## Guardado

El progreso y los ajustes se guardan localmente en `user://pixel_panic_save.json`.
La escritura usa un archivo temporal antes de reemplazar el guardado. En el editor,
**Proyecto → Abrir carpeta de datos de usuario** muestra la ubicación. No se necesita
cuenta. Las capturas y pruebas automáticas usan un entorno aislado y no afectan tu
partida. El código de inicio ignora un JSON ilegible en vez de impedir jugar.

## Editar el juego

- `scripts/world.gd`: nombres, zonas, objetos, frases y parámetros de los 20 niveles.
- `scripts/game.gd`: movimiento, combate, colisiones, progresión, sonido y guardado.
- `scripts/painter.gd`: dibujo de las pantallas, HUD, mapa y efectos.
- `assets/art/`: PNG originales a resolución nativa.
- `assets/audio/`: cinco músicas originales y efectos sintetizados.
- `scenes/main.tscn`: escena inicial, enlazada por `project.godot`.
- `tools/create_assets.py`: generador de los recursos originales. Solo para
  regenerarlos se necesita Python y Pillow; no se ejecuta al jugar.
- `tests/`: pruebas funcionales y recorrido visual automático.

Es una primera versión completa para probar y ajustar. Las ilustraciones son
originales y el control es de arena fija; no incluye personajes ni recursos de Cuphead.

## Pruebas reproducibles

Desde la carpeta del proyecto, con `godot` en PATH:

```sh
godot --headless --editor --import --quit
godot --headless --script tests/smoke.gd -- --test
```

La prueba funcional usa invulnerabilidad únicamente al simular la duración de la
campaña, para aislar sus eventos; daño, muerte, escudos y colisiones se prueban
por separado. No sustituye una prueba humana de dificultad o diversión.

La prueba de guardado usa `pixel_panic_test_save.json`, separado de tu partida,
en `user://` dentro del directorio que indique
`XDG_DATA_HOME` en Linux. Usa un directorio temporal para no tocar una partida
existente. El script `tools/check.sh` configura rutas temporales automáticamente.

Con pantalla gráfica disponible:

```sh
godot --script tests/render.gd -- --test --output=/tmp/pixel-panic-capturas
```

Ese recorrido guarda 29 capturas: veinte arenas, portada, mapa, controles móviles,
carga, pausa, derrota, victoria, ajustes y final. Consulta `VALIDACION.md` para los
resultados de la versión entregada.

## Créditos

Código, gráficos y audio originales creados para Pixel Panic.
Fuente DejaVu Sans: su licencia y atribuciones están en `assets/FONT_LICENSE.txt`.
Motor Godot: https://godotengine.org/license/
