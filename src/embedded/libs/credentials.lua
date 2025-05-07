-- This file is only a placeholder.
-- Put your credentials here, and 
-- rename the file to remove the underscore.
SSID = "default"
PASSWORD = ""
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

--outputs resistor can be 14, or 27
GPIORESISTOR=14
GPIOHUMID = 17

GPIOVOLTEO_UP = 2
GPIOVOLTEO_DOWN = 15
GPIOVOLTEO_EN = 13
--! this variable is going to be overwritten
--! see line 419 incubator.lua
INICIALES = "Tes"
SERVER="http://grafana.altermundi.net:8086/write?db=cto"

--critical configurations resitor must be turned off
gpio.config( { gpio={GPIORESISTOR}, dir=gpio.OUT })
gpio.set_drive(GPIORESISTOR, gpio.DRIVE_3)
gpio.write(GPIORESISTOR, 0)
-- rotation must be disabled
gpio.config( { gpio={GPIOVOLTEO_EN}, dir=gpio.OUT })
gpio.set_drive(GPIOVOLTEO_EN, gpio.DRIVE_3)
gpio.write(GPIOVOLTEO_EN, 0)

gpio.config( { gpio={GPIOVOLTEO_UP}, dir=gpio.OUT })
gpio.set_drive(GPIOVOLTEO_UP, gpio.DRIVE_3)
gpio.write(GPIOVOLTEO_UP, 0)

gpio.config( { gpio={GPIOVOLTEO_DOWN}, dir=gpio.OUT })
gpio.set_drive(GPIOVOLTEO_DOWN, gpio.DRIVE_3)
gpio.write(GPIOVOLTEO_UP, 0)


-- humidifier must be turned off
gpio.config( { gpio={GPIOHUMID}, dir=gpio.OUT })
gpio.set_drive(GPIOHUMID, gpio.DRIVE_3)
gpio.write(GPIOHUMID, 1)

gpio.config({ gpio = { GPIOREEDS_DOWN, GPIOREEDS_UP }, dir = gpio.IN, pull = gpio.PULL_UP })
