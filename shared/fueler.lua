local errors = require("errors")

local fueler = {}

local ACCEPTED_FUEL = {
    ["coal"] = true
}

fueler.refuel_from_inventory = function()
    if turtle.getFuelLevel() > 0 then return true, nil end

    if turtle.getSelectedSlot() ~= 1 then
        turtle.select(1)
    end

    for i = 3, 16 do
        local item = turtle.getItemDetail(i)

        if item and ACCEPTED_FUEL[item.name] then
            turtle.transferTo(1)
        end

        if turtle.getItemCount(1) == 64 then
            break
        end
    end

    local refueled, err = turtle.refuel(5)

    if not refueled and err then
        local fuel = turtle.getItemDetail(1)

        if fuel.count == 0 then
            return nil, errors.NO_FUEL_STORED
        else
            return refueled, err
        end
    end

    return true, nil
end

return fueler
