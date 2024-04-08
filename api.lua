
local socket = require "socket"

local udp = socket.udp()
udp:settimeout(0)
udp:setsockname('*', 12345)

local data, msg_or_ip, port_or_nil
local entity, cmd, parms
local running = true

BalatrobotAPI = { }

function BalatrobotAPI.update(dt)
    data, msg_or_ip, port_or_nil = udp:receivefrom()
	if data then

        -- Protocol is be ACTION|arg1|arg2
        action, params = data:match("^([%a%u_]*)|(.*)")

        if action then
            local _action = Bot.ACTIONS[action]
            sendDebugMessage("Action is: " .. tostring(_action))

            sendDebugMessage(params)
            for _arg in params:gmatch("[%d,]+") do
                sendDebugMessage(tostring(_arg))
            end
        else
            udp:sendto(string.format("%s", "Error: Incorrect message format. Should be ACTION|arg1|arg2"), msg_or_ip, port_or_nil)
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