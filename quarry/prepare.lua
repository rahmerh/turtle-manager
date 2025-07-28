local printer = require("printer")
local fueler = require("fueler")

local startX, startY, startZ, depth, width = tonumber(arg[1]), tonumber(arg[2]), tonumber(arg[3]), tonumber(arg[4]),
    tonumber(arg[5])
if not startX or not startZ or not startY or not depth or not width then
    printer.print_error("Usage: prepare.lua <start_x> <start_y> <start_z> <depth> <width>")
    return
end

local job_file = "job-file"
if fs.exists(job_file) then
    local file = fs.open(job_file, "r")
    local firstLine = file.readLine()
    file.close()

    if firstLine then
        printer.print_warning("Found existing job.")
        printer.write_warning("Overwrite? y/n: ")
        local response = read()
        if response:lower() ~= "y" then
            print("Cancelled.")
            return
        end

        fs.delete(job_file)
    end
end

local layers = math.floor((startY + 59) / 3)
local job = {
    boundaries = { start_pos = { x = startX, y = startY, z = startZ }, width = width, depth = depth },
    total_layers = layers,
    resumable = true,
    unloading_chests = {}
}

local total_fuel = fueler.calculate_fuel_for_quarry(width, depth, layers)

printer.print_info("This quarry requires " .. total_fuel .. " fuel in total, excluding travel to the quarry.")
printer.print_info(" -  " .. fueler.fuel_to_coal(total_fuel) .. " coal")
printer.print_info("")
printer.print_info("Make sure this fuel is either in slot 1 or in the output chest.")

local f = fs.open(job_file, "w")
f.write(textutils.serialize(job))
f.close()

printer.print_success("Initialized job.")
