local printer = require("shared.printer")

local locator = {}

for _ = 1, 3 do
    local x, y, z = gps.locate(2)
    if x and y and z then
        break
    end

    printer.print_warning("Waiting for GPS...")
    sleep(2)
end

locator.get_pos = function()
    local x, y, z = gps.locate(2)
    if not x then error("GPS failed") end
    return { x = x, y = y, z = z }
end

return locator
