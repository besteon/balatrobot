
local Middleware = require "mods/balatrobot/middleware"

local function init_mod()
    print("Balatrobot v0.1 loaded")

    Middleware.hookbalatro()
end

init_mod()