requestAnimationFrame = window.requestAnimationFrame or window.mozRequestAnimationFrame or window.webkitRequestAnimationFrame

canvas = $('canvas')[0]

players = []
maxX = 0

COLORS = ['red', 'blue', 'green', 'black', 'orange', 'purple', 'gray']
PLAYERS = 2
NW_PLAYERS = 1

live = 0
playerTemplate =
  x: 0
  y: 0
  dx: 0
  dy: 0
  dead: false

reset = ->
  players = []
  x = 50
  for i in [1..PLAYERS]
    player = $.extend({}, playerTemplate)
    player.x = x
    player.color = COLORS[i]
    x += 100
    players.push player
  maxX = x + 50

reset()

win = 0

update = ->
  if win >= 1
    win -= 1
    if win == 0
      reset()
    return
  for player in players
    player.x += player.dx
    if player.x < 0 then player.x = 0
    if player.y > 650 then player.y = 500
    player.y += player.dy
    if player.y > 0
      player.dy -= 1
    else
      player.y = player.dy = 0
    for other_player in players
      if Math.abs(player.x - other_player.x) < 20 and player.y < other_player.y + 20 and player.y - player.dy > other_player.y - other_player.dy + 20 and not player.dead and not other_player.dead
        player.dy = 10
        other_player.dead = true
        live = 0
        for test_player in players
          if not test_player.dead then live += 1
        if live <= 1
          win = 10


mainLoop = ->
  ctx = canvas.getContext('2d')
  ctx.clearRect(0, 0, canvas.width, canvas.height)
  for player in players
    if player.dead then continue
    ctx.fillStyle = player.color
    ctx.fillRect(player.x, canvas.height - player.y - 20, 20, 20)
  requestAnimationFrame(mainLoop)

c = new ludos.GameKitController
  server: window.location.hostname + ':8000'

c.bind 'gameStarted', (game) ->
  console.log 'game started'
  updateTimer = new ludos.Timer(25)
  updateTimer.start()
  updateTimer.bind 'tick', ->
    update()
  game.bind 'advanceTimestep', ->
    updateTimer.allowTicks(2)

  keyboard = new ludos.KeyboardEventHelper(game, $(document), [37, 38, 39])
  keyboard.bind 'keyDown', (playerId, which) ->
    player = players[playerId]
    if which == 39
      player.dx = 3
    if which == 37
      player.dx = -3
    if which == 38 and player.y == 0
      player.dy = 10
  keyboard.bind 'keyUp', (playerId, which) ->
    player = players[playerId]
    if which == 39 and player.dx > 0
      player.dx = 0
    if which == 37 and player.dx < 0
      player.dx = 0
  mainLoop()


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


