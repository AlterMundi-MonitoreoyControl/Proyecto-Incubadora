-- Test script for DS18B20 temperature sensors
local ds18b20 = require('ds18b20')
-- just connect the sensor to vcc and gnd 
-- yellow wire to pin 15 and voilà  
-- Initialize sensors on GPIO15
if ds18b20.init(15) then
    -- Read temperatures every 5 seconds
    local read_timer = tmr.create()
    read_timer:register(5000, tmr.ALARM_AUTO, function()
        ds18b20.read_all_temps(function(temps)
            if temps then
                print("\nCurrent readings:")
                for i, temp_data in ipairs(temps) do
                    local addr_str = ""
                    for j=1,8 do
                        addr_str = addr_str .. string.format("%02X", temp_data.address:byte(j))
                    end
                    print(string.format("Sensor %d [%s]: %.2f°C", 
                          i, addr_str, temp_data.temperature))
                end
            end
        end)
    end)
    
    read_timer:start()
    print("Temperature reading started. Press any key to stop.")
else
    print("Failed to initialize sensors!")
end