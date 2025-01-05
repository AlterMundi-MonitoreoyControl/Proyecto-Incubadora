--
-- log.lua
--
-- Copyright (c) 2016 rxi
-- Modified to include NTFY support and Grafana integration
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local log = {
	_version = "0.1.0"
}

-- Configuration options
log.usecolor = true     -- Enable colored output in console
log.outfile = nil       -- File to write logs to (nil for no file output)
log.grafana = true      -- Enable sending logs to Grafana
log.ntfy_enabled = true -- Enable sending notifications through ntfy
log.level = "trace"     -- Default log level
log.x86 = false         -- Platform flag
log.ntfy_url = nil      -- NTFY URL to be set dynamically

-- Define log modes with their colors
local modes = { {
	name = "trace",
	color = "\27[34m" -- Blue
}, {
	name = "debug",
	color = "\27[36m" -- Cyan
}, {
	name = "info",
	color = "\27[32m" -- Green
}, {
	name = "warn",
	color = "\27[33m" -- Yellow
}, {
	name = "error",
	color = "\27[31m" -- Red
}, {
	name = "fatal",
	color = "\27[35m" -- Magenta
}, {
	name = "test",
	color = "\27[30m" -- Black
} }

-- Get file size helper function
local function fsize(file)
	local current = file:seek()  -- Get current position
	local size = file:seek("end") -- Get file size
	file:seek("set", current)    -- Restore position
	return size
end

-- Function to send logs to Grafana
function log.send_to_grafana(message)
	-- Construct the log message with device identifier and timestamp
	local alert_string = "log,device=" .. INICIALES .. " message=\"" .. message .. "\" " ..
			string.format("%.0f", ((time.get()) * 1000000000))

	local token_grafana = "token:e98697797a6a592e6c886277041e6b95"
	local url = SERVER

	local headers = {
		["Content-Type"] = "text/plain",
		["Authorization"] = "Basic " .. token_grafana
	}

	-- Send POST request to Grafana
	http.post(url, {
		headers = headers
	}, alert_string, function(code_return, data_return)
		if (code_return ~= 204) then
			print("Grafana logging error: " .. code_return)
		end
	end)
end

-- Function to send notification through NTFY
function log.ntfy(alert)
	-- Check if NTFY is properly configured
	if not log.ntfy_enabled or not log.ntfy_url then
		print("NTFY not enabled or URL not set")
		return
	end

	local headers = {
		["Content-Type"] = "text/plain"
	}

	-- Send POST request to NTFY
	http.post(log.ntfy_url, {
		headers = headers
	}, alert, function(code_return, _)
		if code_return ~= 200 then
			log.trace("Failed to send notification: " .. code_return)
		else
			log.trace("Notification sent successfully")
		end
	end)
end

-- Function to set the NTFY URL with a given hash
function log.set_ntfy_url(hash)
	if hash then
		log.ntfy_url = "http://ntfy.sh/" .. hash
		print("NTFY URL set to: " .. log.ntfy_url)
	else
		log.ntfy_url = nil
		print("NTFY URL is nil")
	end
end

-- Build log level lookup table
local levels = {}
for i, v in ipairs(modes) do
	levels[v.name] = i
end

-- Rounding function for numbers in log messages
local round = function(x, increment)
	increment = increment or 1
	x = x / increment
	return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end

-- Store original tostring
local _tostring = tostring

-- Override tostring to handle number rounding
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

-- Create log methods for each mode
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

		-- Get debug info and time based on platform
		if log.x86 then
			local info = debug.getinfo(2, "Sl")
			lineinfo = info.short_src .. ":" .. info.currentline
			strtime = os.date("%H:%M:%S")
		else
			lineinfo = " "
			local thismoment = time.getlocal()
			strtime = string.format("%04d-%02d-%02d %02d:%02d:%02d DST:%d",
				thismoment["year"], thismoment["mon"], thismoment["day"],
				thismoment["hour"], thismoment["min"], thismoment["sec"],
				thismoment["dst"])
		end

		-- Output to console with color if enabled
		print(string.format("%s[%-6s%s]%s %s: %s",
			log.usecolor and x.color or "",
			nameupper, strtime,
			log.usecolor and "\27[0m" or "",
			lineinfo,
			msg))

		-- Send error logs to Grafana if enabled
		if log.grafana and nameupper == "ERROR" then
			log.send_to_grafana(string.format("[%-6s%s] %s: %s\n",
				nameupper, strtime, lineinfo, msg))
		end

		-- Send error logs to NTFY if enabled
		if log.ntfy_enabled and log.ntfy_url and nameupper == "ERROR" then
			log.ntfy(string.format("[%-6s%s] %s: %s\n",
				nameupper, strtime, lineinfo, msg))
		end

		-- Write to log file if enabled
		if log.outfile then
			local fp = io.open(log.outfile, "a")
			local str = string.format("[%-6s%s] %s: %s\n",
				nameupper, strtime, lineinfo, msg)
			fp:write(str)
			fp:close()
		end
	end
end

return log
