local wireless = require("wireless")
local printer = require("printer")
local mover = require("mover")
local locator = require("locator")

local manager_id = wireless.register_new_turtle("runner")
if not manager_id then
    printer.print_error("No manager found, is there a manager instance running?")
    return
end

local status = "Idle"

local function runner()
    while true do
        local sender, msg, protocol = wireless.receive(1, "runner_pool")

        if not msg then goto continue end

        wireless.send(sender, "ack", "runner_pool_ack")

        status = "Running"
        local current_pos = locator.get_pos()

        mover.move_to_z(msg.z)
        mover.move_to_x(msg.x)
        mover.move_to_y(msg.y)

        turtle.digDown()

        mover.move_to(current_pos.x, current_pos.y, current_pos.z)
        mover.turn_to_direction("south")

        for i = 2, 16 do
            turtle.select(i)
            turtle.drop()
        end

        turtle.select(1)

        status = "Idle"

        wireless.send(manager_id, "complete", "pickup")

        ::continue::
    end
end

local function heartbeat()
    while true do
        local metadata = {
            status = status,
        }
        if not wireless.heartbeat(manager_id, metadata) then
            error("Could not locate manager.")
        end
        sleep(1)
    end
end

parallel.waitForAny(runner, heartbeat)
