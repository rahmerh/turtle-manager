local printer = require("printer")

local startX, startY, startZ, depth, width = tonumber(arg[1]), tonumber(arg[2]), tonumber(arg[3]), tonumber(arg[4]),
    tonumber(arg[5])
if not startX or not startZ or not startY or not depth or not width then
    printer.print_error("Usage: prepare.lua <start_x> <start_y> <start_z> <forward> <right>")
    return
end

local job_file = "quarry-job"
if fs.exists(job_file) then
    local file = fs.open(job_file, "r")
    local firstLine = file.readLine()
    file.close()

    print("here")

    if firstLine then
        printer.print_warning("Found existing coords.todo with unmined coordinates.")
        write("Overwrite and start new job? (y/N): ")
        local response = read()
        if response:lower() ~= "y" then
            print("Cancelled.")
            return
        end

        fs.delete(job_file)
    end
end

local coords = {}
for dz = 0, depth - 1 do
    for dx = 0, width - 1 do
        table.insert(coords, { startX + dx, startZ + dz })
    end
end

local job = {
    boundaries = { start_pos = { x = startX, y = startY, z = startZ }, width = width, depth = depth },
    current_layer = startY,
    layer_coords = coords
}

local f = fs.open(job_file, "w")
f.write(textutils.serialize(job))
f.close()

printer.print_success("Initialized job.")
