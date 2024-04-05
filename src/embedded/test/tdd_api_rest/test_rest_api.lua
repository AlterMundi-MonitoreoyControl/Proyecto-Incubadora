-- to exclude wifi
-- busted --exclude-tags="wifi" ./test_rest_api.lua
test = {
    http = require("socket.http"),
    JSON = require("JSON"),
    inspect = require("inspect"),
    colors = require("ansicolors"),
    http_request_methods = require("http_request_methods"),
    config = require("config")

}

function test:get_space_location()
    local body, code, _, status, _ = test.http.request(
                                         "http://api.open-notify.org/iss-now.json")
    local lua_value = test.JSON:decode(body) -- decode example
    local lua_value_pretty = test.JSON:encode_pretty(lua_value)
    assert.are.equal(lua_value.message, "success",
                     test.colors('%{red}Fail to get space location'))

    print(string.format(test.colors([[

%{green}%{underline}[#] Space Station location:

%{reset}%{red}BODY:		

%s


%{green}%{underline}RESPONSE CODE: %s	
]]), lua_value_pretty, code))

    return code
end

------------------------------------------------------------------------------------
-- TESTS
------------------------------------------------------------------------------------

describe("[#] API REST TDD", function()
    describe(test.colors("%{green}[#] Get space station location"), function()
        local code_req_space_station = test:get_space_location()
        it(test.colors("%{red}[!]should return the space station location"),
           function() assert.are.equal(code_req_space_station, 200) end)
    end)

    describe(test.colors("%{green}[#] Get the current configuration"),
             function()
        local code_req_actual_config = test.config:get_config()
        it(test.colors("%{red}[!] should return the current configuration"),
           function() assert.are_equal(code_req_actual_config, 200) end)
    end)

    describe("%{green}[#] Get actual temperature and humidity", function()
        local code_req_actual_temp_hum = test.config:get_actual()
        it(test.colors("%{red} should return actual temperature and humidity"),
           function() assert.are.equal(code_req_actual_temp_hum, 200) end)
    end)

    describe("Obtener redes disponibles #wifi", function()
        it("Primera petición debería devolver error",
           test:get_wifi_with_error())
        it("Segunda petición después de escaneo", test:get_wifi())
        it("Tercera petición esperando 5 segundos", test:get_wifi_with_5s())
        it("Cuarta petición sin espera", test:get_wifi_without_tmr())
    end)

    describe(test.colors("%{green}[#] Sets the configuration to default"),
             function()
        test.config:set_config_ok()
        it(test.colors("%{red}[!] should set the configuration to default"),
           function() end)
    end)

    describe(test.colors("%{green}[#] Configuration tests"), function()
        --	set minimum temperature higher than maximum temperature
        local body_req_max_fail = test.config:set_max_fail()
        if body_req_max_fail == 1 then
            body_req_max_fail = "Error in setting min_temp"
        end
        it(test.colors(
               "%{red}[!] Setting min_temp setting higher than max_temp should fail"),
           function()
            assert.are.equal(body_req_max_fail,
                             tostring("Error in setting min_temp"))
        end)
        --	set rotation time higher lower
        local body_req_rotation_time = test.config:set_min_rotation_time_fail()
        if body_req_rotation_time == 1 then
            body_req_rotation_time = "Error in setting rotation_duration"
        end
        it(test.colors(
               "%{red}[!] Setting a minimum value in rotation_duration should fail"),
           function()
            assert.are.equal(body_req_rotation_time,
                             "Error in setting rotation_duration")
        end)
        --	set negative temps
        local body_req_min_temp_negative, body_req_max_temp_negative =
            test.config:set_negative_temps_value_fails()
        if body_req_min_temp_negative == 1 then
            body_req_min_temp_negative = "Error in setting min_temp"
        end
        if body_req_max_temp_negative == 1 then
            body_req_max_temp_negative = "Error in setting max_temp"
        end
        it(test.colors(
               "%{red}[!]Setting temperatures with negative values should fail"),
           function()
            assert.are.equal(body_req_min_temp_negative,
                             "Error in setting min_temp")
            assert.are.equal(body_req_max_temp_negative,
                             "Error in setting max_temp")
        end)

        local body_req_noise_min_temp, body_req_noise_rotation_duration,
              body_req_noise_max_temp = test.config:set_noise_in_parameters()

        if body_req_noise_min_temp == 1 then
            body_req_noise_max_temp = "Error in setting max_temp"
        end
        if body_req_noise_rotation_duration == 1 then
            body_req_noise_rotation_duration =
                "Error in setting rotation_duration"
        end
        if body_req_noise_min_temp == 1 then
            body_req_noise_min_temp = "Error in setting min_temp"
        end

        -- --	set some noise in the parameters
        it(
            test.colors(
                "%{red}[!] Setting strings to numeric values should fail"),
            function()
                assert.are.equal(body_req_noise_max_temp,
                                 "Error in setting max_temp")
                assert.are.equal(body_req_noise_rotation_duration,
                                 "Error in setting rotation_duration")
                assert.are.equal(body_req_noise_min_temp,
                                 "Error in setting min_temp")
            end)
        it(test.colors("%{green}[!] Setting default config"),
           function() config:restore_config() end)
    end)
end)
