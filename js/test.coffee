canvas = null

$ ->
  canvas = $('canvas')[0]

requestAnimationFrame = window.requestAnimationFrame or window.mozRequestAnimationFrame or window.webkitRequestAnimationFrame
COLORS = ['red', 'blue', 'green', 'black', 'orange', 'purple', 'gray']
playerTemplate =
  x: 0
  y: 0
  dx: 0
  dy: 0
  dead: false


class TestGame
  constructor: (numPlayers) ->
    this.numPlayers = numPlayers
    this.maxX = 0
    this.win = 0
    this.reset()
    this.mainLoop()

  reset: ->
    this.players = []
    x = 50
    for i in [1..this.numPlayers]
      player = $.extend({}, playerTemplate)
      player.x = x
      player.color = COLORS[i]
      x += 100
      this.players.push player
    this.maxX = x + 50

  update: ->
    if this.win >= 1
      this.win -= 1
      if this.win == 0
        this.reset()
      return
    for player in this.players
      player.x += player.dx
      if player.x < 0 then player.x = 0
      if player.y > 650 then player.y = 500
      player.y += player.dy
      if player.y > 0
        player.dy -= 1
      else
        player.y = player.dy = 0
      for other_player in this.players
        if Math.abs(player.x - other_player.x) < 20 and player.y < other_player.y + 20 and player.y - player.dy > other_player.y - other_player.dy + 20 and not player.dead and not other_player.dead
          player.dy = 10
          other_player.dead = true
          live = 0
          for test_player in this.players
            if not test_player.dead then live += 1
          if live <= 1
            this.win = 10


  mainLoop: ->
    ctx = canvas.getContext('2d')
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    for player in this.players
      if player.dead then continue
      ctx.fillStyle = player.color
      ctx.fillRect(player.x, canvas.height - player.y - 20, 20, 20)
    requestAnimationFrame(=> this.mainLoop.apply(this))

$ ->

  c = new ludos.GameKitController
    server: window.location.hostname + ':8000'
    stepTime: 25
    networkStepTime: 50

  c.bind 'gameStarted', (engine) ->
    console.log 'game started'
    console.log engine.options
    game = new TestGame(engine.options.players)

    engine.bind 'advanceTimestep', ->
      game.update()

    keyboard = new ludos.KeyboardEventHelper(engine, $(document), [37, 38, 39])
    keyboard.bind 'keyDown', (playerId, which) ->
      player = game.players[playerId]
      if which == 39
        player.dx = 3
      if which == 37
        player.dx = -3
      if which == 38 and player.y == 0
        player.dy = 10
    keyboard.bind 'keyUp', (playerId, which) ->
      player = game.players[playerId]
      if which == 39 and player.dx > 0
        player.dx = 0
      if which == 37 and player.dx < 0
        player.dx = 0


#game = new ludos.Game
#  server: window.location.hostname + ':8000'
#  players: NW_PLAYERS
#game.joinGame('test')
#game.bind 'gameStarted', ->
#  console.log 'game started'
#  updateTimer = new ludos.Timer(25)
#  updateTimer.start()
#  updateTimer.bind 'tick', ->
#    update()
#  game.bind 'advanceTimestep', ->
#    updateTimer.allowTicks(2)
#
#keyboard = new ludos.KeyboardEventHelper(game, $(document), [37, 38, 39])
#keyboard.bind 'keyDown', (playerId, which) ->
#  console.log playerId, which
#  player = players[playerId]
#  if which == 39
#    player.dx = 3
#  if which == 37
#    player.dx = -3
#  if which == 38 and player.y == 0
#    player.dy = 10
#keyboard.bind 'keyUp', (playerId, which) ->
#  player = players[playerId]
#  if which == 39 and player.dx > 0
#    player.dx = 0
#  if which == 37 and player.dx < 0
#    player.dx = 0


#$ ->
#  mainLoop()


