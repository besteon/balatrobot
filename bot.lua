
Bot = { }

-- DO NOT TOUCH
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

-- CHANGE ME
Bot.SETTINGS = {
    stake = 1,

    -- Keep these nil for random seed
    seed = nil,
    challenge = nil,

    -- Time between actions the bot takes (pushing buttons, clicking cards, etc.)
    action_delay = 1.0,
}

--- Skips or selects the current blind
---@param blind string
--      One of 'Small', 'Big', 'Boss'
---@return number Return
--      Bot.CHOICES.SELECT_BLIND or Bot.CHOICES.SKIP_BLIND_SELECT_VOUCHER
function Bot.skip_or_select_blind(blind)
    return Bot.CHOICES.SELECT_BLIND
end

--- Selects cards from the current hand and plays or discards them
---@return integer
--      Bot.CHOICES.PLAY_HAND or Bot.CHOICES.DISCARD_HAND
---@return table
--      { G.hand.cards[1], G.hand.cards[2], G.hand.cards[3] }
function Bot.select_cards_from_hand()
    return Bot.CHOICES.PLAY_HAND, { G.hand.cards[1] }
end

--- 
---@param choices table
-- {
--      Bot.CHOICES.BUY_BOOSTER = { cards },
--      Bot.CHOICES.BUY_VOUCHER = { cards },
--      Bot.CHOICES.BUY_CARD = { cards },
--      Bot.CHOICES.REROLL_SHOP = true/false,
--      Bot.CHOICES.NEXT_ROUND_END_SHOP = true
-- }
---@return integer
--      One of the above Bot.CHOICES
---@return card
--      The card you would like to buy
-- ex. return Bot.CHOICES.BUY_CARD, choices[Bot.CHOICES.BUY_CARD][1]
function Bot.select_shop_action(choices)

    if choices[Bot.CHOICES.BUY_BOOSTER] then
        return Bot.CHOICES.BUY_BOOSTER, choices[Bot.CHOICES.BUY_BOOSTER][1]
    end

    return Bot.CHOICES.NEXT_ROUND_END_SHOP
end


-- Returns one of the following CHOICES, card to pick, and deck cards to pick if applicable
--      SELECT_BOOSTER_CARD
--      SKIP_BOOSTER_PACK

--- Selects actions when opening a booster pack
---@param pack_cards table
--      The list of cards in the booster being opened
---@param hand_cards table
--      The list of cards in your hand when opening a Tarot or Spectral pack
---@return integer
--      Bot.CHOICES.SKIP_BOOSTER_PACK or Bot.CHOICES.SELECT_BOOSTER_CARD
---@return card
--      The booster card to pick ex. pack_cards[1]
---@return table
--      The list of hand cards use the booster card on,
--      up to the max of your pack_choice.ability.consumeable.max_highlighted
--      ex. { hand_cards[1] }
function Bot.select_booster_action(pack_cards, hand_cards)
    return Bot.CHOICES.SELECT_BOOSTER_CARD, pack_cards[1], { hand_cards[1] }
end

--- Directly change the order of G.hand.cards
function Bot.rearrange_hand()
    G.hand:shuffle()
end

--- Directly change the order of G.jokers.cards
function Bot.rearrange_jokers()
    G.jokers:shuffle()
end

return Bot