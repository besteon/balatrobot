local Hook = require "hook"

function testfunc(...)
    local _args, _ret = ...
    print(_args)
    print(_args.node)
    print(_ret)
end

local f = function() return true end
local testtable = {}

--G.GAME.round_resets.blind_states
G = {
    GAME = {
        round_resets = {
            blind_resets = "123"
        }
    }
}

f = Hook.addcallback(f, testfunc)


f({node = 'test'})
--G.GAME.round_resets = Hook.addonread(G.GAME.round_resets, testfunc)
--G.GAME.round_resets = Hook.addonread(G.GAME.round_resets, testfunc)


--a = G.GAME.round_resets['test']
--b = G.GAME.round_resets.blind_resets
--test = G.GAME.round_resets.blind_resets
