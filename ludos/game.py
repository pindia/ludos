class Game(object):
    def __init__(self, id):
        self.id = id
        self.players = {}

class Player(object):
    def __init__(self, id, data, transport):
        self.id = id
        self.data = data
        self.transport = transport

class GameManager(object):
    def __init__(self):
        self.games = {}

    def get_game(self, game_id):
        if game_id in self.games:
            return self.games[game_id]
        else:
            game = Game(game_id)
            self.games[game_id] = game
            return game