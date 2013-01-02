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
            self.game.players[command.player_id] = Player(command.player_id, command.player_data, self.transport)
            for player in self.game.players.values():
                player.transport.send_command(PlayerConnectedCommand(command.player_id, command.player_data))

    def on_close(self):
        pass

    def on_disconnect(self):
        pass