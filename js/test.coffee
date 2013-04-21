requestAnimationFrame = window.requestAnimationFrame or window.mozRequestAnimationFrame or window.webkitRequestAnimationFrame

canvas = $('canvas')[0]

players = []
maxX = 0

COLORS = ['red', 'blue', 'green', 'black', 'orange', 'purple', 'gray']
PLAYERS = 5
NW_PLAYERS = 2

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


game = new ludos.Game
  server: 'localhost:8000'
  players: NW_PLAYERS
  stepTime: 50
  minimumLatency: 150
game.joinGame('test')
game.bind 'gameStarted', ->
  console.log 'game started'

  updateTimer = new ludos.Timer(25)
  updateTimer.start()
  updateTimer.bind 'tick', ->
    update()
  game.bind 'advanceTimestep', ->
    updateTimer.allowTicks(2)
  game.bind 'playerActions', (playerId, commands) ->
    player = players[playerId]
    for command in commands
      if command == 'right'
        player.dx = 3
      if command == 'left'
        player.dx = -3
      if command == 'jump' and player.y == 0
        player.dy = 10
      if command == 'stopRight' and player.dx > 0
        player.dx = 0
      if command == 'stopLeft' and player.dx < 0
        player.dx = 0
  $(document).keydown (evt) ->
    if evt.which == 39
      game.sendAction('right')
    if evt.which == 37
      game.sendAction('left')
    if evt.which == 38
      game.sendAction('jump')
  $(document).keyup (evt) ->
    if evt.which == 39
      game.sendAction('stopRight')
    if evt.which == 37
      game.sendAction('stopLeft')

$ ->
  mainLoop()


