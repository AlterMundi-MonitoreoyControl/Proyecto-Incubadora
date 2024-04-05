**INSTALACION**
sudo apt install lua5.1 liblua5.1-dev luarocks

*Instalar openrestri*
Seguir los pasos que estan acá (los pasos son distintos para las diferentes versiones de ubuntu)

http://openresty.org/en/linux-packages.html#ubuntu


**CONFIGURAR PATH DE LUAROCKS PARA QUE LUA ENCUENTRE LAS LIBS**

luarocks path --lua-version 5.1 >> ~/.bashrc 

**VERIFICAR QUE LA VERSION DE LUA QUE ESTA CORRIENDO SEA 5.1**

sudo update-alternatives --config lua-interpreter
sudo update-alternatives --config lua-compiler

**INSTALAR LIBRERIA DE APIS REST (lapis)**

luarocks install lapis --local --lua-version 5.1

**INICIAR EL SERVIDOR**

cd src/alternativeluaserver
src/alternativeluaserver$ lapis server




**PROBAR EL SERVIDOR**

curl -i -XGET 'localhost:8080' -u token:e98697797a6a592e6c886277041e6 --data-binary "mediciones,device=jj-bme280 temp=38,hum=66,press=800"

los datos estaran en src/alternativeluaserver/datos.txt

cat src/alternativeluaserver/datos.txt
