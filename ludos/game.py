import collections
import itertools
import logging
from ludos.protocol import *

log = logging.getLogger(__name__)

class Game(object):
    STATE_OPEN = 0
    STATE_RUNNING = 1
    STATE_PAUSED = 2
    STATE_OVER = 3
    STATE_DESTROYED = 4

    def __init__(self, id, data, state_callback=lambda new_state: None):
        self.id = id
        self.data = data
        self.state_callback = state_callback
        self._state = Game.STATE_OPEN
        self.players = {}
        self.game_control = collections.defaultdict(set)

    def get_state(self):
        return self._state

    def set_state(self, new_state):
        self._state = new_state
        self.state_callback(new_state)

    state = property(get_state, set_state)

    def assign_player_id(self):
        for i in itertools.count():
            if i not in self.players:
                return i

    def remove_player(self, player_id):
        del self.players[player_id]
        if len(self.players) == 0:
            self.state = Game.STATE_DESTROYED


    def received_game_control(self, command, player):
        s = self.game_control[command]
        s.add(player)
        if len(s) == len(self.players): # All players have agreed on command
            for player in self.players.values():
                player.transport.send_command(command) # Make the command official
            self.process_game_control(command)

    def process_game_control(self, command):
        if command.op == GameControlCommand.START_GAME and self.state == Game.STATE_OPEN:
            self.state = Game.STATE_RUNNING
        if command.op == GameControlCommand.PAUSE_GAME and self.state == Game.STATE_RUNNING:
            self.state = Game.STATE_PAUSED
        if command.op == GameControlCommand.UNPAUSE_GAME and self.state == Game.STATE_PAUSED:
            self.state = Game.STATE_RUNNING
        if command.op == GameControlCommand.END_GAME and self.state > Game.STATE_OPEN:
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
        self.listeners = []

    def get_game(self, game_id, game_data):
        if game_id in self.games:
            return self.games[game_id]
        else:
            game = Game(game_id, game_data, lambda new_state: self.update_game(game_id, new_state))
            self.games[game_id] = game
            game.state = Game.STATE_OPEN
            return game

    def update_game(self, game_id, new_state):
        print game_id, new_state
        if new_state == Game.STATE_OPEN:
            self.send_games_changed()
        if new_state == Game.STATE_DESTROYED:
            log.info('Destroying game %s' % game_id)
            del self.games[game_id]
            self.send_games_changed()

    def assign_game_id(self):
        for i in itertools.count():
            if str(i) not in self.games:
                return str(i)

    def bind_games_changed(self, listener):
        self.listeners.append(listener)
        self.send_games_changed(listener)

    def unbind_games_changed(self, listener):
        try:
            self.listeners.remove(listener)
        except ValueError:
            pass

    def send_games_changed(self, listener=None):
        print self.games
        games = [{'id': game.id, 'players': len(game.players), 'target_players': game.data.get('players')} for game in self.games.values() if game.state == Game.STATE_OPEN]
        data = {'games': len(self.games), 'open_games': len(games), 'players': sum(len(g.players) for g in self.games.values())}
        if listener:
            listener(data, games)
        else:
            for listener in self.listeners:
                listener(data, games)


    def reset(self):
        self.games = {}