"""Exporta el FCStd guardado a STEP y comprueba la geometría al reimportar.

Ejecutar con el Python de FreeCAD, sin reconstruir ni guardar el documento.
"""
import argparse
import hashlib
import json
from pathlib import Path

import FreeCAD as App
import Part


def summary(shape):
    # BoundBox usa la malla de visualización si la hay (FCStd guardado desde la
    # interfaz) y las B-spline reimportadas dan cajas holgadas: el límite óptimo
    # es exacto en los dos casos.
    box = shape.optimalBoundingBox(False, False)
    return {
        'solidos': len(shape.Solids),
        'volumen_mm3': shape.Volume,
        'limites_mm': [box.XMin, box.YMin, box.ZMin, box.XMax, box.YMax, box.ZMax],
    }


def world_shape(obj):
    """Incluye los Placement de todos los App::Part antecesores.

    Shape ya contiene el Placement local; reemplazarlo por el global evita
    perder el movimiento del grupo o aplicar dos veces el movimiento local.
    """
    shape = obj.Shape.copy()
    parent = obj.getGlobalPlacement().multiply(obj.Placement.inverse())
    shape.Placement = parent.multiply(shape.Placement)
    return shape


# El volumen de las caras B-spline se integra distinto al reimportar el STEP:
# la budinera (loft) pierde 2,7 de 97.540 mm3 aunque su intersección con el
# original da el volumen completo y los límites no cambian. Las posiciones se
# siguen controlando con los límites, a 1e-5 mm.
VOLUME_RTOL = 1e-4


def check_same_geometry(before, after, name):
    if before['solidos'] != after['solidos']:
        raise RuntimeError('Cambió el número de sólidos: ' + name)
    if abs(before['volumen_mm3'] - after['volumen_mm3']) > max(1e-3, abs(before['volumen_mm3']) * VOLUME_RTOL):
        raise RuntimeError('Cambió el volumen: ' + name)
    if any(abs(a - b) > 1e-5 for a, b in zip(before['limites_mm'], after['limites_mm'])):
        raise RuntimeError('Cambiaron las posiciones o dimensiones: ' + name)


def group_leaves(doc, names, exclude=()):
    """Part::Feature contenidos (a cualquier profundidad) en los grupos nombrados."""
    found = set()
    stack = [doc.getObject(n) for n in names]
    while stack:
        obj = stack.pop()
        if obj is None:
            continue
        if obj.TypeId == 'Part::Feature':
            found.add(obj.Name)
        else:
            stack.extend(getattr(obj, 'Group', []))
    return [o for o in doc.Objects if o.Name in found and o.Name not in exclude]


# Selecciones de la v3: se exportan solo si el documento tiene esos grupos.
OPTIONAL_TARGETS = {
    'deflector': (['deflector_inferior_bandejas_0p5mm'], ()),
    'fuente-de-calor': (['fuente_calor'], ('fc_agua_referencia',)),
    'carro-y-finales-de-carrera': (['carro_plegado_corredera_perno', 'dos_finales_de_carrera'], ()),
}


def export_document(doc, source, output):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    features = [o for o in doc.Objects if o.TypeId == 'Part::Feature']
    root = doc.getObject('despiece_libreincu')
    if root is None or not features:
        raise RuntimeError('El documento no contiene el despiece esperado')
    tray_groups = [o.Name for o in root.Group if o.Name.startswith(
        ('bandeja_', 'eje_bandeja_', 'soporte_KL08_', 'cuna_brazo_'))]
    screw_groups = ['husillo_8mm_400mm', 'soporte_KP08_superior',
                    'soporte_KP08_inferior', 'acople_8x8_motor']
    targets = {
        'LibreIncu_Rediseno_Despiece': features,
        'bandejas-y-soportes': [o for o in features if any(
            o.Name.startswith(g + '_pieza_') for g in tray_groups)],
        'husillo-kp08-acople': [o for o in features if any(
            o.Name.startswith(g + '_pieza_') for g in screw_groups)],
    }
    for name, (groups, exclude) in OPTIONAL_TARGETS.items():
        if all(doc.getObject(g) is not None for g in groups):
            targets[name] = group_leaves(doc, groups, exclude)
    manifest = {
        'fuente': Path(source).name,
        'sha256_fuente': hashlib.sha256(Path(source).read_bytes()).hexdigest(),
        'unidades': 'mm',
        'freecad': App.Version()[:3],
        'exportaciones': [],
    }
    for name, objects in targets.items():
        if not objects:
            raise RuntimeError('Selección vacía: ' + name)
        if any(o.Shape.isNull() or not o.Shape.isValid() for o in objects):
            raise RuntimeError('Geometría inválida en ' + name)
        shapes = [world_shape(o) for o in objects]
        original = Part.makeCompound(shapes)
        path = output / (name + '.step')
        # Part.export de las hojas originales omite los Placement de sus grupos.
        # Exportar copias globales en un documento temporal, sin tocar la fuente.
        export_doc = App.newDocument('ExportManual')
        try:
            copies = []
            for obj, shape in zip(objects, shapes):
                copy = export_doc.addObject('Part::Feature', obj.Name)
                copy.Label = obj.Label
                copy.Shape = shape
                copies.append(copy)
            export_doc.recompute()
            Part.export(copies, str(path))
        finally:
            App.closeDocument(export_doc.Name)
        imported = Part.read(str(path))
        if imported.isNull() or not imported.isValid():
            raise RuntimeError('STEP inválido: ' + str(path))
        before, after = summary(original), summary(imported)
        check_same_geometry(before, after, name)
        # Verificar cada sólido: los límites del conjunto pueden ocultar una
        # pieza desplazada dentro de la cámara.
        original_solids = [(obj, solid) for obj, shape in zip(objects, shapes)
                           for solid in shape.Solids]
        piece_checks = []
        for (obj, solid), imported_solid in zip(original_solids, imported.Solids):
            check_same_geometry(summary(solid), summary(imported_solid), obj.Name)
            if not imported_solid.isClosed() or imported_solid.Volume <= 0:
                raise RuntimeError('Sólido abierto o invertido: ' + obj.Name)
            result = {'objeto': obj.Name, 'global': summary(solid),
                      'step_reimportado': summary(imported_solid)}
            if obj.Name.startswith('deflector_'):
                missing_volume = solid.Volume - solid.common(imported_solid).Volume
                if abs(missing_volume) > max(1e-3, solid.Volume * 1e-6):
                    raise RuntimeError('El deflector no coincide en posición global: ' + obj.Name)
                result['diferencia_volumen_interseccion_mm3'] = missing_volume
            piece_checks.append(result)
        manifest['exportaciones'].append({
            'archivo': path.name,
            'objetos': [o.Name for o in objects],
            'original': before,
            'step_reimportado': after,
            'valido': True,
            'verificacion_por_solido': piece_checks,
            'sha256_step': hashlib.sha256(path.read_bytes()).hexdigest(),
        })
    return manifest


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--manifest', type=Path, required=True)
    args = parser.parse_args()
    doc = App.openDocument(str(args.source.resolve()))
    try:
        manifest = export_document(doc, args.source, args.output)
        args.manifest.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
        print(json.dumps([{'archivo': e['archivo'], 'valido': e['valido'],
                           'solidos': e['step_reimportado']['solidos']}
                          for e in manifest['exportaciones']], ensure_ascii=False))
    finally:
        App.closeDocument(doc.Name)
