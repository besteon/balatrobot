
local socket = require "socket"

local udp = socket.udp()
udp:settimeout(0)
udp:setsockname('*', 12345)

local data, msg_or_ip, port_or_nil
local entity, cmd, parms
local running = true

BalatrobotAPI = { }

function BalatrobotAPI.respond(str)
    udp:sendto(string.format("%s\n", str), msg_or_ip, port_or_nil)
end

function BalatrobotAPI.queueaction(action)
    local _params = Bot.ACTIONPARAMS[action[1]]
    List.pushleft(Botlogger['q_'.._params.func], { 0, action })
end

function BalatrobotAPI.parseaction(data)
    -- Protocol is ACTION|arg1|arg2
    action = data:match("^([%a%u_]*)")
    params = data:match("|(.*)")

    if action then
        local _action = Bot.ACTIONS[action]
        sendDebugMessage("Action is: " .. tostring(_action))

        if not _action then
            return nil
        end

        local _actiontable = { }
        _actiontable[1] = _action

        if params then
            local _i = 2
            for _arg in params:gmatch("[%w%s,]+") do
                local _splitstring = { }
                local _j = 1
                for _str in _arg:gmatch('([^,]+)') do
                    _splitstring[_j] = tonumber(_str) or _str
                    _j = _j + 1
                end
                _actiontable[_i] = _splitstring
                _i = _i + 1
            end
        end

        return _actiontable
    end
end

function BalatrobotAPI.update(dt)
    data, msg_or_ip, port_or_nil = udp:receivefrom()
	if data then

        local _action = BalatrobotAPI.parseaction(data)

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

end

return BalatrobotAPI