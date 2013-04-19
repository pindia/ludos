from .game import GameManager, Player
from ludos.protocol import *

MANAGER = GameManager()

class LudosConnection(object):
    def __init__(self, transport):
        self.transport = transport
        self.transport.set_command_callback(self.on_command)
        self.transport.set_disconnect_callback(self.on_disconnect)

    def on_command(self, command):
        if isinstance(command, StartConnectionCommand):
            self.game = MANAGER.get_game(command.game_id)
            for player in self.game.players.values():
                self.transport.send_command(PlayerConnectedCommand(player.id, player.data))
            self.player = Player(command.player_id, command.player_data, self.transport)
            self.game.players[command.player_id] = self.player
            for player in self.game.players.values():
                player.transport.send_command(PlayerConnectedCommand(command.player_id, command.player_data))
        if isinstance(command, GameControlCommand):
            self.game.process_game_control(command, self.player)

    def on_close(self):
        pass

    def on_disconnect(self, clean):
        del self.game.players[self.player.id]
        for player in self.game.players.values():
            player.transport.send_command(GameControlCommand(GameControlCommand.PLAYER_QUIT, 0, self.player.id))