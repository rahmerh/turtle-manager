local mover = require("mover")
local fueler = require("fueler")
local errors = require("errors")

local function is_turtle(info)
    return info.name == "computercraft:turtle_advanced" or info.name == "computercraft:turtle_normal"
end

return function(task, config)
    fueler.refuel_from_inventory()

    -- +1 to make sure we're on top of the turtle to rescue
    local arrived, err = mover.move_to(task.pos.x, task.pos.y + 1, task.pos.z)

    while not arrived and err == errors.NO_FUEL do
        fueler.refuel_from_inventory()
        arrived, err = mover.move_to(task.pos.x, task.pos.y, task.pos.z)
    end

    local ok, info = turtle.inspectDown()

    if not ok then
        -- TODO: Handle error
    end

    if is_turtle(info) then

    end
end
