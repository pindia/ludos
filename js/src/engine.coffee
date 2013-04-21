class Timer
  constructor: (interval) ->
    this.ticksAllowed = 0
    this.ready = false
    this.interval = interval

  start: ->
    this._setTimeout()

  allowTicks: (ticks) ->
    this.ticksAllowed += ticks
    if this.ready
      this._tick()
      this.ready = false

  _setTimeout: ->
    setTimeout (=> this._tryTick()), this.interval

  _tryTick: ->
    if this.ticksAllowed > 0
      this._tick()
    else
      this.ready = true

  _tick: ->
    this.ticksAllowed -= 1
    this.trigger('tick')
    this._setTimeout()
MicroEvent.mixin(Timer)

class Engine
  constructor: (playerId, players, stepTime, scheduleDelay) ->
    this.players = players
    this.playerId = playerId
    this.scheduleDelay = scheduleDelay
    this.timestep = 0
    this.maxTimestep = 0
    this.timestepIndex = {}
    this.myCommands = []
    this.timer = new Timer(stepTime)
    this.timer.bind 'tick', =>
      this._step()
    for timestep in [0...this.scheduleDelay]
      for player in [0...this.players]
        this.receiveCommands(player, timestep, [])

  start: ->
    this.timer.start()

  receiveCommands: (player, timestep, commands) ->
    if timestep not of this.timestepIndex then this.timestepIndex[timestep] = {}
    this.timestepIndex[timestep][player] = commands
    this.checkMaxTimestep()

  checkMaxTimestep: ->
    if this.timestep not of this.timestepIndex then return
    for player in [0...this.players]
      if player not of this.timestepIndex[this.timestep]
        return
    this.timer.allowTicks(1)

  sendCommand: (command) ->
    this.myCommands.push command

  _step: ->
    for player in [0...this.players]
      this.trigger('playerCommands', player, this.timestepIndex[this.timestep][player])
    this.trigger('advanceTimestep', this.timestep)
    delete this.timestepIndex[this.timestep]
    this._sendCommands()
    this.timestep += 1
    console.log this.timestep
    this.checkMaxTimestep()

  _sendCommands: ->
    this.trigger('sendCommands', this.playerId, this.timestep + this.scheduleDelay, this.myCommands)
    this.receiveCommands(this.playerId, this.timestep + this.scheduleDelay, this.myCommands)
    this.myCommands = []
MicroEvent.mixin(Engine)

window.ludos = window.ludos or {}
window.ludos.Engine = Engine