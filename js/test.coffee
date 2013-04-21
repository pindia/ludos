$ ->
  game = new ludos.Game
    server: 'localhost:8000'
  game.joinGame('test')