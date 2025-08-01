local errors = require("errors")

local inventory = {}

local function first_empty_slot()
    for i = 1, 16 do
        local info = turtle.getItemDetail(i)

        if not info then return i end
    end
end

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

    return true
end

function inventory.does_slot_contain_item(slot, item)
    local info = turtle.getItemDetail(slot)

    if info and info.name == item then
        return true
    else
        return false
    end
end

return inventory
