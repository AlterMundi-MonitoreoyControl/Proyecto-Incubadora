# Testing guide

LibrePollo has unit tests that help us add new features while keeping maintenance effort contained.

We encourage contributors to write [tests](https://en.wikipedia.org/wiki/Unit_testing)  when adding new functionality and also while fixing [regressions](https://en.wikipedia.org/wiki/Regression_testing).

LibreMesh unit testing is based in the powerful [busted](https://lunarmodules.github.io/busted/) library which has a very good documentation.

## Install required sofotware
```
apt-get install luarocks
sudo luarocks install --server=https://luarocks.org/dev ltn12
sudo luarocks install luasockets
sudo luarocks install busted
sudo luarocks install json-lua 
sudo luarocks install inspect
```
## How to run the tests

Just execute `busted test_*` inside test folder.

## Testing directory structure

Test files for source module `foo.lua` live inside a `test` directory with its names begining with `test_`:

```
test/test_foo.lua

```

Testing utilities, fake libraries and integration tests live inside a root `test/` directory:

```
tests/test_some_integration_tests.lua
tests/test_other_general_tests.lua
tests/fake/bazlib.lua
tests/tests/test_bazlib.lua
```

## How to write tests

Here is a very simple test of a library `foo`:
```[lua]
local foo = require 'foo'

describe('foo library tests', function()
    it('very simple test of f_sum(a, b)', function()
        assert.is.equal(4, foo.f_sum(2, 2))
        assert.is.equal(2, foo.f_sum(2, 0))
        assert.is.equal(0, foo.f_sum(2, -2))
    end)
end)
```
## manual testing
```lua
dofile('credentials.lua')

gpio.config( { gpio={GPIOVOLTEO_UP}, dir=gpio.OUT })
gpio.set_drive(GPIOVOLTEO_UP, gpio.DRIVE_3)
gpio.write(GPIOVOLTEO_UP, 0)

gpio.config( { gpio={GPIOVOLTEO_DOWN}, dir=gpio.OUT })
gpio.set_drive(GPIOVOLTEO_DOWN, gpio.DRIVE_3)
gpio.write(GPIOVOLTEO_UP, 0)

```
TODO: Implement as a post-power-on self-test or in a app command

### Test Rotation
![image](https://github.com/user-attachments/assets/a39c076b-b9ad-4b7d-841e-21c7bdefa4d4)

We are using motor A inputs. So the first thing to test is the digital inputs.
Leave  a jumper in EN_A like the picture and remove the jumper from EN_B.
Use the other pin from EN_B witch should be in a logical 1 state to activate "in 1" first and then "in 2". Just conect a Female to Female wire betwen the pins and watch the engine rotate in both directions. 

![image](https://github.com/user-attachments/assets/b765ac1c-f950-4181-acb7-85e7f522a67b)




Move down:
```lua
-- turn on
gpio.write(GPIOVOLTEO_EN,1)
gpio.write(GPIOVOLTEO_UP,0)
gpio.write(GPIOVOLTEO_DOWN,1)
-- turn off
gpio.write(GPIOVOLTEO_DOWN,0)
```

Move up:
```lua
gpio.write(GPIOVOLTEO_EN,1)
gpio.write(GPIOVOLTEO_DOWN,0)
gpio.write(GPIOVOLTEO_UP,1)
-- turn off
gpio.write(GPIOVOLTEO_UP,0)
```

### Test Sensors
```lua
print(gpio.read(GPIOREEDS_UP), gpio.read(GPIOREEDS_DOWN))
```

When the sensor is near the human, it switches to 0.  
Test both the upper and lower sensors.

### Test Resistor

Turn on:
```lua
gpio.write(GPIORESISTOR,1)
```

Turn off:
```lua
gpio.write(GPIORESISTOR,0)
```

### Test Humidifier

Turn on:
```lua
gpio.write(GPIOHUMID,0)
```

Turn off:
```lua
gpio.write(GPIOHUMID,1)
```
