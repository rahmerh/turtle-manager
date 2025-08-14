local rpc = require("wireless._internal.rpc")

local settings = {}

function settings.apply_settings_on(receiver, all_settings)
    rpc.call(receiver, "settings:update", { settings = all_settings })
end

return settings
