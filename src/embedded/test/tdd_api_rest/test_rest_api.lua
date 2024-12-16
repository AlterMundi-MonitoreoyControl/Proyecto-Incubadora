-- to exclude wifi
-- busted --exclude-tags="wifi" ./test_rest_api.lua

local test = {
	http = require("socket.http"),
	JSON = require("JSON"),
	inspect = require("inspect"),
	colors = require("ansicolors"),
	http_request_methods = require("http_request_methods"),
	config = require("config"),
	tables = require("tables")
}

------------------------------------------------------------------------------------
-- Función para obtener la ubicación de la estación espacial.
------------------------------------------------------------------------------------
function test:get_space_location()
	local body, code = test.http.request("http://api.open-notify.org/iss-now.json")
	local lua_value = test.JSON:decode(body) -- Decode example
	assert.are.equal(lua_value.message, "success", test.colors('%{red}Failed to get space location'))

	print(string.format(test.colors([[

	%{green}%{underline}[#] Space Station Location:

	%{reset}%{red}BODY:

	%s

	%{green}%{underline}RESPONSE CODE: %s	
	]]), test.JSON:encode_pretty(lua_value), code))

	return code
end

------------------------------------------------------------------------------------
-- TESTS
------------------------------------------------------------------------------------

describe("[#] API REST TDD", function()
	describe(test.colors("%{green}[#] Get Space Station Location"), function()
		it(test.colors("%{red}[!] should return the space station location"), function()
			local code_req_space_station = test:get_space_location()
			assert.are.equal(code_req_space_station, 200)
		end)
	end)

	describe(test.colors("%{green}[#] Get Current Configuration"), function()
		it(test.colors("%{red}[!] should return the current configuration"), function()
			local current_config = test.config:get_config()
			assert.is.not_nil(current_config)
		end)
	end)

	describe(test.colors("%{green}[#] Get Actual Temperature and Humidity"), function()
		it(test.colors("%{red} should return actual temperature and humidity"), function()
			local current_values = test.config:get_actual()
			assert.is.not_nil(current_values)
			assert.are.equal(current_values.a_humidity, "99.90")
			assert.are.equal(current_values.a_temperature, "99.90")
		end)
	end)

	describe("Obtener redes disponibles #wifi", function()
		it("Primera petición debería devolver error",
			test:get_wifi_with_error())
		it("Segunda petición después de escaneo", test:get_wifi())
		it("Tercera petición esperando 5 segundos", test:get_wifi_with_5s())
		it("Cuarta petición sin espera", test:get_wifi_without_tmr())
	end)
	
	describe(test.colors("%{green}[#] Set Max Temperature"), function()
    it(test.colors("%{red}[!] should set max temperature correctly"), function()
        local config = test.tables.configs_to_test_numbers.config_40_70
        print("DEBUG: Config values:")
        print("Min Temperature:", config.min_temperature)
        print("Max Temperature:", config.max_temperature)
        print("Max Humidity:", config.max_hum)
        
        local json_value = test.http_request_methods.JSON:encode(config)
        local code = test.http_request_methods:post_and_assert_201("config", json_value)
        assert.are.equal(code, 1)

        local current_config = test.config:get_config()
        assert.are.equal(current_config.max_temperature, 50)
    end)
end)

	describe(test.colors("%{green}[#] Set Humidity Parameters"), function()
		it(test.colors("%{red}[!] should set max humidity correctly"), function()
			local json_value = test.http_request_methods.JSON:encode(test.tables.configs_to_test_numbers.config_40_70)
			local code = test.http_request_methods:post_and_assert_201("config", json_value)
			assert.are.equal(code, 1)

			local current_config = test.config:get_config()
			assert.are.equal(current_config.max_hum, 80)
		end)
	end)

	describe(test.colors("%{green}[#] Set Tray Dates"), function()
		it(test.colors("%{red}[!] should set tray dates correctly"), function()
			local json_value = test.http_request_methods.JSON:encode(test.tables.configs_to_test_numbers.config_tray_dates)
			local code = test.http_request_methods:post_and_assert_201("config", json_value)
			assert.are.equal(code, 1)

			local current_config = test.config:get_config()
			assert.are.equal(current_config.tray_one_date, 1234567891)
			assert.are.equal(current_config.tray_two_date, 1234567892)
			assert.are.equal(current_config.tray_three_date, 1234567893)
		end)

		it(test.colors("%{red}[!] should reject invalid tray dates"), function()
			local json_value = test.http_request_methods.JSON:encode(test.tables.config_to_test_str.noise_in_tray_dates)
			local code = test.http_request_methods:post_and_assert_400("config", json_value)
			assert.are.equal(code, 1)
		end)
	end)

	describe(test.colors("%{green}[#] Set Incubation Period"), function()
		it(test.colors("%{red}[!] should set incubation period correctly"), function()
			local json_value = test.http_request_methods.JSON:encode(test.tables.configs_to_test_numbers
				.config_incubation_period)
			local code = test.http_request_methods:post_and_assert_201("config", json_value)
			assert.are.equal(code, 1)

			local current_config = test.config:get_config()
			assert.are.equal(current_config.incubation_period, 1814400)
		end)
	end)

	describe(test.colors("%{green}[#] Set Incubator Name"), function()
		it(test.colors("%{red}[!] should set incubator name correctly"), function()
			local json_value = test.http_request_methods.JSON:encode(test.tables.config_to_test_str.config_incubator_name)
			local code = test.http_request_methods:post_and_assert_201("config", json_value)
			assert.are.equal(code, 1)

			local current_config = test.config:get_config()
			assert.are.equal(current_config.incubator_name, "incubator_test_01")
		end)

		it(test.colors("%{red}[!] should accept short incubator name"), function()
			local json_value = test.http_request_methods.JSON:encode(test.tables.config_to_test_str.invalid_incubator_name)
			local code = test.http_request_methods:post_and_assert_201("config", json_value)
			assert.are.equal(code, 1)
		end)
	end)

	describe(test.colors("%{green}[#] Validate Hash"), function()
		
		it(test.colors("%{red}[!] should reject invalid hash"), function()
			local json_value = test.http_request_methods.JSON:encode(test.tables.config_to_test_str.config_invalid_hash)
			local code = test.http_request_methods:post_and_assert_400("config", json_value)
			assert.are.equal(code, 1)
		end)

    it(test.colors("%{red}[!] should reject hash longer than 30 characters"), function()
        local json_value = test.http_request_methods.JSON:encode(test.tables.config_to_test_str.long_hash)
        local code = test.http_request_methods:post_and_assert_400("config", json_value)
        assert.are.equal(code, 1)
    end)
		end)

end)


