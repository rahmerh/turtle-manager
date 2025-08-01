local printer = require("shared.printer")
local task_store = require("task_store")
local wireless = require("wireless")
local utils = require("shared.utils")

printer.print_info("Booting runner #" .. os.getComputerID())

local status = "Idle"
local task_handlers = {
    pickup = require("tasks.pickup"),
    resupply = require("tasks.resupply")
}

if not fs.exists("runner.conf") then
    printer.print_error("Please run 'prepare' before starting this runner.")
    return
end

local config_file = fs.open("runner.conf", "r")
local raw = config_file.readAll()
config_file.close()

local config = textutils.unserialize(raw)

local queue = task_store.new()

local manager_id, err = wireless.discovery.find("manager")
if not manager_id and err then
    printer.print_error("Could not determine manager: " .. err)
    return
end

local start_heartbeat, _ = wireless.heartbeat.loop(manager_id, 1, function()
    return {
        last_seen = utils.epoch_in_seconds(),
        status = status
    }
end)

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

printer.print_success("Awaiting tasks...")

parallel.waitForAny(start_heartbeat)
