-- i2cled via PCF8574A

sda=16
scl=0
i2c.setup(0, sda, scl, i2c.SLOW)

pcf8574=require("pcf8574")

-- Knight Rider LED

local ledbit = 0
local dir = 1


function led_setup()
        print(string.byte(data))
        pcf8574.write(data)
        if dir == 1 then
            data = 0xff
            dir = -dir
        else
            data = 0x00
            dir = -dir
        end
   end


--led_move=led_setup()
--tmr.alarm(0, 50, tmr.ALARM_AUTO, led_move)
-- tmr.interval(0, 500)

local led_move = tmr.create()
led_move:register(500, tmr.ALARM_AUTO, led_setup)
led_move:start()


--pin pastilla - puerto - pin placa negra
--pa - pu - pl - hex
-- 4 - 0 -  4  - 1   - 
-- 5  -1 -  5  - 2
-- 6  -2 -  6  - 4
-- 7  -3 -  x  - 8 --- seems to be gnd for backlight in pin 15
-- 9  -4 - 11  - 10  
-- 10 -5 - 12  - 20
-- 11 -6 - 13  - 40
-- 12 -7 - 14  - 80

data = pcf8574.read()
print(string.byte(data))

--todos los pines en 5 v
data = pcf8574.write(0xff)
data = pcf8574.read()
print(string.byte(data))

data = pcf8574.write(0x00)
data = pcf8574.read()
print(string.byte(data))

-- pin 4 de la placa en 5 v 
data = pcf8574.write(0x01)
data = pcf8574.read()
print(string.byte(data))


