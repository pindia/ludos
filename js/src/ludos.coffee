defaultOptions =
  minimumLatency: 150
  stepTime: 50
  players: 2
  protocol: 'ws/json'
  playerData: {}

gameControl = ludos.protocol.gameControl

class Game
  constructor: (_options) ->
    this.options = $.extend({}, defaultOptions, _options)
    if not this.options.server?
      throw new Error('Missing required option "server"')
    this.players = {}
    this.timestep = 0
    this.connection = new ludos.protocol.LudosConnection(this.options.server, this.options.protocol)
    this.connection.bind 'connected', (gameId, playerId) =>
      this.gameId = gameId
      this.playerId = playerId
      this.players[playerId] = this.options.playerData
      this._checkStartGame()
    this.connection.bind 'playerConnected', (playerId, playerData) =>
      this.players[playerId] = playerData
      this._checkStartGame()

    this.connection.bind 'gameControl', (op, timestep, playerId) =>
      if op == gameControl.START_GAME
        this.gameStarted()
        this.trigger('gameStarted')

  _checkStartGame: ->
    if this.options.players == Object.keys(this.players).length
      this.connection.sendGameControl(gameControl.START_GAME, this.timestep)

  gameStarted: ->
    this.engine = new ludos.Engine(
      this.playerId, this.options.players,
      this.options.stepTime, Math.max(1, this.options.minimumLatency / this.options.stepTime)
    )
    this.engine.bind 'advanceTimestep', => this.trigger('advanceTimestep')
    this.engine.bind 'playerCommands', (playerId, actions) => this.trigger('playerActions', playerId, actions)
    this.engine.bind 'sendCommands', (playerId, timestep, actions) =>
      this.connection.sendActions(playerId, timestep, actions)
    this.connection.bind 'playerAction', (playerId, timestep, actions) =>
      this.engine.receiveCommands(playerId, timestep, actions)
    this.engine.start()

  createGame: ->
    this.connection.createGame(this.options.playerData)

  joinGame: (gameId) ->
    this.connection.joinGame(gameId, this.options.playerData)

  sendAction: (action) ->
    this.engine.sendCommand(action)

MicroEvent.mixin(Game)

window.ludos = window.ludos or {}
window.ludos.Game = Game