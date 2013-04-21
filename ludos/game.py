import collections
import itertools
import logging
from ludos.protocol import *

log = logging.getLogger(__name__)

class Game(object):
    STATE_NEW = 0
    STATE_RUNNING = 1
    STATE_PAUSED = 2
    STATE_OVER = 3

    def __init__(self, id, destroy_callback=lambda: None):
        self.id = id
        self.state = Game.STATE_NEW
        self.players = {}
        self.game_control = collections.defaultdict(set)
        self.destroy_callback = destroy_callback

    def assign_player_id(self):
        for i in itertools.count():
            if i not in self.players:
                return i

    def remove_player(self, player_id):
        del self.players[player_id]
        if len(self.players) == 0:
            self.destroy_callback()


    def received_game_control(self, command, player):
        s = self.game_control[command]
        s.add(player)
        if len(s) == len(self.players): # All players have agreed on command
            for player in self.players.values():
                player.transport.send_command(command) # Make the command official
            self.process_game_control(command)

    def process_game_control(self, command):
        if command.op == GameControlCommand.START_GAME and self.state == Game.STATE_NEW:
            self.state = Game.STATE_RUNNING
        if command.op == GameControlCommand.PAUSE_GAME and self.state == Game.STATE_RUNNING:
            self.state = Game.STATE_PAUSED
        if command.op == GameControlCommand.UNPAUSE_GAME and self.state == Game.STATE_PAUSED:
            self.state = Game.STATE_RUNNING
        if command.op == GameControlCommand.END_GAME and self.state > Game.STATE_NEW:
            self.state = Game.STATE_OVER
        if command.op == GameControlCommand.PLAYER_KICKED:
            self.players[command.player].transport.disconnect()




class Player(object):
    def __init__(self, id, data, transport):
        self.id = id
        self.data = data
        self.transport = transport

class GameManager(object):
    def __init__(self):
        self.games = {}

    def get_game(self, game_id):
        if game_id in self.games:
            return self.games[game_id]
        else:
            game = Game(game_id, lambda: self.destroy_game(game_id))
            self.games[game_id] = game
            return game

    def destroy_game(self, game_id):
        log.info('Destroying game %s' % game_id)
        del self.games[game_id]

    def assign_game_id(self):
        for i in itertools.count():
            if str(i) not in self.games:
                return str(i)

    def reset(self):
        self.games = {}