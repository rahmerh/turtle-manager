local wireless = require("wireless")
local printer = require("printer")
local mover = require("mover")
local locator = require("locator")
local task_store = require("task_store")

printer.print_info("Starting runner #" .. os.getComputerID())

local manager_id = wireless.register_new_turtle("runner")
if not manager_id then
    printer.print_error("No manager found, is there a manager instance running?")
    return
end

local status = "Idle"

local queue = task_store.new()

local function receive_task()
    while true do
        local sender, msg, _ = wireless.receive(1, "runner_pool")

        if msg and sender == manager_id then
            printer.print_info("Recieved '" .. msg.type .. "' task from manager.")
            wireless.send(sender, "ack", "runner_pool_ack")
            queue:enqueue(msg.pos, msg.type)
        end

        if queue:size() > 10000 then
            queue:compact()
        end
    end
end

local function run_task()
    while true do
        local task = queue:peek()

        if not task then
            sleep(1)
            goto continue
        end

        status = "Running (pickup)"
        local current_pos = locator.get_pos()

        mover.move_to(task.pos.x, task.pos.y, task.pos.z)

        -- TODO: Move this to pickup task
        turtle.digDown()

        mover.move_to(current_pos.x, current_pos.y, current_pos.z)
        mover.turn_to_direction("south")

        for i = 2, 16 do
            local item = turtle.getItemDetail(i)
            if item and item.count > 0 then
                turtle.select(i)
                turtle.drop()
            end
        end
        turtle.select(1)

        wireless.send(manager_id, "complete", "pickup")
        queue:ack()
        status = "Idle"

        ::continue::
    end
end

local function heartbeat()
    while true do
        local metadata = {
            status = status,
            queued_tasks = queue:size()
        }
        if not wireless.heartbeat(manager_id, metadata) then
            error("Could not locate manager.")
        end
        sleep(1)
    end
end

local function kill_switch()
    while true do
        local _, id_to_kill, _ = wireless.receive(5, "kill")
        if id_to_kill == os.getComputerID() then
            printer.print_warning("Received kill command, exiting.")
            break
        end
    end
end

printer.print_success("Awaiting tasks...")

parallel.waitForAny(receive_task, run_task, kill_switch, heartbeat)
