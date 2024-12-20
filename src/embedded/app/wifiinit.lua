local log = require('log')
require("credentials")

------------------------------------------------------------------------------------
--
-- ! @module w
-- ! WiFi management module for ESP32
-- ! Handles both AP and Station mode configurations
--
------------------------------------------------------------------------------------

local w = {
	-- Configuration tables
	sta_cfg = {
		ip = '192.168.16.10',
		netmask = '255.255.255.0',
		gateway = '192.168.16.1',
		dns = '8.8.8.8'
	},
	ap_config = {
		ssid = wifi.sta.getmac(),
		pwd = "12345678",
		auth = wifi.AUTH_WPA2_PSK
	},
	station_cfg = {
		ssid = "default_ssid",
		pwd = "default_pwd",
		scan_method = "all"
	},
	-- State management
	online = 0,
	connection_timeout = 10000, -- 10 seconds
	max_retries = 10,
	current_retry = 0,
	reconnect_timer = nil,
	validation_timer = nil,
	status = {
		is_transitioning = false,
		last_change_time = 0,
		validation_timeout = 30000, -- 30 seconds to validate new connection
		pending_fallback = false
	}
}

------------------------------------------------------------------------------------
-- Helper Functions
------------------------------------------------------------------------------------

local function format_ip(ip)
	return string.format(
		"IP: %s\nNetmask: %s\nGateway: %s\nDNS: %s",
		ip.ip or "N/A",
		ip.netmask or "N/A",
		ip.gw or "N/A",
		w.sta_cfg.dns
	)
end

function w:reset_state()
	self.current_retry = 0
	self.status.is_transitioning = false
	self.status.pending_fallback = false
	if self.validation_timer then
		self.validation_timer:unregister()
	end
	if self.reconnect_timer then
		self.reconnect_timer:unregister()
	end
end

function w:start_validation_timer()
	if self.validation_timer then
		self.validation_timer:unregister()
	end

	self.validation_timer = tmr.create()
	self.validation_timer:alarm(self.status.validation_timeout, tmr.ALARM_SINGLE, function()
		if self.status.is_transitioning and self.online == 0 then
			log.trace("New credentials validation failed, reverting to previous configuration...")
			self.status.pending_fallback = true

			if self.old_ssid and self.old_passwd then
				self:set_new_ssid(self.old_ssid)
				self:set_passwd(self.old_passwd)
				self.old_ssid = nil
				self.old_passwd = nil
				self:reset_state()
				self:connect()
			end
		end
	end)
end

------------------------------------------------------------------------------------
-- Core WiFi Functions
------------------------------------------------------------------------------------

function w:set_new_ssid(new_ssid)
	if type(new_ssid) == "string" and new_ssid ~= "" then
		self.station_cfg.ssid = new_ssid
		return true
	end
	return false
end

function w:set_passwd(new_passwd)
	if type(new_passwd) == "string" then
		self.station_cfg.pwd = new_passwd
		return true
	end
	return false
end

function w:schedule_reconnect()
	if self.reconnect_timer then
		self.reconnect_timer:unregister()
	end

	-- Exponential backoff for reconnection attempts
	local delay = math.min(self.connection_timeout * math.pow(1.5, self.current_retry - 1), 30000)

	self.reconnect_timer = tmr.create()
	self.reconnect_timer:alarm(delay, tmr.ALARM_SINGLE, function()
		self:connect()
	end)
end

function w:connect()
	wifi.sta.disconnect()
	wifi.sta.config(self.station_cfg, true)
	wifi.sta.connect()
end

------------------------------------------------------------------------------------
-- Event Handlers
------------------------------------------------------------------------------------

local function wifi_connect_event(ev, info)
	w.current_retry = 0
	log.trace(string.format("Connection to AP %s established!", tostring(info.ssid)))
	log.trace("Waiting for IP address...")
end

local function wifi_got_ip_event(ev, info)
	w.online = 1

	-- If this was a credential change and it succeeded
	if w.status.is_transitioning then
		w:reset_state()
		w.old_ssid = nil
		w.old_passwd = nil
		log.trace("New credentials validated successfully")
	end

	log.trace("Network Configuration:")
	log.trace(format_ip(info))

	-- Setup NTP if not enabled
	if not time.ntpenabled() then
		time.initntp("pool.ntp.org")
		if TIMEZONE then
			time.settimezone(TIMEZONE)
		end
	end

	log.trace("System is online and ready!")
end

local function wifi_disconnect_event(ev, info)
	w.online = 0

	log.trace(string.format("WiFi disconnected from AP(%s). Reason: %s",
		info.ssid or "unknown",
		info.reason or "unknown"))

	-- Don't retry if we're waiting for fallback
	if w.status.pending_fallback then
		return
	end

	if w.current_retry < w.max_retries then
		w.current_retry = w.current_retry + 1
		log.trace(string.format("Attempting reconnection... (%d/%d)",
			w.current_retry,
			w.max_retries))
		w:schedule_reconnect()
	else
		if w.old_ssid and w.old_passwd and not w.status.is_transitioning then
			log.trace("Maximum retries reached. Attempting to connect with previous credentials...")
			w:set_new_ssid(w.old_ssid)
			w:set_passwd(w.old_passwd)
			w.old_ssid = nil
			w.old_passwd = nil
			w:reset_state()
			w:connect()
		else
			log.trace("Maximum retries reached. Please check WiFi configuration.")
			w:reset_state()
		end
	end
end

------------------------------------------------------------------------------------
-- Initialization and Configuration
------------------------------------------------------------------------------------

function w:init()
	-- Setup event handlers
	wifi.sta.on("got_ip", wifi_got_ip_event)
	wifi.sta.on("connected", wifi_connect_event)
	wifi.sta.on("disconnected", wifi_disconnect_event)

	-- Configure AP and Station mode
	wifi.mode(wifi.STATIONAP)
	wifi.ap.setip(self.sta_cfg)
	wifi.ap.config(self.ap_config, true)

	-- Setup AP connection handler
	wifi.ap.on("sta_connected", function(event, info)
		log.trace(string.format("Device connected to AP - MAC: %s, ID: %s", info.mac, info.id))
	end)

	-- Start WiFi
	wifi.start()

	-- Configure station
	if SSID and PASSWORD then
		self.station_cfg.ssid = SSID
		self.station_cfg.pwd = PASSWORD
	end

	self:connect()
end

function w:on_change(new_config_table)
	if type(new_config_table) ~= "table" then return end
	if self.status.is_transitioning then
		log.trace("Configuration change already in progress, please wait...")
		return
	end

	if new_config_table.incubator_name then
		self.ap_config.ssid = new_config_table.incubator_name
		local success = wifi.ap.config(self.ap_config, true)
		if not success then
			log.error("Failed to update AP SSID")
		else
			log.trace(string.format("Successfully changed AP SSID to: %s", new_config_table.incubator_name))
		end
	end

	local config_changed = false
	self.status.is_transitioning = true


	-- Backup current configuration before any changes
	if new_config_table.ssid and new_config_table.ssid ~= self.station_cfg.ssid then
		self.old_ssid = self.station_cfg.ssid
		self.old_passwd = self.station_cfg.pwd
		config_changed = self:set_new_ssid(new_config_table.ssid)
	end

	if new_config_table.passwd and new_config_table.passwd ~= self.station_cfg.pwd then
		if not self.old_ssid then
			self.old_ssid = self.station_cfg.ssid
			self.old_passwd = self.station_cfg.pwd
		end
		config_changed = self:set_passwd(new_config_table.passwd) or config_changed
	end

	if config_changed then
		self:reset_state()
		self.status.is_transitioning = true -- Reset by connect success or validation timeout
		self:connect()
		self:start_validation_timer()
	else
		self.status.is_transitioning = false
	end
end

-- Initialize the WiFi connection
w:init()

return w
