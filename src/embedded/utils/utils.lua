local utils = {}

local function is_empty(t)
-- evaluate if a table is empty
   return next(t) == nil
end   

local function inspect(t, lvl)
   -- print a table

   if type(t) ~= "table" then
      print("Not a table. Object type: ".. type(t))
      return
   end

   local lvl = lvl or 1
   for k,v in pairs(t) do
      if lvl > 0 then margin = string.rep(". ", lvl) else margin = "" end
      print(margin .. k .. ": ")
      if type(v) == "table" or type(v) == "romtable" then
         if not is_empty(v) then
            dir(v, lvl+1)
         end
      else
         print(margin .." ".. tostring(v))
      end
   end
end

utils.inspect = inspect
return  utils
