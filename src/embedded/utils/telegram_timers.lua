-- Variables 
local token = "bot5939549515:AAEvLJei-qmmEqIwNwvqNyT9Hrl0fhlvvKs"
local idChat = "-1001767814361"
local temperature = nil
local pressure = nil
local humidity = nil 

-- Conexion a wifi

wifi.mode(wifi.STATION)
wifi.start()
wifi.sta.config({ssid="MilJor",pwd="primavera25"})

-- importando libreria bme280
sensor = require('bme280')


-- inicializa el sensor y guarda los datos en variables
if sensor.init(16,0, true ) then
    sensor.read()
    temperature = math.floor(sensor.temperature * 100)/100
    pressure = sensor.pressure
    humidity = sensor.humidity
end




-- variables que contienen las distintas URL's de temperatura, humedad y presion atmosferica

local temperatura = "https://api.telegram.org/" ..token .. "/sendMessage?chat_id=" .. idChat .."&text=%20Temperatura%20actual%20" .. temperature / 100
local humedad = "https://api.telegram.org/" ..token .. "/sendMessage?chat_id=" .. idChat .."&text=%20Porcentaje%20de%20humedad%20actual%20" .. humidity / 100 
local presionA = "https://api.telegram.org/" ..token .. "/sendMessage?chat_id=" .. idChat .."&text=%20Presion%20Atmosferica%20" .. pressure / 100 


-- temporizador1: Temperatura

temporizador1 = tmr.create()
temporizador1:register(500, tmr.ALARM_AUTO,function()
    temperature = sensor.temperature
    http.get(temperatura ,function(c, d) if c < 0 then print("falló el envio de temperatura, reintentando...") else print(c,#d) end end)

end)

temporizador1:interval(20000)
temporizador1:start()


--Temporizador2 : Humedad 

temporizador2 = tmr.create()
temporizador2:register(500, tmr.ALARM_AUTO,function()
    humidity = sensor.humidity
    http.get(humedad ,function(f, g) if f < 0 then print("falló el envio de porcentaje de humedad, reintentando...") else print(f,#g) end end)

end)
temporizador2:interval(20000)
temporizador2:start()


-- -- Temporaizador3 : Presion Atmosferica

temporizador3 = tmr.create()
temporizador3:register(500, tmr.ALARM_AUTO,function()
    pressure = sensor.pressure
    http.get(presionA ,function(h, i) if h < 0 then print("falló el envio de P. Atmosferica , reintentando...") else print(h,#i) end end)                                    
end)
temporizador3:interval(20000)
temporizador3:start()





