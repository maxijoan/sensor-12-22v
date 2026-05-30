import string
import webserver

class MUX16 : Driver
    var s0, s1, s2, s3, sig
    var data
    var pantalla_on
    var btn_pin
    var btn_last
    var pantalla_timer    # cuenta ciclos de 50ms hasta apagado (400 = 20s)
    var test_timer        # cuenta ciclos de 50ms para el TEST (100 = 5s)
    var en_test           # true cuando estamos mostrando TEST

    def init(pin_s0, pin_s1, pin_s2, pin_s3, pin_sig, pin_btn)
        self.s0      = (pin_s0  != nil) ? pin_s0  : 5
        self.s1      = (pin_s1  != nil) ? pin_s1  : 8
        self.s2      = (pin_s2  != nil) ? pin_s2  : 0
        self.s3      = (pin_s3  != nil) ? pin_s3  : 1
        self.sig     = (pin_sig != nil) ? pin_sig : 2
        self.btn_pin = (pin_btn != nil) ? pin_btn : 9

        gpio.pin_mode(self.s0,      gpio.OUTPUT)
        gpio.pin_mode(self.s1,      gpio.OUTPUT)
        gpio.pin_mode(self.s2,      gpio.OUTPUT)
        gpio.pin_mode(self.s3,      gpio.OUTPUT)
        gpio.pin_mode(self.sig,     gpio.INPUT_PULLUP)
        gpio.pin_mode(self.btn_pin, gpio.INPUT_PULLUP)

        self.data          = []
        self.pantalla_on   = true
        self.btn_last      = 1
        self.pantalla_timer = 0
        self.test_timer    = 0
        self.en_test       = false

        for i: 0..15
            self.data.push(0)
        end
        print("MUX16: Inicializado OK")
    end

    def set_channel(canal)
        gpio.digital_write(self.s0,  canal        & 1)
        gpio.digital_write(self.s1, (canal >> 1)  & 1)
        gpio.digital_write(self.s2, (canal >> 2)  & 1)
        gpio.digital_write(self.s3, (canal >> 3)  & 1)
    end

    def pantalla_encender()
        self.pantalla_on    = true
        self.pantalla_timer = 0
        tasmota.cmd("DisplayDimmer 100")
        print("Pantalla: ON")
    end

    def pantalla_apagar()
        self.pantalla_on = false
        self.en_test     = false
        self.test_timer  = 0
        tasmota.cmd("DisplayDimmer 0")
        print("Pantalla: OFF (standby)")
    end

    def check_button()
        var btn_now = gpio.digital_read(self.btn_pin)
        if btn_now == 0 && self.btn_last == 1
            if self.pantalla_on
                self.pantalla_apagar()
            else
                self.pantalla_encender()
            end
        end
        self.btn_last = btn_now
    end

    def check_timers()
        if !self.pantalla_on  return  end

        # Timer TEST: 5s mostrando TEST, luego vuelve a monitor
        if self.en_test
            self.test_timer += 1
            if self.test_timer >= 20    # 20 x 50ms = 1s
                self.en_test    = false
                self.test_timer = 0
            end
        end

        # Timer inactividad: 20s sin actividad apaga pantalla
        self.pantalla_timer += 1
        if self.pantalla_timer >= 400   # 400 x 50ms = 20s
            self.pantalla_apagar()
        end
    end

    def scan()
        for canal: 0..15
            self.set_channel(canal)
            tasmota.delay(2)
            var lectura = 1 - gpio.digital_read(self.sig)
            if lectura != self.data[canal]
                self.data[canal] = lectura
                self.publish_change(canal, lectura)

                # Canal 0 pulsado = activar pantalla + modo TEST
                if canal == 0 && lectura == 1
                    self.pantalla_encender()
                    self.en_test    = true
                    self.test_timer = 0
                end
            end
        end
    end

    def publish_change(canal, estado)
        var boton_num = canal + 1
        var accion = (estado == 1) ? "PRESSED" : "RELEASED"
        var payload = string.format('{"Button":%d,"Action":"%s"}', boton_num, accion)
        var topic = tasmota.cmd("Topic")['Topic']
        tasmota.cmd("Publish2 tele/" + topic + "/button " + payload)
        print("MQTT MUX16 Enviado: " + payload)
    end

    def every_50ms()
        self.check_button()
        self.check_timers()
        self.scan()
        self.update_display()
    end

    def update_display()
        if !self.pantalla_on  return  end

        if self.en_test
            tasmota.cmd("DisplayText [z][c1][s3][x5y18]TEST C0")
            return
        end

        var cmd = "DisplayText [z][c1][f1x1y1]IP: "
        cmd += tasmota.wifi()['ip']

        for i: 0..15
            var col = i % 4
            var row = int(i / 4)
            var x = col * 32
            var y = 13 + (row * 12)
            cmd += string.format("[x%dy%d]%d:%s", x, y, i, (self.data[i] == 1) ? "1" : "0")
        end

        cmd += " [f0x1y56]www.sistelmatic.com"
        tasmota.cmd(cmd)
    end

    def web_sensor()
        var html = "<tr><th>MUX16</th><td>"
        html += "<div style='display:grid;grid-template-columns:repeat(4,1fr);gap:5px;text-align:center;max-width:250px;'>"

        for i: 0..15
            var color = (self.data[i] == 1) ? "green" : "grey"
            var estado = (self.data[i] == 1) ? "ON" : "OFF"
            html += string.format(
                "<div style='background-color:%s;color:white;padding:5px;border-radius:3px;font-weight:bold;font-size:12px;'>B%d<br><span style='font-size:10px;'>%s</span></div>",
                color, i + 1, estado)
        end

        html += "</div></td></tr>"
        webserver.content_send(html)
    end
end

var mux = MUX16()
tasmota.add_driver(mux)
