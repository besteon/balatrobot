
Bot = { }

Bot.SETTINGS = {
    stake = 2,
    seed = nil,
    challenge = nil,
    action_delay = 1.0
}

Bot.CHOICES = {
    SELECT_BLIND = 1,
    SKIP_BLIND_SELECT_VOUCHER = 2,
    PLAY_HAND = 3,
    DISCARD_HAND = 4,
    NEXT_ROUND_END_SHOP = 5,
    REROLL_SHOP = 6,
    BUY_CARD = 7,
    BUY_VOUCHER = 8,
    BUY_BOOSTER = 9,
    SELECT_BOOSTER_CARD = 10,
    SKIP_BOOSTER_PACK = 11,
}

function Bot.skip_or_select_blind(blind)
    if blind == 'Small' or blind == 'Big' then
        return Bot.CHOICES.SELECT_BLIND
    end

    return Bot.CHOICES.SELECT_BLIND
end

function Bot.select_cards_from_hand()

    local _max_cards_to_select = math.min(5, #G.hand.cards)
    local _num_cards_to_select = _max_cards_to_select

    local _selected = { }
    for i = 1, _num_cards_to_select, 1 do
        _selected[i] = G.hand.cards[i]
    end

    local _play_or_discard = math.random(2)
    local _choice = _play_or_discard == 1 and G.GAME.current_round.discards_left > 0 and Bot.CHOICES.DISCARD_HAND or Bot.CHOICES.PLAY_HAND

    return _choice, _selected
end

function Bot.select_shop_action(choices)

    if choices[Bot.CHOICES.BUY_BOOSTER] then
        return Bot.CHOICES.BUY_BOOSTER, choices[Bot.CHOICES.BUY_BOOSTER][1]
    end

    return Bot.CHOICES.NEXT_ROUND_END_SHOP
end

function Bot.select_booster_action(pack_cards, hand_cards)

    local _action = Bot.CHOICES.SKIP_BOOSTER_PACK
    local _pack_choice = nil
    local _hand_choices = { }

    if G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK then
        _action = Bot.CHOICES.SELECT_BOOSTER_CARD

        _pack_choice = random_element(pack_cards)
        if _pack_choice.ability.consumeable.max_highlighted then
            for i = 1, _pack_choice.ability.consumeable.max_highlighted, 1 do
                _hand_choices[i] = hand_cards[i]
            end
        end
    elseif G.STATE == G.STATES.PLANET_PACK or G.STATE == G.STATES.STANDARD_PACK or G.STATE == G.STATES.BUFFOON_PACK then
        _action = Bot.CHOICES.SELECT_BOOSTER_CARD
        _pack_choice = random_element(pack_cards)
    end

    return _action, _pack_choice, _hand_choices
end

function Bot.rearrange_hand()

    local _choice = math.random(2)
    if _choice == 1 then
        G.FUNCS.sort_hand_suit()
    else
        G.FUNCS.sort_hand_value()
    end

end

function Bot.rearrange_jokers()
    G.jokers:shuffle()
end

return Bot