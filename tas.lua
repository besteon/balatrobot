
-- WIP

Bot = require('bot')
Hook = require('hook')

Tas = { }

function Tas.logbotdecision(...)
    
end

function Tas.hookbot()
    for k,v in pairs(Bot) do
        if type(k) == 'function' then
            Bot.k = Hook.addcallback(Bot.k, Tas.logbotdecision)
        end
    end
end

return Tas