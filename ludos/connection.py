from .game import GameManager, Player, Game
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
            if self.game.state > Game.STATE_NEW:
                self.transport.disconnect()
                return
            for player in self.game.players.values():
                self.transport.send_command(PlayerConnectedCommand(player.id, player.data))
            self.player = Player(command.player_id, command.player_data, self.transport)
            self.game.players[command.player_id] = self.player
            for player in self.game.players.values():
                player.transport.send_command(PlayerConnectedCommand(command.player_id, command.player_data))
        if isinstance(command, GameControlCommand):
            self.game.received_game_control(command, self.player)
        if isinstance(command, PlayerActionCommand) or isinstance(command, ChatMessageCommand) and self.game.state > Game.STATE_NEW:
            for player in self.game.players.values():
                if player != self.player:
                    player.transport.send_command(command)

    def on_disconnect(self, clean):
        del self.game.players[self.player.id]
        for player in self.game.players.values():
            player.transport.send_command(GameControlCommand(GameControlCommand.PLAYER_QUIT, 0, self.player.id))