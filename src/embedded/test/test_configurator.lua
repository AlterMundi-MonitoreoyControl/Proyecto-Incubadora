-- SPDX-FileCopyrightText: 2026 info@altermundi.net
--
-- SPDX-License-Identifier: AGPL-3.0-only

package.path = package.path .. ";../app/?.lua" .. ";../libs/?.lua"

local json = require("dkjson")

_G.sjson = {
    encode = function(t) return json.encode(t) end,
    decode = function(s)
        local obj, _, err = json.decode(s)
        if err then error(err) end
        return obj
    end
}
_G.wifi = { sta = { getmac = function() return "44:1d:64:39:4a:e8" end } }
_G.log = { trace = function() end, warn = function() end }
package.loaded["wifiinit"] = { on_change = function() end }

local configurator = require("configurator")

local function write(path, content)
    local f = assert(io.open(path, "w"))
    f:write(content)
    f:close()
end

local function read(path)
    local f = assert(io.open(path, "r"))
    local content = f:read("*a")
    f:close()
    return json.decode(content)
end

describe("configurator config.json", function()
    local path

    before_each(function()
        path = os.tmpname()
        os.remove(path)
        configurator.path = path
    end)

    after_each(function()
        os.remove(path)
    end)

    it("crea el archivo con los valores por defecto y la versión actual", function()
        local cfg = configurator:read_config_file()
        assert.are.equal(190000, cfg.rotation_duration)
        assert.are.equal(35.0, cfg.humidifier_min_temp)
        assert.are.equal("incu-441d64394ae8", cfg.hash)
        assert.are.equal("incu-441d64394ae8", cfg.incubator_name)
        assert.are.equal(#configurator.MIGRACIONES, cfg.config_version)
        assert.are.same(cfg, read(path))
    end)

    it("migra el default viejo y conserva el estado", function()
        write(path, json.encode({
            rotation_duration = 50000, tray_one_date = 1764000000000, incubator_name = "incu-norte",
            hash = "abc", ssid = "red", passwd = "clave", min_hum = 55,
        }))
        local cfg = configurator:read_config_file()
        assert.are.equal(190000, cfg.rotation_duration)
        assert.are.equal(1764000000000, cfg.tray_one_date)
        assert.are.equal("incu-norte", cfg.incubator_name)
        assert.are.equal("abc", cfg.hash)
        assert.are.equal("red", cfg.ssid)
        assert.are.equal("clave", cfg.passwd)
        assert.are.equal(1, cfg.config_version)
        assert.are.same(cfg, read(path))
    end)

    it("no pisa un valor que el usuario cambió", function()
        write(path, json.encode({ rotation_duration = 120000 }))
        assert.are.equal(120000, configurator:read_config_file().rotation_duration)
        assert.are.equal(120000, read(path).rotation_duration)
    end)

    it("no vuelve a migrar una config ya migrada", function()
        write(path, json.encode({ rotation_duration = 50000, config_version = 1 }))
        assert.are.equal(50000, configurator:read_config_file().rotation_duration)
    end)

    it("respeta una versión más nueva que la del firmware", function()
        write(path, json.encode({ rotation_duration = 50000, config_version = 99 }))
        local cfg = configurator:read_config_file()
        assert.are.equal(50000, cfg.rotation_duration)
        assert.are.equal(99, cfg.config_version)
    end)

    it("completa claves nuevas sin tocar las existentes", function()
        write(path, json.encode({ min_temperature = 36.0, config_version = 1 }))
        local cfg = configurator:read_config_file()
        assert.are.equal(36.0, cfg.min_temperature)
        assert.are.equal(35.0, cfg.humidifier_min_temp)
        assert.are.equal(35.0, read(path).humidifier_min_temp)
    end)

    it("un POST parcial no borra las demás claves", function()
        write(path, json.encode({ tray_two_date = 42, incubator_name = "incu-sur", config_version = 1 }))
        assert.is_true(configurator:encode_config_file({ min_hum = 50 }))
        local saved = read(path)
        assert.are.equal(50, saved.min_hum)
        assert.are.equal(42, saved.tray_two_date)
        assert.are.equal("incu-sur", saved.incubator_name)
        assert.are.equal(1, saved.config_version)
    end)

    it("regenera un archivo ilegible", function()
        write(path, "{no es json")
        local cfg = configurator:read_config_file()
        assert.are.equal(190000, cfg.rotation_duration)
        assert.are.equal(1, read(path).config_version)
    end)

    it("lee archivos más grandes que un bloque de lectura", function()
        write(path, json.encode({ incubator_name = string.rep("x", 30), ssid = string.rep("s", 600), config_version = 1 }))
        assert.are.equal(600, #configurator:read_config_file().ssid)
    end)
end)
