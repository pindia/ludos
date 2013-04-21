from unittest import TestCase
from ludos.connection import LudosConnection, MANAGER
from ludos.transport import Transport


class LudosTestCase(TestCase):
    def setUp(self):
        self.connections = []
        MANAGER.reset()

    def make_connection(self):
        t = TestTransport()
        c = LudosConnection(t)
        self.connections.append(c)
        return c

    def clear_all_buffers(self):
        for connection in self.connections:
            connection.transport.command_buffer = []

    def assertNoCommandsReceived(self, connection):
        self.assertFalse(connection.transport.command_buffer)

    def assertCommandReceived(self, connection, command):
        self.assertTrue(connection.transport.open)
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

    def receive_command(self, cls=None):
        assert len(self.command_buffer)
        if cls is None:
            return self.command_buffer.pop(0)
        else:
            buf = [c for c in self.command_buffer if isinstance(c, cls)]
            assert len(buf)
            c = buf[0]
            self.command_buffer.remove(c)
            return c


    def send_command(self, command):
        self.command_buffer.append(command)

    def disconnect(self):
        self.open = False