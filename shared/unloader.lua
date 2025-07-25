local mover = require("mover")
local locator = require("locator")

local unloader = {}

local total_unloading_chests = 0
local unloading_pos

unloader.create_unloading_area = function(start_x, start_y, start_z)
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

        mover.turn_right()
        mover.move_forward()
        mover.turn_left()
        turtle.select(2)
        turtle.placeDown()
        turtle.select(1)

        total_unloading_chests = total_unloading_chests + 1
    end

    unloading_pos = { x = start_x, y = start_y, z = start_z + 1 }
    mover.move_to(start_x, start_y, start_z)
end

unloader.unload_at_chest = function(chest_number)
    if not unloading_pos then
        error("No unloading chests set.")
    end

    mover.move_to_y(unloading_pos.y)
    mover.move_to_x(unloading_pos.x)
    mover.move_to_z(unloading_pos.z)

    mover.turn_to_direction("east")

    for _ = 1, chest_number - 1 do
        turtle.up()
    end

    for i = 3, 16 do
        turtle.select(i)
        turtle.drop()
    end
    turtle.select(1)
end

return unloader
