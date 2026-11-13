#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extrae el inventario mecanico desde Incubadora-Final.3dm."""

from __future__ import annotations

import collections
import csv
import json
import os
from pathlib import Path

import rhino3dm

from cad_common import (
    AMBIGUAS_VER_CAD,
    MODEL_3DM,
    UNITS,
    bbox_to_bounds,
    build_layer_index,
    component_label,
    component_of,
    component_rank,
    fabricacion_of,
    material_of,
    name_of,
    reconcile_envelope,
    size_sig,
    sorted_dims_from_bbox,
)


def geometry_type(geom) -> str:
    return type(geom).__name__


def is_block_instance(geom, dims) -> bool:
    if dims is None:
        return True
    return dims[0] < 1.0 and dims[1] < 1.0 and geometry_type(geom) != "Extrusion"


def confidence_for(leaf: str, fabricacion: str, block_count: int, real_count: int) -> str:
    n = leaf.lower()
    if block_count and real_count == 0:
        return "instancia (VER CAD)"
    if leaf in AMBIGUAS_VER_CAD:
        return "envolvente (VER CAD)"
    if "comprar" in fabricacion and any(k in n for k in ("rodamiento", "tornillo", "tuerca", "cooler", "bomba")):
        return "estandar"
    return "envolvente"


def collect_objects(model):
    layer_idx = build_layer_index(model)
    objects = []
    for obj in model.Objects:
        geom = obj.Geometry
        path, leaf = layer_idx.get(obj.Attributes.LayerIndex, ("?", "?"))
        try:
            bb = geom.GetBoundingBox()
        except Exception:
            bb = None
        dims = sorted_dims_from_bbox(bb) if bb is not None else None
        bounds = bbox_to_bounds(bb) if bb is not None else None
        objects.append({
            "leaf": leaf,
            "path": path,
            "component": component_of(leaf),
            "dims": dims,
            "size_sig": size_sig(dims),
            "bounds": bounds,
            "is_block_instance": is_block_instance(geom, dims),
            "geometry_type": geometry_type(geom),
        })
    return objects


def build_inventory(objects):
    grouped = collections.defaultdict(lambda: {
        "cant": 0,
        "block_count": 0,
        "real_count": 0,
        "paths": collections.Counter(),
        "geometry_types": collections.Counter(),
        "dims_samples": [],
    })

    layer_summary = collections.defaultdict(lambda: collections.Counter())
    for obj in objects:
        key = (obj["leaf"], obj["size_sig"])
        rec = grouped[key]
        rec["cant"] += 1
        rec["paths"][obj["path"]] += 1
        rec["geometry_types"][obj["geometry_type"]] += 1
        if obj["is_block_instance"]:
            rec["block_count"] += 1
        else:
            rec["real_count"] += 1
        if obj["dims"] is not None:
            rec["dims_samples"].append(obj["dims"])
            layer_summary[obj["leaf"]][obj["size_sig"]] += 1
        elif obj["is_block_instance"]:
            layer_summary[obj["leaf"]]["BLOQUE"] += 1

    rows = []
    for (leaf, sig), rec in grouped.items():
        component = component_of(leaf)
        dims = rec["dims_samples"][0] if rec["dims_samples"] else None
        fabricacion = fabricacion_of(component, leaf)
        rows.append({
            "n": None,
            "component": component,
            "component_label": component_label(component),
            "nombre": name_of(leaf, sig),
            "leaf": leaf,
            "ruta_cad": rec["paths"].most_common(1)[0][0] if rec["paths"] else leaf,
            "dims_mm": dims,
            "medidas": sig if sig != "BLOQUE" else "VER CAD",
            "cant": rec["cant"],
            "material": material_of(leaf),
            "fabricacion": fabricacion,
            "confianza": confidence_for(leaf, fabricacion, rec["block_count"], rec["real_count"]),
            "size_sig": sig,
            "geometry_types": dict(sorted(rec["geometry_types"].items())),
        })

    rows.sort(key=lambda r: (
        component_rank(r["component"]),
        -max(r["dims_mm"] or [0]),
        r["size_sig"],
        r["leaf"].lower(),
    ))
    for i, row in enumerate(rows, start=1):
        row["n"] = i
    return rows, layer_summary


def checks(rows):
    warnings = []
    by_leaf = collections.defaultdict(list)
    for row in rows:
        if row["dims_mm"]:
            by_leaf[row["leaf"]].append(row["dims_mm"])

    for dims in by_leaf.get("Perfil25-25", []):
        if not any(23 <= v <= 31 or 38 <= v <= 42 for v in dims[:2]):
            warnings.append(f"Perfil25-25 fuera de rango testigo: {dims}")
    for dims in by_leaf.get("Chapa 1/8", []):
        if not 2.8 <= dims[0] <= 3.9:
            warnings.append(f"Chapa 1/8 espesor fuera de rango testigo: {dims}")
    for leaf, expect in (("Rodamiento626", (5.0, 6.8, 18.0, 20.5)), ("Rodamiento624", (3.5, 5.8, 12.0, 14.5))):
        lo_inner, hi_inner, lo_outer, hi_outer = expect
        for dims in by_leaf.get(leaf, []):
            if not (lo_inner <= dims[0] <= hi_inner and lo_outer <= dims[-1] <= hi_outer):
                warnings.append(f"{leaf} fuera de rango testigo: {dims}")
    return warnings


def action_bucket(row):
    fabricacion = row["fabricacion"].lower()
    if "comprar" in fabricacion:
        return "Comprar"
    if "cortar" in fabricacion and "plegar" not in fabricacion and "tablero" not in fabricacion:
        return "Cortar"
    if "mecanizar" in fabricacion or "imprimir" in fabricacion:
        return "Fabricar / imprimir"
    if "referencia visual" in fabricacion:
        return "Referencia visual"
    return "VER CAD"


def write_component_summary(cad_dir: Path, by_component):
    order = ["Comprar", "Cortar", "Fabricar / imprimir", "VER CAD", "Referencia visual"]
    component_dir = cad_dir / "componentes"
    component_dir.mkdir(parents=True, exist_ok=True)

    def write_component_block(f, component, include_heading=True):
        if include_heading:
            f.write(f"## {component['label']}\n\n")
        buckets = collections.defaultdict(list)
        for row in component["piezas"]:
            buckets[action_bucket(row)].append(row)
        for bucket in order:
            items = buckets.get(bucket, [])
            if not items:
                continue
            f.write(f"### {bucket}\n\n")
            f.write("| N | Nombre funcional | Medidas mm | Cant | Capa CAD | Confianza |\n")
            f.write("|---:|---|---|---:|---|---|\n")
            for row in items:
                f.write(
                    f"| {row['n']} | {row['nombre']} | {row['medidas']} | {row['cant']} | "
                    f"{row['leaf']} | {row['confianza']} |\n"
                )
            f.write("\n")

    with (cad_dir / "resumen_componentes.md").open("w", encoding="utf-8") as f:
        f.write("# Resumen por componente\n\n")
        f.write(
            "Mini-BOM generado desde `inventario.json`. El inventario CAD completo queda en la pagina "
            "Inventario CAD; estas tablas son para comprar, preparar y montar sin cargar el flujo principal.\n\n"
        )
        for component in by_component.values():
            write_component_block(f, component)
            with (component_dir / f"{component['component']}.md").open("w", encoding="utf-8") as single:
                write_component_block(single, component, include_heading=False)


def write_outputs(cad_dir: Path, rows, layer_summary, envelope, warnings):
    by_component = collections.OrderedDict()
    for row in rows:
        by_component.setdefault(row["component"], {
            "component": row["component"],
            "label": row["component_label"],
            "piezas": [],
        })["piezas"].append(row)

    meta = {
        "modelo": MODEL_3DM,
        "units": UNITS,
        "envelope_body": envelope["body"],
        "envelope_total": envelope["total"],
        "envelope_notes": {
            "body": envelope["body_note"],
            "total": envelope["total_note"],
        },
        "caveat_numeracion": "Numeracion propia y reproducible; no corresponde necesariamente al PDF original.",
        "caveat_medidas": "Dimensiones = medida exterior (envolvente). Para agujeros, plegados y angulos abrir el CAD.",
        "warnings": warnings,
    }

    data = {
        "meta": meta,
        "componentes": list(by_component.values()),
        "maestro": rows,
    }
    cad_dir.mkdir(parents=True, exist_ok=True)
    with (cad_dir / "inventario.json").open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    cols = ["N", "Componente", "Nombre", "Capa CAD", "Medidas mm", "Cantidad", "Material", "Fabricacion", "Confianza"]
    with (cad_dir / "inventario.csv").open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(cols)
        for row in rows:
            writer.writerow([
                row["n"],
                row["component_label"],
                row["nombre"],
                row["leaf"],
                row["medidas"],
                row["cant"],
                row["material"],
                row["fabricacion"],
                row["confianza"],
            ])

    with (cad_dir / "inventario.md").open("w", encoding="utf-8") as f:
        total = " x ".join(f"{v:.1f}" for v in meta["envelope_total"])
        body = " x ".join(f"{v:.1f}" for v in meta["envelope_body"])
        f.write("# LibreIncu-150 - Inventario mecanico\n\n")
        f.write(f"- **Envolvente cuerpo:** {body} mm ({meta['envelope_notes']['body']}).\n")
        f.write(f"- **Envolvente total:** {total} mm ({meta['envelope_notes']['total']}).\n")
        f.write(f"- **Numeracion:** {meta['caveat_numeracion']}\n")
        f.write(f"- **Medidas:** {meta['caveat_medidas']}\n\n")
        if warnings:
            f.write("## Advertencias\n\n")
            for warning in warnings:
                f.write(f"- {warning}\n")
            f.write("\n")
        for component in by_component.values():
            f.write(f"## {component['label']}\n\n")
            f.write("| N | Nombre | Capa CAD | Medidas mm | Cant | Fabricacion | Confianza |\n")
            f.write("|---:|---|---|---|---:|---|---|\n")
            for row in component["piezas"]:
                anchor = f"<a id=\"pieza-{row['n']}\"></a>{row['n']}"
                f.write(
                    f"| {anchor} | {row['nombre']} | {row['leaf']} | {row['medidas']} | "
                    f"{row['cant']} | {row['fabricacion']} | {row['confianza']} |\n"
                )
            f.write("\n")
        f.write("## Resumen por capa\n\n")
        f.write("| Capa CAD | Medidas mm | Cantidad |\n|---|---|---:|\n")
        for leaf in sorted(layer_summary):
            for sig, count in sorted(layer_summary[leaf].items()):
                f.write(f"| {leaf} | {sig} | {count} |\n")
    write_component_summary(cad_dir, by_component)


def main():
    here = Path(__file__).resolve().parent
    model_path = here / MODEL_3DM
    if not model_path.exists():
        raise SystemExit(f"No se encontro {model_path}")
    model = rhino3dm.File3dm.Read(str(model_path))
    objects = collect_objects(model)
    rows, layer_summary = build_inventory(objects)
    envelope = reconcile_envelope(objects)
    warnings = checks(rows)
    write_outputs(here / "cad", rows, layer_summary, envelope, warnings)

    for warning in warnings:
        print(f"ADVERTENCIA: {warning}")
    print(
        f"OK - {len(rows)} tipos pieza. "
        f"Envolvente cuerpo={envelope['body']} total={envelope['total']} mm. "
        "Salidas en Rediseno/cad/inventario.{json,csv,md} y resumen_componentes.md"
    )


if __name__ == "__main__":
    main()
