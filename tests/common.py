import logging
from unittest import TestCase
from ludos.connection import LudosConnection, MANAGER

class LudosTestCase(TestCase):
    def setUp(self):
        self.connections = []
        MANAGER.reset()

    def make_connection(self):
        c = TestConnection()
        self.connections.append(c)
        return c

    def clear_all_buffers(self):
        for connection in self.connections:
            connection.command_buffer = []

    def assertNoCommandsReceived(self, connection):
        self.assertFalse(connection.command_buffer)

    def assertCommandReceived(self, connection, command):
        self.assertTrue(connection.open)
        self.assertIn(command, connection.command_buffer)
        connection.command_buffer.remove(command)

class TestConnection(LudosConnection):
    def __init__(self):
        self.open = True
        self.command_buffer = []
        super(TestConnection, self).__init__()

    def client_command(self, command):
        self.on_command(command)

    def client_disconnected(self, clean):
        self.on_disconnect(clean)

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