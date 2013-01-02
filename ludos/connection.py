class LudosConnection(object):
    def __init__(self, transport):
        self.transport = transport
        self.transport.set_command_callback(self.on_command)
        self.transport.set_disconnect_callback(self.on_disconnect)

    def on_command(self, command):
        pass

    def on_close(self):
        pass

    def on_disconnect(self):
        pass