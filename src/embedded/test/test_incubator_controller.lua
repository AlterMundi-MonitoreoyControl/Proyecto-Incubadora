package.path = package.path .. ";../app/?.lua" .. ";../libs/?.lua"

_G.node =
{
    uptime = function()
        return 1500
    end,
    heap = function()
        return 999
    end
}

_G.sjson = {
    decode = function()
        return {}
    end
}

_G.http = {
    post = function(url, options, body, callback)
        print(body)
    end
}
_G.gpio = {
    config = function(arg)
        print(arg)
    end,
    set_drive = function(arg)
        print(arg)
    end,
    write = function(arg)
        print(arg)
    end
}
_G.i2c = {
    setup = function(arg)
        print(arg)
    end,
    start = function(arg)
        print(arg)
    end,
    address = function(arg)
        print(arg)
    end,
    stop = function(arg)
        print(arg)
    end
}
_G.httpd = {
    dynamic = function(arg)
        print(arg)
    end,
    start = function(arg)
        print(arg)
    end,
    address = function(arg)
        print(arg)
    end,
    stop = function(arg)
        print(arg)
    end
}
_G.tmr = {
    start = function(arg)
        print(arg)
    end,
    create = function(arg)
        print(arg)
        return {
            register = function(arg)
                print(arg)
            end,
            start = function(arg)
                print(arg)
            end
        }
    end,
    stop = function(arg)
        print(arg)
    end
}


--test samples acording to "tescaes humedad ods"
timesamples = { 0, 120, 1140, 1320, 2460, 2520, 2580, 2640, 2700, 2760, 2820, 3420, 3960, 4140, 4260, 5220, 5340, 5400, 5460 }
hum_readings = { 10, 20, 30, 20, 10, 40, 59, 61, 71, 66, 55, 55, 55, 55, 40, 40, 66, 77, 64 }
hum_status = { true, true, false, false, true, true, true, true, false, false, true, true, false, false, false, true, true, false, false }

_G.time = {
    get = function()
        return 1676515676854775806
    end
}
require("SendToGrafana")
require("incubatorController")

log.x86 = true

describe('send to grafana tests', function()
    before_each(
        function()

        end)

    it("call send, and spy on http.post", function()
        --define a global http.post to be called by send to grafana
        --in real code this is implemented by nodemcu firmware.

        spy.on(http, "post")
        spy.on(_G, "print")
        --invoke the method with the desired paramters
        print(
        "        --invoke the method with the desired paramters  invoke the method with the desired paramters      --invoke the method with the desired paramters ")
        create_grafana_message(29, 60, 800, "XX-bme280", "1676515676854775806")
        send_data_grafana(29, 60, 800, "XX-bme280", "1676515676854775806")
        assert.spy(http.post).was.called()
        --verify that moked function was called and printed the desired output.
        assert.spy(_G.print).was.called_with(
        "mediciones,device=XX-bme280 temp=29,hum=60,press=800 1676515676854775805946888192")

        http.post:revert() -- reverts the stub
        print(
        "        --invoke the method with the desired paramters  invoke the method with the desired paramters      --invoke the method with the desired paramters ")
    end)
end)

describe('test grafana message compostition', function()
    it('very simple test of send to grafana with te new time mark functionality', function()
        assert.is.equal("mediciones,device=XX-bme280 temp=29,hum=60,press=800 1676515676854775806",
            create_grafana_message(29, 60, 800, "XX-bme280", "1676515676854775806"))
    end)
end)

describe('malfunction alert', function()
    it('temperature is stable an resitor is on', function()
        spy.on(incubator, "heater")
        incubator.temperature = 20
        for i = 9, 1, -1
        do
            temp_control(20, incubator.min_temp, incubator.max_temp, time)
            assert.spy(incubator.heater).was.called_with(true)
        end
        assert.spy(incubator.heater).was.not_called_with(false)
        assert.spy(incubator.heater).was.called(9)
        temp_control(20, incubator.min_temp, incubator.max_temp)
        assert.spy(incubator.heater).was.called_with(false)
        assert.spy(_G.print).was.called_with(
        "alertas,device=JJ-RIO4 count=1,message=\"temperature is not changing\" 1676515676854775805946888192")
        assert.spy(_G.print).was.called_with(
        "alertas,device=JJ-RIO4 count=2,message=\"temperature < M.min_temp and resistor is off\" 1676515676854775805946888192")
        incubator.temperature = 21
        temp_control(21, incubator.min_temp, incubator.max_temp)
    end)
    it('failed to start temperature sensor', function()
        spy.on(incubator, "heater")
        temp = incubator.get_values()
        assert.spy(_G.print).was.called_with(
        "alertas,device=JJ-RIO4 count=1,message=\"temperature is not changing\" 1676515676854775805946888192")
        assert.spy(_G.print).was.called_with(
        "alertas,device=JJ-RIO4 count=2,message=\"temperature < M.min_temp and resistor is off\" 1676515676854775805946888192")
        incubator.temperature = 21
        temp_control(21, incubator.min_temp, incubator.max_temp)
    end)
end)


describe('humidity control tests', function()
    it('humidity cicle control', function()
        spy.on(incubator, "humidifier_switch")
        incubator.temperature = 20
        for i = 1, 19, 1
        do
            print("------------" .. hum_readings[i] .. " t " .. timesamples[i] .. " bool " .. tostring(hum_status[i]))
            incubator.get_uptime_in_sec = function()
                    return timesamples[i]
                end
            hum_control(hum_readings[i], incubator.min_hum, incubator.max_hum)
            --assert.are_equal(expected,passed)
            assert.are_equal(hum_status[i],incubator.humidifier)
        end
    end)
end)
