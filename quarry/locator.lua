local locator = {}

locator.get_pos = function()
    local x, y, z = gps.locate(2)
    if not x then error("GPS failed") end
    return { x = x, y = y, z = z }
end

return locator
