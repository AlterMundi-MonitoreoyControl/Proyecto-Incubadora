---
icon: material/wrench-outline
---

# Montaje mecánico

Las cotas de esta página se toman con el interior de la cámara como referencia: ancho desde un lateral, profundidad desde el fondo y altura desde el piso. El husillo va contra uno de los laterales; «del lado del husillo» indica ese lateral.

## Mueble

Armar el cuerpo según el plano ALT-INC001-01-00 y la puerta según el ALT-INC001-03-00 del INTI ([carpeta de planos](https://github.com/Pablomonte/LibreIncu-150/tree/LibreIncu-150/HardWare/Mecanica)).

- Unir las placas con tarugos de 8 × 40 mm y tornillos autoperforantes de 4,2 × 13 mm.
- Colocar los perfiles de chapa en los cantos, el burlete tipo D en el marco y las cuatro patas de goma.
- Montar la puerta con dos bisagras ficha de 63 mm y el cierre de tracción.

## Bandejas

1. Fijar los seis soportes KFL08 a los laterales, dos por eje, con el centro del eje a **260 mm del fondo** y a **255, 375 y 495 mm del techo**.
2. Pasar los ejes de 8 mm por los soportes y las cunas.
3. Colocar la varilla de vínculo que une las tres cunas.

!!! note "Plantilla"
    El perforado de los laterales se marca con una plantilla, para que los seis soportes queden alineados.

<div style="display:flex; justify-content:center; align-items:flex-start; gap:12px; flex-wrap:wrap;">
  <img src="img/manual/kp08-dimensiones.png" alt="Plano del soporte KP08 para el tornillo, extraído de la fuente original" style="width:40%; height:auto;">
  <img src="img/manual/kl08-dimensiones.png" alt="Plano del soporte de bandejas KFL08" style="width:40%; height:auto;">
</div>

*Figuras 8 y 9. Soportes KP08 (husillo) y KFL08 (bandejas).*

## Rotación

![Mecanismo real rotulado: acople, KP08, tornillo THSL, carro, reed y finales de carrera](img/manual/rotacion-equipo-real.png){ width=380 }

*Figura 10. Disposición del mecanismo de rotación.*

### Husillo y motor

1. **Montar el carro en el husillo.**
    - Colocar las dos mitades de la tuerca antijuego, una en cada oreja del carro, y fijar cada brida con cuatro tornillos autorroscantes de 2,9 mm.
    - Enhebrar el carro sobre el husillo.
    - Ajustar la altura inicial, de la mitad del husillo hacia abajo.
2. **Montar los soportes KP08 y el motor.**
    - El husillo va a **15 mm del lateral** y a **40 mm del fondo**, desde **10 mm del techo** hacia abajo.
    - Anclar el soporte KP08 superior al mueble y ajustar el husillo con los prisioneros del soporte, con una llave Allen de 1,5 mm. Dejar que sobresalga hacia arriba unos 12 mm.
    - Colocar y anclar el otro soporte KP08 al mueble.
    - Ajustar el acople de 8 mm al motor y al husillo.
    - Colocar el soporte del motor, cuidando que la separación entre los extremos de los ejes en el acople no supere 1 mm y que no queden apretados.

![Vista CAD del husillo vertical, los dos soportes KP08 y el acople superior](img/cad/husillo-kp08-acople.png){ width=75 }

*Vista CAD de referencia: husillo, KP08 y acople.*

### Carro

![Vista CAD del husillo con el carro plegado, los dos soportes KP08 y los dos finales de carrera](img/cad/carro-y-finales-de-carrera.png){ width=145 }

*Figura 11. Carro y finales de carrera en el modelo.*

El alma del carro queda paralela al lateral, en el plano del husillo. La ranura queda horizontal y el perno de la cuna de la bandeja superior corre por ella: al subir y bajar el carro, las bandejas giran.

1. Verificar que el carro suba y baje sin rozar el lateral.
2. Colocar el perno de la cuna de la bandeja superior en la ranura.

### Sensores y finales de carrera

| Elemento | Función | Ubicación |
|---|---|---|
| Reed A | Posición superior: el firmware detiene el motor. | Según la figura 10. |
| Reed B | Posición inferior: el firmware detiene el motor. | Según la figura 10. |
| Final de carrera A (superior) V-156-1C25 | Seguridad: corta el giro a la derecha si falla el reed A. | Rodillo a 40 mm del fondo y 110 mm del techo. |
| Final de carrera B (inferior) V-156-1C25 | Seguridad: corta el giro a la izquierda si falla el reed B. | Rodillo a 40 mm del fondo y 350 mm del techo. |

Los finales de carrera van de plano contra el lateral, detrás del husillo, y los pisan las orejas del carro. En el modelo conmutan a +19,6° y −37,8° de giro de las bandejas.

## Deflector

![Deflector instalado debajo de las bandejas](img/manual/deflector-instalado.png){ width=320 }

*Figura 12. Deflector instalado debajo de las bandejas.*

![Corte lateral del modelo: ventilador, tres bandejas, deflector y fuente de calor, con el fondo a la derecha y el piso abajo](img/cad/corte-lateral.png){ width=300 }

*Figura 13. Corte lateral del modelo, con el fondo a la derecha. El paño vertical del deflector queda a 60 mm del fondo y su borde más bajo a 300 mm del piso, sobre la chapa de impacto.*

El deflector se fabrica según [Compra y corte](compra-y-corte.md#deflector).

1. Ubicar el paño de 50 mm vertical, paralelo al fondo, a **60 mm del fondo**.
2. El paño de 115 mm baja 20° hacia la puerta. Su borde más bajo queda a **300 mm del piso**, justo por encima de la chapa de impacto del agua. El borde superior del paño vertical queda a 446 mm del piso.
3. Fijar las pestañas laterales a las paredes.
4. Girar las bandejas en todo su recorrido y verificar que la inferior no toque el deflector: en el modelo queda a 9,4 mm como mínimo.

## Fuente de calor

La resistencia va debajo de la budinera, apretada contra su fondo por la contraplaca. La budinera se remacha a dos perfiles L que cruzan la cámara a lo ancho y apoyan en los soportes de la bandeja nacedora. Para limpiar la budinera se saca junto con los perfiles L.

<div style="display:flex; justify-content:center; align-items:flex-start; gap:12px; flex-wrap:wrap;">
  <img src="img/cad/fuente-de-calor.png" alt="Fuente de calor vista desde arriba: budinera sobre los perfiles L, soportes de la nacedora, chapa de impacto y fusible" style="width:48%; height:auto;">
  <img src="img/cad/fuente-de-calor-inferior.png" alt="Fuente de calor vista desde abajo: contraplaca bajo la budinera y fusible en la punta" style="width:48%; height:auto;">
</div>

*Figuras 14 y 15. Fuente de calor vista desde arriba y desde abajo: budinera, perfiles L, soportes de la nacedora, contraplaca (gris oscuro), fusible (amarillo) y chapa de impacto.*

| Altura desde el piso | Elemento |
|---|---|
| 8,5 mm | Cara inferior de la contraplaca |
| 14 mm | Base de la budinera |
| 55 mm | Cara superior de los soportes de la nacedora |
| 55 a 75 mm | Perfiles L de la budinera |
| 76 mm | Labio de la budinera |

1. **Soportes de la nacedora.** Fijar un perfil L de 20 × 20 × 3,2 mm en cada lateral, con el ala horizontal hacia adentro y su cara superior a **55 mm del piso**.
2. **Fusible térmico.** En la punta de la budinera del lado del husillo, hacer dos agujeros de 3,2 mm separados 23 mm, con el eje a unos 21 mm sobre la base. Remachar el fusible con la cara sensora contra la pared, con dos remaches pop de 3,2 × 8 mm.
3. **Resistencia.** Centrarla debajo de la base de la budinera, con los cables saliendo por los lados cortos.
4. **Contraplaca.** Colocarla debajo de la resistencia, con las pestañas contra las paredes largas de la budinera. Apretar y remachar las pestañas.
5. **Perfiles L.** Remachar el ala vertical de cada perfil a una pared larga de la budinera, debajo del labio, con el labio apoyado en el borde del ala.
6. **Colocación.** Apoyar las alas horizontales de los perfiles sobre los soportes de la nacedora, con el centro de la budinera a unos 115 mm del fondo.
7. **Conexión.** Conectar la resistencia, con el fusible en serie, al conector interlock macho. Enchufarlo a la toma de chasis de la carcasa.

## Humidificación

1. **Chapa de impacto.** Colocarla en la punta de la budinera del lado del husillo, con el respaldo hacia esa punta y las alas hacia el centro. Su borde superior queda a 298 mm del piso, debajo del deflector. Fijarla a la budinera con tornillos autoperforantes de 4,2 × 13 mm o con remaches pop.
2. **Aspersor.** Fijar la ménsula a la carcasa y montar la boquilla de 6 mm, apuntando a la chapa de impacto.
3. **Bomba y electroválvula.** Conectarlas entre sí y montarlas encima de la cámara, dentro de una caja estanca con un desagote en el punto más bajo para las pérdidas ocasionales. Unirlas a la boquilla con manguera de 10 mm y el acople rápido de 10 a 6 mm.
