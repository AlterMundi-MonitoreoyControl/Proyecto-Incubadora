#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Renderiza piezas, subconjuntos, locators y conjunto desde Incubadora-Final.3dm."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LightSource
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
import numpy as np
import rhino3dm

from cad_common import (
    AMBIENT,
    BLUE,
    CAMERA,
    COMPONENT_ORDER,
    DPI,
    EDGE_MAX_FACES,
    GHOST,
    MODEL_3DM,
    RED,
    VISUAL,
    bbox_to_bounds,
    build_layer_index,
    component_label,
    component_of,
    component_rank,
    include_in_locator_context,
    reconcile_envelope,
    slugify,
    sorted_dims,
)

try:
    import gmsh
    HAS_GMSH = True
except Exception as exc:  # pragma: no cover
    HAS_GMSH = False
    GMSH_IMPORT_ERROR = str(exc)


HERE = Path(__file__).resolve().parent
REPO = HERE.parent
CAD_DIR = HERE / "cad"
MODEL_PATH = HERE / MODEL_3DM
MODEL_STP = HERE / "Incubadora-Final.stp"
MODEL_IGS = HERE / "Incubadora-Final.igs"
PIECE_DIR = REPO / "docs" / "img" / "piezas"
COMPONENT_DIR = REPO / "docs" / "img" / "componentes"

MAX_LOCATOR_TRIANGLES = 400_000
MAX_COMPONENT_TRIANGLES = 250_000


@dataclass
class Group:
    verts: np.ndarray
    faces: np.ndarray
    rgb: tuple[float, float, float, float]
    alpha: float = 1.0
    shaded: bool = True
    edge: bool = False


def mesh_to_arrays(mesh):
    if mesh is None or len(mesh.Vertices) == 0:
        return None, None
    verts = np.array([[v.X, v.Y, v.Z] for v in mesh.Vertices], dtype=float)
    faces = []
    for i in range(len(mesh.Faces)):
        a, b, c, d = mesh.Faces[i]
        faces.append([a, b, c])
        if c != d:
            faces.append([a, c, d])
    if not faces:
        return None, None
    return verts, np.array(faces, dtype=int)


def get_mesh_from_geometry(geom):
    geom_type = type(geom).__name__
    if geom_type == "Extrusion":
        return mesh_to_arrays(geom.GetMesh(rhino3dm.MeshType.Any))
    if geom_type == "Brep":
        verts, faces, offset = [], [], 0
        for face in geom.Faces:
            try:
                v, f = mesh_to_arrays(face.GetMesh(rhino3dm.MeshType.Any))
            except Exception:
                continue
            if v is None:
                continue
            verts.append(v)
            faces.append(f + offset)
            offset += len(v)
        if verts:
            return np.vstack(verts), np.vstack(faces)
    return None, None


def load_inventory():
    path = CAD_DIR / "inventario.json"
    if not path.exists():
        raise SystemExit("Falta Rediseno/cad/inventario.json. Ejecutar primero Rediseno/extract_cad.py")
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    rows = data.get("maestro") or data.get("piezas") or []
    return data, rows


def load_rhino_objects():
    if not MODEL_PATH.exists():
        raise SystemExit(f"No se encontro el CAD maestro: {MODEL_PATH}")
    model = rhino3dm.File3dm.Read(str(MODEL_PATH))
    layer_idx = build_layer_index(model)
    objects = []
    for obj in model.Objects:
        geom = obj.Geometry
        path, leaf = layer_idx.get(obj.Attributes.LayerIndex, ("?", "?"))
        try:
            bb = geom.GetBoundingBox()
            bounds = bbox_to_bounds(bb)
            centroid = tuple((bounds.min[i] + bounds.max[i]) / 2.0 for i in range(3))
        except Exception:
            bounds = None
            centroid = None
        objects.append({
            "path": path,
            "leaf": leaf,
            "component": component_of(leaf),
            "bounds": bounds,
            "centroid": centroid,
            "geom": geom,
            "type": type(geom).__name__,
        })
    return objects


def build_mesh_cache(objects):
    by_leaf = defaultdict(list)
    stats = {}
    for obj in objects:
        by_leaf[obj["leaf"]].append(obj)

    cache = {}
    for leaf, objs in sorted(by_leaf.items()):
        verts, faces, offset = [], [], 0
        type_counts = Counter()
        for obj in objs:
            type_counts[obj["type"]] += 1
            v, f = get_mesh_from_geometry(obj["geom"])
            if v is None:
                continue
            verts.append(v)
            faces.append(f + offset)
            offset += len(v)
        if verts:
            cache[leaf] = (np.vstack(verts), np.vstack(faces))
        stats[leaf] = {
            "object_count": len(objs),
            "geometry_types": dict(sorted(type_counts.items())),
            "tri_count": int(sum(len(f) for f in faces)),
            "status": "renderable" if verts else "no_mallable",
        }
    if not cache:
        raise SystemExit("No se pudo mallar ninguna capa del CAD")
    return cache, stats


def gmsh_diagnostic():
    if not HAS_GMSH:
        return {"ok": False, "source": "ninguno", "note": f"gmsh no disponible: {GMSH_IMPORT_ERROR}"}
    source_path = None
    source = "ninguno"
    for candidate, label in ((MODEL_STP, "stp"), (MODEL_IGS, "igs")):
        if candidate.exists():
            source_path = candidate
            source = label
            break
    if source_path is None:
        return {"ok": False, "source": source, "note": "No hay STEP/IGS para diagnostico gmsh"}
    gmsh.initialize()
    gmsh.option.setNumber("General.Terminal", 0)
    try:
        gmsh.open(str(source_path))
        e3 = gmsh.model.getEntities(3)
        e2 = gmsh.model.getEntities(2)
        bb = gmsh.model.getBoundingBox(-1, -1)
        bbox = [round(bb[3] - bb[0], 1), round(bb[4] - bb[1], 1), round(bb[5] - bb[2], 1)]
        return {
            "ok": True,
            "source": source,
            "entities_3d": len(e3),
            "entities_2d": len(e2),
            "bbox_mm": bbox,
            "note": f"Diagnostico gmsh OK desde {source}",
        }
    except Exception as exc:
        return {"ok": False, "source": source, "note": f"Error gmsh: {exc}"}
    finally:
        try:
            gmsh.finalize()
        except Exception:
            pass


def mesh_bounds(meshes):
    verts = [mesh[0] for mesh in meshes if mesh is not None and len(mesh[0])]
    if not verts:
        return None
    all_v = np.vstack(verts)
    return all_v.min(axis=0), all_v.max(axis=0)


def combine_meshes(meshes):
    verts, faces, offset = [], [], 0
    for mesh in meshes:
        if mesh is None:
            continue
        v, f = mesh
        verts.append(v)
        faces.append(f + offset)
        offset += len(v)
    if not verts:
        return None
    return np.vstack(verts), np.vstack(faces)


def limit_layers(layer_meshes, max_triangles, protected=()):
    protected = set(protected)
    kept = dict(layer_meshes)
    omitted = []
    total = sum(len(f) for _, f in kept.values())
    for leaf in sorted(kept, key=lambda k: (k in protected, len(kept[k][1])), reverse=True):
        if total <= max_triangles:
            break
        if leaf in protected:
            continue
        total -= len(kept[leaf][1])
        omitted.append({"capa": leaf, "tri_count": int(len(kept[leaf][1])), "motivo": "omitida por presupuesto"})
        del kept[leaf]
    return kept, omitted


def render_groups(groups, output_path, *, xlim=None, ylim=None, zlim=None, title=None, dims_mm=None):
    fig = plt.figure(figsize=(7, 7))
    ax = fig.add_subplot(111, projection="3d")
    ls = LightSource(azdeg=315, altdeg=45)
    all_verts = []

    for group in groups:
        if group.verts is None or group.faces is None or len(group.faces) == 0:
            continue
        all_verts.append(group.verts)
        polys = group.verts[group.faces]
        base_rgb = np.array(group.rgb[:3], dtype=float)
        if group.shaded:
            normals = np.cross(polys[:, 1] - polys[:, 0], polys[:, 2] - polys[:, 0])
            norms = np.linalg.norm(normals, axis=1, keepdims=True)
            norms[norms == 0] = 1.0
            intensity = ls.shade_normals(normals / norms)
            shaded = base_rgb[None, :] * (AMBIENT + (1.0 - AMBIENT) * intensity[:, None])
        else:
            shaded = np.repeat(base_rgb[None, :], len(group.faces), axis=0)
        colors = np.ones((len(group.faces), 4))
        colors[:, :3] = np.clip(shaded, 0.0, 1.0)
        colors[:, 3] = group.alpha
        if group.edge and len(group.faces) <= EDGE_MAX_FACES:
            edgecolors = (0.0, 0.0, 0.0, 0.35)
            linewidths = 0.15
        else:
            edgecolors = "none"
            linewidths = 0.0
        ax.add_collection3d(Poly3DCollection(polys, facecolors=colors, edgecolors=edgecolors, linewidths=linewidths))

    if not all_verts:
        raise ValueError("No hay geometria para renderizar")

    verts = np.vstack(all_verts)
    if xlim is None or ylim is None or zlim is None:
        mins = verts.min(axis=0)
        maxs = verts.max(axis=0)
        spans = np.maximum(maxs - mins, 1.0)
        margin = float(spans.max()) * 0.04
        xlim = (mins[0] - margin, maxs[0] + margin)
        ylim = (mins[1] - margin, maxs[1] + margin)
        zlim = (mins[2] - margin, maxs[2] + margin)
    ax.set_xlim(*xlim)
    ax.set_ylim(*ylim)
    ax.set_zlim(*zlim)
    spans = np.array([xlim[1] - xlim[0], ylim[1] - ylim[0], zlim[1] - zlim[0]], dtype=float)
    max_span = float(spans.max()) or 1.0
    ax.set_box_aspect(np.maximum(spans, max_span * 0.03))
    ax.view_init(**CAMERA)
    ax.set_axis_off()
    if title:
        ax.set_title(title, fontsize=9, pad=0)
    if dims_mm:
        fig.text(0.5, 0.02, " x ".join(f"{v:.0f}" for v in dims_mm) + " mm", ha="center", fontsize=7, color="0.5")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, dpi=DPI, bbox_inches="tight", pad_inches=0.05)
    plt.close(fig)


def render_mesh(mesh, output_path, *, title=None, dims_mm=None):
    verts, faces = mesh
    render_groups([Group(verts, faces, BLUE, 1.0, True, True)], output_path, title=title, dims_mm=dims_mm)


def leaf_titles(rows):
    by_leaf = defaultdict(list)
    for row in rows:
        by_leaf[row.get("leaf") or row.get("pieza")].append(row)
    titles = {}
    for leaf, items in by_leaf.items():
        items = sorted(items, key=lambda r: r.get("n") or 999999)
        nums = [str(r["n"]) for r in items if r.get("n") is not None]
        title_num = nums[0] if len(nums) == 1 else f"{nums[0]}-{nums[-1]}" if nums else ""
        name = items[0].get("nombre") or leaf
        # La imagen es UNA instancia representativa; quitar el tamano del titulo para
        # que no contradiga las dims reales del pie (varias instancias = varios tamanos).
        name = re.sub(r"\s+\d+x\d+x\d+$", "", name)
        titles[leaf] = f"{title_num} - {name}" if title_num else name
    return titles, by_leaf


def render_pieces(cache, stats, rows, objects):
    titles, rows_by_leaf = leaf_titles(rows)
    objs_by_leaf = defaultdict(list)
    for obj in objects:
        objs_by_leaf[obj["leaf"]].append(obj)
    manifest = []
    candidate_leaves = sorted({
        leaf for leaf, items in rows_by_leaf.items()
        if items[0].get("component") not in {"visual", "tornilleria"} and items[0].get("fabricacion") != "comprar"
    }, key=lambda leaf: min((r.get("n") or 999999) for r in rows_by_leaf[leaf]))
    for leaf in candidate_leaves:
        slug = slugify(leaf)
        # Imagen de UNA instancia representativa (limpia y liviana); fallback a la capa combinada.
        mesh = representative_mesh(objs_by_leaf.get(leaf, [])) or cache.get(leaf)
        if mesh is None:
            manifest.append({"slug": slug, "pieza": leaf, "estado": "no_mallable", "tri_count": 0, "motivo": "VER CAD"})
            print(f"  [SKIP] pieza {slug}: no mallable")
            continue
        dims = sorted_dims_from_mesh(mesh)
        tri = int(len(mesh[1]))
        render_mesh(mesh, PIECE_DIR / f"{slug}.png", title=titles.get(leaf, leaf), dims_mm=dims)
        manifest.append({"slug": slug, "pieza": leaf, "estado": "rendered", "tri_count": tri,
                         "tri_count_capa": stats[leaf]["tri_count"], "dims_mm": dims})
        print(f"  [OK] pieza {slug}: {tri} triangulos (capa: {stats[leaf]['tri_count']})")
    return manifest


def sorted_dims_from_mesh(mesh):
    verts, _faces = mesh
    return sorted(round(float(verts.max(axis=0)[i] - verts.min(axis=0)[i]), 1) for i in range(3))


def _bbox_diag(bounds):
    if bounds is None:
        return 0.0
    return sum((bounds.max[i] - bounds.min[i]) ** 2 for i in range(3)) ** 0.5


def representative_mesh(objs):
    """Malla de UNA instancia representativa (la de mayor diagonal de bbox) de la capa.

    Para capas con muchas instancias (p. ej. AcopleBandejaEje x75) muestra una pieza
    limpia en vez de todas las copias dispersas, y es mucho mas liviana de renderizar.
    """
    ordered = sorted(objs, key=lambda o: _bbox_diag(o.get("bounds")), reverse=True)
    for obj in ordered:
        v, f = get_mesh_from_geometry(obj["geom"])
        if v is not None:
            return v, f
    return None


def render_components(cache, rows):
    leaves_by_component = defaultdict(set)
    for row in rows:
        component = row.get("component") or component_of(row.get("leaf") or row.get("pieza"))
        leaf = row.get("leaf") or row.get("pieza")
        if component not in {"visual", "tornilleria"}:
            leaves_by_component[component].add(leaf)

    all_context_layers = {
        leaf: mesh for leaf, mesh in cache.items()
        if include_in_locator_context(leaf)
    }
    global_bounds = mesh_bounds(all_context_layers.values())
    if global_bounds is None:
        raise ValueError("No hay contexto global para locators")
    mins, maxs = global_bounds
    spans = maxs - mins
    margin = float(spans.max()) * 0.04
    axes = (
        (mins[0] - margin, maxs[0] + margin),
        (mins[1] - margin, maxs[1] + margin),
        (mins[2] - margin, maxs[2] + margin),
    )

    # Decision UNICA y consistente: que capas pesadas se descartan del contexto
    # fantasma de TODOS los locators (se loguea una sola vez, no por componente).
    context_kept_global, locator_context_omitidas = limit_layers(all_context_layers, MAX_LOCATOR_TRIANGLES)

    manifest = []
    for component in sorted(leaves_by_component, key=component_rank):
        leaves = sorted(leaves_by_component[component])
        layer_meshes = {leaf: cache[leaf] for leaf in leaves if leaf in cache}
        label = component_label(component)
        slug = slugify(component)

        if not layer_meshes:
            manifest.append({"component": component, "label": label, "estado": "no_mallable",
                             "capas_componente": leaves, "tri_count": 0})
            print(f"  [SKIP] componente {component}: no mallable")
            continue

        # Subconjunto (solo): se limita por su propio presupuesto.
        kept_solo, omitidas_solo = limit_layers(layer_meshes, MAX_COMPONENT_TRIANGLES)
        solo = combine_meshes(kept_solo.values())
        tri_solo = int(sum(len(f) for _, f in kept_solo.values()))
        if solo is not None:
            render_mesh(solo, COMPONENT_DIR / f"{slug}-solo.png", title=label, dims_mm=sorted_dims_from_mesh(solo))

        # Locator: contexto = decision global menos las capas del componente; resaltado = componente.
        context_layers = {leaf: mesh for leaf, mesh in context_kept_global.items() if leaf not in leaves}
        context = combine_meshes(context_layers.values())
        highlight = combine_meshes(layer_meshes.values())
        groups = []
        if context is not None:
            groups.append(Group(context[0], context[1], GHOST, GHOST[3], False, False))
        if highlight is not None:
            groups.append(Group(highlight[0], highlight[1], RED, 1.0, True, True))
        render_groups(
            groups,
            COMPONENT_DIR / f"{slug}-locator.png",
            xlim=axes[0],
            ylim=axes[1],
            zlim=axes[2],
            title=f"{label} - locator",
        )
        manifest.append({
            "component": component,
            "label": label,
            "estado": "rendered",
            "tri_count": tri_solo,                 # triangulos realmente renderizados en el solo
            "capas_componente": leaves,            # todas las capas del componente
            "capas_solo": sorted(kept_solo),       # las que entraron en la imagen del solo
            "omitidas_solo": omitidas_solo,        # descartadas del solo por presupuesto
            "solo": f"docs/img/componentes/{slug}-solo.png" if solo is not None else None,
            "locator": f"docs/img/componentes/{slug}-locator.png",
        })
        print(f"  [OK] componente {component}: solo={tri_solo} tri")
    return {"componentes": manifest, "locator_contexto_omitidas": locator_context_omitidas}


def render_conjunto(cache):
    allow_components = {"cajon", "contrafondo", "rotacion", "transmision", "bandejas", "puerta", "electrica"}
    layer_meshes = {
        leaf: mesh for leaf, mesh in cache.items()
        if component_of(leaf) in allow_components and leaf not in VISUAL
    }
    kept, omitted = limit_layers(layer_meshes, MAX_LOCATOR_TRIANGLES)
    conjunto = combine_meshes(kept.values())
    if conjunto is None:
        return {"estado": "error", "tri_count": 0, "omitidas": omitted, "motivo": "sin mallas"}
    render_mesh(conjunto, PIECE_DIR / "_conjunto.png", title="LibreIncu-150 - conjunto", dims_mm=sorted_dims_from_mesh(conjunto))
    return {
        "estado": "rendered",
        "tri_count": int(len(conjunto[1])),
        "capas": sorted(kept),
        "omitidas": omitted,
        "path": "docs/img/piezas/_conjunto.png",
    }


def write_manifest(inventory_data, objects, stats, pieces, components, locator_ctx_omit, conjunto, diag, only):
    envelope = reconcile_envelope(objects)
    piece_ok = only not in {"piece", "all"} or any(p["estado"] == "rendered" for p in pieces)
    component_ok = only not in {"component", "all"} or any(c["estado"] == "rendered" for c in components)
    conjunto_ok = only not in {"conjunto", "all"} or conjunto["estado"] == "rendered"
    complete = piece_ok and component_ok and conjunto_ok
    data = {
        "aceptacion_completa": complete,
        "render_method": "rhino3dm_native_meshes",
        "envelope_body": envelope["body"],
        "envelope_total": envelope["total"],
        "gmsh_diagnostico": diag,
        "inventario_meta": inventory_data.get("meta", {}),
        "mesh_cache": stats,
        "piezas": pieces,
        "componentes": components,
        "locator_contexto_omitidas": locator_ctx_omit,
        "conjunto": conjunto,
    }
    for out_dir in (PIECE_DIR, COMPONENT_DIR):
        out_dir.mkdir(parents=True, exist_ok=True)
    with (PIECE_DIR / "manifiesto.json").open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    with (PIECE_DIR / "manifiesto.md").open("w", encoding="utf-8") as f:
        f.write("# Manifiesto de renders\n\n")
        f.write(f"- **aceptacion_completa:** `{complete}`\n")
        f.write("- **metodo:** rhino3dm_native_meshes\n")
        f.write(f"- **envolvente cuerpo:** {envelope['body']} mm\n")
        f.write(f"- **envolvente total:** {envelope['total']} mm\n")
        f.write(f"- **gmsh:** {diag.get('note')}\n\n")
        f.write("## Componentes\n\n")
        f.write("| Componente | Estado | Triangulos | Locator |\n|---|---|---:|---|\n")
        for item in components:
            f.write(f"| {item['label']} | {item['estado']} | {item['tri_count']} | {item.get('locator', '')} |\n")
        f.write("\n## Piezas\n\n")
        f.write("| Pieza | Estado | Triangulos | Dim mm |\n|---|---|---:|---|\n")
        for item in pieces:
            dims = "x".join(f"{v:.0f}" for v in item.get("dims_mm", []))
            f.write(f"| {item['pieza']} | {item['estado']} | {item['tri_count']} | {dims} |\n")
    return complete


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", choices=["piece", "component", "conjunto", "all"], default="all")
    return parser.parse_args()


def main():
    args = parse_args()
    inventory_data, rows = load_inventory()
    print(f"Leyendo CAD maestro: {MODEL_PATH}")
    objects = load_rhino_objects()
    print(f"  Objetos Rhino: {len(objects)}")
    print("Mallando capas una sola vez...")
    cache, stats = build_mesh_cache(objects)
    print(f"  Capas mallables: {len(cache)} / {len(stats)}")
    diag = gmsh_diagnostic()
    print(f"Diagnostico gmsh: {diag.get('note')}")

    pieces = []
    components = []
    locator_ctx_omit = []
    conjunto = {"estado": "skipped", "tri_count": 0}
    if args.only in {"piece", "all"}:
        print("\nRenderizando piezas...")
        pieces = render_pieces(cache, stats, rows, objects)
    if args.only in {"component", "all"}:
        print("\nRenderizando componentes y locators...")
        comp_result = render_components(cache, rows)
        components = comp_result["componentes"]
        locator_ctx_omit = comp_result["locator_contexto_omitidas"]
    if args.only in {"conjunto", "all"}:
        print("\nRenderizando conjunto...")
        conjunto = render_conjunto(cache)
        print(f"  [{conjunto['estado'].upper()}] conjunto: {conjunto['tri_count']} triangulos")

    complete = write_manifest(inventory_data, objects, stats, pieces, components,
                              locator_ctx_omit, conjunto, diag, args.only)
    print(f"\nManifiesto guardado. aceptacion_completa={complete}")
    return 0 if complete else 1


if __name__ == "__main__":
    sys.exit(main())
