"""Dibuja los desarrollos de chapa de docs/cad/*.dxf como PNG acotados para el manual.

Uso: python scripts/render_desarrollos.py   (requiere matplotlib; no usa FreeCAD)

La geometría sale de los DXF publicados. Las cotas, los ángulos de plegado y la
zona de torsión del carro repiten las constantes de los generadores del diseño
(LibreIncu_Rediseno_Despiece.py y fuente_calor.py); si cambian allá, cambiarlas acá.
"""
import math
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Arc, Circle, Rectangle

REPO = Path(__file__).resolve().parent.parent
CAD = REPO / 'docs' / 'cad'
OUT = REPO / 'docs' / 'img' / 'cad'
CUT, FOLD, REF, DIM = '#1b1b1b', '#1f6fb2', '#9a9a9a', '#444444'


def entities(path):
    """Entidades LINE, ARC, CIRCLE y TEXT de un DXF ASCII simple."""
    text = path.read_text().split('\n')
    pairs = [(text[i].strip(), text[i + 1].rstrip('\r')) for i in range(0, len(text) - 1, 2)]
    section, current, out = None, None, []
    for code, value in pairs:
        if code == '0':
            if current:
                out.append(current)
            current = {'type': value} if section == 'ENTITIES' and value != 'ENDSEC' else None
            if value == 'SECTION':
                section = '?'
        elif code == '2' and section == '?':
            section = value
        elif current is not None:
            current.setdefault(code, []).append(value)
    return out


def draw(ax, path, skip_layers=('NOTAS',)):
    for e in entities(path):
        layer = e.get('8', [''])[0]
        if layer in skip_layers or e['type'] == 'TEXT':
            continue
        color, style = {'PLEGADO': (FOLD, '--'), 'REFERENCIA': (REF, ':')}.get(layer, (CUT, '-'))
        g = lambda k: float(e[k][0])
        if e['type'] == 'LINE':
            ax.plot([g('10'), g('11')], [g('20'), g('21')], color=color, ls=style, lw=1.1)
        elif e['type'] == 'CIRCLE':
            ax.add_patch(Circle((g('10'), g('20')), g('40'), fill=False, color=color, lw=1.1))
        elif e['type'] == 'ARC':
            ax.add_patch(Arc((g('10'), g('20')), 2 * g('40'), 2 * g('40'),
                             theta1=g('50'), theta2=g('51'), color=color, lw=1.1))


def dim(ax, p1, p2, offset, label, fs=9):
    """Cota entre p1 y p2, desplazada `offset` en la normal (izquierda del sentido p1→p2)."""
    (x1, y1), (x2, y2) = p1, p2
    length = math.hypot(x2 - x1, y2 - y1)
    nx, ny = -(y2 - y1) / length, (x2 - x1) / length
    a = (x1 + nx * offset, y1 + ny * offset)
    b = (x2 + nx * offset, y2 + ny * offset)
    for (px, py), (qx, qy) in ((p1, a), (p2, b)):
        ax.plot([px, qx + nx * 0.15 * abs(offset) / max(abs(offset), 1)], [py, qy], color=DIM, lw=0.5)
    ax.annotate('', a, b, arrowprops=dict(arrowstyle='<->', color=DIM, lw=0.7, shrinkA=0, shrinkB=0))
    angle = math.degrees(math.atan2(y2 - y1, x2 - x1))
    if angle > 90 or angle <= -90:
        angle -= 180
    ax.text((a[0] + b[0]) / 2 + nx * 0.6 * fs / 9 * 3, (a[1] + b[1]) / 2 + ny * 0.6 * fs / 9 * 3, label,
            ha='center', va='center', rotation=angle, fontsize=fs, color=DIM,
            bbox=dict(facecolor='white', edgecolor='none', pad=0.6))


def finish(fig, ax, name, title, notes):
    ax.set_aspect('equal')
    ax.axis('off')
    ax.set_title(title, fontsize=11, loc='left', color=CUT)
    fig.text(0.02, 0.02, notes, fontsize=8.5, color=DIM, va='bottom', ha='left')
    fig.savefig(OUT / name, dpi=170, bbox_inches='tight', facecolor='white')
    plt.close(fig)


def deflector():
    width, tab, segments = 500.0, 15.0, (115.0, 60.0, 50.0)
    length = sum(segments)
    fig, ax = plt.subplots(figsize=(8.5, 5.2))
    draw(ax, CAD / 'Deflector_Aire.dxf')
    dim(ax, (0, 0), (width, 0), -22, '500')
    dim(ax, (tab, length), (width - tab, length), 18, '470 útil')
    dim(ax, (0, length), (tab, length), 18, '15', fs=8)
    dim(ax, (width - tab, length), (width, length), 18, '15', fs=8)
    y = 0.0
    for seg in segments:
        dim(ax, (width, y), (width, y + seg), -22, '%g' % seg)
        y += seg
    dim(ax, (0, 0), (0, length), 22, '225')
    for y, label in ((115, 'pliegue 50°'), (175, 'pliegue 20°')):
        ax.text(width / 2, y + 5, label, ha='center', va='bottom', fontsize=9, color=FOLD)
    ax.text(tab / 2, length / 2, 'lengüeta', rotation=90, ha='center', va='center', fontsize=7.5, color=FOLD)
    ax.text(width - tab / 2, length / 2, 'lengüeta', rotation=90, ha='center', va='center', fontsize=7.5, color=FOLD)
    finish(fig, ax, 'desarrollo-deflector.png', 'Deflector: desarrollo (aluminio 0,5 mm)',
           'Pliegues de 50° y 20° en el mismo sentido. Lengüetas de 15 mm plegadas hacia arriba; '
           'cortar en V sobre las líneas de pliegue.\nCotas en mm, desarrollo nominal sin compensar el radio de plegado.')


def contraplaca():
    half_l, half_w, fold = 120.0, 78.35, 57.87
    fig, ax = plt.subplots(figsize=(7.5, 5.4))
    draw(ax, CAD / 'contraplaca_desarrollo.dxf')
    dim(ax, (-half_l, -half_w), (half_l, -half_w), -14, '240')
    dim(ax, (half_l, -half_w), (half_l, half_w), -16, '156,7')
    dim(ax, (-half_l, half_w), (-half_l, fold), -14, '20,5', fs=8)
    dim(ax, (-half_l, fold), (-half_l, -fold), -14, '115,7')
    dim(ax, (-half_l, -fold), (-half_l, -half_w), -14, '20,5', fs=8)
    for y in (fold, -fold):
        ax.text(half_l - 4, y + (3 if y > 0 else -3), 'plegado 83° hacia arriba', ha='right',
                va='bottom' if y > 0 else 'top', fontsize=8.5, color=FOLD)
    ax.text(0, 0, 'resistencia 180 × 65\n(referencia)', ha='center', va='center', fontsize=8, color=REF)
    finish(fig, ax, 'desarrollo-contraplaca.png', 'Contraplaca de la resistencia: desarrollo (acero 1,5 mm)',
           'Los dos plegados van hacia el mismo lado; las pestañas siguen la pared de la budinera y se remachan a ella.\n'
           'Radio interior 1,5 mm y K = 0,4: ajustar a la plegadora. Cotas en mm.')


def carro():
    neck_x, twist, ear_x, ear_y = (57.1, 68.0), (17.0, 31.0), 68.0, 45.0
    fig, ax = plt.subplots(figsize=(6.2, 7.6))
    draw(ax, CAD / 'carro_portatuercas_corredera-Body.dxf')
    for s in (1, -1):
        y0, y1 = sorted((s * twist[0], s * twist[1]))
        ax.add_patch(Rectangle((neck_x[0], y0), neck_x[1] - neck_x[0], y1 - y0, facecolor=FOLD,
                               alpha=0.18, edgecolor='none', hatch='///'))
        ax.plot([neck_x[0] - 2, neck_x[1] + 9], [s * twist[1]] * 2, color=FOLD, ls='--', lw=1.1)
        ax.text(neck_x[0] - 3, s * (twist[0] + twist[1]) / 2, 'torsión 90°', ha='right', va='center',
                fontsize=8.5, color=FOLD)
        ax.text(neck_x[1] + 10, s * twist[1], 'plegado 90°\nhacia el fondo', ha='left', va='center',
                fontsize=8, color=FOLD)
    dim(ax, (ear_x, -ear_y), (ear_x, ear_y), -26, '90 entre ejes de tuerca')
    dim(ax, (0, -4), (53, -4), -14, 'recorrido del perno 53', fs=8)
    finish(fig, ax, 'desarrollo-carro.png', 'Carro: desarrollo (acero 3,2 mm)',
           'Zona de torsión y plegado según el modelo 3D (largo de torsión 14 mm). '
           'Agujeros Ø10,5 para la tuerca antijuego\ny 4 agujeros Ø3 para los tornillos de 2,9 mm de su brida en cada oreja. Cotas en mm.')


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    deflector()
    contraplaca()
    carro()
    print('Desarrollos en', OUT)
