command =
  START_CONNECTION: 0
  PLAYER_CONNECTED: 1
  GAME_CONTROL: 2
  PLAYER_ACTION: 3
  CHAT_MESSAGE: 4

startConnection =
  OP_CREATE_GAME: 0
  OP_JOIN_GAME: 1
  OP_JOIN_GAME_AS_PLAYER: 2

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


  createGame: (playerData) ->
    this.bind 'socketOpen', =>
      this._sendCommand(command.START_CONNECTION,
        [PROTOCOL_VERSION, startConnection.OP_CREATE_GAME, null, null, playerData, null])
    this._connect()

  joinGame: (gameId, playerData) ->
    this.bind 'socketOpen', =>
      this._sendCommand(command.START_CONNECTION,
        [PROTOCOL_VERSION, startConnection.OP_JOIN_GAME, gameId, null, playerData, null])
    this._connect()


MicroEvent.mixin(LudosConnection)

window.ludos = window.ludos or {}
window.ludos.protocol =
  LudosConnection: LudosConnection