local FluidTracker = {}
FluidTracker.__index = FluidTracker

local function save(self)
    local file = fs.open(self._path, "w")
    file.write(textutils.serialize(self._coordinates))
    file.close()
end

function FluidTracker.new(file_name)
    local self = setmetatable({
        _path = file_name or "fluid.db",
        _coordinates = {}
    }, FluidTracker)

    if fs.exists(self._path) then
        local f = fs.open(self._path, "r")
        local raw = f.readAll(); f.close()
        self._coordinates = textutils.unserialize(raw) or {}
    end

    return self
end

function FluidTracker:add(coordinates)
    local key = ("%d%d%d"):format(coordinates.x, coordinates.y, coordinates.z)
    self._coordinates[key] = coordinates

    save(self)
end

function FluidTracker:drain()
    local result = {}

    for _, value in pairs(self._coordinates) do
        table.insert(result, value)
    end

    self._coordinates = {}
    save(self)

    return result
end

return FluidTracker
