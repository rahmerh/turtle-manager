local wireless      = require("wireless")
local locator       = require("movement.locator")

local inventory     = require("lib.inventory")
local errors        = require("lib.errors")

local fueler        = {}

local ACCEPTED_FUEL = {
    ["minecraft:coal"] = true
}

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
    if err ~= errors.NO_FUEL then return ok, err end

    if fueler.refuel_from_inventory() then
        return "retry"
    end

    local manager_id = ctx.manager_id
    local current_coordinates = locator.get_current_coordinates()
    local desired = { ["minecraft:coal"] = 64 }

    if not manager_id then
        return nil, errors.NO_FUEL
    end

    wireless.resupply.request(manager_id, current_coordinates, desired)
    local runner_id, job_id = wireless.resupply.await_arrival()
    inventory.drop_slots(1, 1, "up")
    wireless.resupply.signal_ready(runner_id, job_id)
    wireless.resupply.await_done()

    local slot = inventory.find_item("minecraft:coal")
    if slot ~= 1 then
        local moved, moved_err = inventory.move_to_slot(slot, 1, true)

        if not moved and moved_err then
            return moved, moved_err
        end
    end

    return "retry"
end

return fueler
