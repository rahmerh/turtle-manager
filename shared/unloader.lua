local mover = require("mover")

local unloader = {}

unloader.get_unloading_chests = function(progress)
    return progress.unloading_chests
end

unloader.create_initial_unloading_area = function(start_x, start_y, start_z)
    mover.move_to(start_x, start_y, start_z)

    mover.turn_to_direction("east")

    mover.move_forward()

    mover.turn_right()

    local success, data = turtle.inspect()
    local chest_exists = success and data.name:match("chest")

    if not chest_exists then
        for i = 1, 2 do
            for _ = 1, 3 do
                while turtle.detect() do
                    turtle.dig()
                end
                mover.move_forward()
                turtle.digUp()
            end

            if i == 1 then
                mover.turn_right()
                while turtle.detect() do
                    turtle.dig()
                end
                mover.move_forward()
                mover.turn_right()
                turtle.digUp()
            end
        end

        -- Place the unloading chest
        turtle.back()
        turtle.up()
        mover.turn_right()
        mover.move_forward()
        turtle.select(2)
        turtle.placeDown()

        -- Make it a double
        mover.turn_right()
        mover.move_forward()
        mover.turn_left()
        turtle.select(2)
        turtle.placeDown()

        -- Place refueling chest
        mover.turn_right()
        mover.move_forward()
        mover.turn_right()
        mover.move_forward()
        mover.turn_left()
        turtle.placeDown()

        turtle.select(1)
    end

    local unloading_pos = { x = start_x, y = start_y, z = start_z + 1 }
    mover.move_to(start_x, start_y, start_z)

    return 1, unloading_pos
end

function unloader.unload()
    mover.move_back()
    mover.move_up()
    turtle.select(2)
    turtle.placeDown()

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
