local job = require("job")
local quarry = require("quarry")
local wireless = require("wireless")
local movement = require("movement")

local printer = require("shared.printer")
local inventory = require("shared.inventory")
local miner = require("shared.miner")
local list = require("shared.list")

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

local needed_supplies = {}
if not inventory.is_item_in_slot("minecraft:coal", 1) then
    needed_supplies["minecraft:coal"] = 64
end
if not inventory.is_item_in_slot("minecraft:chest", 2) then
    needed_supplies["minecraft:chest"] = 64
end

if next(needed_supplies) ~= nil then
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

wireless.registry.register_self_as(manager_id, "quarry")

local start_heartbeat, _ = wireless.heartbeat.loop(manager_id, 1, function()
    return {
        status = job.status(),
        current_layer = job.current_layer(),
        current_row = job.current_row(),
        current_location = movement.get_current_coordinates()
    }
end)

local function detect_and_handle_fluids()
    local fluids = {
        "minecraft:water",
        "minecraft:lava"
    }

    local selected = turtle.getSelectedSlot()
    local cobblestone = inventory.find_item("minecraft:cobblestone")

    local detected, info = turtle.inspect()
    if detected and list.contains(fluids, info.name) then
        turtle.select(cobblestone)
        turtle.place()
        miner.mine()
        turtle.select(selected)
    end

    local up_detected, up_info = turtle.inspectUp()
    if up_detected and list.contains(fluids, up_info.name) then
        turtle.select(cobblestone)
        turtle.placeUp()
        miner.mine_up()
        turtle.select(selected)
    end

    local down_detected, down_info = turtle.inspectDown()
    if down_detected and list.contains(fluids, down_info.name) then
        turtle.select(cobblestone)
        turtle.placeDown()
        miner.mine_down()
        turtle.select(selected)
    end
end

local function main()
    local boundaries = job.get_boundaries()

    local movement_context = {
        dig = true,
        manager_id = manager_id
    }

    if not job.is_in_progress() then
        local moved, moved_error = movement.move_to(
            boundaries.starting_position.x,
            boundaries.starting_position.y,
            boundaries.starting_position.z,
            movement_context)

        if not moved then
            error("Turtle stuck: " .. moved_error)
        end
    end

    job.set_status(job.statuses.in_progress)
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
            local moved, moved_error = movement.move_to(coords.x, coords.y, coords.z, movement_context)

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
                detect_and_handle_fluids()

                local success, err = miner.mine()

                if not success and err then
                    printer.print_error(err)
                    return
                end

                movement.move_forward(movement_context)

                -- Ignore errors, we can move forward even with up/down blocked.
                miner.mine_up()
                miner.mine_down()

                -- TODO: Request chests if not enough.
                if inventory.are_all_slots_full() then
                    local has_chests = inventory.is_item_in_slot("minecraft:chest", 2)

                    if not has_chests then
                        local desired = { ["minecraft:chest"] = 64 }
                        wireless.resupply.request(manager_id, movement.get_current_coordinates(), desired)
                        local runner_id, job_id = wireless.resupply.await_arrival()
                        inventory.drop_slots(2, 2, "up")
                        wireless.resupply.signal_ready(runner_id, job_id)
                        wireless.resupply.await_done()

                        local chest_slot = inventory.find_item("minecraft:chest")
                        if chest_slot ~= 2 then
                            inventory.move_to_slot(chest_slot, 2)
                        end
                    end

                    movement.move_back()
                    movement.move_up()

                    turtle.select(2)
                    turtle.placeDown()
                    inventory.drop_slots(3, 16, "down")

                    wireless.pickup.request(manager_id, movement.get_current_coordinates())

                    movement.move_forward()
                    movement.move_down()
                end
            end

            job.increment_row()
        end

        job.next_layer()
    end

    job.complete()
end

parallel.waitForAny(start_heartbeat, main)

job.set_status(job.statuses.idle)
