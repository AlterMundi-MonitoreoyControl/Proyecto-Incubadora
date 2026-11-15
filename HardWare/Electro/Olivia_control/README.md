# Olivia — placa de control de LibreIncu

Placa de control de la incubadora: un controlador basado en ESP32 que maneja las
cargas de 220 V (resistencia, ventilación, volteo) a partir de los sensores.

**Diseño:** Federico Bonino ([@Fede654](https://github.com/Fede654)). Esquemático
y PCB en KiCad, diseñados desde cero: la v0.1 (julio de 2024) y el rediseño v0.2
para fabricación industrial (2025), con aislación y distancias del sector de
220 V, selección de componentes y conectores, pads y perforaciones, serigrafía,
máscara antisoldante, Gerbers, BOM y especificaciones de fabricación. Los
ajustes menores de otras personas figuran en el historial de git.

## Contenido de `v0.2/`

- `v0.2.kicad_sch`, `v0.2.kicad_pcb`, `v0.2.kicad_pro` — proyecto KiCad.
- `esquematico.pdf` — esquemático para consulta.
- `gerber/` — archivos de fabricación.
- `bill-of-materials.csv` — lista de componentes.
- `PCB_specs_fabricacion.txt` — especificaciones para el pedido al fabricante.
- `v0.2-vista1.png`, `v0.2-vista2.png`, `v0.2.stl` — vistas y modelo 3D.

---

# Olivia — LibreIncu control board

ESP32-based mains controller for the incubator. **Designed from scratch by
Federico Bonino ([@Fede654](https://github.com/Fede654))** in KiCad: v0.1 (July
2024) through the v0.2 redesign for industrial fabrication (2025). Minor
adjustments by others are in the git history.
