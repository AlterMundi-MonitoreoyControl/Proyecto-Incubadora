sigma_delta.setprescale(0, 128)
--sigma_delta.setduty(channel, value)  value duty -128 to 127
sigma_delta.setduty(0, 0)
duty_value = -127
outpin = 4
sigma_delta.setup(0, outpin)

function changeduty()
    print("seteando duty a ", value)
    sigma_delta.setduty(0, value)
    value = value + 10
    if value > 127 then
        value = -127
    end

end

local send_data_timer = tmr.create()
send_data_timer:register(3000, tmr.ALARM_AUTO, changeduty)
send_data_timer:start()