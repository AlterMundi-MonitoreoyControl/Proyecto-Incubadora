config = {
    tables = require("tables"),
    http_request_methods = require("http_request_methods"),
    colors = require("ansicolors")
}

function config:get_config()
    local body, code, _, _ = http_request_methods.http.request(
                                 http_request_methods.apiendpoint .. "config")
    local body_table = http_request_methods.JSON:decode(body)
    local pretty_json = http_request_methods.JSON:encode_pretty(body_table)
    print(string.format(self.colors([[

  %{green}%{underline}[#] Get actual Config:%{reset}

  %{red}BODY:		

  %s


  %{green}%{underline}RESPONSE CODE: %s	
]]), pretty_json, code))
    print('\n\n\n')

    return code
end

function config:get_actual()
    local body, code, _, _, _ = http_request_methods.http.request(
                                    http_request_methods.apiendpoint .. "actual")
    http_request_methods.assert.are.equal(code, 200)
    local body_table = http_request_methods.JSON:decode(body)
    local pretty_json = http_request_methods.JSON:encode_pretty(body_table)
    print(string.format(self.colors([[

  %{green}%{underline}[#] Actual Temperature,Humidity and pressure:%{reset}

  %{red}BODY:		

  %s


  %{green}%{underline}RESPONSE CODE: %s	
]]), pretty_json, code))
    print('\n\n\n')
    return code
end

function config:get_wifi_with_error()
    local body, code, _, _, message = http_request_methods.http.request(
                                          http_request_methods.apiendpoint ..
                                              "wifi")
    http_request_methods.inspect(
        print("\nBody de la petición GET: \n " .. body))
    http_request_methods.assert.are.equal(code, 200,
                                          "La primera petición debería devolver un error")
end

function config:get_wifi()
    local body, code, _, status, _ = http_request_methods.http.request(
                                         http_request_methods.apiendpoint ..
                                             "wifi")
    print(code, status, body)
    local lua_value = http_request_methods.JSON:decode(body) -- decode example
    print(lua_value.message)
    http_request_methods.assert.are.equal(lua_value.message, "success")
end

function config:get_wifi_with_5s()
    os.execute("sleep 5")
    local body, code, _, _, message = http_request_methods.http.request(
                                          http_request_methods.apiendpoint ..
                                              "wifi")
    http_request_methods.assert.are.equal(code, 200,
                                          "Error en la tercera petición GET")
    http_request_methods.inspect(print(
                                     "\nBody de la tercera petición GET : \n " ..
                                         body))
end

function config:get_wifi_without_tmr()
    local body, code, _, _, message = http_request_methods.http.request(
                                          http_request_methods.apiendpoint ..
                                              "wifi")
    http_request_methods.assert.are.equal(code, 200,
                                          "Error en la cuarta petición GET")
    http_request_methods.inspect(print(
                                     "\nBody de la cuarta petición GET: \n " ..
                                         body))
end

function config:set_config_ok()
    -- default config
    local default_config = config:assert_defconfig()

    -- save before change config
    local previous_config = config.http_request_methods:get_and_assert_200(
                                "config")

    local success, _ = pcall(function()
        config.http_request_methods:post_and_assert_201("config", self.tables
                                                            .configs_to_test_numbers
                                                            .config_40_50)

        -- waiting for the apply
        os.execute("sleep 1")

        -- get before change confing
        local new_config = config.http_request_methods:get_and_assert_200(
                               "config")

        -- check the changes
        http_request_methods.assert.are.equal(new_config.max_temperature, 50,
                                              "Error: max_temperature no es igual a 30")
        http_request_methods.assert.are.equal(new_config.min_temperature, 40,
                                              "Error: min_temperature no es igual a 40")
        http_request_methods.assert.are.equal(new_config.rotation_duration,
        3600000,
                                              "Error: rotation_duration no es igual a 3500000")
        http_request_methods.assert.are.equal(new_config.rotation_period, 5000,
                                              "Error: rotation_period no es igual a 5000")
        http_request_methods.assert.are.equal(new_config.ssid, "incubator",
                                              "Error: ssid no coincide")
        http_request_methods.assert.are.equal(new_config.passwd, "12345678",
                                              "Error: passwd no coincide")
    end)

    -- restore the config
    config.http_request_methods:post_and_assert_201("config", previous_config)

    if success then
        http_request_methods.inspect(print("No hubo errores en el cambio"))
    end

    -- restore default configg
    config.http_request_methods:post_and_assert_201("config",
                                                    http_request_methods.JSON:encode(
                                                        default_config))
    config:assert_defconfig()
end

function config:set_max_fail()
    default_config = config:assert_defconfig()
    local body = config.http_request_methods:post_and_assert_400("config",
                                                                 self.tables
                                                                     .configs_to_test_numbers
                                                                     .config_50_40)
    default_config = config:assert_defconfig()

    return body
end

function config:set_min_rotation_time_fail()
    default_config = config:assert_defconfig()

    local body = config.http_request_methods:post_and_assert_400("config",
                                                                 self.tables
                                                                     .configs_to_test_numbers
                                                                     .config_1_40_50)
    default_config = config:assert_defconfig()

    return body
end

function config:set_negative_temps_value_fails()
    default_config = config:assert_defconfig()
    local body_negative_1 = config.http_request_methods:post_and_assert_400(
                                "config", self.tables.configs_to_test_numbers
                                    .config_m10_50)
    default_config = config:assert_defconfig()
    local body_negative_2 = config.http_request_methods:post_and_assert_400(
                                "config", self.tables.configs_to_test_numbers
                                    .config_10_m10)
    default_config = config:assert_defconfig()

    return body_negative_1, body_negative_2
end

function config:set_noise_in_parameters()
    default_config = config:assert_defconfig()
    body_noise_1 = config.http_request_methods:post_and_assert_400("config",
                                                                   self.tables
                                                                       .config_to_test_str
                                                                       .noise_in_min_temp)
    default_config = config:assert_defconfig()
    body_noise_2 = config.http_request_methods:post_and_assert_400("config",
                                                                   self.tables
                                                                       .config_to_test_str
                                                                       .noise_in_rotation_duration)
    default_config = config:assert_defconfig()
    body_noise_3 = config.http_request_methods:post_and_assert_400("config",
                                                                   self.tables
                                                                       .config_to_test_str
                                                                       .noise_in_max_temperature)
    default_config = config:assert_defconfig()

    return body_noise_1, body_noise_2, body_noise_3
end

function config:assert_defconfig()
    local body = config.http_request_methods:get_and_assert_200("config")
    local default_config = http_request_methods.JSON:decode(body)
    local body_table = http_request_methods.JSON:decode(body)
    local pretty_json = http_request_methods.JSON:encode_pretty(body_table)

    print(string.format(self.colors([[

  %{magenta}%{underline}[#] Setting Default Config:%{reset}
  
  %{cyan}BODY:		

  %s

]]), pretty_json))

    http_request_methods.assert.are.equal(default_config.min_temperature, 37.3)
    http_request_methods.assert.are.equal(default_config.max_temperature, 37.8)
    http_request_methods.assert.are
        .equal(default_config.rotation_duration, 5000)
    http_request_methods.assert.are
        .equal(default_config.rotation_period, 3600000)
    http_request_methods.assert.are.equal(default_config.ssid, "incubator")
    http_request_methods.assert.are.equal(default_config.passwd, "1234554321")

    return default_config
end

function config:restore_config()
    local default_config_body = config.http_request_methods:post_and_assert_201(
                                    "config", self.tables.set_default_config)
    return default_config_body
end

return config
