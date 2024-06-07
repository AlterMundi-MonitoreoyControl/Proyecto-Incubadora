# sudo apt install python3-flask
# esp32_rest_api_ref.py
# flask --app esp32_rest_api_ref run
import time
from flask import Flask, jsonify
from flask import request
import json

app = Flask(__name__)
app.debug = True
app.run(host='0.0.0.0', port=8080)

html_content = """
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rest Api</title>
</head>
<body>
    <h1i>API REST de prueba</h1>
</body>
</html>
"""

min_temperature = 33
max_temperature = 38
rotation_duration = 3500000
rotation_period = 5000
ssid = "mimimi"
passwd = "12345"
tray_one_date = 1000000
tray_two_date = 500000
tray_three_date = 0
incubation_period = 18
hash_value = 12345

config_dict = {
    "min_temperature": min_temperature,
    "max_temperature": max_temperature,
    "rotation_duration": rotation_duration,
    "rotation_period": rotation_period,
    "ssid": ssid,
    "passwd": passwd,
    "tray_one_date": tray_one_date,
    "tray_two_date": tray_two_date,
    "tray_three_date": tray_three_date,
    "incubation_period": incubation_period,
    "hash": hash_value,
}

a_temperature = 99.90
a_humidity = 99.90
a_pressure = 99.90

actual_dict = {
    "a_temperature": a_temperature,
    "a_humidity": a_humidity,
    "a_pressure": a_pressure,
}

config_json = json.dumps(config_dict)
actual_json = json.dumps(actual_dict)


@app.route("/")
def hello_world():
    return html_content


@app.route("/config", methods=["GET", "POST"])
def config_getter():
    global config_json

    if request.method == "GET":
        return jsonify(json.loads(config_json))
    elif request.method == "POST":
        data = request.json
        # Actualiza los valores de configuración con los datos recibidos en la solicitud POST
        for key, value in data.items():
            if key in config_dict:
                config_dict[key] = value
        config_json = json.dumps(config_dict)  # Actualiza el JSON después de modificar el diccionario
        # Devuelve el JSON actualizado
        return jsonify(json.loads(config_json))




@app.route("/actual", methods=["GET", "POST"])
def actual_getter():
    global actual_json

    if request.method == "GET":
        return jsonify(json.loads(actual_json))
    elif request.method == "POST":
        data = request.json
        # Actualiza los valores de datos actuales con los datos recibidos en la solicitud POST
        for key, value in data.items():
            if key in actual_dict:
                actual_dict[key] = value
        actual_json = json.dumps(actual_dict)
        return jsonify({"message": "Datos actuales actualizados correctamente"})


if __name__ == "__main__":
    app.run(debug=True)
