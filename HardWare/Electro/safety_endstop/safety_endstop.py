#!/usr/bin/env python3
"""Esquemas del final de carrera de seguridad para el motor de volteo.

Agrega DOS finales de carrera (NC, normalmente cerrados) en serie con las
entradas logicas IN1 e IN2 del puente H, en paralelo a los reed switches que
ya usa el firmware (GPIO35 / GPIO34). Es un enclavamiento por HARDWARE: corta
la marcha aunque el firmware o el reed fallen (sobre-recorrido).

Comportamiento DIRECCIONAL:
  - FC-SUP (tope superior) corta IN1 (subir) y deja libre IN2 (bajar).
  - FC-INF (tope inferior) corta IN2 (bajar) y deja libre IN1 (subir).
  => al pisar un tope el motor NO avanza en esa direccion pero puede revertir
     para salir del fin de carrera.

Genera SVG con schemkit (repo vecino). Correr con el venv de schemkit:
    /home/pablo/repos/schemkit/.venv/bin/python safety_endstop.py
"""

import os
import sys

# schemkit (repo vecino) — agregar su raiz por si no esta instalado en el venv
sys.path.insert(0, '/home/pablo/repos/schemkit')

import schemdraw
import schemdraw.elements as elm
from schemdraw import flow

from schemkit import (
    CONFIG, add_title, add_footer,
    C_GPIO, C_VCC, C_GND, C_WARN, C_ADC, NOTE_COLOR,
)

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'schematics')
os.makedirs(OUT, exist_ok=True)


# ---------------------------------------------------------------------------
# 1. Enclavamiento de seguridad: corte direccional de IN1 / IN2
# ---------------------------------------------------------------------------
def draw_safety_interlock():
    with schemdraw.Drawing(file=os.path.join(OUT, 'sch_safety_endstop.svg'),
                           show=False) as d:
        d.config(**CONFIG)

        # === ESP32 — 3 salidas hacia el puente H ===
        esp = d.add(elm.Ic(
            pins=[
                elm.IcPin(name='IN_A_N', anchorname='IN1', side='right', slot='3/3'),
                elm.IcPin(name='IN_A_P', anchorname='IN2', side='right', slot='2/3'),
                elm.IcPin(name='EN_A',   anchorname='EN',  side='right', slot='1/3'),
            ],
            edgepadW=2.8, edgepadH=1.2, pinspacing=3.4, lsize=11,
        ).label('Motor_A / J9\n(placa Olivia)', loc='center', fontsize=10))

        # GPIO de origen (en el ESP32) que sale por cada pin del conector Motor_A
        d.add(elm.Label().at((esp.IN1[0] - 0.3, esp.IN1[1] + 0.55))
              .label('pin2 · GPIO2', fontsize=7, color=NOTE_COLOR, halign='right'))
        d.add(elm.Label().at((esp.IN2[0] - 0.3, esp.IN2[1] + 0.55))
              .label('pin3 · GPIO15', fontsize=7, color=NOTE_COLOR, halign='right'))
        d.add(elm.Label().at((esp.EN[0] - 0.3, esp.EN[1] + 0.55))
              .label('pin4 · EN_A', fontsize=7, color=NOTE_COLOR, halign='right'))

        # === Puente H — alineado pin a pin con el ESP32 ===
        GAP = 11
        hb = d.add(elm.Ic(
            pins=[
                elm.IcPin(name='IN1',  anchorname='HIN1', side='left',  slot='3/3'),
                elm.IcPin(name='IN2',  anchorname='HIN2', side='left',  slot='2/3'),
                elm.IcPin(name='EN',   anchorname='HEN',  side='left',  slot='1/3'),
                elm.IcPin(name='OUT1', anchorname='OUT1', side='right', slot='2/2'),
                elm.IcPin(name='OUT2', anchorname='OUT2', side='right', slot='1/2'),
            ],
            edgepadW=1.2, edgepadH=1.2, pinspacing=3.4, lsize=11,
        ).at((esp.IN1[0] + GAP, esp.IN1[1])).anchor('HIN1')
         .label('Puente H\n(modulo)', loc='center', fontsize=10))

        # --- Helper: tramo IN con final de carrera NC + pull-down ---
        def in_line_with_endstop(esp_pin, hb_pin, fc_label, in_label):
            seg = 2.8          # tramo ESP -> switch
            sw_len = 1.9       # largo del switch
            # tramo desde el pin del ESP
            d.add(elm.Line().at(esp_pin).right(seg).color(C_GPIO)
                  .label(in_label, loc='top', fontsize=8))
            # final de carrera NC (normalmente cerrado) en serie
            sw = d.add(elm.Switch(nc=True).right().length(sw_len).color(C_WARN)
                       .label(fc_label, loc='top', fontsize=8, color=C_WARN))
            node = sw.end
            d.add(elm.Dot().at(node))
            # continua hasta la entrada del puente H
            d.add(elm.Line().at(node).tox(hb_pin[0]).color(C_GPIO))
            # pull-down 10k: deja la entrada en 0 (motor parado) si el FC abre.
            # Cae dentro del hueco bajo su propia linea (no cruza las demas).
            d.add(elm.Resistor().at(node).down(1.6)
                  .label('10k', loc='right', fontsize=8))
            d.add(elm.Ground())
            return node

        # IN1 = IN_A_N (J9 pin2, subir): cortado por el tope SUPERIOR
        in_line_with_endstop(esp.IN1, hb.HIN1, 'FC-SUP (NC)', 'IN_A_N  subir')
        # IN2 = IN_A_P (J9 pin3, bajar): cortado por el tope INFERIOR
        in_line_with_endstop(esp.IN2, hb.HIN2, 'FC-INF (NC)', 'IN_A_P  bajar')

        # EN — directo (sin corte; el corte va solo en IN1/IN2)
        d.add(elm.Line().at(esp.EN).to(hb.HEN).color(C_GPIO)
              .label('EN  habilita', loc='bottom', fontsize=8))

        # === Motor de volteo en OUT1/OUT2 ===
        mx = hb.OUT1[0] + 3.0
        d.add(elm.Line().at(hb.OUT1).right(3.0).color(C_VCC))
        d.add(elm.Line().at(hb.OUT2).right(3.0).color(C_GND))
        d.add(elm.Motor().at((mx, hb.OUT1[1])).down().toy(hb.OUT2[1])
              .label('M\nvolteo', loc='right', fontsize=9))

        add_footer(
            d,
            'Finales de carrera NORMALMENTE CERRADOS (NC) en serie con IN1/IN2  +  pull-down 10k a GND.\n'
            'En reposo el FC esta cerrado -> la senal de control (conector Motor_A) llega al puente H. Al pisar el tope\n'
            '(o si se corta el cable) el FC abre -> el pull-down fuerza esa entrada a 0 -> el puente H deja de empujar.\n'
            'DIRECCIONAL: FC-SUP corta IN1 (subir) y FC-INF corta IN2 (bajar); la direccion opuesta sigue libre para revertir.\n'
            'Es independiente del firmware: actua aunque el reed o el ESP32 fallen. EN_A (J9 pin4) no se corta.')
        add_title(d, 'Final de carrera de seguridad — corte direccional de IN1/IN2')

    print('  OK sch_safety_endstop.svg')


# ---------------------------------------------------------------------------
# 2. Contexto: reed switches (sensado por firmware) vs FC (corte por HW)
# ---------------------------------------------------------------------------
def draw_context():
    with schemdraw.Drawing(file=os.path.join(OUT, 'sch_reeds_vs_endstop.svg'),
                           show=False) as d:
        d.config(**CONFIG)

        # Eje de recorrido vertical
        x_axis = 0
        y_top, y_bot = 3.3, -3.3
        d.add(elm.Line().at((x_axis, y_top)).to((x_axis, y_bot)).color(NOTE_COLOR))
        d.add(elm.Label().at((x_axis, y_top + 0.5)).label('SUBIR', fontsize=9,
              color=NOTE_COLOR, halign='center'))
        d.add(elm.Label().at((x_axis, y_bot - 0.5)).label('BAJAR', fontsize=9,
              color=NOTE_COLOR, halign='center'))

        def stop_pair(y, reed_txt, reed_color, fc_txt, cut_txt):
            d.add(elm.Dot().at((x_axis, y)))
            # Reed (sensor, firmware) a la izquierda
            d.add(elm.Line().at((x_axis, y)).left(1.8).color(reed_color))
            d.add(elm.SwitchReed().left().length(1.8).color(reed_color)
                  .label(reed_txt, loc='top', fontsize=8, color=reed_color))
            d.add(elm.Label().at((x_axis - 5.7, y - 0.05))
                  .label('LEE GPIO\n(sensa)', fontsize=7,
                         color=NOTE_COLOR, halign='center'))
            # Final de carrera (corte HW) a la derecha
            d.add(elm.Line().at((x_axis, y)).right(1.8).color(C_WARN))
            d.add(elm.Switch(nc=True).right().length(1.8).color(C_WARN)
                  .label(fc_txt, loc='top', fontsize=8, color=C_WARN))
            d.add(elm.Label().at((x_axis + 5.6, y - 0.05))
                  .label(cut_txt, fontsize=7, color=C_WARN, halign='center'))

        stop_pair(2.0, 'Reed UP\nGPIO35', C_ADC,
                  'FC-SUP (NC)', 'CORTA IN1\n(subir)')
        stop_pair(-2.0, 'Reed DOWN\nGPIO34', C_ADC,
                  'FC-INF (NC)', 'CORTA IN2\n(bajar)')

        add_footer(
            d,
            'reed (izq.): el firmware lo LEE para frenar en el punto normal.\n'
            'FC de seguridad (der.): apenas mas alla, CORTA IN1/IN2 por hardware.\n'
            'Si el reed o el firmware fallan, el FC frena igual el motor.')
        add_title(d, 'Dos capas por extremo: reed (sensa) + FC (corta)')

    print('  OK sch_reeds_vs_endstop.svg')


if __name__ == '__main__':
    print('Generando esquemas del final de carrera de seguridad...')
    draw_safety_interlock()
    draw_context()
    print(f'\nListo. SVG en {OUT}/')
