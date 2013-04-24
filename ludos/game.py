import collections
import functools
import itertools
import logging
from ludos.event import EventSource
from ludos.protocol import *

log = logging.getLogger(__name__)

class Game(EventSource):
    STATE_OPEN = 0
    STATE_RUNNING = 1
    STATE_PAUSED = 2
    STATE_OVER = 3
    STATE_DESTROYED = 4

    def __init__(self, id, data):
        super(Game, self).__init__()
        self.id = id
        self.data = data
        self._state = Game.STATE_OPEN
        self.players = {}
        self.game_control = collections.defaultdict(set)

    def get_state(self):
        return self._state

    def set_state(self, new_state):
        self._state = new_state
        self.trigger('stateChanged', new_state)

    state = property(get_state, set_state)

    def assign_player_id(self):
        for i in itertools.count():
            if i not in self.players:
                return i

    def add_player(self, player_id, player):
        self.players[player_id] = player
        self.trigger('playersChanged')

    def remove_player(self, player_id):
        del self.players[player_id]
        if len(self.players) == 0:
            self.state = Game.STATE_DESTROYED
        else:
            self.trigger('playersChanged')


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

class GameManager(EventSource):
    def __init__(self):
        super(GameManager, self).__init__()
        self.games = {}

    def get_game(self, game_id, game_data):
        if game_id in self.games:
            return self.games[game_id]
        else:
            game = Game(game_id, game_data)
            game.bind('stateChanged', functools.partial(self.game_state_changed, game))
            game.bind('playersChanged', functools.partial(self.game_players_changed, game))
            self.games[game_id] = game
            return game

    def game_players_changed(self, game):
        if game.state == Game.STATE_OPEN:
            self.send_games_changed()

    def game_state_changed(self, game, new_state):
        print game.id, new_state
        if new_state == Game.STATE_OPEN:
            self.send_games_changed()
        if new_state == Game.STATE_DESTROYED:
            log.info('Destroying game %s' % game.id)
            del self.games[game.id]
            self.send_games_changed()

    def assign_game_id(self):
        for i in itertools.count():
            if str(i) not in self.games:
                return str(i)

    def bind(self, event, listener):
        super(GameManager, self).bind(event, listener)
        if event == 'gamesChanged':
            self.send_games_changed(listener)

    def send_games_changed(self, listener=None):
        print self.games
        games = [{'id': game.id, 'players': len(game.players), 'target_players': game.data.get('players')} for game in self.games.values() if game.state == Game.STATE_OPEN]
        data = {'games': len(self.games), 'open_games': len(games), 'players': sum(len(g.players) for g in self.games.values())}
        if listener:
            listener(data, games)
        else:
            self.trigger('gamesChanged', data, games)

    def reset(self):
        self.games = {}