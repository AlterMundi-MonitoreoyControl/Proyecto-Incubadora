-- ! Modules

local incubator = require("incubator")
INICIALES = incubator.incubator_name

local M = {
  token_grafana = "token:e98697797a6a592e6c886277041e6b95",
  url = SERVER,
  high_bytes, _ = nil,
  uptime_secs = nil,
  uptime = nil,
  heap_bytes = nil,
  node_heap = nil,
}

_G[M] = M


M.high_bytes, _ = node.uptime()
M.uptime_secs = tonumber((M.high_bytes / 1000000))
M.uptime = tonumber(M.uptime_secs / 60)
M.heap_bytes = node.heap()
M.node_heap = tonumber((M.heap_bytes / 1048576))

M.response_heap = "esp_status,device=" .. INICIALES .. " up_time=" ..
    M.uptime ..",heap=" .. M.node_heap ..
    string.format("%.0f", ((time.get()) * 1000000000))

------------------------------------------------------------------------------------
-- ! @function create_grafana_message    to read the data from the bme sensor 
-- !                                     and send it by post request    
-- ! @var temperature                    stores the temperature returned by the internal
-- !                                     function of sensor
-- ! @var humidity                       stores the humidity returned by the internal 
-- !                                     function of sensor
-- ! @var pressure                       stores the pressure returned by the internal
-- !                                     function of sensor
-- ! @var INICIALES                      user's initials, brought from credential.lua  
-- ! @var time							             time in nanosecconds since 
------------------------------------------------------------------------------------

function create_grafana_message(temperature,humidity,pressure,INICIALES,time)
	local data = "mediciones,device=" .. INICIALES .. " temp=" ..
									temperature .. ",hum=" .. humidity .. ",press=" .. pressure .." " .. time
	return data
end


------------------------------------------------------------------------------------
-- ! @function send_data_grafana         to read the data from the bme sensor 
-- !                                     and send it by post request 
-- ! @var temperature                    stores the temperature returned by the internal
-- !                                     function of sensor
-- ! @var humidity                       stores the humidity returned by the internal 
-- !                                     function of sensor
-- ! @var pressure                       stores the pressure returned by the internal
-- !                                     function of sensor
-- ! @var  INICIALES                     user's initials, brought from credential.lua   
------------------------------------------------------------------------------------

function send_data_grafana(temperature,humidity,pressure,INICIALES)

		local data = create_grafana_message(temperature,humidity,pressure,INICIALES, string.format("%.0f", ((time.get()) *1000000000))) 
		local headers = {
				["Content-Type"] = "text/plain",
				["Authorization"] = "Basic " .. M.token_grafana
		}
		http.post(M.url, {headers = headers}, data,
			function(code_return, _)
				if (code_return ~= 204) then
					log.warn("Fail to send data to grafana code returned : " .. code_return)
        else
          log.trace("Sending data to Grafana")
				end
                    
		end) -- * post function end
end -- * send_data_grafana end

----------------------------------------------------------------------------------------
-- ! @function send_data_grafana         to read the uptime,heap and send it to grafana  
---------------------------------------------------------------------------------------

function send_heap_and_uptime_grafana()

  local response = M.response_heap
  local headers =
  {
    ["Content-Type"] = "text/plain",
    ["Authorization"] = "Basic " .. M.token_grafana
  }
--
--  http.post(M.url, {headers = headers}, response, function (code_return, _)
--    if (code ~= 204) then
--      log.warn("Fail to send Heap and Uptime to Grafana code returned: " .. code_return)
--    end -- if end
--  end) -- post function end
end -- callback end

return M
