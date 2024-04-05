tables = {
    configs_to_test_numbers = {
        config_50_40 = [[
      {
        "max_temperature":40,
        "min_temperature":50,
        "rotation_duration":5000,
        "rotation_period":3600000,
        "ssid":"incubator",
        "passwd":"12345678"
      }
    ]],

        config_40_50 = [[
      {
        "max_temperature":70,
        "min_temperature":40,
        "rotation_duration":5000,
        "rotation_period":3600000,
        "ssid": "incubator",
        "passwd":"12345678"
      }
    ]],

        config_1_40_50 = [[
      {
        "max_temperature":70,
        "min_temperature":40,
        "rotation_duration":1,
        "rotation_period": 5000,
        "ssid": "incubator",
        "passwd":"12345678"
      }
    ]],

        config_m10_50 = [[
      {
        "max_temperature":70,
        "min_temperature":-10,
        "rotation_duration":5000,
        "rotation_period": 3600000,
        "ssid": "incubator",
        "passwd":"12345678"
      }
    ]],

        config_10_m10 = [[
      {
        "max_temperature":-10,
        "min_temperature":10,
        "rotation_duration":5000,
        "rotation_period": 3600000,
        "ssid": "incubator",
        "passwd":"12345678"
      }
    ]]

    },

    config_to_test_str = {
        noise_in_min_temp = [[
      {
        "max_temperature":50,
        "min_temperature":"lalala",
        "rotation_duration":5000,
        "rotation_period": 3600000,
        "ssid": "incubator",
        "passwd":"12345678"
      }
    ]],

        noise_in_rotation_duration = [[
      {
        "max_temperature":50,
        "min_temperature":40,
        "rotation_duration":"lalala",
        "rotation_period": 5000,
        "ssid": "incubator",
        "passwd":"12345678"
      }
    ]],

        noise_in_max_temperature = [[
      {
        "max_temperature":"lala",
        "min_temperature":20,
        "rotation_duration":5000,
        "rotation_period": 3600000,
        "ssid": "incubator",
        "passwd":"12345678"
      }
    ]]
    },

    set_default_config = [[
    {
      "max_temperature":"37.8",
      "min_temperature":37.3,
      "rotation_duration":5000,
      "rotation_period": 3600000,
      "ssid": "incubator",
      "passwd":"12345678"
    }
  ]]

}
return tables
