command =
  START_CONNECTION: 0 # version, op, gameId, gameData, playerId, playerData, signature
  PLAYER_CONNECTED: 1 # playerId, playerData
  GAME_CONTROL: 2 # op, timestep, playerId
  PLAYER_ACTION: 3 # playerId, timestep, actions
  CHAT_MESSAGE: 4 # playerId, channel, message

startConnection =
  OP_CREATE_GAME: 0
  OP_JOIN_GAME: 1
  OP_JOIN_GAME_AS_PLAYER: 2
  OP_LIST_GAMES: 3

gameControl =
  START_GAME: 0
  PLAYER_QUIT: 6

PROTOCOL_VERSION = 1


class LudosConnection
  constructor: (server, protocol) ->
    this.server = server
    this.protocol = protocol

  _connect: ->
    this.ws = new WebSocket('ws://' + this.server + '/ws/json')
    this.ws.onopen = =>
      this.trigger('socketOpen')
    this.ws.onmessage = (evt) =>
      data = JSON.parse(evt.data)
      this._commandReceived(data[0], data.slice(1))
      #this.trigger('commandReceived', data[0], data.slice(1))
    this.ws.onclose = =>
      this.trigger('socketClosed')

  _sendCommand: (commandId, args) ->
    this.ws.send(JSON.stringify([commandId].concat(args)))

  _commandReceived: (commandId, args) ->
    if commandId == command.START_CONNECTION
      this.trigger('connected', args[2], args[3], args[4])
    if commandId == command.PLAYER_CONNECTED
      this.trigger('playerConnected', args[0], args[1])
    if commandId == command.PLAYER_ACTION
      this.trigger('playerAction', args[0], args[1], args[2])
    if commandId == command.GAME_CONTROL
      this.trigger('gameControl', args[0], args[1], args[2])

  sendGameControl: (op, timestep, playerId=null) ->
    this._sendCommand(command.GAME_CONTROL, [op, timestep, playerId])

  sendActions: (playerId, timestep, actions) ->
    this._sendCommand(command.PLAYER_ACTION, [playerId, timestep, actions])

  createGame: (gameData, playerData) ->
    this.bind 'socketOpen', =>
      this._sendCommand(command.START_CONNECTION,
        [PROTOCOL_VERSION, startConnection.OP_CREATE_GAME, null, gameData, null, playerData, null])
    this._connect()

  joinGame: (gameId, playerData) ->
    this.bind 'socketOpen', =>
      this._sendCommand(command.START_CONNECTION,
        [PROTOCOL_VERSION, startConnection.OP_JOIN_GAME, gameId, null, null, playerData, null])
    this._connect()

  close: ->
    this.ws.onclose = null
    this.ws.close()


MicroEvent.mixin(LudosConnection)

window.ludos = window.ludos or {}
window.ludos.protocol =
  LudosConnection: LudosConnection
  gameControl: gameControl