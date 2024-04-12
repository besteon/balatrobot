#!/usr/bin/python3

import sys
import json
import socket
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
        self.deck = deck
        self.stake = stake
        self.seed = seed
        self.challenge = challenge

        self.addr = ("127.0.0.1", 12345)
        self.running = False
    
    def skip_or_select_blind(self):
        raise NotImplementedError("Error: Bot.skip_or_select_blind must be implemented.")

    def play_or_discard_hand(self):
        raise NotImplementedError("Error: Bot.play_or_discard_hand must be implemented.")

    def select_shop_action(self):
        raise NotImplementedError("Error: Bot.select_shop_action must be implemented.")
    
    def select_booster_action(self):
        raise NotImplementedError("Error: Bot.select_booster_action must be implemented.")
    
    def rearrange_jokers(self):
        raise NotImplementedError("Error: Bot.rearrange_jokers must be implemented.")
    
    def use_or_sell_consumables(self):
        raise NotImplementedError("Error: Bot.use_or_sell_consumables must be implemented.")
    
    def rearrange_consumables(self):
        raise NotImplementedError("Error: Bot.rearrange_consumables must be implemented.")
    
    def rearrange_hand(self):
        raise NotImplementedError("Error: Bot.rearrange_hand must be implemented.")

    def sendcmd(self, cmd, **kwargs):
        msg = bytes(cmd.name, 'utf-8')
        self.sock.sendto(msg, self.addr)

    def verifyimplemented(self):
        try:
            self.skip_or_select_blind()
            self.play_or_discard_hand()
            self.select_shop_action()
            self.select_booster_action()
            self.rearrange_jokers()
            self.use_or_sell_consumables()
            self.rearrange_consumables()
            self.rearrange_hand()
        except NotImplementedError as e:
            print(e)
            sys.exit(0)
        except:
            pass

    def run(self):
        self.verifyimplemented()

        running = True

        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.settimeout(1.0)

        self.sendcmd(Actions.SEND_GAMESTATE)

        while running:
            try:
                data = self.sock.recv(4096)
                G = json.loads(data)
                self.G = G

                if State(G.state) == State.GAME_OVER:
                    running = False

            except:
                print('Request Timed Out')

            running = False