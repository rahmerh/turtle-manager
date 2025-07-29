local mover = require("mover")
local wireless = require("wireless")
local locator = require("locator")

local unloader = {}

unloader.get_unloading_chests = function(progress)
    return progress.unloading_chests
end

function unloader.unload()
    mover.move_back()
    mover.move_up()

    turtle.select(2)
    turtle.placeDown()

    local pos = locator.get_pos()
    for i = 3, 16 do
        turtle.select(i)
        local item = turtle.getItemDetail()
        if item and not item.name:lower():match("coal") then
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
