local args = { ... }
local role = args[1] or "turtle"

local base = "https://raw.githubusercontent.com/rahmerh/turtle-manager/main"

local files = {
    turtle = {
        ["startup.lua"] = "turtle/startup.lua",
    },
    dashboard = {
        ["startup.lua"] = "dashboard/startup.lua",
    }
}

local selected = files[role]
if not selected then
    print("Unknown role: " .. role)
    return
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
