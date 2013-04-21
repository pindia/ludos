defaultOptions =
  minimumLatency: 150
  stepTime: 50
  players: 2
  protocol: 'ws/json'
  playerData: {}

class Game
  constructor: (_options) ->
    this.options = $.extend({}, defaultOptions, _options)
    if not this.options.server?
      throw new Error('Missing required option "server"')
    this.connection = new ludos.protocol.LudosConnection(this.options.server, this.options.protocol)

  createGame: ->
    this.connection.createGame(this.options.playerData)

window.ludos = window.ludos or {}
window.ludos.Game = Game