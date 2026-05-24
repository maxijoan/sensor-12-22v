# project sensor-12 channels -220v sensor ESP32-c3 supermini and Optocopler 817
El objetivo es tener un sistema de supervision para controlar los circuitos activos de un panel de maniobra de una villa.
el condensador de 22uF se puede cambiar por uno de 4.7uF para aumentar velocidad, pero para mi necesidad el de 22uf es mas útil ya que hay mucha inestabilidad del sistema de compañia.

Función,Pin 

	SIG,   GPIO10
	S0,    GPIO5
	S1,    GPIO6
	S2,    GPIO7
	S3,    GPIO3
	EN,    GPIO4 o conectar a GND todo el rato funcionando
	VCC,    3.3V   Importante: segun modelos aguanta bien a 5v

se usa un ESP32-C3 supermini

y un mux del 74  modelo v799
74HC4067 16-Channel Analog/Digital Multiplexer Module


ESQUEMA ELÉCTRICO FINAL - TODO A 5V
Alimentación general:

Alimenta el ESP32-C3 SuperMini por el pin 5V.
Alimenta el 74HC4067 por VCC a 5V.


Diagrama por Canal (con condensador 22µF)
textLADO 220V AC
220V FASE ─────[ 220kΩ 1W ]────┬──── Anodo LED PC817 (pin 1)
                                │
                             Neutro (N)


                       LADO 5V
+5V ─────[ 4.7kΩ ]──── Collector (pin 4) PC817 ──────► Yx (entrada del 74HC4067)
                       │
                    22µF 25V
                       │
                      GND
                       │
                    Emisor (pin 3) ───── GND
