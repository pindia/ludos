''' Implementation of the TutorMe protocol using Tornado WebSockets '''

from functools import partial
import json
import logging

import tornado, re
from tornado import websocket
from tornado.httpserver import HTTPServer
import tornado.web
from ludos.connection import LudosConnection
from ludos.transport import Transport
from ludos.protocol import commands

def command_to_json(command):
    return json.dumps([command.id] + list(command))

def command_from_json(data):
    l = json.loads(data)
    print l
    cls = commands[l[0]]
    return cls(*l[1:])

class WebSocketTransport(Transport):
    def __init__(self, handler):
        super(WebSocketTransport, self).__init__()
        self.handler = handler

    def send_command(self, command):
        logging.debug('%s -> %d' % (command, self.handler.id))
        self.handler.write_message(command_to_json(command))

    def disconnect(self):
        self.handler.close()

CONNECTION_ID = 1

class LudosWebSocketHandler(websocket.WebSocketHandler):
    def open(self):
        global CONNECTION_ID
        self.id = CONNECTION_ID
        CONNECTION_ID += 1
        logging.info('Connection made. Assigned connection ID %d.' % self.id)
        self.transport = WebSocketTransport(self)
        self.session = LudosConnection(self.transport)

    def on_message(self, message):
        command = command_from_json(message)
        logging.debug('%d -> %s' % (self.id, command))
        self.transport._on_command(command)

    def on_close(self):
        logging.info('Connection %d closed.' % self.id)
        self.transport._on_disconnect(True)

application = tornado.web.Application([
    (r"/ws/json", LudosWebSocketHandler),
])

server = HTTPServer(application)