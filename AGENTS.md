# CAD y manual

- La fuente CAD indicada por el usuario es el FCStd guardado. No reconstruirla
  desde generadores anteriores ni guardar cambios en el original al exportar.
- `scripts/export_manual.py` debe conservar las transformaciones globales de los
  grupos `App::Part`. Exportar hojas con `Part.export` directamente puede perder
  los giros y desplazamientos de sus grupos.
- Validar las piezas del STEP reimportado contra la fuente en coordenadas
  globales. Los límites y el volumen del conjunto no detectan por sí solos una
  pieza interna desplazada. Revisar una captura del STEP que muestre la pieza
  corregida.
- Al modificar el exportador, ejecutar `scripts/test_export_manual.py` con el
  Python de FreeCAD (importar `FreeCAD` antes de `Part`). Esta prueba usa grupos
  anidados y transformados y no modifica los modelos del proyecto.
- Mantener sincronizados los STEP, sus SHA-256 en
  `fuentes/cad-exportacion.json` y los enlaces de `docs/vista-3d.md`. Regenerar el
  PDF si cambian el texto o las imágenes que utiliza.
