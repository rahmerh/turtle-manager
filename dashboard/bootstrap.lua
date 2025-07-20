local base = "https://raw.githubusercontent.com/rahmerh/turtle-manager/main"

local files = {
    ["startup.lua"] = "dashboard/startup.lua",
}

for dest, src in pairs(files) do
    local url = base .. "/" .. src
    print("Downloading " .. src .. " → " .. dest)

    local response = http.get(url)
    if response then
        fs.makeDir(fs.getDir(dest))
        local f = fs.open(dest, "w")
        f.write(response.readAll())
        f.close()
        response.close()
    else
        print("Failed to fetch " .. url)
    end
end

print("✓ All files downloaded. Ready to run.")
