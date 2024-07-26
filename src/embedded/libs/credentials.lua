-- This file is only a placeholder.
-- Put your credentials here, and 
-- rename the file to remove the underscore.
SSID = "fabrica"
PASSWORD = "comunidad2023"
TIMEZONE = "UTC+3"

IP_ADDR = ""         -- static IP
NETMASK = ""   -- your subnet
GATEWAY = ""     -- your gateway
--16mb board
GPIOBMESDA = 21
GPIOBMESCL = 22
GPIOREEDS = 36
--old board
--GPIOBMESDA = 16
--GPIOBMESCL = 0

GPIORESISTOR=26
-- GPIOVOLTEO=14
GPIO_HUMIDIFIER = 33
INICIALES = "JJ-RIO4"
SERVER="http://grafana.altermundi.net:8086/write?db=cto"
--SERVER="http://192.168.43.26:8080/"


--critical configurations resitor must be turned off
--gpio.config( { gpio={GPIORESISTOR}, dir=gpio.OUT })
--gpio.set_drive(GPIORESISTOR, gpio.DRIVE_3)
--gpio.write(GPIORESISTOR, 0)
