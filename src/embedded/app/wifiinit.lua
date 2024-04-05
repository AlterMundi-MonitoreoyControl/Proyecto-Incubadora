-- load credentials, 'SSID' and 'PASSWORD' declared and initialize in there

-------------------------------------
-- global variables come from credentials.lua
-------------------------------------

dofile("credentials.lua")
ONLINE = 0
IPADD = nil
IPGW = nil

------------------------------------------------------------------------------------
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
end -- end if

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
	sta_cfg={}
	sta_cfg.ip='192.168.16.10'
	sta_cfg.netmask='255.255.255.0'
	sta_cfg.gateway='192.168.16.1'
	sta_cfg.dns='8.8.8.8'
	wifi.ap.setip(sta_cfg)
	wifi.ap.config({
		ssid = "incubator",
		pwd = "12345678",
		auth=wifi.AUTH_WPA2_PSK
	},true)
	wifi.ap.on("sta_connected", function(event, info) print("MAC_id"..info.mac,"Name"..info.id) end)
	wifi.start()
	station_cfg = {}
	station_cfg.ssid = SSID
	station_cfg.pwd = PASSWORD
	station_cfg.scan_method = all
	wifi.sta.config(station_cfg,true)
    wifi.sta.sethostname(INICIALES.."-ESP32")
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

function wifi_connect_event (ev, info)
	print(string.format("conecction to AP %s established!", tostring(info.ssid)))
	print("Waiting for IP address...")
	
	if disconnect_ct ~= nil then 
		
		disconnect_ct = nil 
	
	end -- end if

end -- end function

------------------------------------------------------------------------------------
--
-- ! @function wifi_got_ip_event         prints net ip, netmask and gw
--
-- ! @param ev                           event status
-- ! @param info                         net information
-- ! 
------------------------------------------------------------------------------------

function wifi_got_ip_event (ev, info)
	-------------------------------------
	-- Note: Having an IP address does not mean there is internet access!
	-- Internet connectivity can be determined with net.dns.resolve().
	-------------------------------------
	ONLINE = 1
	IPADD = info.ip
	IPGW = info.gw
	print("NodeMCU IP config:", info.ip, "netmask", info.netmask, "gw", info.gw)
	print("Startup will resume momentarily, you have 3 seconds to abort.")
	print("Waiting...")
	print(time.get(), " hora vieja")
	if(not time.ntpenabled())then
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
function wifi_disconnect_event (ev, info)
	ONLINE = 0
	print(info)
	print(info.reason)
	print(info.ssid)
	if info.reason == 8 then
		-------------------------------------
		--the station has disassociated from a previously connected AP
		-------------------------------------
		return
	end -- end function

	------------------------------------------------------------------------------------
	-- total_tries: how many times the station will attempt to connect to the AP. Should consider AP reboot duration.
	------------------------------------------------------------------------------------
	local total_tries = 10
	print("\nWiFi connection to AP(" .. info.ssid .. ") has failed!")

	------------------------------------------------------------------------------------
	-- There are many possible disconnect reasons, the following iterates through
	-- the list and returns the string corresponding to the disconnect reason.
	------------------------------------------------------------------------------------
	print("Disconnect reason: " .. info.reason)
	if disconnect_ct == nil then
		disconnect_ct = 1
	else
		disconnect_ct = disconnect_ct + 1
	end -- end if
	wifi.sta.connect()

	if disconnect_ct < total_tries then
		print("Retrying connection...(attempt " .. (disconnect_ct + 1) .. " of " .. total_tries .. ")")
	else
		wifi.sta.disconnect()
		------------------------------------------------------------------------------------
		--
		-- ! @function wifi.sta.scan         prints avaliable networks
		--
		-- ! @param err                      when scan fails shows the error
		-- ! @param arr                      lists the avaliable networks
		--
		------------------------------------------------------------------------------------
		wifi.sta.scan({ hidden = 1 }, 
			function(err,arr)
				if err then
					print ("Scan failed:", err)
				else
					print(string.format("%-26s","SSID"),"Channel BSSID              RSSI Auth Bandwidth")
					for i,ap in ipairs(arr) do
						print(string.format("%-32s",ap.ssid),ap.channel,ap.bssid,ap.rssi,ap.auth,ap.bandwidth)
					end -- end for
				print("-- Total APs: ", #arr)
				end -- end if
			end) -- end function
		
		print("Aborting connection to AP!")
		mytimer = tmr.create()
		mytimer:register(10000, tmr.ALARM_SINGLE, configwifi)
		mytimer:start()
		disconnect_ct = nil
	end -- end if
end -- end function

configwifi()
print("Connecting to WiFi access point...")
