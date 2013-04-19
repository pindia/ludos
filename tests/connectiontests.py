from .common import LudosTestCase
from ludos.protocol import *

class ConnectionTests(LudosTestCase):
    def test_connection_initial(self):
        c = self.make_connection()
        self.assertNoCommandsReceived(c)

    def test_player_join(self):
        c1 = self.make_connection()
        c1.transport.client_command(StartConnectionCommand(1, 'test', 0, {'name': 'Player 1'}, None))
        c2 = self.make_connection()
        c2.transport.client_command(StartConnectionCommand(1, 'test', 1, {'name': 'Player 2'}, None))
        self.assertCommandReceived(c1, PlayerConnectedCommand(1, {'name': 'Player 2'}))
        self.assertCommandReceived(c2, PlayerConnectedCommand(0, {'name': 'Player 1'}))

        c1.transport.client_disconnected(clean=True)
        self.assertCommandReceived(c2, GameControlCommand(GameControlCommand.PLAYER_QUIT, 0, 0))


    def test_game_start(self):
        c1 = self.make_connection()
        c2 = self.make_connection()
        c1.transport.client_command(StartConnectionCommand(1, 'test', 0, {'name': 'Player 1'}, None))
        c2.transport.client_command(StartConnectionCommand(1, 'test', 1, {'name': 'Player 2'}, None))
        self.clear_all_buffers()


