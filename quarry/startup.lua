local job = require("job")
local printer = require("lib.printer")

if not job.exists() then
    printer.print_info("Quarry #" .. os.getComputerID() .. " awaiting next command.")
    return
end

local quarry = require("quarry")
local wireless = require("wireless")
local movement = require("movement")

local inventory = require("lib.inventory")
local miner = require("lib.miner")

printer.print_info("Booting quarry #" .. os.getComputerID())

local initialized, init_err = job.initialize()
if not initialized and init_err then
    printer.print_error("Please run 'prepare' before starting this quarry.")
    return
end

wireless.open()
local manager_id, find_err = wireless.discovery.find("manager")
if not manager_id and find_err then
    printer.print_error("Could not determine manager: " .. find_err)
    return
end

wireless.router.register_handler(wireless.protocols.rpc, "command:pause", function(sender, m)
    wireless.ack(sender, m)
    job.set_status(job.statuses.paused)
    movement.pause()
    printer.print_warning("Received pause command.")
end)

wireless.router.register_handler(wireless.protocols.rpc, "command:resume", function(sender, m)
    wireless.ack(sender, m)
    job.set_status(job.statuses.in_progress)
    movement.resume()
    printer.print_info("Resuming...")
end)

local running = true
wireless.router.register_handler(wireless.protocols.rpc, "command:kill", function(sender, m)
    movement.pause()

    sleep(1) -- Allow turtle to stop.

    local coordinates = movement.get_current_coordinates()

    wireless.turtle_commands.confirm_kill(sender, m.id, coordinates)
    running = false

    printer.print_warning("Received kill command.")
end)

local movement_context = {
    dig = false,
    manager_id = manager_id
}

local movement_context_with_dig = {
    dig = true,
    manager_id = manager_id
}

local needed_supplies = {}
if not inventory.is_item_in_slot("minecraft:coal", 1) then
    needed_supplies["minecraft:coal"] = 64
end
if not inventory.is_item_in_slot("minecraft:chest", 2) then
    needed_supplies["minecraft:chest"] = 64
end

if next(needed_supplies) ~= nil then
    printer.print_info("Requesting supplies...")

    wireless.resupply.request(manager_id, movement.get_current_coordinates(), needed_supplies)
    local runner_id, job_id = wireless.resupply.await_arrival()
    wireless.resupply.signal_ready(runner_id, job_id)
    wireless.resupply.await_done()

    local coal_slot = inventory.find_item("minecraft:coal")
    if coal_slot ~= 1 then
        inventory.move_to_slot(coal_slot, 1)
    end

    local chest_slot = inventory.find_item("minecraft:chest")
    if chest_slot ~= 2 then
        inventory.move_to_slot(chest_slot, 2)
    end
end

local boundaries = job.get_boundaries()
local metadata = {
    boundaries = boundaries
}

local start_heartbeat, _ = wireless.heartbeat.loop(manager_id, 1, function()
    local stored_fuel_units
    local fuel_slot = inventory.details_from_slot(1)
    if fuel_slot.name == "minecraft:coal" then
        stored_fuel_units = fuel_slot.count * 80
    end

    return {
        status = job.status(),
        current_layer = job.current_layer(),
        current_row = job.current_row(),
        fuel_level = movement.get_fuel_level(),
        stored_fuel_units = stored_fuel_units,
        current_location = movement.get_current_coordinates()
    }
end)

local function kill_switch()
    while running do
        sleep(1)
    end
end

local function main()
    wireless.registry.register_self_as(manager_id, "quarry", metadata)

    if not job.status() == job.statuses.created then
        job.set_status(job.statuses.starting)

        local moved, moved_error = movement.move_to(
            boundaries.starting_position.x,
            boundaries.starting_position.y,
            boundaries.starting_position.z,
            movement_context)

        if not moved then
            error("Turtle stuck: " .. moved_error)
        end
    end

    if job.status() == job.statuses.paused then
        movement.pause()
    else
        job.set_status(job.statuses.in_progress)
    end

    printer.print_info("Quarry #" .. os.getComputerID() .. " in progress...")

    while job.current_layer() > 0 do
        local direction = quarry.get_row_direction_for_layer(boundaries.width, job.current_layer())

        local rows, length
        if direction == "north" or direction == "south" then
            rows = boundaries.width - job.current_row()
            length = boundaries.depth - 1
        else
            rows = boundaries.depth - job.current_row()
            length = boundaries.width - 1
        end

        for _ = 1, rows do
            local coords = quarry.starting_location_for_row(job.current_layer(), job.current_row(), boundaries)
            local moved, moved_error = movement.move_to(coords.x, coords.y, coords.z, movement_context_with_dig)

            if not moved then
                error("Turtle stuck: " .. moved_error)
            end

            local orientation_to_face
            if job.current_row() % 2 == 0 then
                orientation_to_face = direction
            else
                orientation_to_face = movement.opposite_of(direction)
            end
            movement.turn_to_direction(orientation_to_face)

            miner.mine_up()
            miner.mine_down()

            for _ = 1, length do
                local success, err = miner.mine()

                if not success and err then
                    printer.print_error(err)
                    return
                end

                movement.move_forward(movement_context)

                miner.mine_up()
                miner.mine_down()

                if inventory.are_all_slots_full() then
                    quarry.unload(manager_id)
                end
            end

            job.increment_row()
        end

        job.next_layer()
    end

    quarry.mine_bedrock_layer(
        boundaries.starting_position.x,
        boundaries.starting_position.z,
        boundaries.width,
        boundaries.depth,
        movement_context_with_dig)

    printer.print_success("Quarry done.")
    job.complete()

    movement.move_to(
        boundaries.starting_position.x,
        boundaries.starting_position.y,
        boundaries.starting_position.z,
        movement_context)

    wireless.completed.signal_completed(manager_id, movement.get_current_coordinates())
end

parallel.waitForAny(start_heartbeat, wireless.router.loop, main, kill_switch)
