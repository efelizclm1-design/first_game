# Validación de la entrega

Proyecto: **Pixel Panic · versión inicial jugable, estética oscura**.
Motor utilizado: **Godot 4.6.3 estándar**, renderizador Compatibility.
Entorno: Linux, pantalla X11 virtual y Mesa llvmpipe (renderizado por software).

## Resultados

- Importación del proyecto y los recursos: completada, sin errores de scripts.
- **104 comprobaciones funcionales: 104 aprobadas, 0 fallidas.**
- Recorrido de renderizado: **29 capturas no vacías**, incluyendo las veinte
  arenas y todas las pantallas principales; sin errores de scripts.
- Comprobados: movimiento, doble salto y aterrizaje; enfriamiento e invulnerabilidad
  del impulso; colisión de pie y agachado; daño, protección tras el golpe,
  escudo, curación y límite de tres vidas; muerte y reintento; avisos de peligro;
  colisión de pinchos; ralentización; desaparición y restauración del terreno;
  disparos, muerte de enemigos, puntuación y recogida de ayudas; segunda fase de
  jefes; avance por veinte niveles; desbloqueo, final y guardado/recarga; entradas
  táctiles simultáneas; pausa y rechazo de niveles bloqueados.
- La simulación de campaña limita entidades. En la corrida determinista se
  observaron como máximo **25 peligros y 2 enemigos** simultáneos, por debajo de
  los límites configurados. Esto no es una medición de FPS ni de RAM.
- Capturas reales de portada, mapa, bosque, jefe, carga y derrota inspeccionadas.
- No hay dependencias de Python, Pillow o herramientas externas al ejecutar el
  juego; solo son necesarias para regenerar los recursos opcionalmente.

Las pruebas funcionales de campaña utilizan invulnerabilidad para recorrer sus
veinte niveles, mientras que las pruebas de daño y muerte la desactivan. No
representan una partida humana completa sin asistencia ni certifican el equilibrio
final de dificultad. Los cinco jefes fueron derrotados por la simulación con
movimiento y disparo automático; las colisiones se prueban aparte.

## Límites de lo comprobado

- No se ha probado una computadora física antigua ni un teléfono real.
- Se comprobaron eventos táctiles simulados, no una instalación Android/iOS.
- No se han generado ni probado los paquetes Windows, Linux, Web o Android.
  Sus presets son puntos de partida para exportar con las plantillas adecuadas.
- No se ha realizado una prueba de compatibilidad con Godot 3, ni es compatible.
- El servidor gráfico virtual avisa que no puede cambiar V-Sync. Es una limitación
  del controlador de pruebas; no es un error del juego.
- El sonido está sintetizado en WAV y su carga/reproducción no produce errores.
  La salida de audio del entorno de capturas es virtual: no es una evaluación
  auditiva del equipo del usuario.

## Repetir

En Linux, `./tools/check.sh` importa y ejecuta las comprobaciones en directorios de
usuario temporales, conservando el estado de salida del motor y buscando errores
que Godot pudiera escribir aunque terminara con código cero.

Para el recorrido gráfico, con una pantalla real o virtual disponible:

```sh
godot --script tests/render.gd -- --test --output=/tmp/pixel-panic-capturas
```

No se incluye la carpeta `.godot` en el ZIP; Godot debe regenerarla al importarlo.
