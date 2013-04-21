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
            game_id = command.game_id
            player_id = command.player_id
            if command.op == StartConnectionCommand.CREATE_GAME:
                game_id = MANAGER.assign_game_id()
                player_id = 0
            self.game = MANAGER.get_game(game_id)
            if command.op == StartConnectionCommand.JOIN_GAME:
                player_id = self.game.assign_player_id()
            if self.game.state > Game.STATE_NEW:
                self.transport.disconnect()
                return
            for player in self.game.players.values():
                self.transport.send_command(PlayerConnectedCommand(player.id, player.data))
            self.player = Player(player_id, command.player_data, self.transport)
            self.game.players[player_id] = self.player
            for player in self.game.players.values():
                if player != self.player:
                    player.transport.send_command(PlayerConnectedCommand(player_id, command.player_data))
            if command.op == StartConnectionCommand.CREATE_GAME or StartConnectionCommand.JOIN_GAME:
                self.transport.send_command(StartConnectionCommand(command.version, command.op, game_id, player_id, command.player_data, command.signature))
        if isinstance(command, GameControlCommand):
            self.game.received_game_control(command, self.player)
        if isinstance(command, PlayerActionCommand) or isinstance(command, ChatMessageCommand) and self.game.state > Game.STATE_NEW:
            for player in self.game.players.values():
                if player != self.player:
                    player.transport.send_command(command)

    def on_disconnect(self, clean):
        if not hasattr(self, 'game'):
            return
        del self.game.players[self.player.id]
        for player in self.game.players.values():
            player.transport.send_command(GameControlCommand(GameControlCommand.PLAYER_QUIT, 0, self.player.id))
