from bot import Bot

if __name__=='__main__':
    mybot = Bot(deck ="Plasma Deck",
                stake = 1,
                seed = "1OGB5WO")
    
    def skip_or_select_blind(self):
        pass

    def play_or_discard_hand(self):
        pass

    def select_shop_action(self):
        pass

    def select_booster_action(self):
        pass

    def rearrange_jokers(self):
        pass

    def use_or_sell_consumables(self):
        pass

    def rearrange_consumables(self):
        pass

    def rearrange_hand(self):
        pass

    mybot.skip_or_select_blind = skip_or_select_blind
    mybot.play_or_discard_hand = play_or_discard_hand
    mybot.select_shop_action = select_shop_action
    mybot.select_booster_action = select_booster_action
    mybot.rearrange_jokers = rearrange_jokers
    mybot.use_or_sell_consumables = use_or_sell_consumables
    mybot.rearrange_consumables = rearrange_consumables
    mybot.rearrange_hand = rearrange_hand

    mybot.run()