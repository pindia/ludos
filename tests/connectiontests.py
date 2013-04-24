from .common import LudosTestCase
from ludos.protocol import *

class ConnectionTests(LudosTestCase):
    def test_connection_initial(self):
        c = self.make_connection()
        self.assertNoCommandsReceived(c)

    def test_player_join(self):
        c1 = self.make_connection()
        c1.transport.client_command(StartConnectionCommand(1, StartConnectionCommand.JOIN_GAME_AS_PLAYER, 'test', {}, 0, {'name': 'Player 1'}, None))
        c2 = self.make_connection()
        c2.transport.client_command(StartConnectionCommand(1, StartConnectionCommand.JOIN_GAME_AS_PLAYER, 'test', {}, 1, {'name': 'Player 2'}, None))
        self.assertCommandReceived(c1, PlayerConnectedCommand(1, {'name': 'Player 2'}))
        self.assertCommandReceived(c2, PlayerConnectedCommand(0, {'name': 'Player 1'}))

        c1.transport.client_disconnected(clean=True)
        self.assertCommandReceived(c2, GameControlCommand(GameControlCommand.PLAYER_QUIT, 0, 0))


    def test_game_start(self):
        c1 = self.make_connection()
        c2 = self.make_connection()
        c1.transport.client_command(StartConnectionCommand(1, StartConnectionCommand.JOIN_GAME_AS_PLAYER, 'test', {}, 0, {'name': 'Player 1'}, None))
        c2.transport.client_command(StartConnectionCommand(1, StartConnectionCommand.JOIN_GAME_AS_PLAYER, 'test', {}, 1, {'name': 'Player 2'}, None))
        self.clear_all_buffers()

        gc = GameControlCommand(GameControlCommand.START_GAME, 0, None)
        c1.transport.client_command(gc)
        self.assertNoCommandsReceived(c1)
        self.assertNoCommandsReceived(c2) # First game control command has no effect
        c2.transport.client_command(gc)
        self.assertCommandReceived(c1, gc)
        self.assertCommandReceived(c2, gc) # Once acknowledged, command is broadcast

        c3 = self.make_connection()
        c3.transport.client_command(StartConnectionCommand(1, StartConnectionCommand.JOIN_GAME_AS_PLAYER, 'test', {}, 2, {'name': 'Player 3'}, None))
        self.assertFalse(c3.transport.open) # Once started, no new players can join

    def test_create_game(self):
        c1 = self.make_connection()
        c1.transport.client_command(StartConnectionCommand(1, StartConnectionCommand.CREATE_GAME, None, {'players': 2}, None, {'name': 'Player 1'}, None))
        c = c1.transport.receive_command()
        self.assertEquals(c.game_id, c1.game.id)
        self.assertEquals(c.player_id, 0)
        c2 = self.make_connection()
        c2.transport.client_command(StartConnectionCommand(1, StartConnectionCommand.JOIN_GAME, c1.game.id, None, None, {'name': 'Player 1'}, None))
        c = c2.transport.receive_command(StartConnectionCommand)
        self.assertEquals(c.game_id, c1.game.id)
        self.assertEquals(c.game_data, {'players': 2})
        self.assertEquals(c.player_id, 1)

    def test_game_listener(self):
        c1 = self.make_connection()
        c1.transport.client_command(StartConnectionCommand(1, StartConnectionCommand.LIST_GAMES, None, None, None, None, None))
        c = c1.transport.receive_command(GameListCommand)
        self.assertEquals(c.game_list, [])
        self.clear_all_buffers()

        c2 = self.make_connection()
        c2.transport.client_command(StartConnectionCommand(1, StartConnectionCommand.CREATE_GAME, None, {'players': 2}, None, {'name': 'Player 1'}, None))

        c = c1.transport.receive_command(GameListCommand)
        self.assertEquals(c.game_list, [{'id': '0', 'players': 1, 'target_players': 2}])
