local wireless = require("wireless")
local movement = require("movement")

local CancelToken = require("cancel_token")

local queue = require("lib.queue")
local printer = require("lib.printer")
local inventory = require("lib.inventory")

printer.print_info("Booting runner #" .. os.getComputerID())

local task_handlers = {
    pickup = require("tasks.pickup"),
    resupply = require("tasks.resupply"),
    fluid_fill = require("tasks.fluid_fill")
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

local cancel_token

local active_task
local function report_progress(job_id, new_stage, cancelable)
    local index, _ = task_queue:find("job_id", job_id)

    if not index then
        return
    end

    task_queue:update(index, "stage", new_stage)
    task_queue:update(index, "cancelable", cancelable)
end

local runner_status = "Idle"
local start_heartbeat, _ = wireless.heartbeat.loop(manager_id, 1, function()
    local stored_fuel_units
    local fuel_slot = inventory.details_from_slot(1)
    if fuel_slot and fuel_slot.name == "minecraft:coal" then
        stored_fuel_units = fuel_slot.count * 80
    end

    local inventory_contents = inventory.list_contents(2, 16)

    return {
        status = runner_status,
        queued_tasks = task_queue:size(),
        current_location = movement.get_current_coordinates(),
        fuel_level = movement.get_fuel_level(),
        stored_fuel_units = stored_fuel_units,
        inventory_contents = inventory_contents,
        tasks = task_queue:all(),
    }
end)

wireless.router.register_handler(wireless.protocols.rpc, "pickup:dispatch", function(sender, m)
    local task = {
        job_id = m.data.job_id,
        target = m.data.position,
        what = m.data.what,
        task_type = "pickup",
        requested_by = m.data.requested_by,
    }

    task_queue:enqueue(task)

    printer.print_info(("[%s] Queued task 'pickup'"):format(m.data.job_id))
    wireless.pickup.notify_queued(sender, m.id)
end)

wireless.router.register_handler(wireless.protocols.rpc, "resupply:dispatch", function(sender, m)
    local task = {
        job_id = m.data.job_id,
        target = m.data.target,
        desired = m.data.desired,
        task_type = "resupply",
        requested_by = m.data.requested_by,
    }

    task_queue:enqueue(task)

    printer.print_info(("[%s] Queued task 'resupply'"):format(m.data.job_id))
    wireless.resupply.notify_queued(sender, m.id)
end)

wireless.router.register_handler(wireless.protocols.notify, "fluid_fill:dispatch", function(_, m)
    printer.print_info(("[%s] Queued task 'fluid fill'"):format(m.data.job_id))

    local task = {
        job_id = m.data.job_id,
        task_type = "fluid_fill",
        requester = m.data.requester,
        fluid_columns = m.data.fluid_columns,
    }

    task_queue:enqueue(task)
end)

wireless.router.register_handler(wireless.protocols.notify, "command:nudge_task", function(_, m)
    local index, task = task_queue:find("job_id", m.data.job_id)

    local target = task_queue:get(index + m.data.amount)

    if not index or not task or not target then
        error(("No item at %d"):format(index))
    end

    local nudging_active_task = active_task == m.data.job_id or active_task == target.job_id
    if nudging_active_task and (task.cancelable or target.cancelable) then
        cancel_token:cancel()

        task_queue:nudge(index, m.data.amount)

        local direction
        if m.data.amount < 0 then
            direction = "up"
        else
            direction = "down"
        end

        printer.print_info(("Nudged %s %s"):format(m.data.job_id, direction))
    elseif active_task ~= m.data.job_id then
        task_queue:nudge(index, m.data.amount)

        local direction
        if m.data.amount < 0 then
            direction = "up"
        else
            direction = "down"
        end

        printer.print_info(("Nudged %s %s"):format(m.data.job_id, direction))
    end
end)

local function main()
    wireless.registry.announce_at(manager_id, "runner")

    while true do
        local fuel = inventory.details_from_slot(1)
        if not fuel then
            printer.print_info("Requesting supplies...")

            local desired = { ["minecraft:coal"] = 64 }

            local supply_turtle_id = wireless.resupply.request(manager_id, movement.get_current_coordinates(), desired)
            inventory.drop_slots(1, 1, "up")
            wireless.resupply.signal_ready(supply_turtle_id)
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

        runner_status = "Running"
        cancel_token = CancelToken.new()

        local which_completed
        if task_handlers[task.task_type] then
            active_task = task.job_id
            which_completed = parallel.waitForAny(
                function() task_handlers[task.task_type](task, config, movement_context, report_progress) end,
                function() cancel_token:await() end)
        else
            printer.print_warning("Unsupported task: " .. task.task_type)
        end

        if which_completed == 2 then
            active_task = nil
            goto continue
        elseif which_completed == 1 then
            if task.task_type == "pickup" then
                wireless.completed.pickup_done(manager_id, task.what)
            end

            -- Unload inventory
            inventory.drop_slots(2, 16, "down")

            task_queue:ack()

            runner_status = "Idle"
            active_task = nil

            printer.print_info(("[%s] Done."):format(task.job_id))
        end

        ::continue::
    end
end

printer.print_success("Awaiting tasks...")

parallel.waitForAny(start_heartbeat, wireless.router.loop, main)
