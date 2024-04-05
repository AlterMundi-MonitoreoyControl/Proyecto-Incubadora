-- this file is only requiered for testing examples 
local mymodule = {}

function mymodule.foo()
    print("Hello World!")
end

function mymodule.greet(text)
    print("original greet fucntion called whith " .. text)
end

return mymodule