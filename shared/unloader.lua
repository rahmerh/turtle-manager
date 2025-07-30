local mover = require("mover")
local wireless = require("wireless")
local locator = require("locator")

local unloader = {}

unloader.get_unloading_chests = function(progress)
    return progress.unloading_chests
end

function unloader.unload()
    local chest_detail = turtle.getItemDetail(2)
    if not chest_detail or chest_detail.count <= 1 or not chest_detail.name:lower():match("chest") then
        return nil
    end

    mover.move_back()
    mover.move_up()

    turtle.select(2)
    turtle.placeDown()

    -- Refuel first
    for i = 3, 16 do
        local item = turtle.getItemDetail(i)
        if item and item.name:lower():match("coal") then
            turtle.select(i)
            turtle.transferTo(1)
        end

        if turtle.getItemCount(1) == 64 then
            break
        end
    end

    -- Unload inventory
    local pos = locator.get_pos()
    for i = 3, 16 do
        local item = turtle.getItemDetail(i)
        if item and item.count > 0 then
            turtle.select(i)
            turtle.dropDown()
        end
    end
    turtle.select(1)

    mover.move_forward()
    mover.move_down()

    return pos
end

unloader.should_unload = function()
    local amount_of_filled_slots = 0
    for i = 3, 16 do
        if turtle.getItemCount(i) > 0 then
            amount_of_filled_slots = amount_of_filled_slots + 1
        end
    end

    return amount_of_filled_slots == 14
end

return unloader
