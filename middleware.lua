
local Hook = require "mods/initmods/hook"
local Bot = require "mods/initmods/bot"

function random_key(tb)
    local keys = {}
    for k in pairs(tb) do table.insert(keys, k) end
    return keys[math.random(#keys)]
end

function random_element(tb)
    local keys = {}
    for k in pairs(tb) do table.insert(keys, k) end
    return tb[keys[math.random(#keys)]]
end

local Middleware = { }

Middleware.action_pending = false

Middleware.can_reroll_shop = false
Middleware.is_opening_booster = false
Middleware.is_game_over = false

function Middleware.add_event_sequence_recursive(events)
    if events == nil or #events <= 0 then
        return true
    end
    local head = table.remove(events, 1)

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = head.delay,
        blocking = false,
        func = function()
            head.func(head.args)
            Middleware.add_event_sequence_recursive(events)
            return true
        end
    }))
end

function Middleware.add_event_sequence(events)
    if Middleware.action_pending == false then
        Middleware.action_pending = true

        local _totaldelay = 0
        for i = 1, #events, 1 do
            _totaldelay = _totaldelay + events[i].delay
        end

        Middleware.add_event_sequence_recursive(events)
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            func = function()
                Middleware.action_pending = false
                return true
            end
        }))
    end
end

local function c_onmainmenu()

    local function click_run_play_button()
        G.FUNCS.start_run(nil, {stake = Bot.SETTINGS.stake, seed = Bot.SETTINGS.seed, challenge = Bot.SETTINGS.challenge})
        return true
    end

    local function click_main_play_button()
        local _play_button = G.MAIN_MENU_UI:get_UIE_by_ID('main_menu_play')

        G.FUNCS[_play_button.config.button]({
            config = { }
        })
        G.FUNCS.exit_overlay_menu()

        return true        
    end

    Middleware.is_game_over = false

    Middleware.add_event_sequence({
        { func = click_main_play_button, delay = 3.0 },
        { func = click_run_play_button, delay = 1.0 }
    })
end


local function c_onblindselectavailable(blind)

    local function click_select_blind()

        local _button_index = blind == 'Small' and 1 or blind == 'Big' and 2 or blind == 'Boss' and 3
        local _select_button = G.blind_select.UIRoot.children[1].children[_button_index].config.object:get_UIE_by_ID('select_blind_button')
        if _select_button ~= nil and _select_button.config.button ~= nil then
            G.FUNCS[_select_button.config.button](_select_button)
        end
    end
    
    local function click_skip_blind_select_voucher()
        local _tag_blind_skip_button = UIBox:get_UIE_by_ID('tag_'..G.GAME.blind_on_deck, G.blind_select.UIRoot).children[2]
        G.FUNCS[_tag_blind_skip_button.config.button](_tag_blind_skip_button)
    end


    -- OPTIONS -- Make decision logic here
    local function decide(blind)

        local _choice = Bot.skip_or_select_blind(blind)

        -- 1) Select Blind (play)
        if _choice == Bot.CHOICES.SELECT_BLIND then
            Middleware.add_event_sequence_recursive({
                { func = click_select_blind, delay = 2.0 }
            })
        end

        -- 2) Skip Blind (tag)
        if _choice == Bot.CHOICES.SKIP_BLIND_SELECT_VOUCHER then
            Middleware.add_event_sequence_recursive({
                { func = click_skip_blind_select_voucher, delay = 2.0 }
            })
        end

    end

    decide(blind)

end

local function c_can_play_hand()

    local function click_play_hand()
        if G.buttons == nil then return true end

        local _play_button = UIBox:get_UIE_by_ID('play_button', G.buttons.UIRoot)
        if _play_button ~= nil and _play_button.config.button ~= nil then
           G.FUNCS[_play_button.config.button](_play_button)
        end
    end

    local function click_discard_hand()
        if G.buttons == nil then return true end

        local _discard_button = UIBox:get_UIE_by_ID('discard_button', G.buttons.UIRoot)
        if _discard_button ~= nil and _discard_button.config.button ~= nil then
            G.FUNCS[_discard_button.config.button](_discard_button)
        end
    end

    local function decide()

        local _action, _cards_to_play = Bot.select_cards_from_hand()

        local _events = { }
        for i = 1, #_cards_to_play, 1 do
            _events[i] = {
                func = function()
                    G.hand.cards[i]:click()
                end,
                delay = 0.5
            }
        end

        -- Option 1: Play Hand
        if _action == Bot.CHOICES.PLAY_HAND then
            _events[#_events+1] = { func = click_play_hand, delay = 2.0 }
        end

        -- Option 2: Discard Hand
        if _action == Bot.CHOICES.DISCARD_HAND then
            _events[#_events+1] = { func = click_discard_hand, delay = 2.0 } 
        end

        Middleware.add_event_sequence_recursive(_events)

    end

    decide()

end

local function c_can_cash_out()

    local function cash_out()
        e = {
            config = {
                button = nil
            }
        }
        G.FUNCS.cash_out(e)
    end

    Middleware.add_event_sequence_recursive({
        { func = cash_out, delay = 1.0 }
    })  
end

local function c_can_shop()

    local function click_next_round()
        G.FUNCS.toggle_shop()
    end

    local function click_reroll()
        G.FUNCS.reroll_shop()
    end

    local function decide()
        local _done_shopping = false

        local _b_can_round_end_shop = true
        local _b_can_reroll_shop = Middleware.can_reroll_shop

        local _cards_to_buy = { }
        for i = 1, #G.shop_jokers.cards, 1 do
            _cards_to_buy[i] = G.shop_jokers.cards[i].cost <= G.GAME.dollars and G.shop_jokers.cards[i] or nil
        end

        local _vouchers_to_buy = { }
        for i = 1, #G.shop_vouchers.cards, 1 do
            _vouchers_to_buy[i] = G.shop_vouchers.cards[i].cost <= G.GAME.dollars and G.shop_vouchers.cards[i] or nil
        end

        local _boosters_to_buy = { }
        for i = 1, #G.shop_booster.cards, 1 do
            _boosters_to_buy[i] = G.shop_booster.cards[i].cost <= G.GAME.dollars and G.shop_booster.cards[i] or nil
        end

        local _choices = { }
        _choices[Bot.CHOICES.NEXT_ROUND_END_SHOP] = _b_can_round_end_shop
        _choices[Bot.CHOICES.REROLL_SHOP] = _b_can_reroll_shop
        _choices[Bot.CHOICES.BUY_CARD] = #_cards_to_buy > 0 and _cards_to_buy or nil
        _choices[Bot.CHOICES.BUY_VOUCHER] = #_vouchers_to_buy > 0 and _vouchers_to_buy or nil
        _choices[Bot.CHOICES.BUY_BOOSTER] = #_boosters_to_buy > 0 and _boosters_to_buy or nil
        
        local _action, _card = Bot.select_shop_action(_choices)

        if _action == Bot.CHOICES.NEXT_ROUND_END_SHOP then
            Middleware.add_event_sequence_recursive({
                { func = click_next_round, delay = 1.0 }
            }) 
            _done_shopping = true
        elseif _action == Bot.CHOICES.REROLL_SHOP then
            Middleware.add_event_sequence_recursive({
                { func = click_reroll, delay = 1.0 }
            })         
        elseif _action == Bot.CHOICES.BUY_CARD or _action == Bot.CHOICES.BUY_VOUCHER or  _action == Bot.CHOICES.BUY_BOOSTER then
            Middleware.add_event_sequence_recursive({
                { func = function()
                    if not _card then return end
                    _card:click()
                end, delay = 2.0 },
                {
                    func = function()
                        if not _card then return end

                        local _use_button = _card.children.use_button
                        local _buy_button= _card.children.buy_button
                        if _use_button then
                            G.FUNCS[_use_button.definition.config.button](_use_button.definition)
                        elseif _buy_button then
                            G.FUNCS[_buy_button.definition.config.button](_buy_button.definition)
                        end
                    end, delay = 1.0
                }
            }) 
        end

        if not _done_shopping then
            Middleware.add_event_sequence_recursive({
                { func = decide, delay = 10.0 }
            })
        end

    end

    decide()

end

local function c_can_choose_booster_cards(skip_button)

    local function click_deck_card(card)
        card:click()
    end

    local function click_skip_booster()
        G.FUNCS[skip_button.config.button](skip_button)
    end

    local function decide()

        local _action, _card, _hand_cards = Bot.select_booster_action(G.pack_cards.cards, G.hand.cards)

        if _action == Bot.CHOICES.SKIP_BOOSTER_PACK then
            Middleware.add_event_sequence_recursive({
                { func = click_skip_booster, delay = 5.0 }
            })
        elseif _action == Bot.CHOICES.SELECT_BOOSTER_CARD then

            local _events = { }

            -- Click each card from your deck first (only occurs if _pack_card is consumeable)
            for i = 1, #_hand_cards, 1 do
                _events[i] = {
                    func = function()
                        click_deck_card(_hand_cards[i])
                    end,
                    delay = 5.0
                }
            end

            -- Then select the booster card to activate
            _events[#_events+1] = {
                func = function()
                    if not _card then return end
                    _card:click()
                end,
                delay = 2.0
            }

            _events[#_events+1] = {
                func = function()
                    if not _card then return end

                    local _use_button = _card.children.use_button
                    local _buy_and_use_button = _card.children.buy_and_use_button
                    local _buy_button = _card.children.buy_button
                    local _use_and_sell_button = _card.children.use_and_sell_button
                    if _use_button then
                        local _node_index = _card.ability.consumeable and 2 or 1
                        G.FUNCS[_use_button.definition.nodes[_node_index].config.button](_use_button.definition.nodes[_node_index])
                    elseif _buy_and_use_button then
                        G.FUNCS[_buy_and_use_button.definition.config.button](_buy_and_use_button.definition)
                    elseif _buy_button then
                        G.FUNCS[_buy_button.definition.config.button](_buy_button.definition)
                    elseif _use_and_sell_button then
                        G.FUNCS[_use_and_sell_button.definition.config.button](_use_and_sell_button.definition)
                    end
                end,
                delay = 2.0
            }

            -- Once the pack is done, set can_skip_booster back to false
            _events[#_events+1] = {
                func = function()
                    Middleware.is_opening_booster = false
                end,
                delay = 10.0
            }

            Middleware.add_event_sequence_recursive(_events)
        end

    end

    decide()

end


local function c_can_rearrange_jokers()
    Bot.rearrange_jokers()
end

local function c_can_rearrange_hand()
    Bot.rearrange_hand()
end


local function c_initgamehooks()
    -- Hooks break SAVE_MANAGER.channel:push so disable saving. Who needs it when you are botting anyway...
    G.SAVE_MANAGER = {
        channel = {
            push = function() end
        }
    }

    -- Blind selection
    local _prev_blind_state = nil
    G.GAME.round_resets.blind_states = Hook.addonwrite(G.GAME.round_resets.blind_states, function(...)
        local t,k,v = ...
        if k ~= _prev_blind_state and v == 'Select' then
            c_onblindselectavailable(k)
            _prev_blind_state = k
        end
    end)

    -- Detect when hand has been drawn
    G.GAME.blind.drawn_to_hand = Hook.addcallback(G.GAME.blind.drawn_to_hand, function(...)
        Middleware.add_event_sequence_recursive({
            { func = c_can_rearrange_jokers, delay = 2.0 },
            { func = c_can_rearrange_hand, delay = 2.0 },
            { func = c_can_play_hand, delay = 2.0 }
        })
    end)

    -- Cash out
    G.FUNCS.evaluate_round = Hook.addcallback(G.FUNCS.evaluate_round, c_can_cash_out)

    -- Hook shop
    G.CONTROLLER.snap_to = Hook.addcallback(G.CONTROLLER.snap_to, function(...)
        local _self = ...
        if G.shop ~= nil then
            if _self.snap_cursor_to.node == G.shop:get_UIE_by_ID('next_round_button') then
                c_can_shop()
            end
        end
    end)

    -- Set reroll availability
    G.FUNCS.can_reroll = Hook.addcallback(G.FUNCS.can_reroll, function(...)
        local _e = ...
        if _e.config.button == 'reroll_shop' then
            Middleware.can_reroll_shop = true
        else
            Middleware.can_reroll_shop = false
        end
    end)

    -- Booster pack opening
    G.FUNCS.can_skip_booster = Hook.addcallback(G.FUNCS.can_skip_booster, function(...)
        local _e = ...
        if _e.config.button == 'skip_booster' then
            if not Middleware.is_opening_booster then
                Middleware.is_opening_booster = true

                if G.STATE == G.STATES.SPECTRAL_PACK or G.STATE == G.STATES.TAROT_PACK then
                    -- Wait for hand cards to be drawn
                    Middleware.add_event_sequence_recursive({
                        { func = c_can_rearrange_hand, delay = 10.0 },
                        {
                            func = function()
                                c_can_choose_booster_cards(_e)
                            end,
                            delay = 5.0
                        }
                    })
                else
                    c_can_choose_booster_cards(_e)
                end

            end
        end
    end)

    -- Game Over
    G.update_game_over = Hook.addcallback(G.update_game_over, function(...)
        if not Middleware.is_game_over then
            Middleware.is_game_over = true
            Middleware.add_event_sequence_recursive({
                { func = function(...)
                    --local _main_menu_button = G.OVERLAY_MENU:get_UIE_by_ID('from_game_over')
                    --G.FUNCS[_main_menu_button.config.button](_main_menu_button)
                    --G.FUNCS.go_to_menu()
                    G.FUNCS.start_run(nil, {stake = Bot.SETTINGS.stake, seed = Bot.SETTINGS.seed, challenge = Bot.SETTINGS.challenge})
                    G.FUNCS.exit_overlay_menu()
                end, delay = 10.0 }
            })
        end
    end)
end

function Middleware.hookbalatro()
    -- Start game from main menu
    G.main_menu = Hook.addcallback(G.main_menu, c_onmainmenu)
    G.start_run = Hook.addcallback(G.start_run, c_initgamehooks)
end

return Middleware