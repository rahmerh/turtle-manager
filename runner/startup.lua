local task_store = require("task_store")
local wireless = require("wireless")
local movement = require("movement")

local printer = require("lib.printer")
local inventory = require("lib.inventory")

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

wireless.open()
local manager_id, err = wireless.discovery.find("manager")
if not manager_id and err then
    printer.print_error("Could not determine manager: " .. err)
    return
end

local movement_context = {
    dig = false,
    manager_id = manager_id
}

wireless.registry.register_self_as(manager_id, "runner")

local start_heartbeat, _ = wireless.heartbeat.loop(manager_id, 1, function()
    return {
        status = status,
        queued_tasks = queue:size(),
        current_location = movement.get_current_coordinates()
    }
end)

wireless.router.register_handler(wireless.protocols.rpc, "pickup:dispatch", function(sender, m)
    wireless.ack(sender, m)
    printer.print_info(("[%s] Queued task 'pickup'"):format(m.data.job_id))
    queue:enqueue(m)
end)

wireless.router.register_handler(wireless.protocols.rpc, "resupply:dispatch", function(sender, m)
    wireless.ack(sender, m)
    printer.print_info(("[%s] Queued task 'pickup'"):format(m.data.job_id))
    queue:enqueue(m)
end)

local function category(operation)
    local i = operation:find(":", 1, true)
    return i and operation:sub(1, i - 1) or operation
end

local function main()
    while true do
        local fuel = inventory.details_from_slot(1)
        if not fuel then
            printer.print_info("Requesting supplies...")
            local desired = { ["minecraft:coal"] = 64 }
            wireless.resupply.request(manager_id, movement.get_current_coordinates(), desired)
            local runner_id, job_id = wireless.resupply.await_arrival()
            wireless.resupply.signal_ready(runner_id, job_id)
            wireless.resupply.await_done()
        elseif fuel.count < 16 then
            printer.print_info("Refueling self...")
            movement.move_to(
                config.supply_chest_pos.x,
                config.supply_chest_pos.y + 1,
                config.supply_chest_pos.z)
            local slot = inventory.pull_items_from_down("minecraft:coal", 64 - fuel.count)
            inventory.merge_into_slot(slot, 1)
            movement.move_to(
                config.unloading_chest_pos.x,
                config.unloading_chest_pos.y + 1,
                config.unloading_chest_pos.z)
        end

        local task = queue:peek()

        if not task then
            sleep(1)
            goto continue
        end

        local task_type = category(task.operation)

        status = "Running (" .. task_type .. ")"

        if task_handlers[task_type] then
            task_handlers[task_type](task, config, movement_context)
        else
            printer.print_warning("Unsupported task: " .. task_type)
        end

        queue:ack()
        status = "Idle"

        ::continue::
    end
end

printer.print_success("Awaiting tasks...")

parallel.waitForAny(start_heartbeat, wireless.router.loop, main)
