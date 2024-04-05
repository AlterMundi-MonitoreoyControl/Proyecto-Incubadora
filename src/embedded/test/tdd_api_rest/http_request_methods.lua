-- First connect to the incubator's own Wi-Fi to perform unit tests (ssid : incubator | passwd : 12345678) default url: "http://192.168.16.10/"
http_request_methods = {
  http        = require("socket.http"),
  apiendpoint = "http://192.168.1.10/",
  JSON        = require("JSON"),
  inspect     = require("inspect"),
  assert      = require("luassert"),
  ltn12       = require("ltn12"),
  colors      = require("ansicolors")
}

function http_request_methods:get_and_assert_200(atribute)
  
  local body, code, headers, status = http_request_methods.http.request(http_request_methods.apiendpoint .. atribute)
  http_request_methods.assert.are.equal(code, 200)
  return body
end

function http_request_methods:post_and_assert_201(atribute, value)
  
  local body, code, _, _ = http_request_methods.http.request {
    url = http_request_methods.apiendpoint .. atribute,
    headers = {
      ["content-Type"] = 'application/json',
      ["Accept"] = 'application/json',
      ["content-length"] = tostring(#value)
    },
    method = "POST",
    source = http_request_methods.ltn12.source.string(value)
  }
  http_request_methods.assert.are.equal(201, code)
  return body
end

function http_request_methods:post_and_assert_400(atribute, value)
  -- In that case, if a body is provided as a string, the function will
  -- perform a POST method in the url.
  
  local body, code, _, _ = http_request_methods.http.request {
    url = http_request_methods.apiendpoint .. atribute,
    headers = {
      ["content-Type"] = 'application/json',
      ["Accept"] = 'application/json',
      ["content-length"] = tostring(#value)
    },
    method = "POST",
    source = http_request_methods.ltn12.source.string(value)
  }
  local table_json = http_request_methods.JSON:decode(value)
  local pretty_json = http_request_methods.JSON:encode_pretty(table_json)

  print(string.format(self.colors([[

  %{red}%{underline}[#]POST 400:%{reset}

  %{yellow}Config Send:		

  %s


  %{red}%{underline}RESPONSE CODE: %s	%{reset}	

]]), pretty_json, code))

  http_request_methods.assert.are.equal(400, code)

  return body
end

return http_request_methods, http, JSON, inspect
