#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Genera GLB para visor 3D liviano con <model-viewer>.

Salidas:
  docs/models/piezas/<slug>.glb          — una pieza representativa por capa.
  docs/models/conjunto-armado.glb        — conjunto en posicion real.
  docs/models/conjunto-despiece.glb      — conjunto pre-explotado radialmente.
  docs/models/manifiesto_glb.json        — metadata + hotspots.
  Rediseno/cad/vista3d_piezas.md         — grid de thumbnails para docs/vista-3d.md.
  docs/vista-3d.md                       — pagina del visor.

Usa pymeshlab para simplificacion opcional de mallas densas. Sin pymeshlab,
funciona con omisiones (ver plan fallback).
"""

from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path

import numpy as np
import trimesh

# render_parts vive en el mismo directorio; importar funciones reutilizables.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from render_parts import (
    build_mesh_cache,
    combine_meshes,
    limit_layers,
    load_inventory,
    load_rhino_objects,
    representative_mesh,
)

from cad_common import (
    COMPONENT_ORDER,
    VISUAL,
    component_color,
    component_label,
    component_of,
    component_rank,
    name_of,
    slugify,
)

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
MODELS_DIR = REPO / "docs" / "models"
PIEZAS_DIR = MODELS_DIR / "piezas"
CAD_DIR = HERE / "cad"

MAX_PIECE_TRIANGLES = 20_000
SIMPLIFY_THRESHOLD = 10_000       # target por capa en el conjunto
MAX_GLB_TRIANGLES = 300_000       # tope de seguridad tras simplificar
EXPLODE_FACTOR = 0.6

# Dependencia opcional: pymeshlab para decimacion rapida.
try:
    import pymeshlab

    HAS_PYMESHLAB = True
except Exception as _pml_err:  # pragma: no cover
    HAS_PYMESHLAB = False
    pymeshlab = None  # type: ignore


def zup_to_yup(verts: np.ndarray | None) -> np.ndarray | None:
    """Rhino es Z-up; glTF es Y-up. Aplica rotacion -90° en X."""
    if verts is None or len(verts) == 0:
        return verts
    v = np.asarray(verts, dtype=np.float32)
    return np.column_stack([v[:, 0], v[:, 2], -v[:, 1]])


def vec3(v) -> tuple[float, float, float]:
    return (float(v[0]), float(v[1]), float(v[2]))


def normalize(v: np.ndarray) -> np.ndarray:
    norm = np.linalg.norm(v)
    if norm == 0:
        return np.array([0.0, 1.0, 0.0])
    return v / norm


def simplify_mesh(verts, faces, target_faces: int) -> tuple[np.ndarray, np.ndarray]:
    """Decimacion Quadric Edge Collapse con pymeshlab (opcional)."""
    if not HAS_PYMESHLAB:
        return verts, faces
    if len(faces) <= target_faces:
        return verts, faces
    try:
        ms = pymeshlab.MeshSet()
        m = pymeshlab.Mesh(vertex_matrix=np.asarray(verts, dtype=np.float64),
                          face_matrix=np.asarray(faces, dtype=np.int32))
        ms.add_mesh(m)
        ms.meshing_decimation_quadric_edge_collapse(
            targetfacenum=int(target_faces),
            autoclean=True,
            preservenormal=True,
            preserveboundary=False,
        )
        m_out = ms.current_mesh()
        v = np.asarray(m_out.vertex_matrix(), dtype=np.float32)
        f = np.asarray(m_out.face_matrix(), dtype=np.int32)
        if len(f) > 0:
            return v, f
    except Exception as exc:
        print(f"    [WARN] pymeshlab no pudo simplificar: {exc}")
    return verts, faces


def make_trimesh(verts, faces, color_rgba=None, alpha: float | None = None) -> trimesh.Trimesh | None:
    verts = zup_to_yup(verts)
    if verts is None or faces is None or len(faces) == 0:
        return None
    mesh = trimesh.Trimesh(vertices=verts, faces=faces, process=False)
    if color_rgba is not None:
        rgba = np.array(color_rgba, dtype=np.float32)
        if alpha is not None:
            rgba = rgba.copy()
            rgba[3] = alpha
        rgba_u8 = (np.clip(rgba, 0, 1) * 255).astype(np.uint8)
        mesh.visual.vertex_colors = np.tile(rgba_u8, (len(mesh.vertices), 1))
    return mesh


def export_glb(mesh_or_scene, path: Path) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    mesh_or_scene.export(file_obj=str(path), file_type="glb")
    return path.stat().st_size


def centroid_of_verts(verts: np.ndarray) -> np.ndarray:
    return verts.mean(axis=0)


def bounds_of_verts(verts: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    return verts.min(axis=0), verts.max(axis=0)


def diagonal(minmax: tuple[np.ndarray, np.ndarray]) -> float:
    return float(np.linalg.norm(minmax[1] - minmax[0]))


def piece_candidates(rows: list[dict]) -> list[str]:
    """Capas a exportar como GLB individual (mismo criterio que render_pieces)."""
    by_leaf = defaultdict(list)
    for row in rows:
        by_leaf[row.get("leaf") or row.get("pieza")].append(row)
    selected = []
    for leaf, items in by_leaf.items():
        comp = items[0].get("component") or component_of(leaf)
        fab = items[0].get("fabricacion", "")
        if comp in {"visual", "tornilleria"} or "comprar" in fab.lower():
            continue
        selected.append(leaf)
    return sorted(selected, key=lambda leaf: min((r.get("n") or 999999) for r in by_leaf[leaf]))


def export_piece_glbs(cache: dict, objects: list[dict], rows: list[dict]) -> list[dict]:
    print("\nExportando GLB per-pieza...")
    if not HAS_PYMESHLAB:
        print("  (pymeshlab no disponible; piezas densas se omitiran)")
    by_leaf = defaultdict(list)
    for row in rows:
        by_leaf[row.get("leaf") or row.get("pieza")].append(row)

    objs_by_leaf = defaultdict(list)
    for obj in objects:
        objs_by_leaf[obj["leaf"]].append(obj)

    pieces = []
    for leaf in piece_candidates(rows):
        slug = slugify(leaf)
        mesh = representative_mesh(objs_by_leaf.get(leaf, [])) or cache.get(leaf)
        if mesh is None:
            print(f"  [SKIP] {slug}: sin malla")
            continue
        verts, faces = mesh
        original_faces = len(faces)
        omitted = False
        motivo = ""

        if original_faces > MAX_PIECE_TRIANGLES:
            verts, faces = simplify_mesh(verts, faces, MAX_PIECE_TRIANGLES)
        if len(faces) > MAX_PIECE_TRIANGLES:
            omitted = True
            motivo = f"{len(faces)} triangulos exceden presupuesto ({MAX_PIECE_TRIANGLES})"
            print(f"  [SKIP] {slug}: {motivo}")

        items = by_leaf[leaf]
        nums = sorted(r["n"] for r in items if r.get("n") is not None)
        n_range = f"{nums[0]}" if len(nums) == 1 else f"{nums[0]}-{nums[-1]}" if nums else ""
        name = name_of(leaf)
        caption = f"Nº {n_range} — {name}" if n_range else name

        if omitted:
            pieces.append({
                "slug": slug,
                "leaf": leaf,
                "component": items[0].get("component") or component_of(leaf),
                "path": None,
                "poster": f"img/piezas/{slug}.png",
                "caption": caption + " (ver PNG; modelo muy denso para web)",
                "n_range": n_range,
                "tri_count": len(faces),
                "size_bytes": 0,
                "omitida": True,
                "motivo": motivo,
            })
            continue

        tm = make_trimesh(verts, faces)
        if tm is None:
            continue
        path = PIEZAS_DIR / f"{slug}.glb"
        size = export_glb(tm, path)
        pieces.append({
            "slug": slug,
            "leaf": leaf,
            "component": items[0].get("component") or component_of(leaf),
            "path": f"models/piezas/{slug}.glb",
            "poster": f"img/piezas/{slug}.png",
            "caption": caption,
            "n_range": n_range,
            "tri_count": int(len(tm.faces)),
            "size_bytes": size,
        })
        print(f"  [OK] {slug}: {len(tm.faces)} tri, {size/1024:.1f} KB")
    return pieces


def export_conjuntos(cache: dict, objects: list[dict]) -> dict:
    print("\nExportando GLB de conjunto...")
    if not HAS_PYMESHLAB:
        print("  (pymeshlab no disponible; se usara limit_layers con omisiones)")
    allow = {"cajon", "contrafondo", "rotacion", "transmision", "bandejas", "puerta", "electrica"}
    layer_meshes = {
        leaf: mesh for leaf, mesh in cache.items()
        if component_of(leaf) in allow and leaf not in VISUAL
    }

    # Simplificar capas densas antes de ensamblar, para incluir todos los componentes.
    simplified = {}
    for leaf, (verts, faces) in layer_meshes.items():
        if len(faces) > SIMPLIFY_THRESHOLD:
            verts, faces = simplify_mesh(verts, faces, SIMPLIFY_THRESHOLD)
        if len(faces) > 0:
            simplified[leaf] = (verts, faces)

    kept, omitted = limit_layers(simplified, MAX_GLB_TRIANGLES)
    print(f"  Capas incluidas: {len(kept)}; omitidas: {[o['capa'] for o in omitted]}")

    comp_meshes: dict[str, list[tuple[str, trimesh.Trimesh]]] = defaultdict(list)
    comp_centroids: dict[str, np.ndarray] = {}

    for leaf, (verts, faces) in kept.items():
        comp = component_of(leaf)
        # Malla intermedia SIN rotar: la conversion Z-up->Y-up (zup_to_yup) se aplica
        # UNA sola vez al construir armado/despiece con make_trimesh. Aplicarla tambien
        # aca duplicaba la rotacion (-180°) y dejaba el conjunto acostado de espaldas.
        if verts is None or faces is None or len(faces) == 0:
            continue
        tm = trimesh.Trimesh(vertices=np.asarray(verts, dtype=np.float32),
                             faces=np.asarray(faces), process=False)
        comp_meshes[comp].append((leaf, tm))

    if not comp_meshes:
        raise SystemExit("No se pudo crear ningun componente para el conjunto")

    scene_armado = trimesh.Scene()
    scene_despiece = trimesh.Scene()
    hotspots = []

    all_verts = []
    for comp, items in comp_meshes.items():
        for _leaf, tm in items:
            all_verts.append(tm.vertices)
    global_verts = np.vstack(all_verts)
    global_centroid = centroid_of_verts(global_verts)
    global_diag = diagonal(bounds_of_verts(global_verts))

    for comp in sorted(comp_meshes, key=component_rank):
        items = comp_meshes[comp]
        comp_verts = [tm.vertices for _leaf, tm in items]
        comp_all_verts = np.vstack(comp_verts)
        comp_centroid = centroid_of_verts(comp_all_verts)
        comp_bounds_val = bounds_of_verts(comp_all_verts)
        comp_centroids[comp] = comp_centroid

        # Armado: un mesh por componente.
        verts_list = [tm.vertices for _leaf, tm in items]
        faces_list = [tm.faces for _leaf, tm in items]
        armado = make_trimesh(np.vstack(verts_list), np.vstack(faces_list), component_color(comp))
        if armado is None:
            continue
        scene_armado.add_geometry(armado, node_name=comp)

        # Despiece: explode radial desde el centro global.
        direction = normalize(comp_centroid - global_centroid)
        offset = direction * (EXPLODE_FACTOR * global_diag)
        exploded_verts = []
        exploded_faces = []
        voffset = 0
        for _leaf, tm in items:
            exploded_verts.append(tm.vertices + offset)
            exploded_faces.append(tm.faces + voffset)
            voffset += len(tm.vertices)
        despiece = make_trimesh(np.vstack(exploded_verts), np.vstack(exploded_faces), component_color(comp))
        if despiece is not None:
            scene_despiece.add_geometry(despiece, node_name=comp)

        hotspots.append({
            "component": comp,
            "label": component_label(comp),
            "position": vec3(comp_centroid),
            "normal": (0.0, 1.0, 0.0),
        })

    armado_path = MODELS_DIR / "conjunto-armado.glb"
    despiece_path = MODELS_DIR / "conjunto-despiece.glb"
    armado_size = export_glb(scene_armado, armado_path)
    despiece_size = export_glb(scene_despiece, despiece_path)

    total_tri = sum(len(f) for _, f in kept.values())
    print(f"  [OK] conjunto-armado: {total_tri} tri, {armado_size/1024:.1f} KB")
    print(f"  [OK] conjunto-despiece: {total_tri} tri, {despiece_size/1024:.1f} KB")

    return {
        "armado": {
            "path": "models/conjunto-armado.glb",
            "size_bytes": armado_size,
            "tri_count": total_tri,
        },
        "despiece": {
            "path": "models/conjunto-despiece.glb",
            "size_bytes": despiece_size,
            "tri_count": total_tri,
        },
        "capas_incluidas": sorted(kept),
        "capas_omitidas": omitted,
        "hotspots": hotspots,
        "global_centroid": vec3(global_centroid),
        "global_diagonal": global_diag,
    }


def write_vista3d_piezas_md(pieces: list[dict]) -> Path:
    path = CAD_DIR / "vista3d_piezas.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "<!-- Generado por Rediseno/render_glb.py — no editar manualmente -->\n",
        '<div class="vista3d-grid" id="vista3d-grid">\n',
    ]
    for p in sorted(pieces, key=lambda x: (component_rank(x["component"]), x["slug"])):
        # El fragmento se incluye en /vista-3d/, asi que las rutas (relativas a docs/)
        # necesitan ../ para resolver contra docs/models y docs/img.
        poster_rel = f'../{p["poster"]}'
        if p.get("omitida"):
            # Sin GLB: thumbnail informativo que no abre visor.
            lines.append(
                f'  <div class="v3d-thumb v3d-thumb-no3d" title="{p["caption"]}">\n'
                f'    <img src="{poster_rel}" alt="{p["caption"]}" loading="lazy">\n'
                f'    <span>{p["caption"]}</span>\n'
                f'  </div>\n'
            )
        else:
            lines.append(
                f'  <button class="v3d-thumb" data-src="../{p["path"]}" data-poster="{poster_rel}" '
                f'data-caption="{p["caption"]}" aria-label="{p["caption"]}">\n'
                f'    <img src="{poster_rel}" alt="{p["caption"]}" loading="lazy">\n'
                f'    <span>{p["caption"]}</span>\n'
                f'  </button>\n'
            )
    lines.append("</div>\n")
    path.write_text("".join(lines), encoding="utf-8")
    print(f"\nEscrito {path}")
    return path


def write_vista3d_md(pieces: list[dict], conjunto: dict) -> Path:
    """DEPRECADA / NO USAR. docs/vista-3d.md es contenido AUTORADO a mano
    (model-viewer vendorizado en docs/assets, reveal=auto, camara 68deg, sin
    hotspots, rutas ../). El template de abajo quedo viejo y NO se llama desde
    main(); se conserva solo como referencia. Llamarla pisaria la pagina buena."""
    raise RuntimeError(
        "write_vista3d_md esta deprecada: docs/vista-3d.md se edita a mano, no se genera."
    )
    path = REPO / "docs" / "vista-3d.md"
    path.parent.mkdir(parents=True, exist_ok=True)

    hotspot_html = "\n".join(
        f'    <button slot="hotspot-{h["component"]}" data-position="{" ".join(str(v) for v in h["position"])}" '
        f'data-normal="{" ".join(str(v) for v in h["normal"])}">{h["label"]}</button>'
        for h in conjunto["hotspots"]
    )

    md = f"""# Vista 3D y despiece

Explorá el modelo 3D de la LibreIncu-150 directamente en el navegador. Podés rotar con el mouse/tactil,
usar el boton para alternar entre **armado** y **despiece**, y hacer clic en las piezas de abajo para
ver cada una en 3D. Los numeros (`Nº`) coinciden con la tabla del [Inventario CAD](inventario.md).

!!! info "Requisitos"
    Esta pagina usa `<model-viewer>` cargado desde CDN. Necesita un navegador con WebGL e internet.
    No aparece en el PDF. Los modelos se descargan bajo demanda; el poster PNG se muestra hasta entonces.

!!! warning "Modelos 3D = solo visualizacion"
    Los GLB se generan a partir de mallas simplificadas para web. **No usarlos para medir ni fabricar:**
    pierden detalle fino (agujeros, dientes, plegados). Las medidas y la geometria de taller estan en el
    [Inventario CAD](inventario.md) y en el CAD maestro.

<script type="module" src="https://unpkg.com/@google/model-viewer@3.5.0/dist/model-viewer.min.js"></script>

## Conjunto

<div class="vista3d-conjunto">
  <div class="v3d-tabs">
    <button id="btn-armado" class="v3d-tab active" data-mode="armado">Armado</button>
    <button id="btn-despiece" class="v3d-tab" data-mode="despiece">Despiece</button>
  </div>
  <model-viewer id="visor-conjunto"
                src="models/conjunto-armado.glb"
                poster="img/piezas/_conjunto.png"
                alt="Conjunto LibreIncu-150"
                camera-controls
                camera-orbit="-60deg 22deg 2.5m"
                auto-rotate
                reveal="interaction"
                shadow-intensity="1"
                exposure="0.8">
{hotspot_html}
    <div slot="poster" class="v3d-poster-hint">Toca o hace clic para cargar el modelo 3D</div>
    <div class="v3d-fallback">Tu navegador no soporta WebGL o no puede cargar model-viewer.</div>
  </model-viewer>
</div>

## Piezas

Selecciona una pieza para ver su modelo 3D. Los numeros son los mismos del [Inventario CAD](inventario.md).

<div class="vista3d-pieza">
  <model-viewer id="visor-pieza"
                src=""
                poster="img/piezas/_conjunto.png"
                alt="Pieza seleccionada"
                camera-controls
                camera-orbit="-60deg 22deg 1.2m"
                reveal="interaction"
                shadow-intensity="1"
                exposure="0.8">
    <div slot="poster" class="v3d-poster-hint">Selecciona una pieza de la grilla</div>
    <div class="v3d-fallback">Tu navegador no soporta WebGL o no puede cargar model-viewer.</div>
  </model-viewer>
  <div id="pieza-caption" class="v3d-caption">Ninguna pieza seleccionada</div>
</div>

--8<-- "cad/vista3d_piezas.md"

<script>
(function() {{
  const visorConjunto = document.getElementById('visor-conjunto');
  const btnArmado = document.getElementById('btn-armado');
  const btnDespiece = document.getElementById('btn-despiece');
  const visorPieza = document.getElementById('visor-pieza');
  const caption = document.getElementById('pieza-caption');

  function setConjunto(mode) {{
    const src = mode === 'armado' ? 'models/conjunto-armado.glb' : 'models/conjunto-despiece.glb';
    visorConjunto.src = src;
    btnArmado.classList.toggle('active', mode === 'armado');
    btnDespiece.classList.toggle('active', mode === 'despiece');
  }}

  btnArmado.addEventListener('click', () => setConjunto('armado'));
  btnDespiece.addEventListener('click', () => setConjunto('despiece'));

  document.getElementById('vista3d-grid').addEventListener('click', function(e) {{
    const thumb = e.target.closest('.v3d-thumb');
    if (!thumb || thumb.classList.contains('v3d-thumb-no3d')) return;
    visorPieza.src = thumb.dataset.src;
    visorPieza.poster = thumb.dataset.poster;
    caption.textContent = thumb.dataset.caption;
    document.querySelectorAll('.v3d-thumb').forEach(b => b.classList.remove('active'));
    thumb.classList.add('active');
  }});
}})();
</script>

<style>
.vista3d-conjunto, .vista3d-pieza {{
  margin: 1rem 0;
}}
.v3d-tabs {{
  display: flex;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}}
.v3d-tab {{
  padding: 0.4rem 0.8rem;
  border: 1px solid #ccc;
  background: #f5f5f5;
  cursor: pointer;
}}
.v3d-tab.active {{
  background: #2e7d32;
  color: #fff;
  border-color: #2e7d32;
}}
model-viewer {{
  width: 100%;
  height: 480px;
  background: #fafafa;
}}
.v3d-poster-hint {{
  position: absolute;
  bottom: 1rem;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(0,0,0,0.6);
  color: #fff;
  padding: 0.3rem 0.6rem;
  border-radius: 4px;
  font-size: 0.85rem;
  pointer-events: none;
}}
.v3d-fallback {{
  padding: 1rem;
  color: #666;
}}
.v3d-caption {{
  text-align: center;
  font-weight: 500;
  margin-top: 0.5rem;
}}
.vista3d-grid {{
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 0.75rem;
  margin-top: 1rem;
}}
.v3d-thumb {{
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 0.5rem;
  border: 1px solid #ddd;
  background: #fff;
  cursor: pointer;
  transition: border-color 0.2s;
}}
.v3d-thumb:hover, .v3d-thumb.active {{
  border-color: #2e7d32;
}}
.v3d-thumb-no3d {{
  cursor: default;
  opacity: 0.7;
  background: #f0f0f0;
}}
.v3d-thumb img {{
  width: 100%;
  height: 120px;
  object-fit: contain;
  background: #fafafa;
}}
.v3d-thumb span {{
  margin-top: 0.4rem;
  font-size: 0.8rem;
  text-align: center;
  line-height: 1.2;
}}
</style>
"""
    path.write_text(md, encoding="utf-8")
    print(f"Escrito {path}")
    return path


def write_manifest_glb(pieces: list[dict], conjunto: dict) -> Path:
    path = MODELS_DIR / "manifiesto_glb.json"
    data = {
        "piezas": pieces,
        "conjunto": conjunto,
        "totales": {
            "piezas_count": len(pieces),
            "conjunto_tri_count": conjunto["armado"]["tri_count"],
            "armado_size_bytes": conjunto["armado"]["size_bytes"],
            "despiece_size_bytes": conjunto["despiece"]["size_bytes"],
        },
    }
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Escrito {path}")
    return path


def main():
    print(f"pymeshlab disponible: {HAS_PYMESHLAB}")
    print("Leyendo inventario...")
    inventory_data, rows = load_inventory()
    print(f"  Filas maestro: {len(rows)}")

    print("\nLeyendo CAD maestro...")
    objects = load_rhino_objects()
    print(f"  Objetos Rhino: {len(objects)}")

    print("Mallando capas una sola vez...")
    cache, stats = build_mesh_cache(objects)
    print(f"  Capas mallables: {len(cache)} / {len(stats)}")

    pieces = export_piece_glbs(cache, objects, rows)
    conjunto = export_conjuntos(cache, objects)

    write_vista3d_piezas_md(pieces)
    # docs/vista-3d.md es contenido AUTORADO a mano (no se regenera aca): model-viewer
    # vendorizado en docs/assets, reveal=auto, camara 68deg, sin hotspots, rutas ../.
    # write_vista3d_md quedo deprecada (su template es viejo) para no pisar la pagina buena.
    write_manifest_glb(pieces, conjunto)

    total_size = sum(p["size_bytes"] for p in pieces)
    total_size += conjunto["armado"]["size_bytes"] + conjunto["despiece"]["size_bytes"]
    print(f"\nTotal GLB generado: {len(pieces)} piezas + 2 conjuntos = {total_size/1024/1024:.2f} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
