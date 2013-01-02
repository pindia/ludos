from unittest import TestCase
from ludos.connection import LudosConnection
from ludos.transport import Transport


class LudosTestCase(TestCase):
    def setUp(self):
        self.connections = []

    def make_connection(self):
        t = TestTransport()
        c = LudosConnection(t)
        return c

    def clear_all_buffers(self):
        for connection in self.connections:
            connection.command_buffer = []

    def assertNoCommandsReceived(self, connection):
        self.assertFalse(connection.transport.command_buffer)

    def assertCommandReceived(self, connection, command):
        self.assertIn(command, connection.transport.command_buffer)
        connection.transport.command_buffer.remove(command)

class TestTransport(Transport):
    def __init__(self):
        self.open = True
        self.command_buffer = []
        super(TestTransport, self).__init__()

    def client_command(self, command):
        self._on_command(command)

    def client_disconnected(self, clean):
        self._on_disconnect(clean)

    def send_command(self, command):
        self.command_buffer.append(command)

    def disconnect(self):
        self.open = False