package.path = package.path .. ";../app/?.lua"

require ("SendToGrafana")
describe('send to grafana tests', function()
    it("call send, and spy on http.post", function()
        --define a global http.post to be called by send to grafana
        --in real code this is implemented by nodemcu firmware.
        _G.http = {
			post = function(url, options, body, callback) 
                print(body)
            end
		}
        spy.on(http, "post")
        spy.on(_G, "print")
        --invoke the method with the desired paramters 
        send_data_grafana(29,60,800,"XX-bme280", 1676515676854775806)
        assert.spy(http.post).was.called()
        --verify that moked function was called and printed the desired output.
        assert.spy(_G.print).was.called_with("mediciones,device=XX-bme280 temp=29,hum=60,press=800 1676515676854775806")

        http.post:revert() -- reverts the stub
    end)
end)

describe('test grafana message compostition', function()
    it('very simple test of send to grafana with te new time mark functionality', function()
        assert.is.equal("mediciones,device=XX-bme280 temp=29,hum=60,press=800 1676515676854775806", create_grafana_message(29,60,800,"XX-bme280",1676515676854775806))
    end)
end)
