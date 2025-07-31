local errors = require("errors")

local fueler = {}

local ACCEPTED_FUEL = {
    ["coal"] = true
}

local function reason_to_error(reason)
    if reason == "Items not combustible" then return errors.NOT_FUEL end
    if reason == "No items to combust" then return errors.NO_FUEL_STORED end
end

local function get_next_empty_slot()
    for i = 1, 16 do
        local info = turtle.getItemDetail(i)

        if not info then return i end
    end
end

local function scan_for_fuel()
    for i = 3, 16 do
        local item = turtle.getItemDetail(i)

        if item and ACCEPTED_FUEL[item.name] then
            return i
        end
    end
end

fueler.refuel_from_inventory = function()
    if turtle.getFuelLevel() > 0 then return true, nil end

    if turtle.getSelectedSlot() ~= 1 then
        turtle.select(1)
    end

    local refueled, err = turtle.refuel(1)

    if not refueled and err then
        err = reason_to_error(err)

        if err == errors.NOT_FUEL then
            turtle.select(1)

            local empty_slot = get_next_empty_slot()

            if not empty_slot then
                -- TODO: Inventory full, can't move.
            end

            turtle.transferTo(empty_slot)

            local fuel_slot = scan_for_fuel()
            turtle.transferTo(1)
        end

        return refueled, errors.NO_FUEL_STORED
    end

    return true, nil
end

return fueler
