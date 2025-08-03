local args = { ... }
if #args == 0 then
    print("Usage: bootstrap <quarry|runner|manager>")
    return
end

local role    = args[1]

local OWNER   = "rahmerh"
local REPO    = "turtle-manager"
local REF     = "main"

-- ---- Layout per role ----
local LAYOUTS = {
    quarry = {
        { src = "quarry",   dest = "",         flatten = true },
        { src = "shared",   dest = "shared",   flatten = false },
        { src = "wireless", dest = "wireless", flatten = false },
        { src = "movement", dest = "movement", flatten = false },
    },
    runner = {
        { src = "runner",   dest = "",         flatten = true },
        { src = "shared",   dest = "shared",   flatten = false },
        { src = "wireless", dest = "wireless", flatten = false },
        { src = "movement", dest = "movement", flatten = false },
    },
    manager = {
        { src = "manager",  dest = "",         flatten = true },
        { src = "shared",   dest = "shared",   flatten = false },
        { src = "wireless", dest = "wireless", flatten = false },
        { src = "movement", dest = "movement", flatten = false },
    },
}

local layout  = LAYOUTS[role]
if not layout then
    print("Unknown role: " .. role)
    return
end

-- ---- GitHub helpers ----
local function gh(url)
    local headers = { ["User-Agent"] = "CC-Tweaked-bootstrap" }
    local res, err = http.get(url, headers)
    if not res then return nil, err end
    local body = res.readAll(); res.close()
    return body
end

local function list_dir(path)
    local url = ("https://api.github.com/repos/%s/%s/contents/%s?ref=%s")
        :format(OWNER, REPO, textutils.urlEncode(path), REF)
    local body, err = gh(url)
    if not body then return nil, ("http: " .. tostring(err)) end
    local data = textutils.unserializeJSON(body)
    if type(data) ~= "table" then return nil, "bad JSON" end
    return data
end

local function download_file(download_url, dest)
    local body, err = gh(download_url)
    if not body then return nil, err end
    fs.makeDir(fs.getDir(dest))
    local f = fs.open(dest, "w"); f.write(body); f.close()
    return true
end

-- ---- Sync logic ----
local function sync_tree(src_root, dest_root, flatten)
    local queue = { src_root }
    while #queue > 0 do
        local path = table.remove(queue)
        local entries, err = list_dir(path)
        if not entries then
            print("List failed: " .. path .. " (" .. tostring(err) .. ")")
        else
            for _, e in ipairs(entries) do
                if e.type == "file" then
                    -- dest path: flatten removes the leading src_root segment
                    local rel
                    if flatten then
                        -- keep only the file name when flattening
                        rel = e.name
                    else
                        rel = e.path:sub(#src_root + 2) -- strip "src_root/" prefix
                    end
                    local dest = dest_root ~= "" and fs.combine(dest_root, rel) or rel
                    print(("Downloading %s -> %s"):format(e.path, dest))
                    local ok, derr = download_file(e.download_url, dest)
                    if not ok then print("  failed: " .. tostring(derr)) end
                elseif e.type == "dir" then
                    if flatten then
                        -- still recurse, but keep flattening (everything dumped into dest_root)
                        table.insert(queue, e.path)
                    else
                        table.insert(queue, e.path)
                    end
                end
            end
        end
    end
end

-- Main
for _, m in ipairs(layout) do
    if m.dest ~= "" and fs.exists(m.dest) then
        print("Cleaning " .. m.dest .. "/")
        fs.delete(m.dest)
    end
end

for _, m in ipairs(layout) do
    sync_tree(m.src, m.dest, m.flatten)
end

shell.run("set motd.enable false")

print("Update complete.")
