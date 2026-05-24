import webserver
import string

class MUX_Screen : Driver
    var s0, s1, s2, s3, sig
    var estados_botones # Array para guardar el estado de los 16 botones

    def init()
        self.s0 = 5
        self.s1 = 6
        self.s2 = 7
        self.s3 = 3
        self.sig = 10
        
        self.estados_botones = []
        for i: 0..15
            self.estados_botones.push(0)
        end
        
        try
            import gpio
            gpio.pin_mode(self.s0, gpio.OUTPUT)
            gpio.pin_mode(self.s1, gpio.OUTPUT)
            gpio.pin_mode(self.s2, gpio.OUTPUT)
            gpio.pin_mode(self.s3, gpio.OUTPUT)
            
            # Activa el Pull-Up interno para evitar que el pin flote
            gpio.pin_mode(self.sig, gpio.INPUT_PULLUP)
        except ..
        end
    end

    def scan_multiplexer()
        import gpio
        for canal: 0..15
            # CORRECCIÓN REAL: Pasamos el resultado binario directo. Sin operadores '?' inválidos.
            gpio.digital_write(self.s0, canal & 0x01)
            gpio.digital_write(self.s1, canal & 0x02)
            gpio.digital_write(self.s2, canal & 0x04)
            gpio.digital_write(self.s3, canal & 0x08)
            
            tasmota.delay(1)
            
            var numero_boton = canal + 1
            
            # LÓGICA INVERSA: Con PULLUP, 0 significa pulsado.
            if gpio.digital_read(self.sig) == 0
                # Si antes estaba suelto (0) y ahora está pulsado (1) -> ENVIAR PRESSED
                if self.estados_botones[canal] == 0
                    tasmota.publish("tele/Villa_Paraiso/BUTTON", string.format('{"Button": %d, "Action": "PRESSED"}', numero_boton))
                end
                self.estados_botones[canal] = 1
            else
                # Si antes estaba pulsado (1) y ahora está suelto (0) -> ENVIAR RELEASED
                if self.estados_botones[canal] == 1
                    tasmota.publish("tele/Villa_Paraiso/BUTTON", string.format('{"Button": %d, "Action": "RELEASED"}', numero_boton))
                end
                self.estados_botones[canal] = 0
            end
        end
    end

    def every_second()
        self.scan_multiplexer()
    end

    # Interfaz web para pintar los 16 botones
    def web_sensor()
        var html = "<tr><th>Estado de los 16 Botones</th><td>"
        html += "<div style='display:grid; grid-template-columns: repeat(4, 1fr); gap: 5px; text-align:center; max-width:250px;'>"
        
        for i: 0..15
            var color = "grey"
            var texto_estado = "OFF"
            
            if self.estados_botones[i] == 1
                color = "green"
                texto_estado = "ON"
            end
            
            # Formato de string corregido y limpio para Berry
            html += string.format(
                "<div style='background-color:%s; color:white; padding:5px; border-radius:3px; font-weight:bold; font-size:12px;'>B%d<br><span style='font-size:10px;'>%s</span></div>", 
                color, i + 1, texto_estado
            )
        end
        
        html += "</div>"
        html += "</td></tr>"
        
        webserver.content_send(html)
    end
end

mux_screen = MUX_Screen()
tasmota.add_driver(mux_screen)
