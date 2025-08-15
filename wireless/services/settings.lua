local notify = require("wireless._internal.notify")
local core = require("wireless._internal.core")

local settings = {}

function settings.update_setting_on(receiver, key, value)
    notify.send(receiver, "settings:update", core.protocols.notify, {
        key = key,
        value = value,
    })
end

return settings
