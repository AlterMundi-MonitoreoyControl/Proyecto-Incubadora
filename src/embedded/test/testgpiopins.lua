gpio.config( { gpio={14,15,13}, dir=gpio.OUT })
gpio.set_drive(13, gpio.DRIVE_3)
gpio.set_drive(14, gpio.DRIVE_3)
gpio.set_drive(15, gpio.DRIVE_3)

function testpin(pin)
    gpio.write(pin, 0)
    print("prende")
end

function testpinapaga(pin)
    gpio.write(pin, 1)
    print("apaga")
end



mytimer = tmr.create()
mytimer:register(1000, tmr.ALARM_AUTO, function() testpinapaga(13) end)
mytimer:start()


mytimer2 = tmr.create()
mytimer2:register(1500, tmr.ALARM_AUTO, function() testpin(13) end )
mytimer2:start()

--El tiempo de encendido es idispensable ... 