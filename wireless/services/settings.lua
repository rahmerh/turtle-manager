local notify = require("wireless._internal.notify")
local core = require("wireless._internal.core")

local settings = {}

function settings.apply_settings_on(receiver, all_settings)
    notify.send(receiver, "settings:update", core.protocols.notify, {
        settings = all_settings
    })
end

return settings
