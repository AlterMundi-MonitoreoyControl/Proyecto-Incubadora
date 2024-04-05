-- check if chip is present and functional by reading a signature/chip id

-- i2c bus setup
sda = 14 -- pins as on Adafruit Huzzah32 silkscreen
scl = 15
id = i2c.SW -- software interface
speed = i2c.SLOW 

-- values for Bosch Sensortech BMP180 chip
bmpAddress = 0x76
bmpIdRegister = 0xD0
bmpChipSignature = 0x60
-- CHIPID: BMP085/BMP180 0x55, BMP280 0x58, BME280 0x60
-- initialize i2c software interface
i2c.setup(id, sda, scl, speed)

-- attempt to read chip id and compare against expected value
function simple_check_chip(dev_address, dev_register, dev_signature)
  i2c.start(id)
  assert(i2c.address(id, dev_address, i2c.TRANSMITTER) , "!!i2c device did not ACK first address operation" )
  i2c.write(id, dev_register)
  i2c.start(id) -- repeated start condition
  assert( i2c.address(id, dev_address, i2c.RECEIVER) , "!!i2c device did not ACK second address operation" )
  bmpChipSignatureread = i2c.read(id, 1):byte()
  print (bmpChipSignatureread)
  if bmpChipSignatureread == dev_signature then
    print("..chip is operational")
  else
    print("!!The chip does not have the expected signature")
  end
   i2c.stop(id)
end
-- 
print("i2c Chip check, should fail because device address is wrong")
print(bmpAddress)
simple_check_chip(bmpAddress, bmpIdRegister, bmpChipSignature)
