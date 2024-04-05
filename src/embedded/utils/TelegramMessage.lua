--Para enviar mensajes con espacios reemplazar los espacios por %20

-- Reemplazar el contenido de mensaje por lo que se quiera enviar
local mensaje = "Soy%20un%20Mensaje%20:)"

-- Reemplazar <token> por el token que entrega @BotFather
local token = "bot<token>"
-- Reemplazar <id> por el id de chat
local idChat = "<id>"

-- Variable que contiene la url completa 
local url = "https://api.telegram.org/" ..token .. "/sendMessage?chat_id=" .. idChat .."&text=" .. mensaje

-- Conexion a wifi

wifi.mode(wifi.STATION)
wifi.start()

-- Reemplazar ssid por el nombre de tu red y pwd por la contraseña
wifi.sta.config({ssid="<ssid>",pwd="<pwd>"})

-- Peticion GET a la url de Telegram
http.get(url ,function(c, d) if c < 0 then print("falló el envío") else print(c,#d) end end)
