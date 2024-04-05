sensor=require('bme280')
if sensor.init(14,15,true) then -- volatile module
  print (sensor.read()) -- default sampling
end

