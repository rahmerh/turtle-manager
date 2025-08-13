local Settings = {}
Settings.__index = Settings

Settings.keys = {
    AUTO_RECOVER_QUARRIES = "auto_recover_quarries",
}

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
            auto_recover_quarries = false
        },
        keys = {
            auto_recover_quarries = "auto_recover_quarries"
        }
    }, Settings)

    if fs.exists(self._path) then
        local f = fs.open(self._path, "r")
        local raw = f.readAll(); f.close()
        self._settings = textutils.unserialize(raw) or {}
    end

    return self
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
end

return Settings
