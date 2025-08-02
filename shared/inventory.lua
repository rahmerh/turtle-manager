local errors = require("shared.errors")

local inventory = {}

local function first_empty_slot()
    for i = 1, 16 do
        local info = turtle.getItemDetail(i)

        if not info then return i end
    end
end

--- Pulls a specific item/amount from an inventory downwards.
--- Since this can't be done directly, it requires a buffer inventory above.
---@param item string
---@param amount number
---@return number|nil -- The slot it pulled items into or nil if it couldn't pull.
---@return nil|string -- Nil if successful or string if it couldn't pull.
function inventory.pull_items_from_down(item, amount)
    local empty_slot = first_empty_slot()

    if not first_empty_slot then
        return nil, errors.INV_FULL
    end

    local buffer_chest = peripheral.wrap("top")
    local supply_chest = peripheral.wrap("bottom")

    local supply_contents = supply_chest.list()

    local total = 0
    for slot, item_details in pairs(supply_contents) do
        local needed = amount - total
        if item_details.name == item then
            local pushed = supply_chest.pushItems(peripheral.getName(buffer_chest), slot, needed)
            total = total + pushed
        end

        if total == amount then
            break
        end
    end

    turtle.select(empty_slot)
    turtle.suckUp()

    turtle.select(1)

    return empty_slot, nil
end

function inventory.does_slot_contain_item(slot, item)
    local info = turtle.getItemDetail(slot)

    if info and info.name == item then
        return true
    else
        return false
    end
end

function inventory.are_all_slots_full()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            return false
        end
    end

    return true
end

function inventory.drop_slots(from, to, direction)
    for i = from, to do
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)

            if direction == "up" then
                turtle.dropUp()
            elseif direction == "down" then
                turtle.dropDown()
            elseif direction == "forward" then
                turtle.drop()
            else
                error("Invalid direction: " .. direction)
            end
        end
    end

    turtle.select(1)
end

function inventory.is_item_in_slot(item, slot)
    local result = false

    local info = turtle.getItemDetail(slot)
    if info then
        result = item:lower() == info.name:lower()
    end

    return result
end

return inventory
