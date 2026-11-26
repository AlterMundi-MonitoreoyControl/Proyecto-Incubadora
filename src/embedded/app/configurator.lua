-- SPDX-FileCopyrightText: 2025 info@altermundi.net
--
-- SPDX-License-Identifier: AGPL-3.0-only

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
-- Valores por defecto: única fuente. Lo que falte en config.json se completa con estos.
-------------------------------------------------------------------------------------
configurator.DEFAULTS = {
  rotation_duration   = 190000,
  rotation_period     = 3600000,
  min_temperature     = 37.5,
  max_temperature     = 37.7,
  min_hum             = 55,
  max_hum             = 65,
  humidifier_min_temp = 35.0,
  incubation_period   = 18,
  tray_one_date       = 0,
  tray_two_date       = 0,
  tray_three_date     = 0,
}

-------------------------------------------------------------------------------------
-- Migraciones: cada una cambia valores por defecto. Solo pisa el valor guardado si
-- sigue siendo el default anterior, es decir, si el usuario no lo cambió.
-- Para cambiar un default: actualizarlo en DEFAULTS y agregar una migración al final.
-- config.json guarda en config_version cuántas migraciones ya se aplicaron.
-------------------------------------------------------------------------------------
configurator.MIGRACIONES = {
  [1] = { rotation_duration = { de = 50000, a = 190000 } },
}

configurator.path = "config.json"

local function mac_id()
  return "incu-" .. string.gsub(wifi.sta.getmac(), ":", "")
end

-- io:read("*a") falla con archivos grandes en NodeMCU-ESP32: leer por partes
local function read_all(f)
  local parts = {}
  while true do
    local chunk = f:read(256)
    if not chunk then break end
    parts[#parts + 1] = chunk
  end
  return table.concat(parts)
end

-------------------------------------------------------------------------------------
-- @method configurator:complete_config	completa valores faltantes y aplica migraciones
-- @return true si cambió algo y hay que guardar
-------------------------------------------------------------------------------------
function configurator:complete_config(cfg)
  local changed = false
  for k, v in pairs(configurator.DEFAULTS) do
    if cfg[k] == nil then
      cfg[k] = v
      changed = true
    end
  end
  if cfg.hash == nil then cfg.hash = mac_id(); changed = true end
  if cfg.incubator_name == nil then cfg.incubator_name = mac_id(); changed = true end

  local version = tonumber(cfg.config_version) or 0
  local latest = #configurator.MIGRACIONES
  for v = version + 1, latest do
    for k, m in pairs(configurator.MIGRACIONES[v]) do
      if cfg[k] == m.de then
        log.trace("[CFG] migracion " .. v .. ": " .. k .. " " .. tostring(m.de) .. " -> " .. tostring(m.a))
        cfg[k] = m.a
      end
    end
  end
  if version < latest then
    cfg.config_version = latest
    changed = true
  end
  return changed
end

-------------------------------------------------------------------------------------
-- @method configurator:write_config_file	guarda la tabla completa en config.json
-------------------------------------------------------------------------------------
function configurator:write_config_file(cfg)
  local f = io.open(configurator.path, "w")
  if not f then
    return false
  end
  f:write(sjson.encode(cfg))
  f:close()
  return true
end

-------------------------------------------------------------------------------------
-- @method configurator:encode_config_file	encode the new config.json
-------------------------------------------------------------------------------------
function configurator:encode_config_file(new_config_table)
  return configurator:write_config_file(new_config_table)
end

-------------------------------------------------------------------------------------
-- @method configurator:create_config_file	create a new one config.json
-------------------------------------------------------------------------------------
function configurator:create_config_file()
  log.trace("Creating a new config file")
  local cfg = { config_version = #configurator.MIGRACIONES }
  configurator:complete_config(cfg)
  configurator:write_config_file(cfg)
  return cfg
end

-------------------------------------------------------------------------------------
-- @method configurator.read_config_file	lee config.json, completa defaults y migra
-------------------------------------------------------------------------------------
function configurator:read_config_file()
  local f = io.open(configurator.path, "r")
  if not f then
    return configurator:create_config_file()
  end
  local content = read_all(f)
  f:close()
  local ok, cfg = pcall(sjson.decode, content)
  if not ok or type(cfg) ~= "table" then
    log.warn("[CFG] config.json ilegible, se regenera con valores por defecto")
    return configurator:create_config_file()
  end
  if configurator:complete_config(cfg) then
    configurator:write_config_file(cfg)
  end
  return cfg
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
	elseif param == "humidifier_min_temp" then
		status.humidifier_min_temp = incubator.set_humidifier_min_temp(tonumber(value))
		end -- if end 
  
  end -- for end
	configurator.WiFi:on_change(new_config_table)
  log.trace("Configurator status: ", sjson.encode(status))
  return status
end -- function end 

return configurator
