-----------------------------------------------------------------------------
--  This is the reference implementation to simulate the M.
--  this model implements an icubator whos ambient temperatura is always
--  below the control temperature. It also suposes tha when you turn on actuators
--  variables change.
--
-- Copyright (c) 2023  Javier Jorge <jjorge@inti.gob.ar>
-- todo: add jere annie santi ...
-- Copyright (c) 2023  Instituto Nacional de Tecnología Industrial
-- Copyright (C) 2023  Asociación Civil Altermundi <info@altermundi.net>
--
--  SPDX-License-Identifier: AGPL-3.0-only

-----------------------------------------------------------------------------
credentials = require('credentials')

local M = {
	name                   = ..., -- module name, upvalue from require('module-name')
	model                  = nil, -- M model:
	resistor               = false,
	humidifier             = false,
	rotation               = false,
	temperature            = 99.9, -- integer value of temperature [0.01 C]
	pressure               = 0, -- integer value of preassure [Pa]=[0.01 hPa]
	humidity               = 0, -- integer value of rel.humidity [0.01 %]
	is_testing             = false,
	max_temp               = 37.8,
	min_temp               = 37.3,
	is_sensorok            = false,
	is_simulate_temp_local = false,
	rotation_duration      = 5000, -- time in ms
	rotation_period        = 3600000, -- time in ms
	tray_one_date          = 1234567890,
	tray_two_date          = 1234567890,
	tray_three_date        = 1234567890,
	incubation_period      = 1234567890,
	hash                   = 12345
}

_G[M.name] = M

local sensor = require('bme280')

function M.startbme()
	if sensor.init(GPIOBMESDA, GPIOBMESCL, true) then
		M.is_sensorok = true
	else
		M.is_sensorok = false
	end
end

function M.init_values()
	M.startbme()
	gpio.config({ gpio = { GPIOVOLTEO, GPIORESISTOR, 13, 12 }, dir = gpio.OUT })
	gpio.set_drive(13, gpio.DRIVE_3)
	gpio.set_drive(GPIOVOLTEO, gpio.DRIVE_3)
	gpio.set_drive(GPIORESISTOR, gpio.DRIVE_3)
	gpio.set_drive(12, gpio.DRIVE_3)
	gpio.write(13, 1)
	gpio.write(GPIOVOLTEO, 1)
	gpio.write(GPIORESISTOR, 1)
	gpio.write(12, 1)
end -- end function

-------------------------------------
-- @function enable_testing 	Enables testing mode asserting correct M funcioning
--
-- @param min 								is equal to the minimum temperature to test
-- @param max 								is equal to the maximum temperature to test
-------------------------------------
function M.enable_testing(simulatetemp)
	M.is_testing = true;
	M.is_simulate_temp_local = simulatetemp
end --end function

-------------------------------------
-- simulates a change in sensors acording to actuators and returns sensor readings
--
-- @returns temperature, humidity, pressure
-------------------------------------
function M.get_values()
	if M.is_simulate_temp_local then
		if M.resistor then
			M.temperature = (M.temperature + 1)
		else
			M.temperature = (M.temperature - math.random(1, 15))
		end --end if

		if M.humidifier then
			M.humidity = (M.humidity + 1)
		else
			M.humidity = (M.humidity - math.random(1, 4))
		end --end if
	else
		M.startbme()
		if M.is_sensorok then
			sensor.read()
			print("temp ", sensor.temperature)
			if (sensor.temperature / 100) < -40 or (sensor.temperature / 100) > 86 then
				M.temperature = 99.9
				M.humidity = 99.9
				M.pressure = 99.9
				print("[!] Failed to read bme, Please check the cables and connections.")
				alerts.send_alert_to_grafana("[!] Failed to read bme, Please check the cables and connections.")
				log.error("temperature is not changing")
				--try to restart bme
			else
				M.temperature = (sensor.temperature / 100)
				M.humidity = (sensor.humidity / 100)
				M.pressure = (sensor.pressure / 100)
			end
		else
			M.temperature = 99.9
			M.humidity = 99.9
			M.pressure = 99.9
			log.error("Failed to start bme, Please check the cables and connections.")
			alerts.send_alert_to_grafana("[!] Failed to start bme, Please check the cables and connections.")
			print("[!] Failed to start bme, Please check the cables and connections.")
		end -- end if
	end --if end

	return M.temperature, M.humidity, M.pressure
end --end function

-------------------------------------
-- @function heater 					Activates or deactivates heater
--
-- @param status "true" 			increments temperature, "false" temp "decrements"
-------------------------------------
function M.heater(status --[[bool]])
	M.resistor = status
	if status then
		gpio.write(GPIORESISTOR, 1)
	else
		gpio.write(GPIORESISTOR, 0)
	end
	M.assert_conditions()
end --end function

function M.assert_conditions()
	log.trace("temp actual ", M.temperature, ", max ", M.max_temp, ",min ", M.min_temp, ",resitor status ", M.resistor)
	if M.is_testing then
		if (M.temperature > M.max_temp and M.resistor) then
			alerts.send_alert_to_grafana("temperature > max_temp and resistor is on")
			log.error("temperature > max_temp and resistor is on")
			--assert(not M.resistor)
		end --if end
		if (M.temperature < M.min_temp and not M.resistor) then
			alerts.send_alert_to_grafana("temperature < M.min_temp and resistor is off")
			log.error("temperature < M.min_temp and resistor is off")
			--assert(M.resistor)
		end --if end
	end -- if is_testing
end   --end fucition

-------------------------------------
-- @function humidifier 			Activates or deactivates humidifier
--
-- @param status "true" 		  increments humidity, "false" humidity "decrements"
-------------------------------------
function M.humidifier(status)
	humidifier = status
	if status then
		gpio.write(14, 0)
	else
		gpio.write(14, 1)
	end -- if end
end  -- function end

-------------------------------------
-- @function rotation 			Activates or deactivates rotation
--
-- @param status "true" activates rotation, "false" stops rotation
-------------------------------------
function M.rotation(status)
	rotation = status
	if status then
		gpio.write(GPIOVOLTEO, 0)
	else
		gpio.write(GPIOVOLTEO, 1)
	end -- if end
	--todo: implement logger for debug
end  -- function end

-------------------------------------
-- @function set_max_temp	modify the actual max_temp from API
--
-- @param new_max_temp"	comes from json received from API
-------------------------------------
function M.set_max_temp(new_max_temp)
	if new_max_temp ~= nil and new_max_temp < 60
		and tostring(new_max_temp):sub(1, 1) ~= '-'
		and type(new_max_temp) == "number"
		and new_max_temp >= 0 then
		M.max_temp = tonumber(new_max_temp)
		return true
	else
		return false
	end
end

-------------------------------------
-- @function set_min_temp	modify the actual min_temp from API
--
-- @param new_min_temp"	comes from json received from API
-------------------------------------
function M.set_min_temp(new_min_temp)
	if new_min_temp ~= nil and new_min_temp >= 0
		and new_min_temp <= M.max_temp
		and tostring(new_min_temp):sub(1, 1) ~= '-'
		and type(new_min_temp) == "number" then
		M.min_temp = tonumber(new_min_temp)
		return true
	else
		return false
	end
end

-------------------------------------
-- @function set_rotation_period	modify the actual period time from API
--
-- @param new_period_time"	comes from json received from API
-------------------------------------
function M.set_rotation_period(new_period_time)
	if new_period_time ~= nil and new_period_time >= 0
		and tostring(new_period_time):sub(1, 1) ~= '-'
		and type(new_period_time) == "number" then
		M.rotation_period = new_period_time
		return true
	else
		return false
	end
end

-------------------------------------
-- @function set_rotation_duration	modify the actual duration time from API
--
-- @param new_rotation_time"	comes from json received from API
-------------------------------------
function M.set_rotation_duration(new_rotation_duration)
	if new_rotation_duration ~= nil
		and tostring(new_rotation_duration):sub(1, 1) ~= '-'
		and type(new_rotation_duration) == "number" then
		M.rotation_duration = new_rotation_duration
		return true
	else
		return false
	end
end

-- -----------------------------------
-- @function set_new_ssid	modify the actual ssid WiFi from API

-- @param	new_ssid comes from json received from API
-- -----------------------------------
function M.set_new_ssid(new_ssid)
	if new_ssid ~= nil then
		M.ssid = new_ssid
		return true
	else
		return false
	end
end

-------------------------------------
-- @function set_passwd	modify the actual ssid WiFi from API
--
-- @param	new_passwd comes from json received from API
-------------------------------------
function M.set_passwd(new_passwd)
	if new_passwd ~= nil then
		M.passwd = new_passwd
		return true
	else
		return false
	end -- if end
end  -- function end

-------------------------------------------------------------------------------------------------
-- @function set_tray_*_date
-- Ensures that new_tray_one_date is exactly a string of 10 digits before setting the value.
-- @param	new_tray_*_date <-- Unix Time format
-------------------------------------------------------------------------------------------------
function M.set_tray_one_date(new_tray_one_date)
	if type(new_tray_one_date) == "number" and #tostring(new_tray_one_date) == 10 then
		M.tray_one_date = new_tray_one_date
		return true
	else
		return false
	end -- if end
end     -- function end

function M.set_tray_two_date(new_tray_two_date)
	if type(new_tray_two_date) == "number" and #tostring(new_tray_two_date) == 10 then
		M.tray_two_date = new_tray_two_date
		return true
	else
		return false
	end -- if end
end     -- function end

function M.set_tray_three_date(new_tray_three_date)
	if type(new_tray_three_date) == "number" and #tostring(new_tray_three_date) == 10 then
		M.tray_three_date = new_tray_three_date
		return true
	else
		return false
	end --if end
end     -- function end

-------------------------------------------------------------------------------------------------
-- @function set_incubation_period
-- Ensures that new_tray_one_date is exactly a string of 10 digits before setting the value.
-- @param	new_tray_*_date <-- Unix Time format
-------------------------------------------------------------------------------------------------

function M.set_incubation_period(new_incubation_period)
	if type(new_incubation_period) == "number" and #tostring(new_incubation_period) == 10 then
		M.incubation_period = new_incubation_period
		return true
	else
		return false
	end -- if end
end     -- function end

-------------------------------------------------------------------------------------------------
-- @function set_hash
-- varifies if the input string is at most 20 characters long and sets it as the hash if valid.
-- @param	new_hash
-------------------------------------------------------------------------------------------------

function M.set_hash(new_hash)
	if type(new_hash) == "string" and #new_hash <= 20 then
		M.hash = new_hash
		return true
	else
		return false
	end -- if end
end     -- function end

return M
