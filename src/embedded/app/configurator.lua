configurator =
{
  incubator = {},
  WiFi = require("wifiinit"),

}
-------------------------------------------------------------------------------------
-- @method configurator:init_module   load config file to incubator table
-------------------------------------------------------------------------------------
function configurator:init_module(incubator_object)
  local config_table = configurator:read_config_file()
  configurator.incubator = incubator_object
  if config_table ~= nil then
    configurator:load_objects_data(config_table)
  end
end


-------------------------------------------------------------------------------------
--------------------------        CONFIGURATOR       --------------------------------
-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
-- @method configurator:encode_config_file	encode the new config.json
-------------------------------------------------------------------------------------
function configurator:encode_config_file(new_config_table)
  local table_to_json = sjson.encode(new_config_table)
  local new_config_file = io.open("config.json", "w")
  if not new_config_file then
    return false
  else
    new_config_file:write(table_to_json)
    new_config_file:close()
    return true
  end -- if else end
end

-------------------------------------------------------------------------------------
-- @method configurator:create_config_file	create a new one config.json
-------------------------------------------------------------------------------------

function configurator:create_config_file()
	log.trace("Creating a new config file")
	local new_file = io.open("config.json", "w")
			local config = {
					rotation_duration = 50000,
					rotation_period = 3600000,
					min_temperature = 37.3,
					max_temperature = 37.8,
					tray_one_date = 0,
					tray_two_date = 0,
					tray_three_date = 0,
					incubation_period = 0,
					hash = "1234567890",
					incubator_name = string.format("incubadora-%s",wifi.sta.getmac()),
					max_hum = 70,
					min_hum = 60
			}
			new_file:write(sjson.encode(config))
			new_file:close()
end

-------------------------------------------------------------------------------------
-- @method configurator.read_config_file	read the current config.json in the file
-------------------------------------------------------------------------------------

function configurator:read_config_file()
  local file = io.open("config.json", "r")
  if not file then
    configurator:create_config_file()
    file = io.open("config.json", "r")
  end
    local config_json = file:read("*a")
    file:close()
    local config_table = sjson.decode(config_json)
    return config_table
end

-----------------------------------------------------------------------------------
-- @method configurator.change_config	change currents parameters in the incubator object
-- and validates input

-- @ param new_config_table
-----------------------------------------------------------------------------------
function configurator:load_objects_data(new_config_table)
  local status = {}

  for param, value in pairs(new_config_table) do
    if param == "min_temperature" then
      status.min_temp = incubator.set_min_temp(tonumber(value))
    elseif param == "max_temperature" then
      status.max_temp = incubator.set_max_temp(tonumber(value))
    elseif param == "rotation_duration" then
      status.rotation_duration = incubator.set_rotation_duration(tonumber(value))
    elseif param == "rotation_period" then
      status.rotation_period = incubator.set_rotation_period(tonumber(value))
		elseif param == "tray_one_date" then
			status.tray_one_date = incubator.set_tray_date("one",tonumber(value))
		elseif param == "tray_two_date" then
			status.tray_two_date = incubator.set_tray_date("two",tonumber(value))
		elseif param == "tray_three_date" then
			status.tray_three_date = incubator.set_tray_date("three",tonumber(value))
		elseif param == "incubation_period" then 
			status.incubation_period = incubator.set_incubation_period(tonumber(value))
		elseif param == "hash" then 
			status.hash = incubator.set_hash(value)
    elseif param == "incubator_name" then
			status.incubator_name = incubator.set_incubator_name(tostring(value))
		elseif param == "max_hum" then 
			status.max_hum = incubator.set_max_humidity(tonumber(value))
		elseif param == "min_hum" then
			status.min_hum = incubator.set_min_humidity(tonumber(value))
		end -- if end 

  end -- for end
	configurator.WiFi:on_change(new_config_table)
  return status
end -- function end 

return configurator
