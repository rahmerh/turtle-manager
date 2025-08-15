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
local FluidTracker = require("lib.fluid-tracker")

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

local settings
local boundaries = job.get_boundaries()
local metadata = {
    boundaries = boundaries
}

wireless.router.register_handler(wireless.protocols.rpc, "command:pause", function(_, _)
    job.set_status(job.statuses.paused)
    movement.pause()
    printer.print_warning("Received pause command.")
end)

wireless.router.register_handler(wireless.protocols.rpc, "command:resume", function(_, _)
    job.set_status(job.statuses.in_progress)
    movement.resume()
    printer.print_info("Resuming...")
end)

wireless.router.register_handler(wireless.protocols.notify, "settings:update", function(_, m)
    printer.print_info(("Setting update '%s': %s -> %s"):format(
        m.data.key,
        settings[m.data.key],
        m.data.value))
    settings[m.data.key] = m.data.value
end)

local running = true
wireless.router.register_handler(wireless.protocols.rpc, "command:kill", function(sender, m)
    movement.pause()
    job.set_status(job.statuses.offline)

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

local start_heartbeat, _ = wireless.heartbeat.loop(manager_id, 1, function()
    local stored_fuel_units
    local fuel_slot = inventory.details_from_slot(1)
    if fuel_slot and fuel_slot.name == "minecraft:coal" then
        stored_fuel_units = fuel_slot.count * 80
    end

    return {
        status = job.status(),
        current_layer = job.current_layer(),
        current_row = job.current_row(),
        fuel_level = movement.get_fuel_level(),
        stored_fuel_units = stored_fuel_units,
        current_location = movement.get_current_coordinates(),
        boundaries = boundaries,
    }
end)

local function kill_switch()
    while running do
        sleep(1)
    end
end

local function main()
    settings = wireless.registry.announce_at(manager_id, "quarry", metadata)

    local needed_supplies = {}
    if not inventory.is_item_in_slot("minecraft:coal", 1) then
        needed_supplies["minecraft:coal"] = 64
    end
    if not inventory.is_item_in_slot("minecraft:chest", 2) then
        needed_supplies["minecraft:chest"] = 64
    end

    if next(needed_supplies) ~= nil then
        printer.print_info("Requesting supplies...")

        local supply_turtle_id = wireless.resupply.request(
            manager_id,
            movement.get_current_coordinates(),
            needed_supplies)
        inventory.drop_slots(1, 1, "up")
        wireless.resupply.signal_ready(supply_turtle_id)
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

    if job.status() == job.statuses.created then
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
    end

    local track_fluids = settings.fill_quarry_fluids
    local fluid_tracker = FluidTracker.new()

    printer.print_info("Quarry #" .. os.getComputerID() .. " in progress...")

    local row_done_callback = function()
        job.increment_row()
    end

    job.set_status(job.statuses.in_progress)
    while job.current_layer() > 0 do
        local _, fluid_columns = quarry.mine_layer(
            job.current_layer(),
            boundaries,
            job.current_row(),
            row_done_callback,
            manager_id,
            fluid_tracker)

        if track_fluids then
            wireless.fluid_fill.report(manager_id, fluid_columns)
        end

        job.next_layer()
    end

    local end_y = boundaries.starting_position.y - 2 - ((boundaries.layers - 1) * 3)
    if end_y == -56 and job.current_layer() == 0 then
        job.set_status(job.statuses.in_progress)
        movement.move_to(
            boundaries.starting_position.x,
            -58,
            boundaries.starting_position.z,
            movement_context_with_dig)
        movement.turn_to_direction("north")

        for row = 1, boundaries.width do
            for _ = 1, boundaries.depth - 1 do
                miner.mine()
                movement.move_forward(movement_context)

                if inventory.are_all_slots_full() then
                    quarry.unload(manager_id)
                end
            end

            if row % 2 == 0 then
                movement.turn_left()
                miner.mine()
                movement.move_forward(movement_context)
                movement.turn_left()
            else
                movement.turn_right()
                miner.mine()
                movement.move_forward(movement_context)
                movement.turn_right()
            end
        end
    end

    if job.current_layer() == 0 then
        job.next_layer()
    end

    if job.current_layer() == -1 then
        job.set_status(job.statuses.in_progress)
        quarry.mine_bedrock_layer(
            boundaries.starting_position.x,
            boundaries.starting_position.z,
            boundaries.width,
            boundaries.depth,
            movement_context_with_dig)
    end

    printer.print_success("Quarry done.")
    job.complete()

    movement.move_to(
        boundaries.starting_position.x,
        boundaries.starting_position.y,
        boundaries.starting_position.z,
        movement_context)

    wireless.completed.quarry_done(manager_id, movement.get_current_coordinates())
end

parallel.waitForAny(start_heartbeat, wireless.router.loop, main, kill_switch)
