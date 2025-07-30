local task_store = {}

task_store.__index = task_store

function task_store.new()
    return setmetatable({ first = 1, last = 0, items = {} }, task_store)
end

function task_store:enqueue(pos, type)
    self.last = self.last + 1
    self.items[self.last] = { pos = pos, type = type }
end

function task_store:peek()
    if self.first > self.last then return nil end
    return self.items[self.first]
end

function task_store:ack()
    if self.first > self.last then return false, "empty" end

    self.items[self.first] = nil
    self.first = self.first + 1
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
