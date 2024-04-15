#!/usr/bin/python3

import sys
import json
import socket
import time
from enum import Enum

class State(Enum):
    SELECTING_HAND = 1
    HAND_PLAYED = 2
    DRAW_TO_HAND = 3
    GAME_OVER = 4
    SHOP = 5
    PLAY_TAROT = 6
    BLIND_SELECT = 7
    ROUND_EVAL = 8
    TAROT_PACK = 9
    PLANET_PACK = 10
    MENU = 11
    TUTORIAL = 12
    SPLASH = 13
    SANDBOX = 14
    SPECTRAL_PACK = 15
    DEMO_CTA = 16
    STANDARD_PACK = 17
    BUFFOON_PACK = 18
    NEW_ROUND = 19

class Actions(Enum):
    SELECT_BLIND = 1
    SKIP_BLIND = 2
    PLAY_HAND = 3
    DISCARD_HAND = 4
    END_SHOP = 5
    REROLL_SHOP = 6
    BUY_CARD = 7
    BUY_VOUCHER = 8
    BUY_BOOSTER = 9
    SELECT_BOOSTER_CARD = 10
    SKIP_BOOSTER_PACK = 11
    SELL_JOKER = 12
    USE_CONSUMABLE = 13
    SELL_CONSUMABLE = 14
    REARRANGE_JOKERS = 15
    REARRANGE_CONSUMABLES = 16
    REARRANGE_HAND = 17
    PASS = 18
    START_RUN = 19
    SEND_GAMESTATE = 20

class Bot:

    def __init__(self, deck: str, stake: int = 1, seed: str = None, challenge: str = None):
        self.G = None
        self.deck = deck
        self.stake = stake
        self.seed = seed
        self.challenge = challenge

        self.addr = ("127.0.0.1", 12345)
        self.running = False

        self.state = { }
    
    def skip_or_select_blind(self):
        raise NotImplementedError("Error: Bot.skip_or_select_blind must be implemented.")

    def select_cards_from_hand(self):
        raise NotImplementedError("Error: Bot.select_cards_from_hand must be implemented.")

    def select_shop_action(self):
        raise NotImplementedError("Error: Bot.select_shop_action must be implemented.")
    
    def select_booster_action(self):
        raise NotImplementedError("Error: Bot.select_booster_action must be implemented.")
    
    def sell_jokers(self):
        raise NotImplementedError("Error: Bot.sell_jokers must be implemented.")

    def rearrange_jokers(self):
        raise NotImplementedError("Error: Bot.rearrange_jokers must be implemented.")
    
    def use_or_sell_consumables(self):
        raise NotImplementedError("Error: Bot.use_or_sell_consumables must be implemented.")
    
    def rearrange_consumables(self):
        raise NotImplementedError("Error: Bot.rearrange_consumables must be implemented.")
    
    def rearrange_hand(self):
        raise NotImplementedError("Error: Bot.rearrange_hand must be implemented.")

    def sendcmd(self, cmd, **kwargs):
        msg = bytes(cmd, 'utf-8')
        self.sock.sendto(msg, self.addr)

    def actionToCmd(self, action):
        result = [ ]

        for x in action:
            if isinstance(x, Actions):
                result.append(x.name)
            elif type(x) is list:
                result.append(','.join([str(y) for y in x]))
            else:
                result.append(str(x))                

        return '|'.join(result)

    def verifyimplemented(self):
        try:
            self.skip_or_select_blind(self, { })
            self.select_cards_from_hand(self, { })
            self.select_shop_action(self, { })
            self.select_booster_action(self, { })
            self.sell_jokers(self, { })
            self.rearrange_jokers(self, { })
            self.use_or_sell_consumables(self, { })
            self.rearrange_consumables(self, { })
            self.rearrange_hand(self, { })
        except NotImplementedError as e:
            print(e)
            sys.exit(0)
        except:
            pass

    def chooseaction(self):
        if self.G['state'] == State.GAME_OVER:
            self.running = False

        match self.G['waitingFor']:
            case 'start_run':
                return [ Actions.START_RUN, self.stake, self.deck, self.seed, self.challenge ]
            case 'skip_or_select_blind':
                return self.skip_or_select_blind(self, self.G)
            case 'select_cards_from_hand':
                return self.select_cards_from_hand(self, self.G)
            case 'select_shop_action':
                return self.select_shop_action(self, self.G)
            case 'select_booster_action':
                return self.select_booster_action(self, self.G)
            case 'sell_jokers':
                return self.sell_jokers(self, self.G)
            case 'rearrange_jokers':
                return self.rearrange_jokers(self, self.G)
            case 'use_or_sell_consumables':
                return self.use_or_sell_consumables(self, self.G)
            case 'rearrange_consumables':
                return self.rearrange_consumables(self, self.G)
            case 'rearrange_hand':
                return self.rearrange_hand(self, self.G)

    def run(self):
        self.verifyimplemented()
        self.state = { }

        self.running = True

        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.settimeout(1.0)

        while self.running:
            self.sendcmd('HELLO')

            jsondata = { }
            try:
                data = self.sock.recv(4096)
                jsondata = json.loads(data)

                if 'response' in jsondata:
                    print(jsondata['response'])
                else:
                    self.G = jsondata
                    if self.G['waitingForAction']:
                        # Choose next action
                        action = self.chooseaction()
                        if action == None:
                            raise ValueError("All actions must return a value!")
                        
                        cmdstr = self.actionToCmd(action)
                        print(f'CMD: {cmdstr}')
                        self.sendcmd(cmdstr)
            except socket.error:
                self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                self.sock.settimeout(1.0)