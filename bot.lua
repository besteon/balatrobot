
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

-- Options: Small, Big, Boss
function Bot.skip_or_select_blind(blind)
    if blind == 'Small' or blind == 'Big' then
        return Bot.CHOICES.SELECT_BLIND
    end

    return Bot.CHOICES.SELECT_BLIND
end

-- Return PLAY_HAND or DISCARD_HAND, hand card indices
-- ex. return Bot.CHOICES.PLAY_HAND, { 1, 2, 3 }
function Bot.select_cards_from_hand()

    local _cards_in_hand = #G.hand.cards
    local _max_cards_to_select = math.min(5, _cards_in_hand)
    local _num_cards_to_select = _max_cards_to_select   --math.random(_max_cards_to_select)

    local _selected = { }
    for i = 1, _num_cards_to_select, 1 do
        _selected[i] = i
    end

    local _play_or_discard = math.random(2)
    local _choice = _play_or_discard == 1 and G.GAME.current_round.discards_left > 0 and Bot.CHOICES.DISCARD_HAND or Bot.CHOICES.PLAY_HAND

    return _choice, _selected
end

-- Returns one of the following CHOICES, card to buy if applicable
--      NEXT_ROUND_END_SHOP
--      REROLL_SHOP
--      BUY_CARD
--      BUY_VOUCHER
--      BUY_BOOSTER
-- ex. return Bot.CHOICES.BUY_CARD, choices[Bot.CHOICES.BUY_CARD][1]
function Bot.select_shop_action(choices)

    if choices[Bot.CHOICES.BUY_CARD] then
        return Bot.CHOICES.BUY_CARD, choices[Bot.CHOICES.BUY_CARD][1]
    end

    return Bot.CHOICES.NEXT_ROUND_END_SHOP
end


-- Returns one of the following CHOICES, card to pick, and deck cards to pick if applicable
--      SELECT_BOOSTER_CARD
--      SKIP_BOOSTER_PACK
function Bot.select_booster_action(pack_cards, hand_cards)

    local _action = Bot.CHOICES.SKIP_BOOSTER_PACK
    local _pack_choice = nil
    local _hand_choices = { }

    if G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK then
        _action = Bot.CHOICES.SELECT_BOOSTER_CARD

        -- Example of choosing the first card from the pack and 
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

-- Directly change the order of G.hand.cards
function Bot.rearrange_hand()

    --G.hand:shuffle()

    local _choice = math.random(2)
    if _choice == 1 then
        G.FUNCS.sort_hand_suit()
    else
        G.FUNCS.sort_hand_value()
    end

    --if #G.hand.cards > 1 then
    --    local _swap = G.hand.cards[1]
    --    G.hand.cards[1] = G.hand.cards[2]
    --    G.hand.cards[2] = _swap
    --end

end

-- Directly change the order of G.jokers.cards
function Bot.rearrange_jokers()
    G.jokers:shuffle()
end

return Bot