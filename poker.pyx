import random
import math
import operator
import marshal
import types
import pickle
import json

class Card:
    def __init__(self, value, suit):
        self.value = value
        self.suit = suit
    
    def __str__(self):
        v = self.value
        if v == 14:
            v = 'A'
        elif v == 11:
            v = 'J'
        elif v == 12:
            v = 'Q'
        elif v == 13:
            v = 'K'
        return str(v) + self.suit

class Deck:
    def __init__(self, r=4):
        self.cards = []
        self.draw_queue = []
        self.random_num = r
    
    def copy(self):
        new_deck = Deck(self.random_num)
        new_deck.cards = list(self.cards)
        new_deck.draw_queue = list(self.draw_queue)
        
        return new_deck
    
    def __str__(self):
        return_value = ""
        for card in self.draw_queue:
            return_value += str(card) + '\n'
        
        return return_value
    
    def setup(self, n=1):
        if len(self.cards) == 0:
            for i in range(0, n):
                for v in range(2, 15):
                    for s in ['S', 'D', 'C', 'H']:
                        self.cards.append(Card(v, s))

        self.draw_queue = []
        self.shuffle(self.random_num)
        self.random_num += 1
    
    def shuffle(self, r=4):
        self.draw_queue = list(self.cards)
        #for i in range(0, 10):
        #    print self.draw_queue[i]
        #random.Random(self.random_num).shuffle(self.draw_queue)
        random.shuffle(self.draw_queue)

    def draw(self):
        return self.draw_queue.pop()

class Player:
    def __init__(self, hand, pot):
        self.hand = hand
        self.pot = pot
        self.folded = False
        self.current_bet = 0
        self.last_move = None
    
    def copy(self):
        new_p = Player(list(self.hand), self.pot)
        new_p.folded = self.folded
        new_p.current_bet = self.current_bet
        new_p.last_move = self.last_move
        
        return new_p
    
    def __str__(self):
        result = ''
        result += 'Hand: ' + str(self.hand[0]) + '  ' + str(self.hand[1])
        return result + '\nPot: ' + str(self.pot) + '\n'  
    
    def softReset(self):
        self.folded = False
        self.current_bet = 0
        self.last_move = None        
    
    def bid(self, amount):
        bid_value = amount
        if amount > self.pot:
            bid_value = self.pot
        
        self.pot = self.pot - bid_value
        self.current_bet += bid_value
        
        return bid_value

class Gameloop:
    def __init__(self, number_of_players, starting_player_pot, small_blind):
        self.number_of_players = number_of_players
        self.players = []
        for n in range(0, self.number_of_players):
            self.players.append(Player(0, starting_player_pot))
        self.current_player = 0
        self.button = 0
        self.original_small_blind = small_blind
        self.small_blind = small_blind
        self.big_blind = 2 * small_blind
        self.number_of_raises = 0
        self.limit_of_raises = 3
        self.deck = Deck()
        self.pot = 0
        self.board = []
        self.active_players = 2
        self.highest_bidder = None
        self.current_bid = 0
        self.action_history = ""
    
    def copy(self):
        new_gloop = Gameloop(self.number_of_players, 0, self.small_blind)
        new_gloop.players = []
        for i in range(0, self.number_of_players):
            new_gloop.players.append(self.players[i].copy())
        new_gloop.current_player = self.current_player
        new_gloop.button = self.button
        new_gloop.original_small_blind = self.original_small_blind
        new_gloop.small_blind = self.small_blind
        new_gloop.big_blind = self.big_blind
        new_gloop.number_of_raises = self.number_of_raises
        new_gloop.limit_of_raises = self.limit_of_raises
        new_gloop.deck = self.deck.copy()
        new_gloop.pot = self.pot
        new_gloop.board = list(self.board)
        new_gloop.active_players = self.active_players
        new_gloop.highest_bidder = self.highest_bidder
        new_gloop.current_bid = self.current_bid
        new_gloop.action_history = self.action_history
        
        return new_gloop
    
    def __str__(self):
        result = ''
        for player in self.players:
            result += str(player)
        
        return result
    
    def setup(self):
        self.deck.setup()
        self.pot = 0
        self.action_history = ""
        self.button = (self.button + 1) % self.number_of_players
        self.board = []
        self.number_of_raises = 0
        self.limit_raises = 3
        self.small_blind = self.original_small_blind
        self.big_blind = 2 * self.original_small_blind
        
        small_blind_index = (self.button + 1) % self.number_of_players
        big_blind_index = (self.button + 2) % self.number_of_players
        
        #print str(small_blind_index) + ", " + str(big_blind_index)
        
        for i in range(0, self.number_of_players):
            hand = (self.deck.draw(), self.deck.draw())
            self.players[i].softReset()
            self.players[i].hand = hand
            if i == small_blind_index:
                self.pot += self.players[i].bid(self.small_blind)
            elif i == big_blind_index:
                self.pot += self.players[i].bid(self.big_blind)
        
        self.current_player = ((self.button + 3) % self.number_of_players)
        self.active_players = 2 #set(range(0, self.number_of_players))
        self.highest_bidder = big_blind_index
        self.current_bid = self.big_blind
        
        #self.button = (self.button + 1) % self.number_of_players
    
    def flop(self):
        self.board.append(self.deck.draw())
        self.board.append(self.deck.draw())
        self.board.append(self.deck.draw())
        self.number_of_raises = 0
        self.limit_raises = 4
        if self.active_players > 1:
            self.current_player = ((self.button + 2) % self.number_of_players)
            self.highest_bidder = self.current_player
            self.players[0].last_move = None
            self.players[1].last_move = None
        
        self.action_history += "/"
    
    def turn(self):
        self.board.append(self.deck.draw())
        self.number_of_raises = 0
        self.limit_raises = 4
        if self.active_players > 1:
            self.current_player = ((self.button + 2) % self.number_of_players)
            self.highest_bidder = self.current_player
            self.players[0].last_move = None
            self.players[1].last_move = None

        self.small_blind = self.big_blind
        self.big_blind = 2 * self.big_blind
        
        self.action_history += "/"
    
    def river(self):
        self.board.append(self.deck.draw())
        self.number_of_raises = 0
        self.limit_raises = 4
        if self.active_players > 1:
            self.current_player = ((self.button + 2) % self.number_of_players)
            self.highest_bidder = self.current_player
            self.players[0].last_move = None
            self.players[1].last_move = None
        
        self.action_history += "/"
    
    '''
    value  :   hand
    10 : Royal Straight Flush
    9  : Straight Flush
    8  : Four of a Kind
    7  : Full House
    6  : Flush
    5  : Straight
    4  : Three of a Kind
    3  : Two Pair
    2  : One Pair
    0  : High Card
    '''
    
    def flush(self, order_by_suit):
        max_value = 0
        max_suit = None
        for suit in order_by_suit:
            length = len(order_by_suit[suit])
            if length >= 5:
                max_value = length
                max_suit = suit
                break
        
        if max_value < 5:
            return (0, [])

        cards = order_by_suit[max_suit]
        
        if len(set([14, 13, 12, 11, 10]) & set(cards)) == 5: # Royal Straight Flush
            return (10, [])
        
        if 14 in cards:
            cards = [1] + cards # To guarantee that A's can also sequel with low card sequences
        difference_list = [cards[i+1]-cards[i] for i in range(0, len(cards)-1)]
        string_difference_list = ''.join([str(x) for x in difference_list])
        if '1111' in string_difference_list: # Straight Flush
            index = string_difference_list.find('1111')
            
            return (9, [cards[index+4]])
        
        return (6, [cards[-1], cards[-2], cards[-3], cards[-4], cards[-5]]) # Flush

    def xOfAKind(self, order_by_value, cards):
        values = order_by_value.values()
        keys = order_by_value.keys()
        card_set = set(cards)
        if 4 in values:
            card_value = keys[values.index(4)]
            temp = card_set.difference(set([card_value]))
            return (8, [card_value, max(temp)]) # 4 of a Kind
        
        if (3 in values and 2 in values) or (3 in values and values.count(3) > 1):
            dict_of_keys = {2: [], 3: []}
            for key in order_by_value:
                if order_by_value[key] == 3:
                    dict_of_keys[3].append(key)
                    dict_of_keys[2].append(key)
                elif order_by_value[key] == 2:
                    dict_of_keys[2].append(key)
            
            max_3_card = max(dict_of_keys[3])
            max_2_card = max(set(dict_of_keys[2]).difference(set([max_3_card])))
            
            return (7, [max_3_card, max_2_card]) # Full House
        
        if 3 in values:
            dict_of_keys = {3: []}
            for key in order_by_value:
                if order_by_value[key] == 3:
                    dict_of_keys[3].append(key)
            
            card_value = max(dict_of_keys[3])
            max_1st_card_left = max(card_set.difference(set([card_value])))
            max_2nd_card_left = max(card_set.difference(set([card_value, max_1st_card_left])))
            
            return (4, [card_value, max_1st_card_left, max_2nd_card_left]) # 3 of a Kind
        
        if 2 in values:
            list_of_pair_keys = []
            for key in order_by_value:
                if order_by_value[key] == 2:
                    list_of_pair_keys.append(key)

            rank = 2
            if len(list_of_pair_keys) > 1:
                rank = 3
            
            max_1st_card = max(list_of_pair_keys)
            set_of_pair_keys = set(list_of_pair_keys).difference(set([max_1st_card]))
            max_2nd_card = 0
            if len(set_of_pair_keys) > 0:
                max_2nd_card = max(set_of_pair_keys)
            
            temp = list(card_set.difference(set([max_1st_card, max_2nd_card])))
            temp = sorted(temp)
            
            if rank == 3:
                return (3, [max_1st_card, max_2nd_card, temp[-1]])
            
            return (2, [max_1st_card, temp[-1], temp[-2], temp[-3]])
            #return 3 if values.count(2) >= 2 else 2 # Two or One Pair

        return (0, [])
    
    def straight(self, cards):
        if 14 in cards:
            cards = [1] + cards # To guarantee that A's can also sequel with low card sequences

        difference_list = [cards[i+1].value-cards[i].value for i in range(0, len(cards)-1)]
        string_difference_list = ''.join([str(x) if x < 10 else str(9) for x in difference_list])
        if '1111' in string_difference_list: # Straight
            index = string_difference_list.find('1111')
            return (5, [cards[index+4].value])
    
        return (0, [])
    
    def rankHand(self, player_index):
        player = self.players[player_index]
        
        list_of_all_cards = self.board + [player.hand[0], player.hand[1]]
        list_of_all_cards.sort(key=operator.attrgetter('value'))
        
        order_by_suit = {'S': [], 'H': [], 'C': [], 'D': []}
        for card in list_of_all_cards:
            order_by_suit[card.suit].append(card.value)
        
        order_by_value = {}
        for card in list_of_all_cards:
            if card.value not in order_by_value:
                order_by_value[card.value] = 1
            else:
                order_by_value[card.value] += 1
        
        hand_rank = (0, [])
        
        hand_rank = self.flush(order_by_suit)
        if hand_rank[0] < 9:
            temp = self.xOfAKind(order_by_value, [card.value for card in list_of_all_cards])
            hand_rank = temp if temp > hand_rank else hand_rank
        if hand_rank[0] < 5:
            temp = self.straight(list_of_all_cards)
            hand_rank = temp if temp > hand_rank else hand_rank
        
        if hand_rank[0] == 0:
            temp = [x.value for x in player.hand]
            temp = sorted(temp)
            
            hand_rank = (0, [temp[-1], temp[-2]])
        
        return hand_rank
    
    def isBettingRoundOver(self):
        if self.active_players <= 1:
            #print "1 player"
            return True
        
        temp = self.action_history.split("/")
        if len(temp[-1]) > 1 and temp[-1][-1] == 'c':
            return True
        
        #print (self.current_player, self.highest_bidder, self.players[self.current_player].last_move)
        if self.current_player == self.highest_bidder and self.players[self.current_player].last_move != None:
            #print "All checks"
            return True
        
        return False

    def nextPlayer(self):
        self.current_player = (self.current_player + 1) % self.number_of_players
        #while self.current_player not in self.active_players:
        #    self.current_player = (self.current_player + 1) % self.number_of_players
    
    def raiseBet(self, multiplier=1):
        if self.number_of_raises >= self.limit_of_raises:
            return self.check()
        
        player = self.players[self.current_player]
        
        amount = self.current_bid - player.current_bet + (multiplier * self.big_blind)
        value_of_bid = player.bid(amount)
        self.pot += value_of_bid

        if value_of_bid == 0 or (player.current_bet + value_of_bid == self.current_bid):
            player.last_move = 'check'
        else:
            player.last_move = 'raise'
            self.action_history += "r"
            self.current_bid += (multiplier * self.big_blind)
            self.highest_bidder = self.current_player
        
        self.number_of_raises += 1
        self.nextPlayer()
        
    def fold(self):
        player = self.players[self.current_player]
        #self.active_players.remove(self.current_player)
        self.active_players -= 1
        
        player.last_move = 'fold'
        flag = False
        if self.highest_bidder == self.current_player:
            flag = True
        
        self.nextPlayer()
        if flag:
            self.highest_bidder = self.current_player
    
    def check(self):
        player = self.players[self.current_player]
        
        amount = self.current_bid - player.current_bet
        
        player.last_move = 'check'        
        self.action_history += "c"

        if amount > 0:
            value_of_bid = player.bid(amount)
            self.pot += value_of_bid
            
        self.nextPlayer()
    
    def possible_moves(self):
        moves = ['raise', 'check', 'fold']
        
        #player = self.players[self.current_player]
        
        #if player.current_bet == self.current_bid:
        #    moves.append('check')
        
        return moves
    
    def executeMove(self, move):
        if move == 'raise':
            self.raiseBet()

        elif move == 'raise5':
            self.raiseBet(5)

        elif move == 'raise10':
            self.raiseBet(10)

        elif move == 'check':
            self.check()
        
        elif move == 'fold':
            self.fold()
    
    def isHandHigher(self, hand1, hand2):
        if hand1[0] > hand2[0]:
            return 0 # CHALLENGING HAND IS LOWER
        
        if hand2[0] > hand1[0]:
            return 1 # CHALLENGING HAND IS HIGHER
        
        for i in range(0, len(hand1[1])):
            if hand1[1][i] > hand2[1][i]:
                return 0 # CHALLENGING HAND IS LOWER
            if hand2[1][i] > hand1[1][i]:
                return 1 # CHALLENGING HAND IS HIGHER
        
        return 2 # TIE
    
    def winner(self):
        results = {}
        if self.active_players >= 2:
            for player_index in range(0, self.active_players):
                results[player_index] = self.rankHand(player_index)
        else:
            return [self.current_player]
        
        #print results
        
        highest_hand = None
        winning_players = []
        
        for key in results:
            if highest_hand == None:
                highest_hand = results[key]
                winning_players.append(key)
            else:
                evaluation = self.isHandHigher(highest_hand, results[key])
                if evaluation == 1:
                    highest_hand = results[key]
                    winning_players = [key]
                elif evaluation == 2: 
                    winning_players.append(key)
        
        return winning_players

class GameHandler:
    def __init__(self, number_of_players, agents, starting_player_pot, small_blind):
        self.starting_player_pot = starting_player_pot
        self.game = Gameloop(number_of_players, starting_player_pot, small_blind)
        self.agents = agents

    def run_gameloop_upTo(self, cutoff_street=1):
        for i in range(0, self.game.number_of_players):
            self.game.players[i].pot = self.starting_player_pot
            
        self.game.setup()
       
        for i in range(0, self.game.number_of_players):
            self.agents[i].setHand(self.game.players[i].hand)
        
        counter = 0
        while not self.game.isBettingRoundOver():
            current_agent = self.game.current_player
            
            move = self.agents[current_agent].decide(self.game, self.game.possible_moves())
            self.game.executeMove(move)

        self.game.flop()

        if cutoff_street > 1:
            while not self.game.isBettingRoundOver():
                current_agent = self.game.current_player

                move = self.agents[current_agent].decide(self.game, self.game.possible_moves())
                self.game.executeMove(move)

            self.game.turn()

        if cutoff_street > 2:
            while not self.game.isBettingRoundOver():
                current_agent = self.game.current_player

                move = self.agents[current_agent].decide(self.game, self.game.possible_moves())
                self.game.executeMove(move)
                
            self.game.river()

    def gameloop(self, street=3):
        for i in range(0, self.game.number_of_players):
            self.game.players[i].pot = self.starting_player_pot
            
        self.game.setup()
        
        if street > 0:
            self.game.flop()
        if street > 1:
            self.game.turn()
        if street > 2:
            self.game.river()
        
        for i in range(0, self.game.number_of_players):
            self.agents[i].setHand(self.game.players[i].hand)
        
        counter = 0
        while not self.game.isBettingRoundOver():
            current_agent = self.game.current_player
            
            move = self.agents[current_agent].decide(self.game, self.game.possible_moves())
            self.game.executeMove(move)

        if street < 1:
            self.game.flop()
        if street < 2:
            self.game.turn()
        if street < 3:
            self.game.river()

    def resume_gameloop(self, street=1):
        for i in range(0, self.game.number_of_players):
            self.agents[i].setHand(self.game.players[i].hand)
        
        while not self.game.isBettingRoundOver():
            current_agent = self.game.current_player
            
            move = self.agents[current_agent].decide(self.game, self.game.possible_moves())
            self.game.executeMove(move)

        if street < 1:
            self.game.flop()
        if street < 2:
            self.game.turn()
        if street < 3:
            self.game.river()

    def full_gameloop(self):
        for i in range(0, self.game.number_of_players):
            self.game.players[i].pot = self.starting_player_pot
            
        self.game.setup()
        
        for i in range(0, self.game.number_of_players):
            self.agents[i].setHand(self.game.players[i].hand)
        
        while not self.game.isBettingRoundOver():
            current_agent = self.game.current_player
            
            move = self.agents[current_agent].decide(self.game, self.game.possible_moves())
            self.game.executeMove(move)

        self.game.flop()
        
        while not self.game.isBettingRoundOver():
            current_agent = self.game.current_player
            
            move = self.agents[current_agent].decide(self.game, self.game.possible_moves())
            self.game.executeMove(move)
        
        self.game.turn()
        
        while not self.game.isBettingRoundOver():
            current_agent = self.game.current_player
            
            move = self.agents[current_agent].decide(self.game, self.game.possible_moves())
            self.game.executeMove(move)
        
        self.game.river()
        
        while not self.game.isBettingRoundOver():
            current_agent = self.game.current_player
            
            move = self.agents[current_agent].decide(self.game, self.game.possible_moves())
            self.game.executeMove(move)
            
    def run(self, street=3):
        self.gameloop(street)
        winners = self.game.winner()
        #print winners
        num_of_winners = float(len(winners))
        for win_player_index in winners:
            self.game.players[win_player_index].pot += int(float(self.game.pot) / num_of_winners)        
        
        return winners, self.game.players[0].pot
    
    def runResume(self, street=3):
        self.resume_gameloop(street)
        winners = self.game.winner()

        num_of_winners = float(len(winners))
        for win_player_index in winners:
            self.game.players[win_player_index].pot += int(float(self.game.pot) / num_of_winners)        
        
        return winners, self.game.players[0].pot        

    def runFullGame(self):
        self.full_gameloop()
        winners = self.game.winner()

        num_of_winners = float(len(winners))
        for win_player_index in winners:
            self.game.players[win_player_index].pot += int(float(self.game.pot) / num_of_winners)        
        
        return winners, self.game.players[0].pot

    def runTestGame(self):
        self.test_full_gameloop()
        winners = self.game.winner()

        num_of_winners = float(len(winners))
        for win_player_index in winners:
            self.game.players[win_player_index].pot += int(float(self.game.pot) / num_of_winners)        
        
        return winners, self.game.players[0].pot

    def runGetAllPlayerPots(self):
        self.gameloop()
        
        winners = self.game.winner()
        num_of_winners = float(len(winners))
        for win_player_index in winners:
            self.game.players[win_player_index].pot += int(float(self.game.pot) / num_of_winners)        
        
        return winners, [self.game.players[i].pot for i in range(self.game.number_of_players)]

class TierHandAI:
    def __init__(self):
        self.offset = 0.0
        self.fold_offset = 0.0
    
    def setHand(self, hand):
        self.hand = [hand[0].value, hand[1].value]
        self.isSameSuit = True if hand[0].suit == hand[1].suit else False
        self.hand_value = self.evaluateHand()
    
    def generateOffset(self):
        self.offset = 0#random.randint(0, 100)
        self.fold_offset = 0.0#random.uniform(-0.2, 0.2)
    
    def evaluateHand(self):
        hand_value = 0
        highest_card = max(self.hand)
        smallest_card = min(self.hand)
        
        if highest_card == 14:
            hand_value += 10.0
        elif highest_card == 13:
            hand_value += 8.0
        elif highest_card == 12:
            hand_value += 7.0
        elif highest_card == 11:
            hand_value += 6.0
        else:
            hand_value += float(highest_card) / 2.0
        
        if self.hand[0] == self.hand[1]:
            hand_value *= 2.0
            if self.hand[0] == 5:
                hand_value += 1.0
        
        if self.isSameSuit:
            hand_value += 2.0

        point_gap = highest_card - smallest_card
        if highest_card == 14 and smallest_card < 6:
            point_gap = smallest_card - 1

        if point_gap == 2:
            hand_value -= 1.0
        elif point_gap == 3:
            hand_value -= 2.0
        elif point_gap == 4:
            hand_value -= 4.0
        elif point_gap > 4:
            hand_value -= 5.0
        
        if point_gap < 2 and highest_card < 12:
            hand_value += 1.0
        
        if hand_value < 0:
            hand_value = 0.0

        return hand_value
        
    def decide(self, gamestate, available_actions):
        self_current_bet = gamestate.players[gamestate.current_player].current_bet
        buy_in = float(gamestate.current_bid - self_current_bet) / float(gamestate.big_blind)
        
        self_current_bet = float(self_current_bet) / float(gamestate.big_blind)
        
        if self.hand_value == 0.0:
            if buy_in <= 10.0:
                return 'check'
            return 'fold'
        
        MAX_BID_LEVEL = 50.0
        
        random_value = random.uniform(0, 1)
        #current_total_bid_level = float(gamestate.current_bid) / float(gamestate.big_blind)
        current_total_bid_level = float(gamestate.pot) / float(gamestate.big_blind)
        
        normalized_hand_value = self.hand_value / 20.0
        
        #raise_chance = normalized_hand_value
        highest_bid_level = MAX_BID_LEVEL * normalized_hand_value + self.offset
        #print(highest_bid_level)
        #fold_chance = (1.0 - normalized_hand_value) / 2.0
        fold_chance = (1.0 - math.log(self.hand_value, 20)) + self.fold_offset#+ self.offset
        
        max_buy_in = 8. * normalized_hand_value
        
        if buy_in > max_buy_in:
            return 'fold'
        
        if random_value < fold_chance:
            if buy_in == 0.0 or self_current_bet > 3.0:
                return 'check'
            return 'fold'
        
        if highest_bid_level > current_total_bid_level:
            return 'raise'
        
        return 'check'

### Play Poker Like the Pros (Book), Author: Phil Hellmuth

class TopTenHandAI:
    def __init__(self):
        self.offset = 0.0
        self.tier = 0
    
    def setHand(self, hand):
        self.hand = [hand[0].value, hand[1].value]
        self.isSameSuit = True if hand[0].suit == hand[1].suit else False
        self.hand_value = self.evaluateHand()
    
    def generateOffset(self):
        self.offset = 0#random.randint(0, 100)
    
    def evaluateHand(self):
        hand_value = 0.0
        card1 = max(self.hand)
        card2 = min(self.hand)
        
        if card1 == card2 and card1 >= 7:
            hand_value = 1.0
        else:
            if card2 >= 12:
                hand_value = 1.0
        
        if hand_value > 0.0:
            self.tier = 1
            if card1 <= 8:
                self.tier = 3
            elif card1 != card2 and card2 == 12:
                self.tier = 3
            elif card1 == card2 and card1 <= 11:
                self.tier = 2

        return hand_value
        
    def decide(self, gamestate, available_actions):
        buy_in = float(gamestate.current_bid - gamestate.players[gamestate.current_player].current_bet) / float(gamestate.big_blind)
        
        if self.hand_value == 0.0:
            if buy_in <= 1.5:
                return 'check'
            return 'fold'
        
        MAX_BID_LEVEL = 50.0
        
        #current_total_bid_level = float(gamestate.current_bid) / float(gamestate.big_blind)
        current_total_bid_level = float(gamestate.pot) / float(gamestate.big_blind)

        highest_bid_level = MAX_BID_LEVEL + self.offset
        #max_buy_in = float(8.0) * float(self.tier) / 3.0
        #print max_buy_in
        
        if highest_bid_level > current_total_bid_level:
            #if buy_in > max_buy_in:
            #    return 'fold'
            return 'raise'
        
        return 'check'


### Preflop Alberta Bot - Cepheus ( http://poker.srv.ualberta.ca/preflop )

class AlbertaAI:
    def __init__(self):
        self.look_up_table = {}
        self.other_player_called = False
        
        pickle_in = open("Alberta-bot.dat","rb")
        self.look_up_table = pickle.load(pickle_in)
    
    def setHand(self, hand):
        self.other_player_called = False
        self.hand = [hand[0].value, hand[1].value]
        self.isSameSuit = True if hand[0].suit == hand[1].suit else False
        self.hand_value = self.evaluateHand()
    
    def generateOffset(self):
        self.offset = 0#random.randint(0, 100)
    
    def evaluateHand(self):
        return 0
        
    def decide(self, gamestate, available_actions):
        player_index = gamestate.current_player
        
        card1 = self.hand[0]
        card2 = self.hand[1]
        suit = self.isSameSuit
        
        prob_num = random.uniform(0, 1)
        
        action_sequence = ""
        
        if self.other_player_called:
            action_sequence += "c"

        if gamestate.highest_bidder != player_index and gamestate.current_bid == gamestate.big_blind:
            action_sequence = "n"
        elif gamestate.pot == 2 * gamestate.big_blind:
            action_sequence = "c"
            self.other_player_called = True
        if gamestate.pot == 3 * gamestate.big_blind:
            action_sequence += "r"
        elif gamestate.pot == 4 * gamestate.big_blind:
            action_sequence += "r"
        elif gamestate.pot == 5 * gamestate.big_blind:
            action_sequence += "rr"
        elif gamestate.pot == 6 * gamestate.big_blind:
            action_sequence += "rr"
        elif gamestate.pot >= 7 * gamestate.big_blind:
            action_sequence += "rrr"
        #elif gamestate.pot >= 8 * gamestate.big_blind:
        #    action_sequence += "rrr"
        
        '''
        if self.other_player_called:
            action_sequence += "c"
        if gamestate.pot >= 3 * gamestate.big_blind:
            action_sequence += "r"
        if gamestate.pot >= 7 * gamestate.big_blind:
            action_sequence += "r"
        if gamestate.pot >= 11 * gamestate.big_blind:
            action_sequence += "r"
        '''
        
        decision = self.look_up_table[action_sequence][card1][card2][suit]
        
        if prob_num < decision['raise']:
            return 'raise'
        
        prob_num -= decision['raise']
        if prob_num < decision['check']:
            return 'check'

        return 'fold'

class RandomAI:
    def __init__(self):
        pass
    
    def setHand(self, hand):
        self.hand = [hand[0].value, hand[1].value]
        self.isSameSuit = True if hand[0].suit == hand[1].suit else False
    
    def generateOffset(self):
        pass
    
    def parseHeuristic(self):
        pass
    
    def decide(self, gamestate, available_actions):
        return random.choice(['raise', 'check', 'fold'])

class WeightedRandomAI:
    def __init__(self):
        pass
    
    def setHand(self, hand):
        self.hand = [hand[0].value, hand[1].value]
        self.isSameSuit = True if hand[0].suit == hand[1].suit else False
    
    def generateOffset(self):
        pass
    
    def parseHeuristic(self):
        pass
    
    def decide(self, gamestate, available_actions):
        probabilities = {}
        if len(gamestate.board) == 0:
            probabilities = {
                'raise': 0.25,
                'check': 0.7,
                'fold' : 0.05,
            }
        else:
            rank = gamestate.rankHand(gamestate.current_player)
            if rank == 0:
                probabilities = {
                    'raise': 0.0,
                    'check': 0.15,
                    'fold' : 0.85,
                }

            elif rank <= 2:
                probabilities = {
                    'raise': 0.4,
                    'check': 0.5,
                    'fold' : 0.1,
                }
            elif rank <= 6:
                probabilities = {
                    'raise': 0.7,
                    'check': 0.25,
                    'fold' : 0.05,
                }
            else:
                probabilities = {
                    'raise': 0.95,
                    'check': 0.05,
                    'fold' : 0.0,
                }
        
        random_n = random.uniform(0, 1)
        
        if random_n < probabilities['raise']:
            return 'raise'
        
        random_n -= probabilities['raise']
        
        if random_n < probabilities['check']:
            return 'check'
        
        return 'fold'

class CFRAI:
    def __init__(self):
        self.strategy_dict = None
        strategy_filename = "CFR_strategy_refined_moreiters_dict.json"
        strategy_file = open(strategy_filename, 'r')
        self.strategy_dict = json.loads(strategy_file.read())
        strategy_file.close()
    
    def setHand(self, hand):
        self.hand = [hand[0].value, hand[1].value]
        self.isSameSuit = True if hand[0].suit == hand[1].suit else False
    
    def generateOffset(self):
        pass
    
    def parseHeuristic(self):
        pass
    
    def decide(self, gamestate, available_actions):
        hand_rank = 0
        if gamestate.board == []:
            hand_rank = 1
        else:
            hand_rank = gamestate.rankHand(gamestate.current_player)[0]
        if hand_rank == 0:
            hand_rank = 1
        elif hand_rank == 10:
            hand_rank = 9
        
        #print hand_rank
        probabilities = self.strategy_dict[gamestate.action_history][str(hand_rank)]
        
        if 'r' not in probabilities:
            probabilities['r'] = 0.0
        if 'c' not in probabilities:
            probabilities['c'] = 0.0
        if 'f' not in probabilities:
            probabilities['f'] = 0.0
        
        random_n = random.uniform(0, 1)
        
        if random_n < probabilities['r']:
            return 'raise'
        
        random_n -= probabilities['r']
        
        if random_n < probabilities['c']:
            return 'check'
        
        return 'fold'

### PRIMITIVE TREE FUNCTIONS

def IfThenElse(input_condition, output1, output2):
    if input_condition:
        return output1
    else:
        return output2

def isSameSuit(hand):
    if hand[0].suit == hand[1].suit:
        return True
    
    return False

def notSameSuit(hand):
    if hand[0].suit != hand[1].suit:
        return True
    
    return False

def hasDoubles(hand):
    if hand[0].value == hand[1].value:
        return True
    
    return False

def notHasDoubles(hand):
    if hand[0].value != hand[1].value:
        return True
    
    return False

def cardDifferenceLE(hand, value):
    diff = abs(hand[0].value - hand[1].value)
    
    if diff <= value:
        return True
    return False

def cardDifferenceGE(hand, value):
    diff = abs(hand[0].value - hand[1].value)
    
    if diff >= value:
        return True
    return False

def highestCard(hand):
    temp = [hand[0].value, hand[1].value]
    
    return max(temp)

def highestCardGE(hand, value):
    highest_card = highestCard(hand)
    
    if highest_card >= value:
        return True
    return False

def highestCardEQ(hand, value):
    highest_card = highestCard(hand)
    
    if highest_card == value:
        return True
    return False

def highestCardLE(hand, value):
    highest_card = highestCard(hand)
    
    if highest_card <= value:
        return True
    return False

def lowestCard(hand):
    temp = [hand[0].value, hand[1].value]
    
    return min(temp)

def lowestCardGE(hand, value):
    lowest_card = lowestCard(hand)
    
    if lowest_card >= value:
        return True
    return False

def lowestCardEQ(hand, value):
    lowest_card = lowestCard(hand)
    
    if lowest_card == value:
        return True
    return False

def lowestCardLE(hand, value):
    lowest_card = lowestCard(hand)
    
    if lowest_card <= value:
        return True
    return False

def totalPotGE(potSize, value):
    if isinstance(potSize, list):
        return True
    return potSize >= value

def totalPotLE(potSize, value):
    if isinstance(potSize, list):
        return True
    return potSize <= value

def returnHandRank(hand, board):
    if board == []:
        return 1
    
    gloop = Gameloop(1, 10, 1)
    gloop.players[0].hand = hand
    gloop.board = board
    rank = gloop.rankHand(0)[0]
    if rank == 0:
        rank = 1

    return rank

def handValueGE(hand, value, board):
    return returnHandRank(hand, board) >= value

def handValueLE(hand, value, board):
    return returnHandRank(hand, board) <= value

### PRIMITIVE TREE FUNCTIONS

### Heuristic AI
func_globals = globals()
func_globals['and_'] = operator.and_

class HeuristicAI:
    def __init__(self):
        pass
    
    def setHeuristic(self, heuristic):
        self.heuristic = heuristic
    
    def parseHeuristic(self):
        code = marshal.loads(self.heuristic)
        self.heuristic = types.FunctionType(code, func_globals)
    
    def setHand(self, hand):
        self.hand = hand
    
    def generateOffset(self):
        pass
    
    def decide(self, gamestate, available_actions):
        #hand = self.gamestate.players[self.gamestate.current_player]
        pot_size = int(float(gamestate.current_bid) / float(gamestate.big_blind))
        board = gamestate.board
        
        return self.heuristic(self.hand, pot_size, board)

def runSimulation(individual, n, NUM_OF_PLAYERS=2, TOTAL_PLAYER_POT=1000, BIG_BLIND=20, street=3):
    number_of_players = NUM_OF_PLAYERS
    total_player_pot = TOTAL_PLAYER_POT
    small_blind = BIG_BLIND / 2

    agents = [individual]
    agents[0].parseHeuristic()
    
    agents.append(WeightedRandomAI())

    gh = GameHandler(number_of_players, agents, total_player_pot, small_blind)
    
    results = []
    agent_pot = []
    
    for i in range(0, n):
        result, money = gh.run(street=street)
        results.append(result)
        agent_pot.append(money)
    '''
    one_third_n = n / 2

    agents.append(TopTenHandAI())

    gh = GameHandler(number_of_players, agents, total_player_pot, small_blind)
    
    results = []
    agent_pot = []
    
    for i in range(0, one_third_n):
        result, money = gh.run(street=street)
        results.append(result)
        agent_pot.append(money)

    agents = [individual]

    agents.append(AlbertaAI())
    gh = GameHandler(number_of_players, agents, total_player_pot, small_blind)
    
    for i in range(0, one_third_n):
        result, money = gh.run(street=street)
        results.append(result)
        agent_pot.append(money)
    '''
    return (results, agent_pot)

def runFullSimulation(individual, n, NUM_OF_PLAYERS=2, TOTAL_PLAYER_POT=1000, BIG_BLIND=20):
    number_of_players = NUM_OF_PLAYERS
    total_player_pot = TOTAL_PLAYER_POT
    small_blind = BIG_BLIND / 2

    agents = [individual]
    agents[0].parseHeuristic()
    
    #agents.append(WeightedRandomAI())
    agents.append(CFRAI())

    gh = GameHandler(number_of_players, agents, total_player_pot, small_blind)
    
    results = []
    agent_pot = []
    
    for i in range(0, n):
        result, money = gh.runFullGame()
        results.append(result)
        agent_pot.append(money)

    return (results, agent_pot)

def runSimulationJustCepheus(individual, n, NUM_OF_PLAYERS=2, TOTAL_PLAYER_POT=1000, BIG_BLIND=20):
    number_of_players = NUM_OF_PLAYERS
    total_player_pot = TOTAL_PLAYER_POT
    small_blind = BIG_BLIND / 2

    agents = [individual]
    agents[0].parseHeuristic()
    
    one_third_n = n

    agents.append(AlbertaAI())

    gh = GameHandler(number_of_players, agents, total_player_pot, small_blind)
    
    results = []
    agent_pot = []

    for i in range(0, one_third_n):
        result, money = gh.run()
        results.append(result)
        agent_pot.append(money)
    
    return (results, agent_pot)

def runSimulationJustTopTen(individual, n, NUM_OF_PLAYERS=2, TOTAL_PLAYER_POT=1000, BIG_BLIND=20):
    number_of_players = NUM_OF_PLAYERS
    total_player_pot = TOTAL_PLAYER_POT
    small_blind = BIG_BLIND / 2

    agents = [individual]
    agents[0].parseHeuristic()
    
    one_third_n = n

    agents.append(TopTenHandAI())

    gh = GameHandler(number_of_players, agents, total_player_pot, small_blind)
    
    results = []
    agent_pot = []

    for i in range(0, one_third_n):
        result, money = gh.run()
        results.append(result)
        agent_pot.append(money)
    
    return (results, agent_pot)

def runSimulationFreezeGame(individual, n, gameloops, street, NUM_OF_PLAYERS=2, TOTAL_PLAYER_POT=1000, BIG_BLIND=20):
    number_of_players = NUM_OF_PLAYERS
    total_player_pot = TOTAL_PLAYER_POT
    small_blind = BIG_BLIND / 2

    agents = [individual]
    agents[0].parseHeuristic()
    
    agents.append(CFRAI())
    
    results = []
    agent_pot = []
    
    for i in range(0, n):
        gh = GameHandler(number_of_players, agents, total_player_pot, small_blind)
        #gh.agents = agents
        gh.game = gameloops[i].copy()
        result, money = gh.runResume(street)
        results.append(result)
        agent_pot.append(money)
        
        del gh
    
    return (results, agent_pot)

def evaluateFreezeGameState(player, gameloops, n=8000, street=3, TOTAL_PLAYER_POT=1000):
    #game_handlers = pickle.load(open(input_file, "rb"))
    results, money = runSimulationFreezeGame(player, n, gameloops, street, TOTAL_PLAYER_POT=TOTAL_PLAYER_POT)
    
    return (float(sum(money)) / float(n) - float(TOTAL_PLAYER_POT),)

def evaluate(player, n=8000, street=3, TOTAL_PLAYER_POT=1000):
    results, money = runSimulation(player, n, TOTAL_PLAYER_POT=TOTAL_PLAYER_POT, street=street)
    score = {'wins': 0.0, 'ties': 0.0, 'losses': 0.0}
    money_lost = 0.0
    
    return (float(sum(money)) / float(n) - float(TOTAL_PLAYER_POT),)

def evaluateFullGame(player, n=8000, TOTAL_PLAYER_POT=1000):
    results, money = runFullSimulation(player, n, TOTAL_PLAYER_POT=TOTAL_PLAYER_POT)
    score = {'wins': 0.0, 'ties': 0.0, 'losses': 0.0}
    money_lost = 0.0
    
    return (float(sum(money)) / float(n) - float(TOTAL_PLAYER_POT),)

def evaluateJustCepheus(player, n=8000, TOTAL_PLAYER_POT=1000):
    results, money = runSimulationJustCepheus(player, n, TOTAL_PLAYER_POT=TOTAL_PLAYER_POT)
    score = {'wins': 0.0, 'ties': 0.0, 'losses': 0.0}
    money_lost = 0.0
    
    return (float(sum(money)) / float(n) - float(TOTAL_PLAYER_POT),)

def evaluateJustTopTen(player, n=8000, TOTAL_PLAYER_POT=1000):
    results, money = runSimulationJustTopTen(player, n, TOTAL_PLAYER_POT=TOTAL_PLAYER_POT)
    score = {'wins': 0.0, 'ties': 0.0, 'losses': 0.0}
    money_lost = 0.0
    
    return (float(sum(money)) / float(n) - float(TOTAL_PLAYER_POT),)

def evaluateMoney(player, n=8000):
    results, money = runSimulation(player, n)
    score = {'wins': 0.0, 'ties': 0.0, 'losses': 0.0}
    money_lost = 0.0
    
    return money

def evaluateVariance(player, n=8000):
    results, money = runSimulation(player, n)
    score = {'wins': 0.0, 'ties': 0.0, 'losses': 0.0}
    money_lost = 0.0

    return (money,)

def runSimulationForTrees(individual, opponent, n,  TOTAL_PLAYER_POT=1000, BIG_BLIND=20):
    number_of_players = 2
    total_player_pot = TOTAL_PLAYER_POT
    small_blind = BIG_BLIND / 2

    agents = [individual, opponent]
    agents[0].parseHeuristic()
    agents[1].parseHeuristic()
        
    gh = GameHandler(number_of_players, agents, total_player_pot, small_blind)
    
    results = []
    agent_pot = []
    
    for i in range(0, n):
        result, money = gh.runGetAllPlayerPots()
        results.append(result)
        agent_pot.append(money)
    
    return agent_pot

def evaluateMatchUp(player, opponent, n=8000, TOTAL_PLAYER_POT=1000, BIG_BLIND=20):
    money = runSimulationForTrees(player, opponent, n, TOTAL_PLAYER_POT, BIG_BLIND)
    
    p_money = 0.0
    op_money = 0.0
    
    for agent_money in money:
        p_money += agent_money[0]
        #op_money += agent_money[1]
    
    #return ((p_money / float(n)) - float(TOTAL_PLAYER_POT), (op_money / float(n)) - float(TOTAL_PLAYER_POT))
    return ((p_money / float(n)) - float(TOTAL_PLAYER_POT), )
