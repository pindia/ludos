import os, sys, logging

import tornado.ioloop

from ludos.implwebsocket import server
from ludos.logconfig import setup_logging

setup_logging()

PORT = int(sys.argv[1] if len(sys.argv) > 1 else 8000)

server.listen(PORT)
logging.info('Starting game server on port %d' % PORT)

try:
    tornado.ioloop.IOLoop.instance().start()
except KeyboardInterrupt:
    os._exit(0)