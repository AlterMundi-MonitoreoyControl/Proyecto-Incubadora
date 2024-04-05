bmesda = 14
bmescl = 15
outpin = 4

sensor=require('bme280')


function sense_control()
    input_temp = sensor.temperature / 100
    --input_temp=input_temp+(Setpoint-temp_inicial)/2000*(Output/255);
	Output=myPID.Compute(input_temp)
    PID_value = Output - 127

    if PID_value < -127 then
        PID_value = -127
    elseif PID_value > 127  then
        PID_value = 127
    end
    ---Now we can write the PWM signal to the mosfet on digital pin D3
    print (input_temp,"; " ,Output, "; ",PID_value);
    sigma_delta.setduty(0, PID_value)
end

if sensor.init(bmesda,bmescl,true) then
    print("iniciando pid")
    local myPID=require('PID_v1')
    local Setpoint = 38
    local input_temp = 15
    local temp_inicial = input_temp
    local Output = 0
    myPID.initPID(Setpoint,2,150,150,1,1)

    sigma_delta.setprescale(0, 128)
    sigma_delta.setduty(0, 0)
    sigma_delta.setup(0, outpin)

    local send_data_timer = tmr.create()
    send_data_timer:register(300, tmr.ALARM_AUTO, sense_control)
    send_data_timer:start()

end