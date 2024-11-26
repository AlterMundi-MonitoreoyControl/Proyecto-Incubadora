http_request_methods = {
	http = require("socket.http"),
	apiendpoint = "http://192.168.1.16/", -- <-- default ip
	JSON = require("JSON"),
	inspect = require("inspect"),
	assert = require("luassert"),
	ltn12 = require("ltn12"),
	colors = require("ansicolors")
}

local function delay(seconds)
	os.execute("sleep " .. tonumber(seconds))
end

function http_request_methods:get_and_assert_200(attribute)
	delay(2) 
	local body, code = self.http.request(self.apiendpoint .. attribute)
	self.assert.are.equal(code, 200)
	return body
end

function http_request_methods:post_and_assert_201(attribute, json_value)
	delay(2)  

	local body, code = self.http.request {
			url = self.apiendpoint .. attribute,
			headers = {
					["content-Type"] = 'application/json',
					["Accept"] = 'application/json',
					["content-length"] = tostring(#json_value)
			},
			method = "POST",
			source = self.ltn12.source.string(json_value)
	}

	self.assert.are.equal(201, code)
	return body
end

function http_request_methods:post_and_assert_400(attribute, json_value)
	delay(2)

	local body, code = self.http.request {
			url = self.apiendpoint .. attribute,
			headers = {
					["content-Type"] = 'application/json',
					["Accept"] = 'application/json',
					["content-length"] = tostring(#json_value)
			},
			method = "POST",
			source = self.ltn12.source.string(json_value)
	}

	self.assert.are.equal(400, code)
	return body
end

return http_request_methods