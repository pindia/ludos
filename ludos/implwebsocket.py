''' Implementation of the TutorMe protocol using Tornado WebSockets '''
from datetime import timedelta

from functools import partial
import json
import logging

import tornado, re
from tornado import websocket
from tornado.ioloop import IOLoop
from tornado.httpserver import HTTPServer
import tornado.web
from ludos.connection import LudosConnection
from ludos.protocol import commands

def command_to_json(command):
    return json.dumps([command.id] + list(command))

def command_from_json(data):
    l = json.loads(data)
    cls = commands[l[0]]
    return cls(*l[1:])

CONNECTION_ID = 1

class LudosWebSocketHandler(websocket.WebSocketHandler):
    def open(self):
        global CONNECTION_ID
        self.id = CONNECTION_ID
        CONNECTION_ID += 1
        logging.info('Connection made. Assigned connection ID %d.' % self.id)
        self.connection = LudosConnection()
        self.connection.bind('sendCommand', self.send_command)
        self.connection.bind('disconnect', self.disconnect)
        self.periodic()

    def periodic(self):
        self.connection.periodic()
        self.timeout = IOLoop.instance().add_timeout(timedelta(seconds=2), self.periodic)

    def send_command(self, command):
        logging.debug('%s -> %d' % (command, self.id))
        try:
            self.write_message(command_to_json(command))
        except AttributeError:
            pass

    def disconnect(self):
        self.close()

    def on_message(self, message):
        command = command_from_json(message)
        logging.debug('%d -> %s' % (self.id, command))
        self.connection.on_command(command)

    def on_close(self):
        logging.info('Connection %d closed.' % self.id)
        IOLoop.instance().remove_timeout(self.timeout)
        self.connection.on_disconnect(True)

application = tornado.web.Application([
    (r"/ws/json", LudosWebSocketHandler),
])

server = HTTPServer(application)