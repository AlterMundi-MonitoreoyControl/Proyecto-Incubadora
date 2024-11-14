
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

W.station_cfg.ssid = "default_ssid"
W.station_cfg.pwd = "default_pwd"
W.station_cfg.scan_method = "all"



IPADD = nil
IPGW = nil


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

function configwifi()
	print("Running")
	wifi.sta.on("got_ip", wifi_got_ip_event)
	wifi.sta.on("connected", wifi_connect_event)
	wifi.sta.on("disconnected", wifi_disconnect_event)
	wifi.mode(wifi.STATIONAP)
	sta_cfg = {}
	sta_cfg.ip = '192.168.16.10'
	sta_cfg.netmask = '255.255.255.0'
	sta_cfg.gateway = '192.168.16.1'
	sta_cfg.dns = '8.8.8.8'
	wifi.ap.setip(sta_cfg)
	wifi.ap.config({
		ssid = "incubator",
		pwd = "12345678",
		auth = wifi.AUTH_WPA2_PSK
	}, true)
	wifi.ap.on("sta_connected", function(event, info) print("MAC_id" .. info.mac, "Name" .. info.id) end)
	wifi.start()
	W.station_cfg = {}
	W.station_cfg.ssid = SSID
	W.station_cfg.pwd = PASSWORD
	W.station_cfg.scan_method = all
	wifi.sta.config(W.station_cfg, true)
	wifi.sta.sethostname(INICIALES .. "-ESP32")
	wifi.sta.connect()
end -- end function

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
	print(info)
	print(info.reason)
	print(info.ssid)

	if info.reason == 8 then
		-- the station has disassociated from a previously connected AP
		return
	end

	local total_tries = 10
	log.trace("\nWiFi connection to AP(" .. info.ssid .. ") has failed!")
	log.trace("Disconnect reason: " .. info.reason)

	if disconnect_ct == nil then
		disconnect_ct = 1
	else
		disconnect_ct = disconnect_ct + 1
	end -- if end

	if disconnect_ct < total_tries then
		log.trace("Retrying connection...(attempt " .. (disconnect_ct + 1) .. " of " .. total_tries .. ")")
		wifi.sta.connect()
	else
		wifi.sta.disconnect()

		if W.old_ssid and W.old_passwd then
			log.trace("Attempting to connect with previous credentials")
			W:set_new_ssid(W.old_ssid)
			W:set_passwd(W.old_passwd)
			W.station_cfg = {
				ssid = W.old_ssid,
				pwd = W.old_passwd,
				save = true
			}
			wifi.sta.config(W.station_cfg)
			W.old_ssid = nil
			W.old_passwd = nil
		end -- if end 

		log.trace("Reattempting WiFi connection in 10 seconds...")
		mytimer = tmr.create()
		mytimer:register(10000, tmr.ALARM_SINGLE, configwifi)
		mytimer:start()
		disconnect_ct = nil
	end -- else end
end -- function end

------------------------------------------------------------------------------------
-- ! @function W:on_change
-- ! manage the new WiFi conections
-- @param new_config_table            contains the ssid and passwd 
------------------------------------------------------------------------------------
function W:on_change(new_config_table)
	local new_ssid = new_config_table.ssid
	local new_passwd = new_config_table.passwd
	local config_changed = false

	-- Verifica si son diferentes de las actuales
	if new_ssid and new_ssid ~= W.station_cfg.ssid then
		W:set_new_ssid(new_ssid)
		config_changed = true
	end -- if end 

	if new_passwd and new_passwd ~= W.station_cfg.pwd then
		W:set_passwd(new_passwd)
		config_changed = true
	end -- if end

	if config_changed then
		-- save the actual credentials 
		W.old_ssid = W.station_cfg.ssid
		W.old_passwd = W.station_cfg.pwd

		-- update the config and try connect 
		wifi.sta.disconnect()
		W.station_cfg = {
			ssid = W.station_cfg.ssid,
			pwd = W.station_cfg.pwd,
			save = true
		}
		wifi.sta.config(W.station_cfg)
		wifi.sta.connect()
	else
		-- try reconnect
		--wifi.sta.disconnect()
	 	--wifi.sta.connect()
		--return
	end -- else end
end -- function end

configwifi()
log.trace("Connecting to WiFi access point...")


return W
