
log = require ('log')

W = {
	sta_cfg = {},
	ap_config = {},
	station_cfg = {},
	ONLINE = 0

}

W.sta_cfg.ip = '192.168.16.10'
W.sta_cfg.netmask = '255.255.255.0'
W.sta_cfg.gateway = '192.168.16.1'
W.sta_cfg.dns = '8.8.8.8'

W.ap_config.ssid = "incubator"
W.ap_config.pwd = "12345678"
W.ap_config.auth = wifi.AUTH_WPA2_PSK

W.station_cfg.ssid = ""
W.station_cfg.pwd = ""
W.station_cfg.scan_method = "all"



IPADD = nil
IPGW = nil

--------------------------------------
-- @function W:load_saved_config	modify the station ssid WiFi
-- -----------------------------------
function W:load_saved_config()
	if file.exists("config.json") then
			local f = io.open("config.json", "r")
			if f then
					local config = sjson.decode(f:read("*a"))
					f:close()
					-- use default name or create another one
					W.ap_config.ssid = config.incubator_name or string.format("incubadora-%s", wifi.sta.getmac())
					-- Guardar la configuración inicial
					W.ap_config.pwd = "12345678"
					W.ap_config.auth = wifi.AUTH_WPA2_PSK
					return true
			end
	end
	-- if file dnt existe 
	W.ap_config.ssid = string.format("incubadora-%s", wifi.sta.getmac())
	W.ap_config.pwd = "12345678"
	W.ap_config.auth = wifi.AUTH_WPA2_PSK
	return false
end

W:load_saved_config()
W.ap_config.pwd = "12345678"
W.ap_config.auth = wifi.AUTH_WPA2_PSK

-- -----------------------------------
-- @function set_new_ssid	modify the station ssid WiFi
-- -----------------------------------
function W:update_ap_name(new_name)
	if new_name and type(new_name) == "string" then
			-- Guardar el nombre anterior por si acaso
			local old_name = W.ap_config.ssid
			
			-- Actualizar la configuración
			W.ap_config.ssid = new_name
			
			-- Crear un timer para la reconexión
			local reconnect_timer = tmr.create()
			
			-- Función de reconexión segura
			local function safe_reconnect()
					-- Configurar el modo AP
					wifi.mode(wifi.STATIONAP)
					
					-- Mantener la configuración existente y solo actualizar el SSID
					local ap_config = {
							ssid = new_name,
							pwd = W.ap_config.pwd,
							auth = W.ap_config.auth
					}
					
					-- Aplicar la configuración del AP
					if not pcall(function()
							wifi.ap.config(ap_config)
							wifi.ap.setip(W.sta_cfg)
					end) then
							-- Si falla, intentar restaurar la configuración anterior
							W.ap_config.ssid = old_name
							wifi.ap.config({
									ssid = old_name,
									pwd = W.ap_config.pwd,
									auth = W.ap_config.auth
							})
							return false
					end
					
					-- Si hay una conexión de estación activa, mantenerla
					if W.station_cfg.ssid and W.station_cfg.ssid ~= "" then
							wifi.sta.connect()
					end
					
					return true
			end
			
			-- Desconectar suavemente
			wifi.mode(wifi.NULLMODE)
			
			-- Esperar un momento y reconectar
			reconnect_timer:alarm(1000, tmr.ALARM_SINGLE, function()
					return safe_reconnect()
			end)
			
			return true
	end
	return false
end

-- -----------------------------------
-- @function set_new_ssid	modify the actual ssid WiFi
-- -----------------------------------
function W:set_new_ssid(new_ssid)
	if new_ssid ~= nil then
		W.station_cfg.ssid = new_ssid
		return true
	else
		return false
	end
end

-------------------------------------
-- @function set_passwd	modify the actual ssid WiFi
-------------------------------------
function W:set_passwd(new_passwd)
	if new_passwd ~= nil then
		W.station_cfg.pwd = new_passwd
		return true
	else
		return false
	end
end ---------------------------------------------------------------------------

--
-- ! @function startup                   opens init.lua if exists, otherwise,
-- !                                     prints "running"
--
------------------------------------------------------------------------------------

function startup()
	if file.open("init.lua") == nil then
		print("init.lua deleted or renamed")
	else
		print("Running")
		file.close("init.lua")
		-------------------------------------
		-- the actual application is stored in 'application.lua'
		-------------------------------------
		dofile("application.lua")
	end -- end else
end  -- end if

------------------------------------------------------------------------------------
--
-- ! @function configwifi                sets the wifi configurations
-- !                                     uses SSID and PASSWORD from credentials.lua
--
------------------------------------------------------------------------------------
W:load_saved_config()

function configwifi()
	print("Running")
	wifi.sta.on("got_ip", wifi_got_ip_event)
	wifi.sta.on("connected", wifi_connect_event)
	wifi.sta.on("disconnected", wifi_disconnect_event)
	wifi.mode(wifi.STATIONAP)
	
	-- Use the current AP configuration instead of hardcoded values
	wifi.ap.setip(W.sta_cfg)
	wifi.ap.config({
			ssid = W.ap_config.ssid,  -- Use the stored SSID
			pwd = W.ap_config.pwd,
			auth = W.ap_config.auth
	}, true)

	wifi.ap.on("sta_connected", function(event, info) 
			print("MAC_id" .. info.mac, "Name" .. info.id) 
	end)
	wifi.start()
	station_cfg = {}
	station_cfg.ssid = SSID
	station_cfg.pwd = PASSWORD
	station_cfg.scan_method = all
	wifi.sta.config(station_cfg, true)
	wifi.sta.sethostname(INICIALES .. "-ESP32")
	wifi.sta.connect()
end
------------------------------------------------------------------------------------
--
-- ! @function wifi_connect_event        establishes connection
--
-- ! @param ev                           event status
-- ! @param info                         net information
--
------------------------------------------------------------------------------------

function wifi_connect_event(ev, info)
	log.trace(string.format("conecction to AP %s established!", tostring(info.ssid)))
	log.trace("Waiting for IP address...")

	if disconnect_ct ~= nil then
		disconnect_ct = nil
	end -- end if
end  -- end function

------------------------------------------------------------------------------------
--
-- ! @function wifi_got_ip_event         prints net ip, netmask and gw
--
-- ! @param ev                           event status
-- ! @param info                         net information
-- !
------------------------------------------------------------------------------------

function wifi_got_ip_event(ev, info)
	-------------------------------------
	-- Note: Having an IP address does not mean there is internet access!
	-- Internet connectivity can be determined with net.dns.resolve().
	-------------------------------------
	W.ONLINE = 1
	IPADD = info.ip
	IPGW = info.gw
	log.trace("NodeMCU IP config:", info.ip, "netmask", info.netmask, "gw", info.gw)
	log.trace("Startup will resume momentarily, you have 3 seconds to abort.")
	log.trace("Waiting...")
	print(time.get(), " hora vieja")
	if (not time.ntpenabled()) then
		time.initntp("pool.ntp.org")
	end
	print(time.get(), " hora nueva")
	time.settimezone(TIMEZONE)
end -- end function

------------------------------------------------------------------------------------
--
-- ! @function wifi_disconnect_event     when not able to connect, prints why
--
-- ! @param ev                           event status
-- ! @param info                         net information
--
------------------------------------------------------------------------------------
function wifi_disconnect_event(ev, info)
	W.ONLINE = 0
	log.trace("Disconnect event: " .. (info.reason or "unknown reason"))

	if info.reason == 8 then
			-- the station has disassociated from a previously connected AP
			return
	end

	local total_tries = 10
	log.trace("\nWiFi connection to AP(" .. (info.ssid or "unknown") .. ") has failed!")
	log.trace("Disconnect reason: " .. (info.reason or "unknown"))

	if disconnect_ct == nil then
			disconnect_ct = 1
	else
			disconnect_ct = disconnect_ct + 1
	end

	if disconnect_ct < total_tries then
			log.trace("Retrying connection...(attempt " .. (disconnect_ct + 1) .. " of " .. total_tries .. ")")
			local status, err = pcall(wifi.sta.connect)
			if not status then
					log.error("Connection retry failed: " .. tostring(err))
			end
	else
			-- Reset disconnect counter
			disconnect_ct = nil
			
			-- Safe mode switch
			wifi.mode(wifi.NULLMODE)
			
			-- Attempt recovery with old credentials if available
			if W.old_ssid and W.old_passwd then
					log.trace("Attempting to connect with previous credentials")
					W:set_new_ssid(W.old_ssid)
					W:set_passwd(W.old_passwd)
					station_cfg = {
							ssid = W.old_ssid,
							pwd = W.old_passwd,
							save = true
					}
					
					tmr.create():alarm(1000, tmr.ALARM_SINGLE, function()
							wifi.mode(wifi.STATIONAP)
							local status = wifi.sta.config(station_cfg, true)
							if status then
									wifi.sta.connect()
							else
									log.error("Failed to configure WiFi with old credentials")
							end
					end)
					
					W.old_ssid = nil
					W.old_passwd = nil
			end

			log.trace("Reattempting WiFi connection in 10 seconds...")
			local mytimer = tmr.create()
			mytimer:register(10000, tmr.ALARM_SINGLE, configwifi)
			mytimer:start()
	end
end


------------------------------------------------------------------------------------
-- ! @function W:on_change
-- ! manage the new WiFi conections
-- @param new_config_table            contains the ssid and passwd 
------------------------------------------------------------------------------------
function W:on_change(new_config_table)
	local new_ssid = new_config_table.ssid
	local new_passwd = new_config_table.passwd
	local config_changed = false

	-- Verify if credentials are different from current ones
	if new_ssid and new_ssid ~= W.station_cfg.ssid then
			W:set_new_ssid(new_ssid)
			config_changed = true
	end

	if new_passwd and new_passwd ~= W.station_cfg.pwd then
			W:set_passwd(new_passwd)
			config_changed = true
	end

	if config_changed then
			-- Save the actual credentials 
			W.old_ssid = W.station_cfg.ssid
			W.old_passwd = W.station_cfg.pwd

			-- Implement safe disconnect and reconnect
			local function safe_reconnect()
					-- Update the config first
					station_cfg = {
							ssid = W.station_cfg.ssid,
							pwd = W.station_cfg.pwd,
							save = true
					}
					
					-- Set WiFi mode to NULL before reconfiguring
					wifi.mode(wifi.NULLMODE)
					
					-- Wait a brief moment before reconfiguring
					tmr.create():alarm(1000, tmr.ALARM_SINGLE, function()
							-- Set mode back to STATIONAP
							wifi.mode(wifi.STATIONAP)
							
							-- Configure AP
							wifi.ap.config(W.ap_config, true)
							wifi.ap.setip(W.sta_cfg)
							
							-- Configure and connect station
							local status = wifi.sta.config(station_cfg, true)
							if status then
									wifi.sta.connect()
							else
									log.error("Failed to configure WiFi station")
							end
					end)
			end
        -- Attempt safe reconnect with error handling
        local status, err = pcall(safe_reconnect)
        if not status then
            log.error("WiFi reconfiguration failed: " .. tostring(err))
            -- Attempt recovery by reverting to old credentials if available
            if W.old_ssid and W.old_passwd then
                W:set_new_ssid(W.old_ssid)
                W:set_passwd(W.old_passwd)
                safe_reconnect()
            end
        end
    end
end

configwifi()
log.trace("Connecting to WiFi access point...")


return W
