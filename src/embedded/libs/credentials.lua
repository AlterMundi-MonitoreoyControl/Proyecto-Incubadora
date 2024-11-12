-- This file is only a placeholder.
-- Put your credentials here, and 
-- rename the file to remove the underscore.
SSID = "ChinaNet-POLLO2_0"
PASSWORD = "1234554321"
TIMEZONE = "UTC+3"

IP_ADDR = ""         -- static IP
NETMASK = ""   -- your subnet
GATEWAY = ""     -- your gateway
--16mb board
GPIOBMESDA = 32
GPIOBMESCL = 33

--inputs
GPIOREEDS_UP = 35
GPIOREEDS_DOWN = 34
--old board
--GPIOBMESDA = 16
--GPIOBMESCL = 0

--outputs
GPIORESISTOR=14
GPIOHUMID = 17

GPIOVOLTEO_UP = 2
GPIOVOLTEO_DOWN = 15
GPIOVOLTEO_EN = 13

INICIALES = "JC"
SERVER="http://grafana.altermundi.net:8086/write?db=cto"

--critical configurations resitor must be turned off
gpio.config( { gpio={GPIORESISTOR}, dir=gpio.OUT })
gpio.set_drive(GPIORESISTOR, gpio.DRIVE_3)
gpio.write(GPIORESISTOR, 0)
-- rotation must be disabled
gpio.config( { gpio={GPIOVOLTEO_EN}, dir=gpio.OUT })
gpio.set_drive(GPIOVOLTEO_EN, gpio.DRIVE_3)
gpio.write(GPIOVOLTEO_EN, 0)
-- humidifier must be turned off
gpio.config( { gpio={GPIOHUMID}, dir=gpio.OUT })
gpio.set_drive(GPIOHUMID, gpio.DRIVE_3)
gpio.write(GPIOHUMID, 1)
