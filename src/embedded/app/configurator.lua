configurator =
{
  wifi = {},
  incubator = {}

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
-- @method configurator.set_new_credentials	set the new credentials for wifi
-------------------------------------------------------------------------------------
function configurator.wifi:set_new_credentials(ssid, passwd)
  -- TODO
end

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
  print("[!] Failed to read JSON file, creating a new one")
  new_file = io.open("config.json", "w")
  new_file:write(
    '{"rotation_duration":5000,"rotation_period":360000,"min_temperature":37.3,"max_temperature":37.8,"ssid":"incubator","passwd":"1234554321"}')
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
    elseif param == "ssid" then
      status.ssid = incubator.set_new_ssid(tostring(value))
    elseif param == "passwd" then
      status.passwd = incubator.set_passwd(tostring(value))
    end
  end
  return status
end

return configurator
