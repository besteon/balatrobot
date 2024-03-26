print("Mod loaded!")

--local hook = require "mods/initmods/hook"
local Middleware = require "mods/initmods/middleware"

local function init_mod()
    print("init_mod")

    Middleware.hookbalatro()
end

init_mod()