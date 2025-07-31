local wireless = require("wireless")
local printer = require("printer")
local task_store = require("task_store")

printer.print_info("Starting runner #" .. os.getComputerID())

local manager_id = wireless.register_new_turtle("runner")
if not manager_id then
    printer.print_error("No manager found, is there a manager instance running?")
    return
end

local status = "Idle"
local task_handlers = {
    pickup = require("pickup"),
    resupply = require("resupply")
}

local config_file = fs.open("runner.conf", "r")
local raw = config_file.readAll()
config_file.close()

local config = textutils.unserialize(raw)

local queue = task_store.new()

local function receive_task()
    while true do
        local sender, msg = wireless.receive_runner_task()

        if msg and msg.type and sender == manager_id then
            wireless.confirm_task_received(sender)
            printer.print_info("Queued task '" .. msg.type .. "'")
            queue:enqueue(msg)
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

        status = "Running (" .. task.type .. ")"

        if task_handlers[task.type] then
            task_handlers[task.type](task, config)
        else
            printer.print_warning("Unsupported task: " .. task.type)
        end

        wireless.task_completed(manager_id, task.type)

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
        if not wireless.send_heartbeat(manager_id, metadata) then
            error("Could not locate manager.")
        end
        sleep(1)
    end
end

local function kill_switch()
    while true do
        local _, id_to_kill = wireless.receive_kill()
        if id_to_kill == os.getComputerID() then
            printer.print_warning("Received kill command, exiting.")
            break
        end
    end
end

printer.print_success("Awaiting tasks...")

parallel.waitForAny(receive_task, run_task, kill_switch, heartbeat)
