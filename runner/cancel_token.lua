local CancelToken = {}
CancelToken.__index = CancelToken

function CancelToken.new()
    return setmetatable({}, CancelToken)
end

function CancelToken:cancel()
    os.queueEvent("cancel_event")
end

function CancelToken:await()
    os.pullEvent("cancel_event")

    return true
end

return CancelToken
