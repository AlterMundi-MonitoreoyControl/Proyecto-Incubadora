# Project-Incubadora Software

## Notes before you start :raised_back_of_hand:

 add the current user to the dialout group. This will allow us to use the USB directly

```bash
sudo usermod -a -G dialout $USER
```
We also add ourselves to the group temporarily so we don't have to log in to the system again. If we do not, it will be necessary to restart for the changes to take effect.

```bash
newgrp dialout
```

if you are usign ubuntu 22 and the esp32cam motherboard based on "ID 1a86:7523 QinHeng Electronics CH340 serial converter" you won't be able to use the device. This happens because of conflict between product IDs (a Braille screen reader and my CH340 based chip). Here is the solution :

Edit /usr/lib/udev/rules.d/85-brltty.rules; Search for this line and comment it out:

```bash
ENV{PRODUCT}=="1a86/7523/*", ENV{BRLTTY_BRAILLE_DRIVER}="bm", GOTO="brltty_usb_run"
```

then reboot.


## Firmware with lua support

 clone the repository

```bash
git clone --branch dev-esp32 --depth=1 --shallow-submodules --recurse-submodules https://github.com/nodemcu/nodemcu-firmware.git firmwareESP32 
```
 Once cloned enter the downloaded file with:

```bash
 cd firmwareESP32
```
then download the sdkmanager file to be able to compile the firmware:

```bash
 wget -c https://cutt.ly/QwjY9Sdt --output-document sdkconfig --show-progress
```
```bash
git pull
```
```bash
./install.sh
```
```bash
make menuconfig  
```

```bash
make -j4  
```


## Burn Firmware with ESPTool

__Installation of ESPTool__

```bash
sudo apt install esptool
```


Put the ESP32 in programming mode by holding the IO0 button and pressing the RST button at the same time.

from the 'build' folder run:

```bash
esptool --chip esp32 --port /dev/ttyUSB0 --baud 921600 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size detect 0x1000 bootloader/bootloader.bin 0x10000 NodeMCU.bin 0x8000 partitions.bin
```
or
```bash
make flash
```

## Load the Lua scripts

To load the scripts we have 2 options:
* [EspLorer](https://github.com/4refr0nt/ESPlorer)
* [nodemcu-uploader](https://pypi.org/project/nodemcu-uploader/)

## Editing Lua scripts
* [ZeroBrane](https://studio.zerobrane.com/)
* VSCodium... remember to install sumneko's Lua package, then using the open addon manager install esp32 definitions. 


## Option 1 (ESPlorer, must be latest version)
* [Link to git and readme for the latest version of ESPlorer](https://github.com/4refr0nt/ESPlorer)

 clone the repository:

```bash
git clone https://github.com/4refr0nt/ESPlorer.git
```
after cloning it:

```bash
cd ESPlorer
./mvnw clean package
```
to execute ESPlorer:

```bash
java -jar target/ESPlorer.jar
```

## Option 2 (nodemcu-uploader)

installation:

```bash
sudo pip install nodemcu-uploader
```
once installed, we can upload files using:

```bash
nodemcu-uploader upload init.lua
```

to see the different commands that can be used:
```bash
nodemcu-uploader -h
```

## Option 3 (ZeroBraneStudio)

installation:
```bash
wget https://download.zerobrane.com/ZeroBraneStudioEduPack-1.90-linux.sh
```
After downloading, we give it execution permission with:

```bash
chmod +x ZeroBraneStudioEduPack-1.90-linux.sh
```
after giving it permissions, run the installer:

```bash
./ZeroBraneStudioEduPack-1.90-linux.sh
```

## Useful Links

* [Pad incubadora](https://pad.codigosur.org/AM_Proyecto_Incubadora)
* [Sensor information BME280](https://3iinc.xyz/blog/how-to-use-i2c-sensor-bme280-with-esp32cam/)
* [Documentation nodemcu](https://nodemcu.readthedocs.io/en/dev-esp32)
* [Repository with modules Lua](https://github.com/novalabsxyz/api-examples/blob/master/script/bme280/bme280.lua)
* [Sensor information DHT22](https://nodemcu.readthedocs.io/en/dev-esp32/modules/dht/#dhtread2x)
* [Git Tutorials](https://rogerdudler.github.io/git-guide/index.es.html )
* [Files and photos](https://nube.altermundi.net/s/3arPqaHxs763pmB?path=%2F)


## files we need to send to the ESP32

1. bmw280.lua located in the libs folder 
2. credentials.lua located in the libs folder (in lines 5 and 6 you have to write your SSID and password)
3. wifiinit.lua located in the app folder 
4. SendToGrafana.lua located in the app folder  



