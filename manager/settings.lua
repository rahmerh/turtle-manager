local Settings = {}
Settings.__index = Settings

local function save(self)
    local file = fs.open(self._path, "w")
    file.write(textutils.serialize(self._settings))
    file.close()
end

function Settings.new(settings_file)
    local self = setmetatable({
        _path = settings_file or "settings.conf",
        _settings = {
            -- Default values
            auto_recover_quarries = false,
            fill_quarry_fluids = false,
        },
        keys = {
            auto_recover_quarries = "auto_recover_quarries",
            fill_quarry_fluids = "fill_quarry_fluids",
        }
    }, Settings)

    if fs.exists(self._path) then
        local f = fs.open(self._path, "r")
        local raw = f.readAll(); f.close()
        self._settings = textutils.unserialize(raw) or {}
    end

    return self
end

function Settings:register_on_change(on_change)
    if type(on_change) ~= "function" then
        error("Invalid on_change type, must be a function.")
    end

    self.on_change = on_change
end

function Settings:read(key)
    if not self.keys[key] then
        error(("Invalid setting: '%s'"):format(key))
    end

    return self._settings[key]
end

function Settings:set(key, value)
    if not self.keys[key] then
        error(("Invalid setting: '%s'"):format(key))
    end

    self._settings[key] = value
    save(self)

    self.on_change(key, value)
end

function Settings:list()
    return self._settings
end

return Settings
