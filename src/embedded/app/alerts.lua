require('credentials')
deque = require ('deque')

local alerts = {
	alers_counter = 0,
	messages_queue = deque.new()
}

-----------------------------------------------------------------------------------
-- ! @function is_temp_changing 	     verifies if temperature is changing 
-- ! @param temperature						 actual temperature
------------------------------------------------------------------------------------
function alerts.add_message_to_the_queue(message)
    if alerts.messages_queue:length() > 10 then
        alerts.messages_queue:pop_left()
    end
    alerts.messages_queue:push_right(message)
end

function alerts.send_alert_to_grafana(message)

	alerts.alers_counter = alerts.alers_counter+1

	local alert_string = "alertas,device=" .. INICIALES .. " count=" ..
	alerts.alers_counter .. ",message=\"" .. message .. "\" " .. string.format("%.0f", ((time.get()) *1000000000))
	alerts.add_message_to_the_queue({time.get(),message,alerts.alers_counter})
	local token_grafana = "token:e98697797a6a592e6c886277041e6b95"
	local url = SERVER 

	local headers = {
			["Content-Type"] = "text/plain",
			["Authorization"] = "Basic " .. token_grafana
	}
	
	http.post(url, {headers = headers}, alert_string,
		function(code_return, data_return)
			if (code_return ~= 204) then
				print(" " .. code_return)
			end
	end) -- * post function end
end -- * send_data_grafana end

return alerts
