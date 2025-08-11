local wireless = require("wireless")
local movement = require("movement")

local queue = require("lib.queue")
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

local task_queue = queue.new("tasks.db")

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

local start_heartbeat, _ = wireless.heartbeat.loop(manager_id, 1, function()
    local stored_fuel_units
    local fuel_slot = inventory.details_from_slot(1)
    if fuel_slot and fuel_slot.name == "minecraft:coal" then
        stored_fuel_units = fuel_slot.count * 80
    end

    local inventory_contents = inventory.list_contents(2, 16)

    return {
        status = status,
        queued_tasks = task_queue:size(),
        current_location = movement.get_current_coordinates(),
        fuel_level = movement.get_fuel_level(),
        stored_fuel_units = stored_fuel_units,
        inventory_contents = inventory_contents,
        tasks = task_queue:all(),
    }
end)

wireless.router.register_handler(wireless.protocols.rpc, "pickup:dispatch", function(sender, m)
    wireless.ack(sender, m)
    printer.print_info(("[%s] Queued task 'pickup'"):format(m.data.job_id))

    local task = {
        job_id = m.data.job_id,
        target = m.data.target,
        task_type = "pickup",
        requester = m.data.requester,
    }

    task_queue:enqueue(task)
end)

wireless.router.register_handler(wireless.protocols.rpc, "resupply:dispatch", function(sender, m)
    wireless.ack(sender, m)
    printer.print_info(("[%s] Queued task 'resupply'"):format(m.data.job_id))

    local task = {
        job_id = m.data.job_id,
        target = m.data.target,
        task_type = "resupply",
        requester = m.data.requester,
        desired = m.data.desired,
    }

    task_queue:enqueue(task)
end)

local function main()
    wireless.registry.register_self_as(manager_id, "runner")

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

        local task = task_queue:peek()

        if not task then
            sleep(1)
            goto continue
        end

        status = "Running"

        if task_handlers[task.task_type] then
            task_handlers[task.task_type](task, config, movement_context)
        else
            printer.print_warning("Unsupported task: " .. task.task_type)
        end

        wireless.completed.signal_completed(manager_id, movement.get_current_coordinates())

        -- Unload inventory
        inventory.drop_slots(2, 16, "down")

        task_queue:ack()
        status = "Idle"
        printer.print_info(("[%s] Done."):format(task.job_id))

        ::continue::
    end
end

printer.print_success("Awaiting tasks...")

parallel.waitForAny(start_heartbeat, wireless.router.loop, main)
