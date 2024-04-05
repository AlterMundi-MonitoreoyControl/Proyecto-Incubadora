sensor=require('bme280')
set_temperature = 30
temperature_read = 0.0
PID_error = 0.0
previous_error = 0
elapsedTime = 0
Time = 0
timePrev = 0
PID_value = 0

--PID constants
kp = 9.1   
ki = 0.3   
kd = 1.8
PID_p = 0    
PID_i = 0    
PID_d = 0

sigma_delta.setprescale(0, 128)
--sigma_delta.setduty(channel, value)  value duty -128 to 127
sigma_delta.setduty(0, 0)


bmesda = 14
bmescl = 15
outpin = 4
--sigma_delta.setup(channel, pin)
sigma_delta.setup(0, outpin)

--if sensor.init(14,15,true) then
while true do
    -- node.sleep({ secs = 1 })   --print (sensor.read()) -- default sampling
    --temperature_read = sensor.temperature / 100
    ---Next we calculate the error between the setpoint and the real value
    PID_error = set_temperature - temperature_read;
    --Calculate the P value
    PID_p = kp * PID_error;
    print("PID_p value ".. PID_p);

    --Calculate the I value in a range on +-3
    if(-3 < PID_error <3) then
    
        PID_i = PID_i + (ki * PID_error);
        print("PID_i value ".. PID_i);
    
    end
    --//For derivative we need real time to calculate speed change rate
    timePrev = Time;                            --// the previous time is stored before the actual time read
    sec, usec = time.get()                        --    // actual time read
    Time = usec
    elapsedTime = (Time - timePrev) / 1000000
    --//Now we can calculate the D calue
    PID_d = kd*((PID_error - previous_error)/elapsedTime);
    print("PID_d value ".. PID_d);

    --Final total PID value is the sum of P + I + D
    PID_value = PID_p + PID_i + PID_d;

    -- //We define PWM range between 0 and 255
    if PID_value < 0 then
        PID_value = 0
    elseif PID_value > 127  then
        PID_value = 127
    end
    ---Now we can write the PWM signal to the mosfet on digital pin D3
    print("pid value ".. PID_value);
    sigma_delta.setduty(0, PID_value)
    previous_error = PID_error;     --Remember to store the previous error for next loop.

end
  
--end

