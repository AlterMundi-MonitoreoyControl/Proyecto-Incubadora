local lapis = require("lapis")
local app = lapis.Application()
local json_params = require("lapis.application").
json_params

file = io.open("datos.txt", "a")


app:match("/", function(self)
    print(self.params.value)
    print(self.params.device)
  print (ngx.req.get_body_data())
  ngx.req.read_body()
  file:write(ngx.req.get_body_data() or "sin datos",";",os.date("%c"), "\n")
  --return ngx.req.get_body_data()
  return ngx.req.get_body_file()
  --return "OK"
end)

return app
