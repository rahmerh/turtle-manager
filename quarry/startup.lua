local jobfile_name = "job-file"
local function load_jobfile()
    if not fs.exists(jobfile_name) then
        return
    end

    local f = fs.open(jobfile_name, "r")
    local data = textutils.unserialize(f.readAll())
    f.close()

    return data
end

local jobfile = load_jobfile()

if jobfile.resumable and jobfile.current_row then
    shell.run("quarry")
end
