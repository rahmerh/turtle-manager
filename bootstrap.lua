local args = { ... }

if #args == 0 then
    print("Error: No role provided. Usage:")
    print("  lua bootstrap.lua <turtle|dashboard>")
    return
end

local role = args[1]
local base = "https://raw.githubusercontent.com/rahmerh/turtle-manager/main"

local files = {
    quarry = {
        ["quarry.lua"] = "quarry/quarry.lua",
        ["prepare.lua"] = "quarry/prepare.lua",
        ["startup.lua"] = "quarry/startup.lua",
        ["job.lua"] = "quarry/job.lua",
    },
    manager = {
        ["startup.lua"] = "manager/startup.lua"
    }
}

local selected = files[role]
if not selected then
    print("Unknown role: " .. role)
    return
end

local shared_files = {
    ["fueler.lua"] = "shared/fueler.lua",
    ["locator.lua"] = "shared/locator.lua",
    ["mover.lua"] = "shared/mover.lua",
    ["printer.lua"] = "shared/printer.lua",
    ["wireless.lua"] = "shared/wireless.lua"
}

for name, path in pairs(shared_files) do
    selected[name] = path
end

for dest, _ in pairs(selected) do
    if fs.exists(dest) then
        fs.delete(dest)
    end
end

for dest, src in pairs(selected) do
    local url = base .. "/" .. src
    print("Downloading " .. src .. " → " .. dest)

    local res = http.get(url)
    if res then
        fs.makeDir(fs.getDir(dest))
        local f = fs.open(dest, "w")
        f.write(res.readAll())
        f.close()
        res.close()
    else
        print("Failed to download: " .. src)
    end
end

print("Update complete.")
