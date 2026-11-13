# Manual de Montaje - Incubadora Libreincu 150 v1

### 1. Introducción


Este manual describe el proceso de montaje de la incubadora Libreincu 150 v1, un sistema automatizado para incubación de huevos con control preciso de temperatura, humedad y rotación.

![image](https://hackmd.io/_uploads/SJ7zuawhfl.png)


#### Dimensiones
| Parámetro | Medida |
| -------- | -------- |
| Ancho interno     | 470 mm     |
|Profundidad interna|	500 mm|
|Alto interno|	970 mm|
|Bandejas	|400 × 400 mm|
|Separación vertical entre ejes	|120 mm|
|Separación entre bandeja pivotante y pared	|30 mm|
|Separación entre eje superior e inferior|	240 mm|
|Altura del deflector desde la base	|300 mm|
|Distancia del deflector al fondo|	70 mm|
|Inclinación principal	|20° hacia abajo|
|Planos del deflector|	115, 60 y 50 mm
|Pliegues del deflector	|60° y 30°|



---
### 2. Componentes del Sistema

#### 2.1 Sistema de Control Electrónico
![photo_5062176746198732026_y](https://hackmd.io/_uploads/H1BZzM_jzx.jpg)

| Componente | Descripción |
|------------|-------------|
| **Protecciones** | Disyuntor diferencial e interruptores termomagnéticos |
| **Alimentación** | Fuente (220Vac-12Vcc) + Step-Down (12Vcc - 5Vcc) |
| **Placa Olivia control** | * ESP32, Control central con WiFi  *   Salida Triac-> Control de resistencia 200W a 220V AC *  Comunicación I2C con Sensor Temp + Hum BME280 * Entradas Digitales-> Sensores de posición bandejas) * Salidas Digitales a puente H y relés|
| **Módulo Puente H** | Control motor de rotación
| **Módulo relés** |  Control bomba del humidificador |

![PCB Olivia](https://hackmd.io/_uploads/H1iLalviGl.png)

#### 2.2 Sistema Mecánico de Rotación

| Componente | Descripción |
|------------|-------------|
| **Soportes 8mm** |kl08 (bandejas) y kp08 (tornillo) |
| **Transmisión** | soportes + Motor + acople 8mm + tornillo Thsl |
| **Carro de Elevación** | 2 tuercas Thsl. Sube y baja sobre el tornillo |
| **Cuna para Bandejas** | estante pivotante para bandejas 40x40cm |
| **Sensores Reed** | 2 sensores magnéticos (posición arriba/abajo) |
| **Finales de Carrera** | 2 finales (protección mecánica) |
| **Seguidor y Perno de Bandejas** | Oscila en la ranura horizontal del carro |

#### 2.3 Sistema de Humidificación

| Componente | Descripción |
|------------|-------------|
| **Electroválvula** | Control de suministro de agua |
| **Bomba de Agua** | Impulsión de agua al aspersor |
| **Manguera y Conector** | manguera 10mm + adaptador 10-6mm |
| **Aspersor** | pico 6mm |
| **Soporte Aspersor** | Ángulo L empotrado |

---


## 3. Preparación del Montaje

### 3.1 Materiales Necesarios

- [ ] Mueble terminado
- [ ] Tablero eléctrico
- [ ] Elementos del Sistema mecánico de rotación
- [ ] Sensores Reed y finales de carrera
- [ ] Elementos del Sistema de humidificación
- [ ] Herramientas de montaje
- [ ] Tornillos y accesorios

### 3.2 Verificación de Seguridad

- Verificar que no haya tensión eléctrica en el sistema
- Confirmar que todos los componentes estén presentes
- Revisar elementos de protección personal
- Asegurar espacio y ventilación adecuado

---

## 4. Montaje del Sistema de Control

### 4.1 Instalación de la Placa ESP32

 **Ubicación de la placa**
   - Montar la placa Olivia Control en el gabinete previamente acoplado al tablero eléctrico de la incubadora, observando la ubicación de ranuras y orificios para cableado.

### 4.2 **Conexión al sensor BME280**
   **(J11 - I2C)**
    <div style="display:flex; justify-content:center;
            align-items:flex-start; gap:12px; flex-wrap:wrap;">
  <img src="https://hackmd.io/_uploads/HJR0Tlvofe.png"
       alt="Imagen 1"
       style="width:30%; height:auto;">
  <img src="https://hackmd.io/_uploads/ByKbWcUnzg.png"
       alt="Imagen 2"
       style="width:30%; height:auto;">
</div>

### 4.3 **Conexión al relé Humidificador**
La alimentación de los relés del módulo (JVcc) deberá conectarse a la salida del step down en 5Vcc. Gnd In1/2 Vcc se conectan a J6 de la placa principal.
Lso contactos NO (normal abierto) del relé se conectan como interruptor en uno de los cables de alimentación de la bomba de agua
   **(J6 - Led)**

   <div style="display:flex; justify-content:center;
            align-items:flex-start; gap:12px; flex-wrap:wrap;">
  <img src="https://hackmd.io/_uploads/SJV-AlPoMg.png"
       alt="Imagen 1"
       style="width:30%; height:auto;">
  <img src="https://hackmd.io/_uploads/rySlMcI2zx.png"
       alt="Imagen 2"
       style="width:30%; height:auto;">
    <img src="https://hackmd.io/_uploads/SJXmPq8nMg.png"
       alt="Imagen 3"
       style="width:19%; height:auto;">
</div>
![image](https://hackmd.io/_uploads/SJXmPq8nMg.png)



### 4.4 **Conexión al Puente H Rotación**
Remover el jumper que normalmente puentea "EnA" en el módulo
   **(J9 - Motor A)**
     <div style="display:flex; justify-content:center;
            align-items:flex-start; gap:12px; flex-wrap:wrap;">
  <img src="https://hackmd.io/_uploads/Sy04CePjGx.png"
       alt="Imagen 1"
       style="width:25%; height:auto;">
  <img src="https://hackmd.io/_uploads/rk0dCqIhMe.png"
       alt="Imagen 2"
       style="width:50%; height:auto;">
  </div> 
  
 

 ***Interrumpir las conexiones a IN1,IN2 con Finales de Carrera arriba y abajo**

### 4.5 Conexiones de Sensores Reed
   **Input4**
```
   GPIO 35 → Reed sensor A (posición arriba)
```
   **Input3**
```
   GPIO 34 → Reed sensor B (posición abajo)
```
![image](https://hackmd.io/_uploads/HyENBZDsGg.png)

### 4.6 Conexiones de Finales de Carrera

```
  Final de carrera A → interrumpe el cable que conecta la salida MotorA de la placa Olivia (GPIO 2) y la entrada IN1 del módulo puente H
  Final de carrera B → interrumpe el cable que conecta la salida MotorA de la placa Olivia (GPIO 15) y la entrada IN2 del módulo puente H

```

---

## 5. Montaje del Sistema Mecánico
![Soporte KP08 (1)](https://hackmd.io/_uploads/SybnmZwoGg.png)

### 5.1 Ensamblaje del Tornillo de Rotación

1. **Montar el carro de elevación**
   - Insertar y ajustar las 2 tuercas en el carro
   - Enhebrar el carro sobre el tornillo
   - Ajustar altura inicial, de la mitad hacia abajo

2. **Montar soporte motor y soportes KP08**
   - Anclar un soporte Kp08 al mueble y ajustar el tornillo thsl mediante los prisioneros de dicho soporte utilizando llave allen de 1,5mm. Observar que sobresalga hacia arriba aprox 12mm. Luego colocar y anclar el otro soporte KP08 al mueble
   - Ajustar acople 8mm al motor y al tornillo
   - Colocar el soporte de motor revisando que las distancias entre acoples no superen 1mm ni queden apretadas.

  <div style="display:flex; justify-content:center;
            align-items:flex-start; gap:12px; flex-wrap:wrap;">
  <img src="https://hackmd.io/_uploads/rkNGtAw3Gg.png"
       alt="Imagen 1"
       style="width:40%; height:auto;">
  <img src="https://hackmd.io/_uploads/HJdHFCvhfe.png"
       alt="Imagen 2"
       style="width:40%; height:auto;">
  </div> 
  


## Deflector
1. Cortar chapa de 0,5 mm. El modelo representa 240 x 470 mm de ancho y aletas laterales de 15 mm para fijar a cada lado.
2. Considerar un largo total de 225 mm: paños de 115, 60 y 50 mm.
3. Marcar los pliegues a 115 mm y 175 mm desde un extremo.
4. Cortar las aletas en ángulo "V" sobre las líneas a plegar
5. Plegar siguiendo la imagen: aproximadamente -20°, 60° y 30° respecto de la horizontal.
6. Colocar los seis laterales de 15 mm, desbarbar y verificar que no interfiera con las bandejas ni las paredes.
  <div style="display:flex; justify-content:center;
            align-items:flex-start; gap:2px; flex-wrap:wrap;">
  <img src="https://hackmd.io/_uploads/ByvP9Av2Ml.png"
       alt="Imagen 1"
       style="width:28%; height:auto;">
  <img src="https://hackmd.io/_uploads/SJy9pCD2Mg.png"
       alt="Imagen 2"
       style="width:30%; height:auto;">
  <img src="https://hackmd.io/_uploads/Hkmhl1dnzg.png"
       alt="Imagen 3"
       style="width:50%; height:auto;">
  </div> 


![chapa_impacto_agua](https://hackmd.io/_uploads/BkWMDjqpGg.jpg)


