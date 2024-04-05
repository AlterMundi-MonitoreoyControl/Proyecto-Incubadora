myChannel = ledc.newChannel({
    gpio=4,
    bits=ledc.TIMER_13_BIT,
    mode=ledc.LOW_SPEED,
    timer=ledc.TIMER_0,
    channel=ledc.CHANNEL_0,
    frequency=1000,
    duty=4096
  });

value=4096
function changeduty()
    print("seteando duty a ", value)
    myChannel:setduty(value)
    value = value - 100
end

local send_data_timer = tmr.create()
send_data_timer:register(3000, tmr.ALARM_AUTO, changeduty)
send_data_timer:start()
