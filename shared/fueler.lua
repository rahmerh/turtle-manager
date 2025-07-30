local printer = require("printer")

local fueler = {}

local COAL_FUEL_UNITS = 80

fueler.refuel_from_inventory = function()
    if turtle.getFuelLevel() > 0 then return true end

    turtle.select(1)
    if turtle.refuel(5) then return true end
    for slot = 3, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then
            turtle.transferTo(1)
        end

        if turtle.getItemCount(1) == 64 then
            break
        end
    end

    turtle.select(1)
    return turtle.refuel(1)
end

fueler.refuel_from_chest = function()
    local success, data = turtle.inspect()
    local chest_exists = success and data.name:match("chest")

    if not chest_exists then
        printer.print_error("No chest in front of turtle, can't refuel.")
        return
    end
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
