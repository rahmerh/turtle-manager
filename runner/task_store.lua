local FILE = "tasks.db"

local task_store = {}

task_store.__index = task_store

local function atomic_write(path, tbl)
    local tmp = path .. ".tmp"
    local f = fs.open(tmp, "w")
    f.write(textutils.serialize(tbl))
    f.close()
    if fs.exists(path) then fs.delete(path) end
    fs.move(tmp, path)
end

local function load_file(path)
    if not fs.exists(path) then return nil end
    local f = fs.open(path, "r")
    local raw = f.readAll()
    f.close()
    return textutils.unserialize(raw)
end

local function persist(self)
    atomic_write(FILE, { first = self.first, last = self.last, items = self.items })
end

function task_store.new()
    local self = setmetatable({ first = 1, last = 0, items = {} }, task_store)

    local data = load_file(FILE)
    if data then
        self.first = data.first or 1
        self.last  = data.last or 0
        self.items = data.items or {}
    else
        persist(self)
    end

    return self
end

function task_store:enqueue(task)
    self.last = self.last + 1
    self.items[self.last] = task
    persist(self)
end

function task_store:peek()
    if self.first > self.last then return nil end
    return self.items[self.first]
end

function task_store:ack()
    if self.first > self.last then return false end
    self.items[self.first] = nil
    self.first = self.first + 1
    persist(self)
    return true
end

function task_store:size()
    return self.last - self.first + 1
end

function task_store:compact()
    if self.first == 1 then return end
    local j = 1
    for i = self.first, self.last do
        self.items[j] = self.items[i]
        self.items[i] = nil
        j = j + 1
    end
    self.first, self.last = 1, j - 1
end

return task_store
