# Instalación eléctrica

Trabajar siempre sin tensión. El equipo se conecta a la red recién en la [puesta en marcha](puesta-en-marcha.md).

## Tablero

![Tablero eléctrico del equipo real con protecciones, fuente, placa y módulos](img/manual/tablero-electrico.jpg){ width=500 }

*Figura 9. Tablero eléctrico del equipo.*

| Componente | Descripción |
|---|---|
| Protecciones | Disyuntor diferencial e interruptores termomagnéticos. |
| Alimentación | Fuente de 220 V CA a 12 V CC y step-down de 12 V CC a 5 V CC. |
| Placa Olivia Control | ESP32 con WiFi; salida TRIAC para la resistencia de 200 W a 220 V CA; comunicación I2C con el BME280; entradas para los sensores de posición de las bandejas y salidas para puente H y relés. |
| Módulo puente H | Control del motor de rotación. |
| Módulo de relés | Control de la bomba del humidificador. |

![Placa Olivia y conexiones de potencia rotuladas en la fuente original](img/manual/placa-olivia-potencia.png){ width=440 }

*Figura 10. Placa Olivia Control V2.*

## Placa Olivia

Montar la placa Olivia Control en el gabinete acoplado al tablero eléctrico, respetando la ubicación de las ranuras y los orificios para el cableado.

## Resistencia

La salida TRIAC de la placa (**GPIO 14**) alimenta la resistencia de 200 W.

- El fusible térmico KSD301 va **en serie** con la resistencia, en la misma budinera. Corta a 175 °C sin depender del firmware.
- La resistencia se conecta con un conector interlock macho a una toma de chasis en la carcasa, para poder sacar la budinera.
- Conectar a tierra la budinera y la contraplaca.

## Sensor BME280

**Conector J11 — I2C.**

<div style="display:flex; justify-content:center; align-items:flex-start; gap:12px; flex-wrap:wrap;">
  <img src="img/manual/j11-bme280.png" alt="Conector J11 de Olivia con SDA, SCL, VCC y GND rotulados" style="width:30%; height:auto;">
  <img src="img/manual/sensor-bme280.png" alt="Sensor BME280 con los terminales VIN, GND, SCL y SDA visibles" style="width:30%; height:auto;">
</div>

*Figuras 11 y 12. J11 y sensor BME280.*

| Señal de J11 | PinOut ESP32|
|---|---|
| SDA | GPIO 32 |
| SCL | GPIO 33 |
| VCC | 3,3 V |
| GND | GND |

## Relé del humidificador

**Conector J6.** La alimentación de los relés del módulo, **JVCC**, se conecta a la salida de **5 V CC** del step-down.

<div style="display:flex; justify-content:center; align-items:flex-start; gap:12px; flex-wrap:wrap;">
  <img src="img/manual/j6-humidificador.png" alt="Conector J6 rotulado con VCC de 3,3 V, Hum/GPIO 17 y GND" style="width:30%; height:auto;">
  <img src="img/manual/modulo-reles.png" alt="Módulo de dos relés utilizado en el equipo real" style="width:30%; height:auto;">
  <img src="img/manual/step-down.png" alt="Step-down utilizado para la alimentación del módulo de relés" style="width:19%; height:auto;">
</div>

*Figuras 13–15. J6, módulo de relés y step-down. La alimentación JVCC de los relés es de 5 V; Hum/GPIO 17 debe accionar el mismo canal cuya salida normalmente abierta conmuta la bomba.*

| Señal de J6 | PinOut ESP32 |
|---|---|
| VCC | 3,3 V |
| Hum | GPIO 17 |
| GND | GND |

Los contactos **NO —normalmente abiertos—** del relé se conectan como interruptor en uno de los cables de alimentación de la bomba de agua.

Conectar **Hum/GPIO 17 a la entrada IN1 o IN2 del canal elegido**. La bomba debe conectarse a la salida NO de **ese mismo relé**. Puede utilizarse cualquiera de los dos canales, siempre que la entrada de control y la salida de la bomba correspondan al mismo relé.

Conectar GND y VCC del módulo a las señales correspondientes de J6, conservando la alimentación JVCC de los relés a 5 V CC.

## Puente H de rotación

**Conector J9 — Motor A.** Retirar el jumper que normalmente puentea **ENA** en el módulo.

<div style="display:flex; justify-content:center; align-items:flex-start; gap:12px; flex-wrap:wrap;">
  <img src="img/manual/j9-puente-h.png" alt="Conector J9 rotulado con GND y GPIO 2, 15 y 13" style="width:25%; height:auto;">
  <img src="img/manual/modulo-puente-h.png" alt="Módulo puente H con alimentación, entradas IN1 e IN2 y ENA rotuladas" style="width:50%; height:auto;">
</div>

*Figuras 16 y 17. Señales de J9 y conexiones rotuladas del puente H; los asteriscos indican la interrupción mediante finales de carrera.*

| Señal de J9 | Conexión al puente H |
|---|---|
| GND | GND |
| GPIO 2 | IN1, pasando por el final de carrera A |
| GPIO 15 | IN2, pasando por el final de carrera B |
| GPIO 13 | ENA |

## Sensores reed

| Entrada | PinOut ESP32 | Sensor |
|---|---|---|
| Input4 | GPIO 35 | Reed A: posición superior |
| Input3 | GPIO 34 | Reed B: posición inferior |

![Sensores reed A y B del mecanismo real](img/manual/sensores-reed.png){ width=280 }

*Figura 18. Sensores magnéticos de posición superior e inferior.*

## Finales de carrera

Los finales de carrera V-156-1C25 interrumpen las señales de mando del puente H:

- **Final de carrera A:** interrumpe el cable entre Motor A de Olivia, **GPIO 2**, y **IN1** del puente H.
- **Final de carrera B:** interrumpe el cable entre Motor A de Olivia, **GPIO 15**, y **IN2** del puente H.
