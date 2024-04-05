--
-- log.lua
--
-- Copyright (c) 2016 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--
local log = {
    _version = "0.1.0"
}

log.usecolor = true
log.outfile = nil
log.grafana = true
log.level = "trace"
log.x86 = false

local modes = {{
    name = "trace",
    color = "\27[34m"
}, {
    name = "debug",
    color = "\27[36m"
}, {
    name = "info",
    color = "\27[32m"
}, {
    name = "warn",
    color = "\27[33m"
}, {
    name = "error",
    color = "\27[31m"
}, {
    name = "fatal",
    color = "\27[35m"
}, {
    name = "test",
    color = "\27[30m"
}}

local function fsize(file)
    local current = file:seek() -- get current position
    local size = file:seek("end") -- get file size
    file:seek("set", current) -- restore position
    return size
end

function log.send_to_grafana(message)

    local alert_string = "log,device=" .. INICIALES .. " message=\"" .. message .. "\" " ..
                             string.format("%.0f", ((time.get()) * 1000000000))

    local token_grafana = "token:e98697797a6a592e6c886277041e6b95"
    local url = SERVER

    local headers = {
        ["Content-Type"] = "text/plain",
        ["Authorization"] = "Basic " .. token_grafana
    }

    http.post(url, {
        headers = headers
    }, alert_string, function(code_return, data_return)
        if (code_return ~= 204) then
            print(" " .. code_return)
        end
    end) -- * post function end
end -- * send_data_grafana end

local levels = {}
for i, v in ipairs(modes) do
    levels[v.name] = i
end

local round = function(x, increment)
    increment = increment or 1
    x = x / increment
    return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end

local _tostring = tostring

local tostring = function(...)
    local t = {}
    for i = 1, select('#', ...) do
        local x = select(i, ...)
        if type(x) == "number" then
            x = round(x, .01)
        end
        t[#t + 1] = _tostring(x)
    end
    return table.concat(t, " ")
end

for i, x in ipairs(modes) do
    local nameupper = x.name:upper()
    log[x.name] = function(...)

        -- Return early if we're below the log level
        if i < levels[log.level] then
            return
        end

        local msg = tostring(...)
        local strtime = " "
        local lineinfo = " "
        if log.x86 then
            local info = debug.getinfo(2, "Sl")
            lineinfo = info.short_src .. ":" .. info.currentline
            strtime = os.date("%H:%M:%S")
        else
            lineinfo = " "
            local thismoment = time.getlocal()
            strtime = string.format("%04d-%02d-%02d %02d:%02d:%02d DST:%d", thismoment["year"], thismoment["mon"], thismoment["day"],
            thismoment["hour"], thismoment["min"], thismoment["sec"], thismoment["dst"])
        end

        -- Output to console
        print(string.format("%s[%-6s%s]%s %s: %s", log.usecolor and x.color or "", nameupper, strtime,
            log.usecolor and "\27[0m" or "", lineinfo, msg))

        -- Output to grafana
        if log.grafana then
            log.send_to_grafana(string.format("[%-6s%s] %s: %s\n", nameupper, strtime, lineinfo, msg))
        end

        -- Output to log file
        if log.outfile then
            local fp = io.open(log.outfile, "a")
            local str = string.format("[%-6s%s] %s: %s\n", nameupper, strtime, lineinfo, msg)
            fp:write(str)
            fp:close()
        end

    end
end

return log
