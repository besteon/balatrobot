
local socket = require "socket"

local data, msg_or_ip, port_or_nil

BalatrobotAPI = { }
BalatrobotAPI.socket = nil

function BalatrobotAPI.notifyapiclient(...)
    -- TODO Generate gamestate json object
    local _gamestate = Utils.getGamestate()
    local _gamestateJsonString = json.encode(_gamestate)

    if BalatrobotAPI.socket then
        BalatrobotAPI.socket:sendto(string.format("%s", _gamestateJsonString), msg_or_ip, port_or_nil)
    end
end

function BalatrobotAPI.respond(str)
    if BalatrobotAPI.socket then
        BalatrobotAPI.socket:sendto(string.format("%s\n", str), msg_or_ip, port_or_nil)
    end
end

function BalatrobotAPI.queueaction(action)
    local _params = Bot.ACTIONPARAMS[action[1]]
    List.pushleft(Botlogger['q_'.._params.func], { 0, action })
end

function BalatrobotAPI.update(dt)
    if not BalatrobotAPI.socket then
        BalatrobotAPI.socket = socket.udp()
        BalatrobotAPI.socket:settimeout(0)
        BalatrobotAPI.socket:setsockname('*', 12345)
    end

    data, msg_or_ip, port_or_nil = BalatrobotAPI.socket:receivefrom()
	if data then

        local _action = Utils.parseaction(data)

        if _action and #_action > 1 and #_action > Bot.ACTIONPARAMS[_action[1]].num_args then
            BalatrobotAPI.respond("Error: Incorrect number of params for action " .. action)
        elseif not _action then
            BalatrobotAPI.respond("Error: Incorrect message format. Should be ACTION|arg1|arg2")
        else
            BalatrobotAPI.queueaction(_action)
        end

	elseif msg_or_ip ~= 'timeout' then
		sendDebugMessage("Unknown network error: "..tostring(msg))
	end
	
	socket.sleep(0.01)
end

function BalatrobotAPI.init()

    love.update = Hook.addcallback(love.update, BalatrobotAPI.update)

    if Bot.SETTINGS.api == true then
        for k,v in pairs(Bot) do
            if type(Bot[k]) == 'function' then
                Bot[k] = Hook.addbreakpoint(Bot[k], BalatrobotAPI.notifyapiclient)
            end
        end
    end
end

return BalatrobotAPI