import time
from .game import GameManager, Player, Game
from ludos.event import EventSource
from ludos.protocol import *

MANAGER = GameManager()

class LudosConnection(EventSource):
    def __init__(self):
        self.pings = []
        super(LudosConnection, self).__init__()


    def on_command(self, command):
        if isinstance(command, StartConnectionCommand):
            if command.op == StartConnectionCommand.LIST_GAMES:
                MANAGER.bind('gamesChanged', self.send_games_changed)
                return
            game_id = command.game_id
            player_id = command.player_id
            if command.op == StartConnectionCommand.CREATE_GAME:
                game_id = MANAGER.assign_game_id()
                player_id = 0
            self.game = MANAGER.get_game(game_id, command.game_data)
            game_data = self.game.data
            if command.op == StartConnectionCommand.JOIN_GAME:
                player_id = self.game.assign_player_id()
            if self.game.state > Game.STATE_OPEN:
                self.disconnect()
                return
            for player in self.game.players.values():
                self.send_command(PlayerConnectedCommand(player.id, player.data))
            self.player = Player(player_id, command.player_data, self)
            self.game.add_player(player_id, self.player)
            for player in self.game.players.values():
                if player != self.player:
                    player.connection.send_command(PlayerConnectedCommand(player_id, command.player_data))
            if command.op == StartConnectionCommand.CREATE_GAME or StartConnectionCommand.JOIN_GAME:
                self.send_command(StartConnectionCommand(command.version, command.op, game_id, game_data, player_id, command.player_data, command.signature))
        if isinstance(command, GameControlCommand):
            self.game.received_game_control(command, self.player)
        if isinstance(command, PlayerActionCommand) or isinstance(command, ChatMessageCommand) and self.game.state > Game.STATE_OPEN:
            for player in self.game.players.values():
                if player != self.player:
                    player.connection.send_command(command)
        if isinstance(command, PingCommand):
            latency = int((time.time() - self.pings.pop(0))*1000)
            self.player.latency = latency

    def periodic(self):
        if hasattr(self, 'game'):
            for player in self.game.players.values():
                self.send_command(PlayerStatusCommand(player.id, {'latency': player.latency}))
            self.pings.append(time.time())
            self.send_command(PingCommand())

    def send_games_changed(self, data, games):
        self.send_command(GameListCommand(data, games))

    def send_command(self, command):
        self.trigger('sendCommand', command)

    def disconnect(self):
        self.trigger('disconnect')

    def on_disconnect(self, clean):
        try:
            MANAGER.unbind('gamesChanged', self.send_games_changed)
        except ValueError:
            pass
        if not hasattr(self, 'game'):
            return
        self.game.remove_player(self.player.id)
        for player in self.game.players.values():
            player.connection.send_command(GameControlCommand(GameControlCommand.PLAYER_QUIT, 0, self.player.id))
