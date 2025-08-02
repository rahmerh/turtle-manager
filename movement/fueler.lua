local wireless      = require("wireless")

local printer       = require("shared.printer")
local inventory     = require("shared.inventory")
local errors        = require("shared.errors")
local locator       = require("shared.locator")

local fueler        = {}

local ACCEPTED_FUEL = {
    ["minecraft:coal"] = true
}

local function parse_error(reason)
    if reason == "Items not combustible" then return errors.NOT_FUEL end
    if reason == "No items to combust" then return errors.NO_FUEL end
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
    if turtle.getFuelLevel() > 0 then
        return true
    end

    turtle.select(1)
    if turtle.refuel(4) then
        return true
    end

    local fuel_slot = scan_for_fuel()
    if not fuel_slot then
        return false, errors.NO_FUEL_STORED
    end

    if turtle.getItemCount(1) > 0 then
        local empty_slot = get_next_empty_slot()
        if not empty_slot then
            return false, errors.INV_FULL
        end
        turtle.select(1)
        turtle.transferTo(empty_slot)
    end

    turtle.select(fuel_slot)
    turtle.transferTo(1)
    turtle.select(1)
    if turtle.refuel(4) then
        return true
    else
        return false, errors.NOT_FUEL
    end
end

function fueler.handle_movement_result(ok, err, ctx)
    if ok then return "retry" end
    if err ~= errors.NO_FUEL then return nil, err end

    if fueler.refuel_from_inventory() then
        return "retry"
    end

    local manager_id = ctx.manager_id
    local current_position = locator.get_pos()
    local desired = { ["minecraft:coal"] = 64 }

    if not manager_id then
        return nil, errors.NO_FUEL
    end

    wireless.resupply.request(manager_id, current_position, desired)
    local runner_id, job_id = wireless.resupply.await_arrival()

    inventory.drop_slots(1, 1, "up")

    wireless.resupply.signal_ready(runner_id, job_id)

    wireless.resupply.await_done()

    return "retry"
end

return fueler
