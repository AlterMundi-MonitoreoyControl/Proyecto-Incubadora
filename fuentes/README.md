# Fuentes del manual

El manual publicado está en `docs/`, una página por etapa (orden en `mkdocs.yml`).

## Texto y fotografías

`manual-montaje-original.md` conserva el adjunto proporcionado por el usuario sin modificaciones. Las imágenes se extrajeron de las URLs de HackMD incluidas en ese adjunto. `imagenes.json` registra la URL original, el nombre descriptivo y el SHA-256 de cada archivo. Las fotografías se conservan sin retoques ni reconstrucción.

## CAD utilizado para ilustraciones

Archivo fuente: `/home/pablo/repos/2Incubadora/Rediseno/LibreIncu_Rediseno_Despiece.FCStd`.
SHA-256: `5ab180d757550a3b983e3bd64d6d23e9dcaabd0f47e3b2760ac321a8220ceab8`.

El archivo original se abrió para lectura y no se guardó ni modificó. Las vistas muestran componentes existentes, sin reconstruir piezas. Se ajustaron la cámara y los colores para facilitar su lectura y se extrajo el área visible de cada captura, quitando los márgenes blancos sin retocar la geometría.

Brief de exportación y vistas: se utiliza el FCStd guardado como fuente, sin ejecutar los generadores anteriores ni reconstruir piezas. Unidades en mm; X es ancho, Y profundidad, Z altura. Se conservan dimensiones y posiciones del documento. Salidas STEP en `docs/cad/`: conjunto completo (213 sólidos), bandejas con ejes, cunas y soportes (78 sólidos), y husillo con KP08 y acople (105 sólidos). Las dos selecciones parciales coinciden con las del macro de capturas. La cámara y los colores solo afectan las capturas.

`scripts/export_manual.py` exporta copias con posiciones globales, incluyendo los giros y desplazamientos de todos los grupos `App::Part`. Esto es necesario para conservar la posición del deflector: exportar directamente las piezas sueltas omite la transformación de su grupo. Se reimporta cada STEP para comprobar geometría válida, sólidos cerrados de volumen positivo, número de sólidos, volumen y límites XYZ de cada pieza contra la fuente en coordenadas globales. Para las nueve piezas del deflector se comprueba además la coincidencia geométrica mediante el volumen de intersección. `cad-exportacion.json` registra los resultados y los SHA-256 de fuente y salidas. `docs/img/cad/vistas.json` registra el SHA-256 del mismo FCStd para las imágenes.

El conjunto completo también se sincronizó con `LibreIncu_Rediseno_Layout_Preciso.step` en la carpeta del modelo original. Los STEP de otros generadores se conservan como versiones independientes.

El FCStd contiene dimensiones y posiciones provisionales del carro, finales de carrera, cunas y vínculo. No se trasladan esas cotas al manual como medidas de fabricación. Para los detalles del mecanismo se conserva la fotografía del equipo real. El deflector se documenta con las fotografías originales y las medidas confirmadas, sin utilizar la posición guardada del deflector en el CAD como instrucción de montaje.

Para regenerar las capturas con FreeCAD y su interfaz gráfica:

```bash
LIBREINCU_FCSTD="/home/pablo/repos/2Incubadora/Rediseno/LibreIncu_Rediseno_Despiece.FCStd" \
LIBREINCU_RENDER_DIR="$PWD/docs/img/cad" \
FreeCAD scripts/render_manual.FCMacro
```

Para regenerar los STEP, ejecutar desde la raíz del repositorio con un Python que pueda importar `FreeCAD` y `Part`:

```bash
python scripts/export_manual.py /home/pablo/repos/2Incubadora/Rediseno/LibreIncu_Rediseno_Despiece.FCStd \
  docs/cad --manifest fuentes/cad-exportacion.json
```

Con un AppImage montado, ese Python está disponible como `AppRun python`; definir `PYTHONPATH` apuntando a `usr/lib` dentro del montaje. Después de regenerar las capturas, actualizar el PDF con `python docs/build_doc.py` usando las dependencias indicadas en ese script.

Antes de publicar cambios del exportador, ejecutar `python scripts/test_export_manual.py` con ese mismo Python de FreeCAD. La prueba comprueba transformaciones anidadas y la reimportación STEP, incluyendo un caso donde los límites y el volumen del conjunto ocultan una pieza desplazada. Todos sus archivos se crean en una carpeta temporal.

## Aclaraciones confirmadas por el usuario

- Deflector: desarrollo de 225 mm; 470 mm de ancho útil; pestañas de 15 mm por lado; 500 mm de ancho total.
- Utilizar vistas CAD para la disposición general y fotos reales para los detalles que permanecen provisionales en el CAD.
- Relé de la bomba: puede elegirse IN1 o IN2; la entrada controlada por Hum/GPIO17 y la salida NO utilizada por la bomba deben pertenecer al mismo canal.

## Criterios de corrección

- Las conexiones J11, J6 y J9 se transcriben de los rótulos de las fotografías de la fuente; VCC de J6 (3,3 V) se distingue de JVCC del módulo de relés (5 V).
- Se eliminó la segunda aparición de la misma foto del step-down.
- Se reemplazaron los títulos genéricos de las imágenes por descripciones y pies de figura. La fotografía del mecanismo se identifica como conjunto; los planos KP08 y KFL08/KL08 se identifican por separado.
- Los ángulos del deflector se expresan como inclinación principal y pliegues, siguiendo la tabla original, sin atribuir todos los ángulos a planos absolutos respecto de la horizontal.
- Se retiraron del sitio los renders, modelos y manifiestos de la mecánica anterior. Las fotografías de referencia y las nuevas capturas quedan como únicos recursos gráficos del manual.
