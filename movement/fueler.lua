local errors = require("shared.errors")
local resupply = require("wireless").resupply

local fueler = {}

local ACCEPTED_FUEL = {
    ["minecraft:coal"] = true
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
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)

        if item and ACCEPTED_FUEL[item.name] then
            return i
        end
    end
end

function fueler.refuel_from_inventory()
    if turtle.getFuelLevel() > 0 then return true, nil end

    if turtle.getSelectedSlot() ~= 1 then
        turtle.select(1)
    end

    local refueled, err = turtle.refuel(4)

    while not refueled and err do
        err = reason_to_error(err)

        if err == errors.NOT_FUEL then
            turtle.select(1)

            local empty_slot = get_next_empty_slot()

            if not empty_slot then
                -- TODO: Inventory full, can't move.
            end

            turtle.transferTo(empty_slot)

            local fuel_slot = scan_for_fuel()

            if not fuel_slot then
                return refueled, errors.NO_FUEL_STORED
            end

            turtle.select(fuel_slot)
            turtle.transferTo(1)
            turtle.select(1)

            refueled, err = turtle.refuel(4)
        end

        return refueled, errors.NO_FUEL_STORED
    end

    return true, nil
end

function fueler.handle_movement_result(ok, err, ctx)
    if ok then return "retry" end
    if err ~= errors.NO_FUEL then return nil, err end

    if fueler.refuel_from_inventory() then
        return "retry"
    end

    local manager_id = ctx.manager_id
    local current_position = ctx.current_position
    local desired = { ["minecraft:coal"] = 64 }

    if not manager_id or not current_position then
        return nil, errors.NO_FUEL
    end
    -- TODO: Re-implement resupply
end

return fueler
