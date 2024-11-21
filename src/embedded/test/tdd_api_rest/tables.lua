local default_config = {
    max_temperature = 37.8,
    min_temperature = 37.3,
    rotation_duration = 5000,
    rotation_period = 3600000,
    ssid = "incubator",
    passwd = "12345678",
    tray_one_date = 1234567890,
    tray_two_date = 1234567890,
    tray_three_date = 1234567890,
    incubation_period = 1234567890,
    hash = "1234567890",
    incubator_name = "incubator_1",
    max_hum = 70,
    min_hum = 60
}

local tables = {
    default_config = default_config,
    configs_to_test_numbers = {},
    config_to_test_str = {}
}

local function generate_config(modifications)
    local new_config = {}
    for k, v in pairs(default_config) do
        new_config[k] = modifications[k] or v
    end
    return new_config
end

tables.configs_to_test_numbers.config_50_40 = generate_config({
    min_temperature = 50,
    max_temperature = 40
})

tables.configs_to_test_numbers.config_40_70 = generate_config({
    min_temperature = 30,
    max_temperature = 50,
    max_hum = 80
})

tables.configs_to_test_numbers.config_1_40_50 = generate_config({
    rotation_duration = 1
})

tables.configs_to_test_numbers.config_humid_min_50 = generate_config({
    min_hum = 50,
    max_hum = 80
})

tables.configs_to_test_numbers.config_invalid_min_temp = generate_config({
	min_temperature = 38.0,
	max_temperature = 37.8
})

tables.configs_to_test_numbers.config_invalid_humidity = generate_config({
	min_hum = 60,
	max_hum = 55
})

tables.configs_to_test_numbers.config_1_40_50 = generate_config({
	rotation_duration = 1
})

tables.configs_to_test_numbers.config_low_temp = generate_config({
	max_temperature = 20,
	min_temperature = 10
})

tables.config_to_test_str.noise_in_min_temp = generate_config({
	min_temperature = "lalala"
})

tables.config_to_test_str.noise_in_max_hum = generate_config({
	max_hum = "no_hum"
})

tables.configs_to_test_numbers.config_tray_dates = generate_config({
	tray_one_date = 1234567891,
	tray_two_date = 1234567892,
	tray_three_date = 1234567893
})

tables.configs_to_test_numbers.config_incubation_period = generate_config({
	incubation_period = 1814400  -- 21 días en segundos
})

tables.config_to_test_str.config_incubator_name = generate_config({
	incubator_name = "incubator_test_01"
})

tables.config_to_test_str.config_invalid_hash = generate_config({
	hash = "invalid_hash_1234567890"
})

tables.config_to_test_str.noise_in_tray_dates = generate_config({
	tray_one_date = "invalid_date",
	tray_two_date = "invalid_date",
	tray_three_date = "invalid_date"
})

tables.config_to_test_str.invalid_incubator_name = generate_config({
	incubator_name = "404:HuevoNoEncontradoEnIncubadora"  -- nombre muy corto o inválido
})

return tables
