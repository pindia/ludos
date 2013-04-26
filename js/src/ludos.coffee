defaultOptions =
  minimumLatency: 150
  stepTime: 50
  players: 0
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
    this.connection.bind 'connected', (gameId, gameData, playerId) =>
      this.gameId = gameId
      $.extend(this.options, gameData)
      this.playerId = playerId
      this.players[playerId] = this.options.playerData
      this.trigger('connected')
      this._checkStartGame()
    this.connection.bind 'playerConnected', (playerId, playerData) =>
      this.players[playerId] = playerData
      this.trigger('playersChanged')
      this._checkStartGame()

    this.connection.bind 'gameControl', (op, timestep, playerId) =>
      if op == gameControl.START_GAME
        this.gameStarted()
        this.trigger('gameStarted')
      if op == gameControl.PLAYER_QUIT
        delete this.players[playerId]
        this.trigger('playersChanged')

    this.connection.bind 'disconnected', =>
      this.trigger 'disconnected'

  _checkStartGame: ->
    if this.options.players == this.numPlayers()
      this.connection.sendGameControl(gameControl.START_GAME, this.timestep)

  gameStarted: ->
    this.engine = new ludos.Engine(
      this.playerId, this.players,
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
    this.connection.createGame(this.options, this.options.playerData)

  joinGame: (gameId) ->
    this.connection.joinGame(gameId, this.options.playerData)

  sendAction: (action) ->
    this.engine.sendCommand(action)

  quit: ->
    this.connection.close()
    if this.engine?
      this.engine.stop()
    this.trigger('quit')

  numPlayers: ->
    return Object.keys(this.players).length


MicroEvent.mixin(Game)

window.ludos = window.ludos or {}
window.ludos.Game = Game