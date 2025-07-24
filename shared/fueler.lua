local fueler = {}

local COAL_FUEL_UNITS = 80

fueler.refuel = function()
    if turtle.getFuelLevel() > 0 then return true end

    turtle.select(1)
    if turtle.refuel(1) then return true end
    for slot = 2, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then
            turtle.transferTo(1)
        end
    end
    turtle.select(1)
    return turtle.refuel(1)
end

fueler.calculate_fuel_for_quarry = function(width, depth, layers)
    local fuel_per_layer = (depth - 1) * width + (width - 1)
    local horizontal_fuel = fuel_per_layer * layers
    local vertical_fuel = (layers - 1) * 3

    return horizontal_fuel + vertical_fuel
end

fueler.fuel_to_coal = function(fuel)
    return math.ceil(fuel / COAL_FUEL_UNITS)
end

return fueler
