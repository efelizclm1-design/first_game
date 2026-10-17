# Validación de Pixel Panic 0.2

Motor: **Godot 4.6.3 estándar**, Compatibility. Entorno: Linux, pantalla X11
virtual y Mesa llvmpipe. Los resultados describen este entorno, no el hardware
del jugador.

## Resultados

- Importación de recursos y scripts sin errores.
- **222 comprobaciones funcionales aprobadas, 0 fallidas**, sin errores de ejecución.
- **Dos recorridos de jugabilidad aprobados**: un controlador reactivo completó
  los niveles 1 y 2 con tres corazones, cero golpes y 6/5 enemigos derrotados.
  Usa movimiento, salto, agachado y disparos; no añade invulnerabilidad ni cambia
  velocidades, vidas, apariciones o daño. Esto comprueba que las primeras arenas
  admiten esquivas con esos controles; no evalúa la diversión de una persona.
- **33 capturas no vacías**: veinte arenas, portada, mapa, controles táctiles,
  carga, pausa, derrota, victoria, ajustes, final, tres páginas de guía y práctica.
- Curvas de velocidad/frecuencia comprobadas en 600 puntos de cada nivel:
  aumento gradual, avisos de al menos 0,85 s y dificultad inicial/final creciente
  de un nivel al siguiente, sin reinicios al cambiar de zona.
- Dirección del personaje y disparos, puntería solo hacia delante, fogonazo,
  daño real a enemigos, animaciones/estados de ataque y objetivo fijado durante
  el aviso. Colisión continua de proyectiles rápidos, salto doble, impulso,
  agachado, plataformas y descenso voluntario.
- Lava inofensiva durante el aviso; salto seguro, daño al aterrizar, suelo seguro
  al lado y enfriamiento. Pianos bajos superables saltando y flechas altas
  evitables agachándose, comprobados sin invulnerabilidad añadida.
- Guía presente al volver al nivel 1 incluso con la práctica ya completada;
  simulación detenida durante sus páginas, seis ejercicios funcionales y omisión.
- Tres vidas, escudo, curación, ralentización, fuego rápido, muerte/reintento,
  cambios de terreno, progresión, guardado aislado, controles táctiles simultáneos,
  pausa y bloqueo de niveles todavía no abiertos.
- En la simulación larga se observaron como máximo **22 peligros y 4 enemigos**.
  Todos los niveles respetaron los límites de entidades. No es una medición de FPS.

El recorrido largo de veinte niveles utiliza invulnerabilidad para aislar el
funcionamiento del director y la progresión. Usa disparos reales; si un jefe no
muere durante el recorrido, comprueba que atacó y recibió daño y después fuerza
su derrota para probar la transición. Por tanto, **no certifica que una persona
haya superado los veinte niveles ni el equilibrio final de los cinco jefes**.
Las pruebas de daño, lava, colisiones y los dos recorridos iniciales son separadas.

## Alcance

El ZIP incluye recursos listos para importar; no requiere Python al jugar.
Los generadores de arte son opcionales para desarrollo. Las capturas se revisaron
visualmente, incluyendo cielo, infierno y guía.

No se han probado una PC antigua ni teléfonos físicos, ni se han generado EXE,
APK o paquetes Web. Los presets son puntos de partida para exportar con las
plantillas del editor. Los controles móviles se probaron con eventos simulados.
La advertencia de V-Sync del servidor gráfico corresponde al controlador virtual.
El audio se carga sin errores; el dispositivo virtual no permite evaluar cómo
sonará en los altavoces del jugador.

## Repetir

Desde la carpeta del proyecto, con Godot en PATH:

```sh
./tools/check.sh
```

Importa y ejecuta ambas suites con datos de usuario temporales. Conserva los
códigos de salida y busca errores aunque el motor terminase con código cero.

Con una pantalla disponible:

```sh
godot --script tests/render.gd -- --test --output=/tmp/pixel-panic-capturas
```

No se incluye `.godot` ni partidas guardadas en el ZIP. Godot regenera su caché
al importar `project.godot`.
