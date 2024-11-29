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
	name                            = ..., -- module name, upvalue from require('module-name')
	model                           = nil, -- M model:
	resistor                        = false,
	humidifier                      = false,
	rotation                        = false,
	temperature                     = 99.9, -- integer value of temperature [0.01 C]
	pressure                        = 0, -- integer value of preassure [Pa]=[0.01 hPa]
	humidity                        = 0, -- integer value of rel.humidity [0.01 %]
	is_testing                      = false,
	max_temp                        = 37.8,
	min_temp                        = 37.3,
	is_sensorok                     = false,
	is_simulate_temp_local          = false,
	rotation_switch_deactivate_time = 10000, -- max ammount of time the sensor is down when the incubator is moving
	rotation_duration               = 50000, -- max ammount of time the rotation should last
	rotation_period                 = 3600000, -- time in ms
	humidifier_enabled              = true,
	max_hum                         = 70,
	min_hum                         = 60,
	humidifier_max_on_time          = 2, --sec
	humidifier_off_time             = 15, -- sec
	hum_turn_on_time                = 0,
	hum_turn_off_time               = 0,
	tray_one_date = 0,
	tray_two_date = 0,
	tray_three_date = 0,
	incubation_period = 0,
	hash = 1235,
	incubator_name = string.format("incubadora-%s",wifi.sta.getmac()),
	rotate_up                       = true
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
	gpio.config({ gpio = { GPIORESISTOR, GPIOVOLTEO_UP, GPIOVOLTEO_DOWN, GPIOHUMID, GPIOVOLTEO_EN }, dir = gpio.OUT })
	-- config inputs
	gpio.config({ gpio = { GPIOREEDS_DOWN, GPIOREEDS_UP }, dir = gpio.IN, pull = gpio.PULL_UP })

	gpio.set_drive(GPIOVOLTEO_UP, gpio.DRIVE_3)
	gpio.set_drive(GPIOVOLTEO_DOWN, gpio.DRIVE_3)
	gpio.set_drive(GPIOHUMID, gpio.DRIVE_3)
	gpio.set_drive(GPIORESISTOR, gpio.DRIVE_3)
	gpio.set_drive(GPIOVOLTEO_EN, gpio.DRIVE_3)



	--revisar estos valores inicliales
	gpio.write(GPIOVOLTEO_UP, 1)
	gpio.write(GPIOVOLTEO_DOWN, 1)
	gpio.write(GPIOHUMID, 1)
	gpio.write(GPIORESISTOR, 1)
	gpio.write(GPIOVOLTEO_EN, 0)
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

function M.get_uptime_in_sec()
	local high_bytes, _ = node.uptime()
	return tonumber((high_bytes / 1000000))
end

-------------------------------------
-- @function humidifier 			Activates or deactivates humidifier
--
-- @param status "true" 		  increments humidity, "false" humidity "decrements"
-------------------------------------
function M.humidifier_switch(status)
	local current_time = M.get_uptime_in_sec()
	log.warn("humidifier current_time " .. current_time)

	if not M.humidifier_enabled then
		--humidifier disabled, check for waiting_off time concluded
		log.error("humidifier disabled ")
		if ((current_time - M.hum_turn_off_time) > M.humidifier_off_time) then
			M.humidifier_enabled = true
			log.warn("humidifier enabled time out expired")
			if status then
				if (not M.humidifier) then
					log.warn("humidifier was off... turning on ")
					--estaba apagado y lo prendo
					M.hum_turn_on_time = current_time
					M.humidifier = status
				end
			end
		end
	end

	log.warn("humidifier enabled")
	if status and M.humidifier_enabled then -- encender humidifier
		if (not M.humidifier) then       -- estaba apagado
			log.warn("humidifier was off... turning on ")

			--estaba apagado y lo prendo
			M.hum_turn_on_time = current_time
			M.humidifier = status
		else
			--estaba pendido y sigue
			log.warn("humidifier was on... turned on" .. M.hum_turn_on_time)

			log.warn("humidifier was on... turning on.. time transcurred " .. (current_time - M.hum_turn_on_time))
			log.warn("humidifier was on... turning on.. time left " ..
				(M.humidifier_max_on_time - (current_time - M.hum_turn_on_time)))
			--verificar el tiempo maximo de on
			if ((current_time - M.hum_turn_on_time) > M.humidifier_max_on_time) then
				M.humidifier_enabled = false
				M.humidifier = false
				M.hum_turn_off_time = current_time
				log.error("humidifier disabled beacuse time greater than max")
			end
		end
	end

	if status and M.humidifier_enabled then
		-- logica negada
		-- gpio.write(GPIOHUMID, 1)
		gpio.write(GPIOHUMID, 0)
		log.warn("humidifier pin turned on--------------------")
	else
		M.humidifier = false
		-- logica negada
		-- gpio.write(GPIOHUMID, 0)
		gpio.write(GPIOHUMID, 1)
		log.warn("humidifier pin turned off--------------------")
	end -- if end
end  -- function end

-------------------------------------
-- @function rotation 			Activates or deactivates rotation
--
-- @param status "true" activates rotation, "false" stops rotation
-------------------------------------
function M.rotation_switch(status)
	M.rotation = status
	if status then
		--switch on
		M.rotation_change_dir()
		if M.rotate_up then
			log.trace("rotating upppppp")
			gpio.write(GPIOVOLTEO_UP, 1)
			gpio.write(GPIOVOLTEO_DOWN, 0)
		else
			log.trace("rotating downnn")

			gpio.write(GPIOVOLTEO_UP, 0)
			gpio.write(GPIOVOLTEO_DOWN, 1)
		end
		log.trace("rotating turning onnnn")
		gpio.write(GPIOVOLTEO_EN, 1)
	else
		--switch off
		log.trace("turning offfffffff")

		gpio.write(GPIOVOLTEO_UP, 0)
		gpio.write(GPIOVOLTEO_DOWN, 0)
		gpio.write(GPIOVOLTEO_EN, 0)
	end
end -- function end

function M.rotation_change_dir()
	local upvalue = gpio.read(GPIOREEDS_UP)
	local downvalue = gpio.read(GPIOREEDS_DOWN)
	log.trace("gpio reeds values up: " .. upvalue .. " down: " .. downvalue)

	if (upvalue == 0 and downvalue == 1) then
		M.rotate_up = false
	elseif (upvalue == 1 and downvalue == 0) then
		M.rotate_up = true
	else
		--something is wrong, invert rotation
		log.error("gpio reeds not active inverting rotation just in case")
		M.rotate_up = not M.rotate_up
	end
end

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
	end -- if end
end -- function end

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
	end -- if end 
end -- function end

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
	end -- if end
end -- function end 

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
	end -- if end
end --function end 

local tray_map = {
	one = "tray_one_date",
	two = "tray_two_date",
	three = "tray_three_date"
}
---------------------------------------------------------------------------------------------------
-- @function set_tray_date
-- Ensures that new_tray_date is exactly a string of 10 digits before setting the value.
-- @param tray_number string: "one", "two", or "three"
-- @param new_tray_date number: Unix Time format
-- @return boolean: true if the date was set successfully, false otherwise
---------------------------------------------------------------------------------------------------
function M.set_tray_date(tray_number, new_tray_date)
	if type(new_tray_date) == "number" and #tostring(new_tray_date) < 20 then
			local tray_var = tray_map[tray_number]
			if tray_var then
					M[tray_var] = new_tray_date
					return true
			end
	end
	return false
end
-------------------------------------------------------------------------------------------------
-- @function set_incubation_period
-- Ensures that new_tray_one_date is exactly a string of 10 digits before setting the value.
-- @param	new_tray_*_date <-- Unix Time format
-------------------------------------------------------------------------------------------------

function M.set_incubation_period(new_incubation_period)
	if type(new_incubation_period) == "number" and #tostring(new_incubation_period) < 10 then
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
	if type(new_hash) == "string" and #new_hash <= 35 then
		M.hash = new_hash
		return true
	else
		return false
	end -- if end
end     -- function end

-------------------------------------------------------------------------------------------------
-- @function set_incubator_name
-- set the name oif incubator 
-- @param	new_incubator_name
-------------------------------------------------------------------------------------------------
function M.set_incubator_name(new_incubator_name)
if type(new_incubator_name) == "string" and #new_incubator_name <= 35 then
		M.incubator_name = new_incubator_name
		return true
else
		return false
	end -- if end 
end -- function end

-------------------------------------------------------------------------------------------------
-- @function set_max_humidity
-- set the max humidity parameter 
-- @param	new_max_hum
-------------------------------------------------------------------------------------------------
function M.set_max_humidity(new_max_hum)
	if new_max_hum ~= nil and new_max_hum >= 0
			and new_max_hum > M.min_hum
			and tostring(new_max_hum):sub(1, 1) ~= '-'
			and type(new_max_hum) == "number" then
		M.max_hum = new_max_hum
		return true
	else
		return false
	end
end
-------------------------------------------------------------------------------------------------
-- @function set_min_humidity
-- set the min humidity parameter 
-- @param	new_min_hum
-------------------------------------------------------------------------------------------------
function M.set_min_humidity(new_min_hum)
	if new_min_hum ~= nil and new_min_hum >= 0
		and new_min_hum < M.max_hum
		and tostring(new_min_hum):sub(1, 1) ~= '-'
		and type(new_min_hum) == "number" then
	M.min_hum = new_min_hum
			return true
		else
			return false
		end
end

return M