#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Utilidades compartidas para el CAD LibreIncu-150."""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Iterable

MODEL_3DM = "Incubadora-Final.3dm"
UNITS = "mm"
NULL_GUID = "00000000-0000-0000-0000-000000000000"

CAMERA = {"elev": 22, "azim": -60}
DPI = 200
BLUE = (0.12, 0.42, 0.72, 1.0)
GHOST = (0.80, 0.80, 0.82, 0.16)
RED = (0.86, 0.16, 0.16, 1.0)
AMBIENT = 0.35
EDGE_MAX_FACES = 6000

COMPONENT_ORDER = [
    "cajon",
    "contrafondo",
    "rotacion",
    "transmision",
    "bandejas",
    "puerta",
    "electrica",
    "tornilleria",
    "visual",
    "otros",
]

COMPONENT_LABELS = {
    "cajon": "Cajon y estructura",
    "contrafondo": "Contrafondo y cerramientos",
    "rotacion": "Mecanismo de rotación (ejes, acoples, rodamientos)",
    "transmision": "Transmision y guiado",
    "bandejas": "Bandejas y bastidor giratorio",
    "puerta": "Puerta",
    "electrica": "Actuadores y electrica",
    "tornilleria": "Tornilleria",
    "visual": "Referencias visuales",
    "otros": "Otros / VER CAD",
}

# Paleta estable para visualizacion 3D (RGBA 0-1 y HEX).
COMPONENT_COLORS = {
    "cajon": (0.90, 0.30, 0.25, 1.0),          # rojo terracota
    "contrafondo": (0.35, 0.55, 0.35, 1.0),    # verde bosque
    "rotacion": (0.95, 0.70, 0.15, 1.0),       # amarillo mostaza
    "transmision": (0.20, 0.50, 0.80, 1.0),    # azul acero
    "bandejas": (0.95, 0.50, 0.20, 1.0),       # naranja
    "puerta": (0.55, 0.25, 0.65, 1.0),         # violeta
    "electrica": (0.20, 0.75, 0.75, 1.0),      # cyan
    "tornilleria": (0.75, 0.35, 0.70, 1.0),    # magenta suave
    "visual": (0.65, 0.65, 0.65, 1.0),         # gris
    "otros": (0.50, 0.50, 0.50, 1.0),          # gris oscuro
}

COMPONENT_COLORS_HEX = {
    k: "#" + "".join(f"{int(c*255):02x}" for c in v[:3])
    for k, v in COMPONENT_COLORS.items()
}


def component_color(component: str) -> tuple[float, float, float, float]:
    return COMPONENT_COLORS.get(component, (0.5, 0.5, 0.5, 1.0))


def component_color_hex(component: str) -> str:
    return COMPONENT_COLORS_HEX.get(component, "#808080")

VISUAL = {"Pelos", "Auxiliar1", "Auxiliar2", "Auxiliar3", "Reguetones", "Letritas"}
ACTUADORES_ELEC = {"Cooler", "BombaStuff"}
PUERTA_ABIERTA = {"U 2219 - Door", "VentilacionDoor", "FRENTE-PC"}
AMBIGUAS_VER_CAD = {"BASE", "ChapaCooler", "GUIA-CREMA", "BoquillaAltaP"}
TORNILLERIA_HINTS = ("tornillo", "tuerca", "arandela")
EXCLUIR_LOCATOR = set(VISUAL)

NAME_HINTS = {
    "Perfil25-25": "Perfil estructural",
    "Chapa 1/8": "Chapa 1/8 pulg.",
    "Chapa-SoporteInferior": "Chapa soporte inferior",
    "Chapa-Paredon": "Chapa paredon",
    "Chapa-Caja": "Chapa caja",
    "ChapaCooler": "Chapa soporte cooler",
    "MDF18mm": "Panel MDF 18 mm",
    "MDF55": "Panel MDF",
    "FRENTE-PC": "Frente policarbonato",
    "U 2219 - Door": "Puerta U 2219",
    "VentilacionDoor": "Ventilacion de puerta",
    "BisagraP": "Bisagra puerta",
    "Tapas": "Tapas",
    "huevera": "Bandeja huevera",
    "BandejasFijas": "Bandeja fija",
    "HombroBandej": "Hombro de bandeja",
    "AcopleBandejaEje": "Acople bandeja-eje",
    "ACOPLE 8 a 5": "Acople 8 a 5",
    "AcoplesPA6": "Acople PA6",
    "Buje-PTFE": "Buje PTFE",
    "PoleaDentada": "Polea dentada",
    "Cremayera": "Cremallera dentada",
    "GUIA-CREMA": "Guia de cremallera",
    "Barra Avance Z": "Barra avance Z",
    "FondoBrazo": "Fondo de brazo",
    "SoporT-AntiVib": "Soporte antivibracion",
    "Rodamiento626": "Rodamiento 626",
    "Rodamiento624": "Rodamiento 624",
    "RodamientoHLM8UU": "Rodamiento lineal HLM8UU",
    "BombaStuff": "Bomba y accesorios",
    "Cooler": "Cooler",
    "BoquillaAltaP": "Boquilla alta",
    "HerrajesTraseros": "Herrajes traseros",
    "SeparadorPAI": "Separador PAI",
}


@dataclass(frozen=True)
class Bounds:
    min: tuple[float, float, float]
    max: tuple[float, float, float]


def build_layer_index(model):
    """Devuelve {layer_index: (ruta_completa, nombre_hoja)}."""
    layers = list(model.Layers)
    by_id = {str(layer.Id): layer for layer in layers}
    out = {}
    for i, layer in enumerate(layers):
        parts = [layer.Name]
        pid = str(layer.ParentLayerId)
        seen = set()
        while pid and pid != NULL_GUID and pid not in seen:
            seen.add(pid)
            parent = by_id.get(pid)
            if parent is None:
                break
            parts.insert(0, parent.Name)
            pid = str(parent.ParentLayerId)
        out[i] = ("::".join(parts), layer.Name)
    return out


def slugify(name: str) -> str:
    s = name.lower().strip().replace(" ", "-").replace("/", "-").replace(":", "-")
    s = re.sub(r"[^a-z0-9_-]+", "", s)
    return s or "pieza"


def component_of(leaf: str) -> str:
    n = leaf.lower()
    if leaf in VISUAL or n.startswith("auxiliar") or "pelo" in n or "letrita" in n or "regueton" in n:
        return "visual"
    if any(k in n for k in TORNILLERIA_HINTS):
        return "tornilleria"
    if leaf in ACTUADORES_ELEC or "cooler" in n or "bomba" in n:
        return "electrica"
    if "door" in n or "bisagra" in n or "tapa" in n or "frente" in n:
        return "puerta"
    if "huevera" in n or "bandeja" in n or "hombro" in n:
        return "bandejas"
    if "crema" in n or "barra avance" in n or "polea" in n:
        return "transmision"
    if any(k in n for k in ("acople", "buje", "rodamiento", "brazo", "antivib")):
        return "rotacion"
    if leaf in {"Chapa-Paredon", "Chapa-SoporteInferior", "ChapaCooler", "MDF18mm", "MDF55", "Chapa 1/8"}:
        return "contrafondo"
    if leaf in {"Perfil25-25", "Chapa-Caja"}:
        return "cajon"
    return "otros"


def component_label(component: str) -> str:
    return COMPONENT_LABELS.get(component, component)


def component_rank(component: str) -> int:
    try:
        return COMPONENT_ORDER.index(component)
    except ValueError:
        return len(COMPONENT_ORDER)


def material_of(leaf: str) -> str:
    n = leaf.lower()
    if "perfil25" in n:
        return "Perfil plegado en L 25x25 / 30x30 segun CAD"
    if "chapa 1/8" in n:
        return "Chapa 1/8 pulg. (~3.2 mm)"
    if n.startswith("chapa"):
        return "Chapa metalica plegada"
    if "mdf18" in n:
        return "Tablero MDF 18 mm"
    if "mdf55" in n:
        return "Tablero MDF"
    if "ptfe" in n or "buje" in n:
        return "PTFE"
    if "pa6" in n or ("acople" in n and "8 a 5" not in n):
        return "Nylon PA6"
    if "rodamiento626" in n:
        return "Rodamiento 626 - 6x19x6 mm"
    if "rodamiento624" in n:
        return "Rodamiento 624 - 4x13x5 mm"
    if "hlm8uu" in n:
        return "Rodamiento lineal HLM8UU"
    if "rodamiento" in n:
        return "Rodamiento comercial"
    if any(k in n for k in TORNILLERIA_HINTS):
        return "Fijacion comercial"
    if "cooler" in n:
        return "Ventilador / cooler comercial"
    if "bomba" in n:
        return "Bomba comercial"
    return ""


def fabricacion_of(component: str, leaf: str) -> str:
    n = leaf.lower()
    if component in {"tornilleria", "electrica"} or "rodamiento" in n:
        return "comprar"
    if component == "visual":
        return "referencia visual"
    if "perfil" in n:
        return "cortar"
    if "chapa" in n:
        return "cortar + plegar (VER CAD)"
    if "mdf" in n or "frente" in n:
        return "cortar tablero (VER CAD)"
    if any(k in n for k in ("ptfe", "pa6", "buje", "acople", "polea", "crema", "brazo", "boquilla")):
        return "mecanizar / imprimir (VER CAD)"
    return "VER CAD"


def name_of(leaf: str, size_sig_value: str | None = None) -> str:
    base = NAME_HINTS.get(leaf, leaf)
    if size_sig_value and size_sig_value != "BLOQUE":
        return f"{base} {size_sig_value}"
    return base


def sorted_dims_from_bbox(bb) -> list[float] | None:
    dims = sorted([
        round(float(bb.Max.X - bb.Min.X), 1),
        round(float(bb.Max.Y - bb.Min.Y), 1),
        round(float(bb.Max.Z - bb.Min.Z), 1),
    ])
    if dims[-1] <= 0:
        return None
    return dims


def sorted_dims(bounds: Bounds) -> list[float]:
    return sorted(round(bounds.max[i] - bounds.min[i], 1) for i in range(3))


def size_sig(dims: Iterable[float] | None) -> str:
    if dims is None:
        return "BLOQUE"
    return "x".join(f"{float(v):.0f}" for v in dims)


def bbox_to_bounds(bb) -> Bounds:
    return Bounds(
        (float(bb.Min.X), float(bb.Min.Y), float(bb.Min.Z)),
        (float(bb.Max.X), float(bb.Max.Y), float(bb.Max.Z)),
    )


def merge_bounds(bounds: Iterable[Bounds]) -> Bounds | None:
    items = list(bounds)
    if not items:
        return None
    mins = tuple(min(b.min[i] for b in items) for i in range(3))
    maxs = tuple(max(b.max[i] for b in items) for i in range(3))
    return Bounds(mins, maxs)


def bounds_dims(bounds: Bounds | None) -> list[float] | None:
    if bounds is None:
        return None
    return [round(bounds.max[i] - bounds.min[i], 1) for i in range(3)]


def reconcile_envelope(objects: Iterable[dict]) -> dict:
    items = list(objects)
    total = merge_bounds(o["bounds"] for o in items if o.get("bounds") is not None)
    body = merge_bounds(
        o["bounds"]
        for o in items
        if o.get("bounds") is not None and o.get("leaf") not in PUERTA_ABIERTA
    )
    return {
        "body": bounds_dims(body),
        "total": bounds_dims(total),
        "body_note": "Sin puerta abierta, VentilacionDoor ni FRENTE-PC",
        "total_note": "AABB completo del CAD",
    }


def is_tornilleria(leaf: str) -> bool:
    n = leaf.lower()
    return any(k in n for k in TORNILLERIA_HINTS)


def include_in_locator_context(leaf: str) -> bool:
    return leaf not in EXCLUIR_LOCATOR and not is_tornilleria(leaf)
