
Utils = { }

function Utils.getCardData(card)
    local _card = { }


    return _card
end

function Utils.getDeckData()
    local _deck = { }

    return _deck
end

function Utils.getHandData()
    local _hand = { }

    for i = 1, #G.hand.cards do
        local _card = Utils.getCardData(G.hand.cards[i])
        _hand[i] = _card
    end

    return _hand
end

function Utils.getJokersData()
    local _jokers = { }

    for i = 1, #G.jokers.cards do
        local _card = Utils.getCardData(G.jokers.cards[i])
        _jokers[i] = _card
    end

    return _jokers
end

function Utils.getConsumablesData()
    local _consumables = { }

    for i = 1, #G.consumeables.cards do
        local _card = Utils.getCardData(G.consumeables.cards[i])
        _consumables[i] = _card
    end

    return _consumables
end

function Utils.getBlindData()
    local _blinds = { }

    return _blinds
end

function Utils.getAnteData()
    local _ante = { }
    _ante.blinds = Utils.getBlindData()

    return _ante
end

function Utils.getBackData()
    local _back = { }

    return _back
end

function Utils.getShopData()
    local _shop = { }
    if not G.shop then return _shop end
    
    _shop.reroll_cost = G.GAME.current_round.reroll_cost
    _shop.cards = { }
    _shop.boosters = { }
    _shop.vouchers = { }

    for i = 1, #G.shop_jokers.cards do
        _shop.cards[i] = Utils.getCardData(G.shop_jokers.cards[i])
    end

    for i = 1, #G.shop_booster.cards do
        _shop.boosters[i] = Utils.getCardData(G.shop_booster.cards[i])
    end

    for i = 1, #G.shop_vouchers.cards do
        _shop.vouchers[i] = Utils.getCardData(G.shop_vouchers.cards[i])
    end

    return _shop
end

function Utils.getHandScoreData()
    local _handscores = { }

    return _handscores
end

function Utils.getTagsData()
    local _tags = { }

    return _tags
end

function Utils.getRoundData()
    local _current_round = { }

    return _current_round
end

function Utils.getGameData()
    local _game = { }

    return _game
end

function Utils.getGamestate()
    -- TODO
    local _gamestate = { }
    _gamestate.game = Utils.getGameData()
    _gamestate.deckback = Utils.getBackData()
    _gamestate.deck = Utils.getDeckData() -- Ensure this is not ordered
    _gamestate.hand = Utils.getHandData()
    _gamestate.jokers = Utils.getJokersData()
    _gamestate.consumables = Utils.getConsumablesData()
    _gamestate.ante = Utils.getAnteData()
    _gamestate.shop = Utils.getShopData() -- Empty if not in shop phase
    _gamestate.handscores = Utils.getHandScoreData()
    _gamestate.tags = Utils.getTagsData()
    _gamestate.current_round = Utils.getRoundData()

    return _gamestate
end

function Utils.parseaction(data)
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

return Utils