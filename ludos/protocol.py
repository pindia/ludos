import inspect
from collections import namedtuple
import re


def command_class_decorator(cls):
    ''' Decorator to transform command classes into named tuples for performance. The signature of the __init__ method
    is used to determine the field names. '''
    new_cls = namedtuple(cls.__name__, inspect.getargspec(cls.__init__).args[1:])
    for attr in dir(cls):
        if re.match('^[A-Z_]+$', attr):
            setattr(new_cls, attr, getattr(cls, attr))
    return new_cls

class Command(object):
    id = None

class StartConnectionCommand(Command):
    ''' Sent by a player connecting to a game server for the first time.
    @arg version: Integer protocol version being used to connect.
    @arg game_id: String unique identifier of the game being connected to
    @arg player_id: Integer ID of the player number that is connecting
    @arg player_data: Object containing arbitrary data for the player that is connecting
    @arg signature: String signature from a master game server validating the previous arguments
    '''
    id = 0
    CREATE_GAME = 0
    JOIN_GAME = 1
    JOIN_GAME_AS_PLAYER = 2
    def __init__(self, version, op, game_id, player_id, player_data, signature):
        self.version = self.op = self.game_id = self.player_id = self.player_data = self.signature = None

class PlayerConnectedCommand(Command):
    ''' Sent by the server to inform a player of the other players in the game.
    @arg player_id: Integer ID of the player the connected
    @arg player_data: Object containing arbitrary data for the player that is connecting
    '''
    id = 1
    def __init__(self, player_id, player_data):
        self.player_id = self.player_data = None

class GameControlCommand(Command):
    ''' Sent by the server to control the flow of the game. Multiple players must agree on a game control
    action for the server to acknowledge it and forward it to the remaining players.
    @arg op: Integer ID of the game control operation to perform
    @arg timestep: The timestep when the command will become effective
    @arg player_id: Integer ID of the player being affected by the operation (if applicable)
    '''
    id = 2
    START_GAME = 0
    END_GAME = 1
    PAUSE_GAME = 2
    UNPAUSE_GAME = 3
    PLAYER_VICTORY = 4
    PLAYER_DEFEAT = 5
    PLAYER_QUIT = 6
    PLAYER_KICKED = 7
    def __init__(self, op, timestep, player_id):
        self.op = self.timestep = self.player_id = None

class PlayerActionCommand(Command):
    ''' Sent by a player and forwarded by the server, containing the player's actions for a given time step.
    @arg player_id: Integer ID of the player whose actions are being sent.
    @arg timestep: Integer timestep for which the actions are being sent.
    @arg actions: List of actions the player is taking.
    '''
    id = 3
    def __init__(self, player_id, timestep, actions):
        self.player_id = self.timestep = self.actions = None

class ChatMessageCommand(Command):
    ''' Sent by a player and forwarded by the server, containing a chat message sent by a player.
    @arg player_id: Integer ID of the player who is sending a message
    @arg channel: Integer channel ID to which the player is sending a message
    @arg message: String message that is being sent
    '''
    id = 4
    def __init__(self, player_id, channel, message):
        self.player_id = self.channels = self.message = None





commands = {}

# Because class decorators are not available in Python 2.7, apply the decorator to all subclasses of Command with
# globals() trickery. Also create an index of command classes by command ID in the "commands" dict.

for cls in Command.__subclasses__():
    decorated_class = command_class_decorator(cls)
    globals()[cls.__name__] = decorated_class
    commands[cls.id] = decorated_class
