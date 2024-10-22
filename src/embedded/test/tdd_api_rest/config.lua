local tables = require("tables") 
local http_request_methods = require("http_request_methods")
local colors = require("ansicolors")

local config = {}

function config:get_config()
    local body = http_request_methods.http.request(http_request_methods.apiendpoint .. "config")
    local body_table = http_request_methods.JSON:decode(body)

    print(string.format(colors([[

    %{green}%{underline}[#] Get Actual Config:%{reset}
    %{red}BODY:		
    %s
    ]]), http_request_methods.JSON:encode_pretty(body_table)))

    return body_table
end

function config:get_actual()
    local body = http_request_methods.http.request(http_request_methods.apiendpoint .. "actual")
    local body_table = http_request_methods.JSON:decode(body)

    print(string.format(colors([[

    %{green}%{underline}[#] Actual Temperature, Humidity and Pressure:%{reset}
    %{red}BODY:		
    %s
    ]]), http_request_methods.JSON:encode_pretty(body_table)))

    return body_table
end

function config:restore_default_config()
    local default_config = tables.default_config
    local body = http_request_methods.JSON:encode(default_config)
    return http_request_methods:post_and_assert_201("config", body)
end

function config:assert_defconfig()
    local current_config = self:get_config()

    print(string.format(colors([[

    %{magenta}%{underline}[#] Assert Default Config:%{reset}
    BODY: %s
    ]]), http_request_methods.JSON:encode_pretty(current_config)))

    for key, expected_value in pairs(tables.default_config) do
        http_request_methods.assert.are.equal(current_config[key], expected_value, 
            string.format("Error: %s no coincide", key))
    end

    return current_config
end

return config
