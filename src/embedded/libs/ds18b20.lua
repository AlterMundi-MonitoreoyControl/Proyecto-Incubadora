-- DS18B20 Multi-Sensor Temperature Reader
-- Supports reading temperatures from multiple DS18B20 sensors on the same bus
-- ESP32 Version - Non-blocking implementation

local M = {
    pin = nil,
    addresses = {},
    initialized = false,
    conversion_timer = nil,
    current_reading = nil,
    callback = nil
}

-- Initialize the one-wire bus and discover all DS18B20 sensors
function M.init(pin_number)
    M.pin = pin_number
    M.addresses = {}
    M.conversion_timer = tmr.create()
    
    gpio.config({ gpio = pin_number, dir = gpio.IN, pull = gpio.FLOATING })
    -- Setup one-wire bus
    ow.setup(M.pin)
    
    -- Search for all devices on the bus
    local count = 0
    local addr
    
    addr = ow.reset_search(M.pin)
    addr = ow.search(M.pin)
    
    while addr and count < 100 do
        -- Verify CRC and device family
        local crc = ow.crc8(string.sub(addr, 1, 7))
        if crc == addr:byte(8) then
            if (addr:byte(1) == 0x10) or (addr:byte(1) == 0x28) then
                -- Valid DS18B20 device found
                count = count + 1
                table.insert(M.addresses, addr)
                --print(string.format("Found DS18B20 sensor %d with address:", count))
                for i=1,8 do
                    --print(string.format("%02X", addr:byte(i)))
                end
            end
        end
        addr = ow.search(M.pin)
    end
    
    if #M.addresses == 0 then
        --print("No DS18B20 sensors found!")
        return false
    end
    
    --print(string.format("Found %d DS18B20 sensor(s)", #M.addresses))
    M.initialized = true
    return true
end

-- Internal function to read temperature after conversion is complete
local function read_temp_data(addr)
    -- Reset and select device again to read data
    ow.reset(M.pin)
    ow.select(M.pin, addr)
    -- Read scratchpad command
    ow.write(M.pin, 0xBE, 1)
    
    -- Read 9 bytes of data
    local data = ""
    for i = 1, 9 do
        data = data .. string.char(ow.read(M.pin))
    end
    
    -- Verify CRC
    local crc = ow.crc8(string.sub(data, 1, 8))
    if crc ~= data:byte(9) then
        --print("CRC verification failed!")
        return nil
    end
    
    -- Convert data to temperature
    local temp = (data:byte(1) + data:byte(2) * 256)
    -- Handle negative temperatures
    if temp > 0x7FF then
        temp = temp - 0x1000
    end
    -- Convert to Celsius (each bit represents 1/16 degree)
    temp = temp * 0.0625
    
    return temp
end

-- Start temperature reading from a specific sensor
function M.start_conversion(addr, callback)
    if not addr then return nil end
    
    M.current_reading = addr
    M.callback = callback
    
    -- Reset and select device
    ow.reset(M.pin)
    ow.select(M.pin, addr)
    -- Start temperature conversion
    ow.write(M.pin, 0x44, 1)
    
    -- Set timer for 750ms (conversion time for 12-bit precision)
    M.conversion_timer:register(750, tmr.ALARM_SINGLE, function()
        local temp = read_temp_data(addr)
        if M.callback then
            M.callback(temp)
        end
    end)
    M.conversion_timer:start()
end

-- Read temperatures from all discovered sensors
function M.read_all_temps(callback)
    if not M.initialized then
        --print("Module not initialized! Call init() first")
        return
    end
    
    local temps = {}
    local current_sensor = 1
    
    local function read_next_sensor()
        if current_sensor <= #M.addresses then
            M.start_conversion(M.addresses[current_sensor], function(temp)
                if temp then
                    temps[current_sensor] = {
                        address = M.addresses[current_sensor],
                        temperature = temp
                    }
                    -- --print formatted address and temperature
                    local addr_str = ""
                    for j=1,8 do
                        addr_str = addr_str .. string.format("%02X", M.addresses[current_sensor]:byte(j))
                    end
                    --print(string.format("Sensor %d (addr: %s): %.2f°C", current_sensor, addr_str, temp))
                else
                    --print(string.format("Failed to read sensor %d", current_sensor))
                end
                
                current_sensor = current_sensor + 1
                read_next_sensor()
            end)
        elseif callback then
            callback(temps)
        end
    end
    
    read_next_sensor()
end

return M
