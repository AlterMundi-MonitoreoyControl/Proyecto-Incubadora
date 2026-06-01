# Nomenclatura y BOM — Esquema eléctrico LibreIncu

Referencias de componentes y mapa de señales del esquema `EsquemaLibreIncu.fc.qet`.
**Fuente de verdad para señales/GPIO: el firmware** (`src/embedded/libs/credentials.lua`).

## Mapa de señales (firmware = verdad)

| GPIO | Constante firmware | Señal / red | Destino |
|------|--------------------|-------------|---------|
| 2  | `GPIOVOLTEO_UP`   | **IN_A_N** | L298 IN1 — motor subir |
| 15 | `GPIOVOLTEO_DOWN` | **IN_A_P** | L298 IN2 — motor bajar |
| 13 | `GPIOVOLTEO_EN`   | **EN_A**   | L298 ENA — habilita motor |
| 14 | `GPIORESISTOR`    | calefactor | TRIAC → resistencia 200W |
| 17 | `GPIOHUMID`       | humidificador | relé → bomba |
| 35 | `GPIOREEDS_UP`    | reed superior | entrada (pull-up int.) |
| 34 | `GPIOREEDS_DOWN`  | reed inferior | entrada (pull-up int.) |
| 32 / 33 | `GPIOBMESDA/SCL` | I²C | sensor BME280 |

> ⚠️ **Discrepancia firmware ↔ placa v0.2:** el firmware usa `EN = GPIO13`, pero el
> esquemático KiCad de la placa rotula `EN_A = IO12` y `IO13 = TRIAC_B`. Por decisión
> del proyecto se toma el **firmware como verdad** (EN = GPIO13). Verificar el ruteo
> físico de la placa o corregir uno de los dos.

## Referencias de componentes

| Ref | Componente | Señal / GPIO | Spec (BOM) |
|-----|------------|--------------|------------|
| Q1 | Disyuntor diferencial | 220 VAC | Bipolar 2×25A |
| Q2 | Termomagnética «Electrónica» | 220 VAC | DIN 782105 |
| Q3 | Termomagnética «Calefactor» | 220 VAC | DIN 782105 |
| Q4 | Termomagnética «Luz + Ventilador» | 220 VAC | DIN 782105 |
| A2 | Placa de control Olivia (ESP32-WROOM-32D) | — | Diseño propio LibreIncu |
| A1 | Driver puente H **L298** (volteo) | IN_A_N/IN_A_P/EN_A | módulo L298N |
| G1 | Fuente switching 12V | 220→12 VDC | FSI-1205 12V 5A |
| G2 | Step-down 5V | 12→5 VDC | LM2596 |
| M1 | Motorreductor volteo | salida L298 (12V) | Ignis MR08B-012004, 12V 4W 17rpm |
| M2 | Bomba de agua | 12V (vía K1) | Singflo/SEAFLO 12V 4,3LPM |
| M3 | Ventilador turbina | 220 VAC (vía Q4) | 220V 120mm c/rulemán |
| K1 | Módulo relé 2CH | GPIO17 (humid.) | relé 2 canales |
| E1 | Resistencia calefactora | 220 VAC (TRIAC, GPIO14) | 200W panchera |
| E2 | Luz interior LED | 220 VAC (vía Q4) | proyector LED 10W |
| S1 | Reed switch superior | GPIO35 (sensa) | sensor magnético |
| S2 | Reed switch inferior | GPIO34 (sensa) | sensor magnético |
| **S3** | **Final de carrera FC-SUP** (seguridad) | corta **IN_A_N** | microswitch NC |
| **S4** | **Final de carrera FC-INF** (seguridad) | corta **IN_A_P** | microswitch NC |
| **R1** | **Pull-down 10k** (IN_A_N) | a GND | 10 kΩ |
| **R2** | **Pull-down 10k** (IN_A_P) | a GND | 10 kΩ |

> En el `.qet`, las referencias de los componentes cuyo símbolo no tiene campo de
> etiqueta (A1, A2, G1, K1, E1, E2, M2, M3) están en los datos del elemento y se
> identifican visualmente por su texto descriptivo (Lm298, Placa olivia control,
> Fuente, Módulo Relé, etc.). Q1–Q4, M1, G2, S1, S2, S3/S4, R1/R2 se muestran.

## Código de colores de conductores (por dominio)

| Color | Dominio |
|-------|---------|
| 🔴 rojo oscuro `#991b1b` | Potencia **220 VAC** (no se separa L/N: el `.qet` no rotula terminales) |
| 🟢 verde `#15803d` | **+12 VDC** |
| 🟣 violeta `#7c3aed` | Salida del puente H al **motor** |
| 🔵 azul `#1d4ed8` | Señal **IN_A_N** (subir) |
| 🟠 naranja `#ea580c` | Señal **IN_A_P** (bajar) |
| 🟤 marrón `#92400e` | Señal **EN_A** (habilita) |
| 🔷 cian `#0891b2` | Señales de control placa↔relé |
| negro | resto / sin clasificar (relé↔step-down, salida de agua) |
