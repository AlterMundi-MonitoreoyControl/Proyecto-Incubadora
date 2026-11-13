#!/usr/bin/env python3
"""
Genera el PDF del manual LibreIncu-150 desde los archivos Markdown de docs/.

Uso:
    .venv-render/bin/python docs/build_doc.py

Salida:
    docs/manual_libreincu_150.pdf

Requisitos:
    - markdown
    - pymdown-extensions
    - pyyaml
    - pillow
    - libreoffice (headless)
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml


def check_deps():
    try:
        import markdown  # noqa: F401
    except ImportError:
        sys.exit("Falta: pip install markdown")
    try:
        import pymdownx  # noqa: F401
    except ImportError:
        sys.exit("Falta: pip install pymdown-extensions")
    try:
        import yaml  # noqa: F401
    except ImportError:
        sys.exit("Falta: pip install pyyaml")
    try:
        import PIL  # noqa: F401
    except ImportError:
        sys.exit("Falta: pip install pillow")
    if not shutil.which("libreoffice"):
        sys.exit(
            "Falta LibreOffice. Instalar con:\n"
            "  Linux:  sudo apt install libreoffice\n"
            "  macOS:  brew install --cask libreoffice\n"
            "  Windows: https://www.libreoffice.org/download/"
        )


REPO = Path(__file__).resolve().parent.parent
DOCS_DIR = REPO / "docs"
MKDOCS_YML = REPO / "mkdocs.yml"

# Páginas que no tienen sentido en PDF (interactivas/web-only o demasiado extensas).
EXCLUDED_PAGES = {"vista-3d.md", "inventario.md"}

CSS = """
<style>
  @page { margin: 2.5cm 2.5cm 3cm 2.5cm; }
  body {
    font-family: 'Liberation Serif', Georgia, serif;
    font-size: 11pt;
    line-height: 1.6;
    color: #111;
  }
  h1 { font-size: 16pt; border-bottom: 2px solid #333; padding-bottom: 6px; margin-top: 40px; }
  h2 { font-size: 13pt; color: #222; margin-top: 30px; }
  h3 { font-size: 11pt; font-style: italic; margin-top: 20px; }
  h1, h2, h3, h4 { page-break-after: avoid; }
  table { border-collapse: collapse; width: 100%; margin: 16px 0; font-size: 10pt; }
  table, tr { page-break-inside: avoid; }
  th { background: #e8e8e8; border: 1px solid #999; padding: 6px 10px; text-align: left; }
  td { border: 1px solid #bbb; padding: 5px 10px; vertical-align: top; }
  tr:nth-child(even) td { background: #f7f7f7; }
  hr { border: none; border-top: 1px solid #ccc; margin: 24px 0; }
  code, pre {
    font-family: 'Liberation Mono', monospace;
    background: #f4f4f4;
    padding: 2px 5px;
    border-radius: 3px;
    font-size: 9.5pt;
  }
  pre { padding: 10px; overflow-x: auto; }
  img {
    max-width: 100%;
    height: auto;
    display: block;
    margin: 0.8em auto;
  }
  .admonition {
    border: 1px solid #999;
    border-left: 4px solid #2e7d32;
    background: #f9f9f9;
    padding: 10px 14px;
    margin: 16px 0;
  }
  .admonition-title {
    font-weight: bold;
    margin-bottom: 6px;
  }
  .admonition.danger { border-left-color: #c62828; background: #ffebee; }
  .admonition.warning { border-left-color: #f9a825; background: #fffde7; }
  .admonition.info { border-left-color: #1565c0; background: #e3f2fd; }
  .admonition.tip { border-left-color: #2e7d32; background: #e8f5e9; }
  ul.task-list { list-style: none; padding-left: 1.2em; }
  .task-list-item { margin: 4px 0; }
  .task-list-item input[type="checkbox"] {
    margin-right: 0.5em;
    vertical-align: middle;
  }
  .page-break { page-break-after: always; }
</style>
"""


def nav_files_from_mkdocs() -> list[Path]:
    """Devuelve los .md del nav de mkdocs.yml en orden, excluyendo páginas web-only."""
    if not MKDOCS_YML.exists():
        sys.exit(f"No se encontró {MKDOCS_YML}")
    config = yaml.safe_load(MKDOCS_YML.read_text(encoding="utf-8"))
    nav = config.get("nav", [])
    files: list[Path] = []

    def collect(item):
        if isinstance(item, dict):
            for value in item.values():
                if isinstance(value, str):
                    if value.endswith(".md") and value not in EXCLUDED_PAGES:
                        path = DOCS_DIR / value
                        if path.exists():
                            files.append(path)
                        else:
                            print(f"Advertencia: no existe {path}", file=sys.stderr)
                elif isinstance(value, list):
                    for sub in value:
                        collect(sub)
        elif isinstance(item, list):
            for sub in item:
                collect(sub)

    for entry in nav:
        collect(entry)
    return files


ADMONITION_COLORS = {
    "danger": ("#c62828", "#ffebee"),
    "warning": ("#f9a825", "#fffde7"),
    "info": ("#1565c0", "#e3f2fd"),
    "tip": ("#2e7d32", "#e8f5e9"),
}


def postprocess_html(body: str) -> str:
    """Adapta admonitions, checkboxes e imágenes para LibreOffice."""
    import re

    # --- Admonitions: convertir <div class="admonition kind"> en tablas con borde/fondo ---
    def admonition_repl(match: re.Match) -> str:
        classes = match.group(1)
        inner = match.group(2)
        # Detectar clase semántica
        kind = "info"
        for k in ADMONITION_COLORS:
            if k in classes:
                kind = k
                break
        border_color, bg_color = ADMONITION_COLORS[kind]
        # Extraer título
        title_match = re.search(r'<p class="admonition-title">(.*?)</p>', inner)
        if title_match:
            title = title_match.group(1)
            inner = re.sub(r'<p class="admonition-title">.*?</p>', '', inner, count=1).strip()
            header = f'<p><strong>{title}</strong></p>'
        else:
            header = ''
        return (
            f'<table width="100%" cellpadding="10" cellspacing="0" '
            f'style="border-left: 4px solid {border_color}; background-color: {bg_color}; margin: 16px 0;">\n'
            f'<tr><td>\n{header}\n{inner}\n</td></tr>\n</table>'
        )

    body = re.sub(
        r'<div class="admonition ([^"]+)">(.*?)<\/div>',
        admonition_repl,
        body,
        flags=re.DOTALL,
    )

    # --- Checkboxes de pymdownx.tasklist: reemplazar inputs por caracteres Unicode ---
    body = re.sub(
        r'<input[^>]*type="checkbox"[^>]*checked[^>]*>',
        '☑ ',
        body,
    )
    body = re.sub(
        r'<input[^>]*type="checkbox"[^>]*>',
        '☐ ',
        body,
    )

    # --- Imágenes: forzar ancho máximo efectivo y centrado para LibreOffice ---
    def img_style_repl(match: re.Match) -> str:
        tag = match.group(0)
        # LibreOffice requiere dimensiones explícitas para conservar la proporción.
        src = re.search(r'\bsrc="([^"]+)"', tag)
        image_path = DOCS_DIR / src.group(1) if src else None
        if image_path is not None and image_path.is_file():
            from PIL import Image

            with Image.open(image_path) as img:
                width, height = img.size
            scale = min(600 / width, 500 / height, 1)
            width, height = round(width * scale), round(height * scale)
            tag = re.sub(r'\s+(?:width|height|style)="[^"]*"', '', tag)
            return tag.replace('<img', f'<img width="{width}" height="{height}"', 1)
        # Quitar atributos width/height para que el CSS controle la escala.
        tag = re.sub(r'\s+width="[^"]*"', '', tag)
        tag = re.sub(r'\s+height="[^"]*"', '', tag)
        # Agregar estilo inline de escala y centrado.
        style = 'max-width: 16cm; width: 100%; height: auto; display: block; margin: 0.8em auto;'
        if 'style="' in tag:
            tag = tag.replace('style="', f'style="{style} ')
        else:
            tag = tag.replace('/>', f' style="{style}"/>')
        return tag

    body = re.sub(r'<img[^>]+>', img_style_repl, body)

    # Mantener cada imagen junto a su pie en el documento imprimible.
    body = re.sub(
        r'<p>(<img[^>]+>)</p>\s*<p>(<em>.*?</em>)</p>',
        r'<p style="page-break-inside: avoid;">\1<br>\2</p>',
        body,
        flags=re.DOTALL,
    )

    return body


def strip_inventory_snippets(text: str) -> str:
    """Elimina snippets de mini-BOMs/inventario para la versión PDF reducida."""
    lines = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith('--8<-- "cad/resumen_componentes.md"'):
            continue
        if stripped.startswith('--8<-- "cad/componentes/'):
            continue
        lines.append(line)
    return "\n".join(lines)


def build_html(files: list[Path], title: str, page_breaks: bool, exclude_inventory: bool = False) -> str:
    import markdown

    md = markdown.Markdown(
        extensions=[
            "tables",
            "fenced_code",
            "sane_lists",
            "attr_list",
            "md_in_html",
            "admonition",
            "pymdownx.snippets",
            "pymdownx.superfences",
            "pymdownx.tasklist",
        ],
        extension_configs={
            "pymdownx.snippets": {
                "base_path": [str(REPO), str(REPO / "Rediseno")],
                "check_paths": True,
            },
        },
    )
    parts = []
    for i, path in enumerate(files):
        md.reset()
        raw = path.read_text(encoding="utf-8")
        # Front matter de MkDocs (íconos de la navegación): no va al PDF.
        raw = re.sub(r"\A---\n.*?\n---\n", "", raw, flags=re.S)
        if exclude_inventory:
            raw = strip_inventory_snippets(raw)
        body = md.convert(raw)
        body = postprocess_html(body)
        if page_breaks and i < len(files) - 1:
            body += '\n<div class="page-break"></div>\n'
        parts.append(body)

    return (
        f'<!DOCTYPE html>\n<html lang="es">\n<head>\n'
        f'  <meta charset="UTF-8">\n  <title>{title}</title>\n'
        f'  {CSS}\n</head>\n<body>\n'
        + "\n".join(parts)
        + "\n</body>\n</html>\n"
    )


def lo_convert(src: Path, fmt: str) -> Path:
    """Convierte src al formato dado usando LibreOffice; devuelve el archivo resultante."""
    tmp = Path(tempfile.mkdtemp())
    r = subprocess.run(
        ["libreoffice", "--headless", "--convert-to", fmt, "--outdir", str(tmp), str(src)],
        capture_output=True, text=True,
    )
    out = tmp / src.with_suffix(f".{fmt}").name
    if r.returncode != 0 or not out.exists():
        sys.exit(f"LibreOffice falló al convertir a {fmt}:\n{r.stderr or '(sin mensajes)'}")
    return out


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "files", nargs="*", type=Path,
        help="Archivos .md a combinar (en orden). Si se omite, usa el nav de mkdocs.yml.",
    )
    parser.add_argument("--output", "-o", default="manual_libreincu_150", help="Nombre base de salida")
    parser.add_argument(
        "--outdir", type=Path, default=DOCS_DIR,
        help="Directorio de salida (default: docs/)",
    )
    parser.add_argument(
        "--formats", nargs="+", default=["pdf"],
        choices=["pdf", "docx", "html"],
        metavar="FMT",
        help="Formatos a generar: pdf docx html (default: pdf)",
    )
    parser.add_argument("--title", default="Manual de fabricación y montaje - LibreIncu 150 v3", help="Título del documento")
    parser.add_argument(
        "--no-break", dest="page_breaks", action="store_false",
        help="No insertar saltos de página entre archivos",
    )
    args = parser.parse_args()

    check_deps()

    if args.files:
        files = [p.resolve() for p in args.files]
        missing = [f for f in files if not f.exists()]
        if missing:
            sys.exit("Archivos no encontrados:\n" + "\n".join(str(m) for m in missing))
    else:
        files = nav_files_from_mkdocs()
        if not files:
            sys.exit("No se encontraron archivos .md en el nav de mkdocs.yml")
        print(f"Usando {len(files)} archivos .md del nav.")

    outdir = args.outdir.resolve()
    outdir.mkdir(parents=True, exist_ok=True)

    stem = args.output
    title = args.title

    html_path = outdir / f"{stem}.html"

    if "html" in args.formats:
        html_content = build_html(files, title, args.page_breaks, exclude_inventory=False)
        html_path.write_text(html_content, encoding="utf-8")
        print(f"OK  {html_path}")

    if "pdf" in args.formats or "docx" in args.formats:
        # Versión reducida para documentos: sin tablas de inventario embebidas.
        pdf_html_content = build_html(files, title, args.page_breaks, exclude_inventory=True)
        tmp_dir = Path(tempfile.mkdtemp())
        tmp_html = tmp_dir / f"{stem}.html"
        tmp_html.write_text(pdf_html_content, encoding="utf-8")
        # Copiar imágenes para que las rutas relativas de docs/ sigan funcionando.
        src_img = DOCS_DIR / "img"
        if src_img.exists():
            shutil.copytree(src_img, tmp_dir / "img", dirs_exist_ok=True)

    if "pdf" in args.formats:
        src = lo_convert(tmp_html, "pdf")
        dest = outdir / f"{stem}.pdf"
        shutil.copy2(src, dest)
        print(f"OK  {dest}")

    if "docx" in args.formats:
        odt = lo_convert(tmp_html, "odt")
        docx = lo_convert(odt, "docx")
        dest = outdir / f"{stem}.docx"
        shutil.copy2(docx, dest)
        print(f"OK  {dest}")


if __name__ == "__main__":
    main()
