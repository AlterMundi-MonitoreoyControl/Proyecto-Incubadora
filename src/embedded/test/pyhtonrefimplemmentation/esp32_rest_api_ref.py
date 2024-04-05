#sudo apt install python3-flask
# esp32_rest_api_ref.py
# flask --app esp32_rest_api_ref run
import time
from flask import Flask
from flask import request
from flask import Response
import time


app = Flask(__name__)
app.debug = True

@app.route("/")
def hello_world():
    return "Hello, World!"
maxtemp = 78
mintemp = 11
@app.route("/maxtemp", methods=['GET', 'POST'])
def maxtempgeter():
    global maxtemp
    if request.method == 'GET':
        return '{"message": "success", "maxtemp":'+str(maxtemp)+'}'
    if request.method == 'POST':
        maxtemp = request.json.get('maxtemp')
        return Response( status=201)

@app.route("/mintemp",methods=['GET', 'POST'])
def mintempgeter():
    global mintemp
    if request.method == 'GET':
        return '{"message": "success", "mintemp":'+str(mintemp)+'}'
    if request.method == 'POST':
        mintemp = request.json.get('mintemp')
        return Response( status=201)

@app.route("/version")
def version():
    return '{"message": "success", "version":"0.0.1"}'

@app.route("/date")
def date():
    now = int( time.time() )
    return '{"message": "success", "date":' + str(now) + '}'
