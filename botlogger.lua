
Botlogger = { }
Botlogger.path = ''
Botlogger.filename = nil

function Botlogger.fileexists(filename)
    local _f = io.open(filename, 'r')
    if _f ~= nil then
        io.close(_f)
        return true
    else
        return false
    end
end

function Botlogger.getfilename(settings)
    local _filename = ''
    _filename = _filename .. tostring(settings.seed)
    _filename = _filename .. '_' .. tostring(settings.deck)
    _filename = _filename .. '_' .. tostring(settings.stake)
    _filename = _filename .. '_' .. tostring(settings.challenge)
    _filename = _filename .. '.run'
    --_filename = Botlogger.path .. _filename
    sendDebugMessage(_filename)
    return _filename
end

function Botlogger.logbotdecision(...)
    local _action, _arg1, _arg2 = ...

    local _logstring = ''
    
    if _action then
        for key,v in pairs(Bot.ACTIONS) do
            if _action == v then
                _logstring = key
                break
            end
        end

        if _arg1 then
            if type(_arg1) == 'number' then
                _logstring = _logstring .. ',' .. tostring(_arg1)
            elseif type(_arg1) == 'table' then
                for i = 1, #_arg1 do
                    _logstring = _logstring .. ',' .. tostring(_arg1[i])
                end
            end
        end

        if _arg2 then -- This is only the case for select_booster_action
            for i = 1, #_arg2 do
                _logstring = _logstring .. ',' .. tostring(_arg2[i])
            end
        end

        if Botlogger.filename then
            local _f = io.open(Botlogger.filename, 'a')
            _f:write(_logstring, '\n')
            _f:close()
        end
    end
end

function Botlogger.start_run()
    if Bot.SETTINGS.replay and Bot.SETTINGS.replay == true then
        local _filename = Botlogger.getfilename(Bot.SETTINGS)
        if Botlogger.fileexists(_filename) then
            Botlogger.filename = _filename
        end
    else
        -- TODO if seed not specified, get it from the game
        local _filename = nil
        if Bot.SETTINGS.seed and Bot.SETTINGS.seed ~= '' then
            _filename = Botlogger.getfilename(Bot.SETTINGS)
        else
            local _settings = {
                stake = Bot.SETTINGS.stake,
                deck = Bot.SETTINGS.deck,
                seed = tostring(G.GAME.pseudorandom.seed),
                challenge = Bot.SETTINGS.challenge
            }
            _filename = Botlogger.getfilename(_settings)
        end

        if not Botlogger.fileexists(_filename) then
            Botlogger.filename = _filename
        end
    end
end

function Botlogger.inithooks()

    Botlogger.q_skip_or_select_blind = List.new()
    Botlogger.q_select_cards_from_hand = List.new()
    Botlogger.q_select_shop_action = List.new()
    Botlogger.q_select_booster_action = List.new()
    Botlogger.q_sell_jokers = List.new()
    Botlogger.q_rearrange_jokers = List.new()
    Botlogger.q_use_or_sell_consumables = List.new()
    Botlogger.q_rearrange_consumables = List.new()
    Botlogger.q_rearrange_hand = List.new()
    Botlogger.q_start_run = List.new()
    
    -- Hook bot functions
    if Bot.SETTINGS.replay == true or Bot.SETTINGS.api == true then
        -- Redefine Bot functions to just return the next action from their queue
        Botlogger.nextaction = 1
        for k,v in pairs(Bot) do
            if type(Bot[k]) == 'function' then
                Bot[k] = function()
                    if not List.isempty(Botlogger['q_'..k]) then
                        local _action = List.popright(Botlogger['q_'..k])

                        if Bot.SETTINGS.api == false and _action[1] == Botlogger.nextaction then
                            Botlogger.nextaction = Botlogger.nextaction + 1
                            return unpack(_action[2])

                        elseif Bot.SETTINGS.api == false then
                            List.pushright(Botlogger['q_'..k], _action)
                            sendDebugMessage('q_'..k.." is not empty. Returning Bot.ACTIONS.PASS")
                            return Bot.ACTIONS.PASS

                        -- We don't care about action order for the API.
                        -- When the queue is populated, return the choice.
                        elseif Bot.SETTINGS.api == true then
                            return unpack(_action[2])
                        end
                    else
                        -- Return an action of "PASS" when the API is not enabled.
                        -- When API is enabled, nothing is returned, and the system waits for the queue to be populated
                        if Bot.SETTINGS.api == false then
                            sendDebugMessage('q_'..k.." is empty. Returning Bot.ACTIONS.PASS")
                            return Bot.ACTIONS.PASS
                        else
                            sendDebugMessage('q_'..k.." is empty. Waiting for API to populate queue...")
                        end
                    end
                end
            end
        end 
    end

    -- Read replay file and populate action queues
    if Bot.SETTINGS.replay == true then
        local _replayfile = Botlogger.getfilename(Bot.SETTINGS)

        if Botlogger.fileexists(_replayfile) then

            local _num_action = 0
            for line in io.lines(_replayfile) do
                _num_action = _num_action + 1
                local _action = { }

                local _splitstring = { }
                local _i = 1
                for str in string.gmatch(line, '([^,]+)') do
                    _splitstring[_i] = str
                    _i = _i + 1
                end

                _action[1] = Bot.ACTIONS[_splitstring[1]]
                
                if _action[1] == Bot.ACTIONS.SELECT_BLIND or _action[1] == Bot.ACTIONS.SKIP_BLIND then
                    List.pushleft(Botlogger.q_skip_or_select_blind, { _num_action, _action })
                elseif _action[1] == Bot.ACTIONS.PLAY_HAND or _action[1] == Bot.ACTIONS.DISCARD_HAND then
                    local _cards = { }
                    for i = 2, #_splitstring do
                        _cards[i-1] = tonumber(_splitstring[i])
                    end
                    _action[2] = _cards

                    List.pushleft(Botlogger.q_select_cards_from_hand, { _num_action, _action })
                elseif _action[1] == Bot.ACTIONS.END_SHOP or _action[1] == Bot.ACTIONS.REROLL_SHOP or _action[1] == Bot.ACTIONS.BUY_CARD or _action[1] == Bot.ACTIONS.BUY_VOUCHER or _action[1] == Bot.ACTIONS.BUY_BOOSTER then
                    if #_splitstring > 1 then
                        _action[2] = {tonumber(_splitstring[2])}
                    end
                    List.pushleft(Botlogger.q_select_shop_action, { _num_action, _action })
                elseif _action[1] == Bot.ACTIONS.SELECT_BOOSTER_CARD or _action[1] == Bot.ACTIONS.SKIP_BOOSTER_PACK then
                    if #_splitstring > 1 then
                        _action[2] = {tonumber(_splitstring[2])}
                    end

                    if #_splitstring > 2 then
                        local _cards = { }
                        for i = 3, #_splitstring do
                            _cards[i-2] = tonumber(_splitstring[i])
                        end
                        _action[3] = _cards
                    end
                    List.pushleft(Botlogger.q_select_booster_action, { _num_action, _action })
                elseif _action[1] == Bot.ACTIONS.SELL_JOKER then
                    local _cards = { }
                    for i = 2, #_splitstring do
                        _cards[i-1] = tonumber(_splitstring[i])
                    end
                    _action[2] = _cards
                    List.pushleft(Botlogger.q_sell_jokers, { _num_action, _action })
                elseif _action[1] == Bot.ACTIONS.USE_CONSUMABLE or _action[1] == Bot.ACTIONS.SELL_CONSUMABLE then
                    _action[2] = {tonumber(_splitstring[2])}
                    List.pushleft(Botlogger.q_use_or_sell_consumables, { _num_action, _action })
                elseif _action[1] == Bot.ACTIONS.REARRANGE_JOKERS then
                    local _cards = { }
                    for i = 2, #_splitstring do
                        _cards[i-1] = tonumber(_splitstring[i])
                    end
                    _action[2] = _cards
                    List.pushleft(Botlogger.q_rearrange_jokers, { _num_action, _action })
                elseif _action[1] == Bot.ACTIONS.REARRANGE_CONSUMABLES then
                    local _cards = { }
                    for i = 2, #_splitstring do
                        _cards[i-1] = tonumber(_splitstring[i])
                    end
                    _action[2] = _cards
                    List.pushleft(Botlogger.q_rearrange_consumables, { _num_action, _action })
                elseif _action[1] == Bot.ACTIONS.REARRANGE_HAND then
                    local _cards = { }
                    for i = 2, #_splitstring do
                        _cards[i-1] = tonumber(_splitstring[i])
                    end
                    _action[2] = _cards
                    List.pushleft(Botlogger.q_rearrange_hand, { _num_action, _action })
                end
            end           
        end
    elseif Bot.SETTINGS.replay == false then
        for k,v in pairs(Bot) do
            if type(Bot[k]) == 'function' then
                Bot[k] = Hook.addcallback(Bot[k], Botlogger.logbotdecision)
            end
        end
    end

    -- TODO Hook run start/end
    G.FUNCS.start_run = Hook.addcallback(G.FUNCS.start_run, Botlogger.start_run)
end

return Botlogger