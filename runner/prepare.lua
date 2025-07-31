local printer = require("printer")

printer.print_info("Coordinates of the unloading chest:")

local unloading_chest_x, unloading_chest_y, unloading_chest_z
local unloading_chest_complete = false

while not unloading_chest_complete do
    if not unloading_chest_x then
        printer.write_prompt("X: ")
        unloading_chest_x = read()
    elseif not unloading_chest_y then
        printer.write_prompt("Y: ")
        unloading_chest_y = read()
    elseif not unloading_chest_z then
        printer.write_prompt("Z: ")
        unloading_chest_z = read()
    end

    if unloading_chest_x and unloading_chest_y and unloading_chest_z then
        unloading_chest_complete = true
    end
end

printer.print_info("Coordinates of the supply chest:")

local supply_chest_x, supply_chest_y, supply_chest_z
local supply_chest_complete = false

while not supply_chest_complete do
    if not supply_chest_x then
        printer.write_prompt("X: ")
        supply_chest_x = read()
    elseif not supply_chest_y then
        printer.write_prompt("Y: ")
        supply_chest_y = read()
    elseif not supply_chest_z then
        printer.write_prompt("Z: ")
        supply_chest_z = read()
    end

    if supply_chest_x and supply_chest_y and supply_chest_z then
        supply_chest_complete = true
    end
end

local config = {
    unloading_chest_pos = {
        x = unloading_chest_x,
        y = unloading_chest_y,
        z = unloading_chest_z
    },
    supply_chest_pos = {
        x = supply_chest_x,
        y = supply_chest_y,
        z = supply_chest_z
    }
}

local config_file = fs.open("runner.conf", "w+")
config_file.write(textutils.serialize(config))
config_file.close()

printer.print_success("Runner configured, reboot the turtle to start.")
