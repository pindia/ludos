from .common import LudosTestCase

class ConnectionTests(LudosTestCase):
    def test_connection_initial(self):
        c = self.make_connection()
        self.assertNoCommandsReceived(c)
        #self.assertCommandReceived(c, 1)
