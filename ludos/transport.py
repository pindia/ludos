class Transport(object):
    ''' A transport object facilitates communication between a client and server, exposing methods and callbacks
    to abstract the network protocol to higher-level objects into sending and receiving "commands". '''

    def __init__(self):
        self._command_callback = lambda command: None
        self._disconnect_callback = lambda clean: None

    def set_command_callback(self, command_callback):
        ''' Sets the transport's command callback. The given function will be called with a command object as its
        first and only argument when a command is received from the client. '''
        self._command_callback = command_callback

    def set_disconnect_callback(self, command_callback):
        ''' Sets the transport's disconnect callback. When the transport connection is broken, the given function will
        be called with a boolean argument representing whether the connection closure was clean (i.e. initiated by either
         the client or server) as opposed to unclean (i.e. caused by network issues). '''
        self._disconnect_callback = command_callback

    def _on_command(self, command):
        self._command_callback(command)

    def _on_disconnect(self, clean):
        self._disconnect_callback(clean)

    def send_command(self, command):
        ''' Sends the given command object to the client. '''
        raise NotImplementedError

    def disconnect(self):
        ''' Disconnects the client. Will result in on_disconnect being called with the clean argument True. '''
        raise NotImplementedError

