class Timer
  constructor: (interval) ->
    this.ticks = 0
    this.maxTicks = 0
    this.ready = false
    this.interval = interval

  start: ->
    this._setTimeout()

  stop: ->
    this.ready = false
    clearTimeout this.timeout

  allowTicks: (ticks) ->
    this.maxTicks += ticks
    if this.ready
      this._tick()
      this.ready = false

  setMaxTicks: (maxTicks) ->
    this.maxTicks = maxTicks

  _setTimeout: ->
    this.timeout = setTimeout (=> this._tryTick()), this.interval

  _tryTick: ->
    if this.ticks < this.maxTicks
      this._tick()
    else
      this.ready = true

  _tick: ->
    this.ticks += 1
    this.trigger('tick')
    this._setTimeout()
MicroEvent.mixin(Timer)

class Engine
  constructor: (playerId, players, stepTime, scheduleDelay) ->
    this.players = players
    this.playerId = playerId
    this.scheduleDelay = Math.max(1, scheduleDelay)
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
    this.checkMaxTimestep()

  start: ->
    this.timer.start()

  stop: ->
    this.timer.stop()

  receiveCommands: (player, timestep, commands) ->
    if timestep not of this.timestepIndex then this.timestepIndex[timestep] = {}
    this.timestepIndex[timestep][player] = commands
    this.checkMaxTimestep()

  checkMaxTimestep: ->
    if this.timestep not of this.timestepIndex then return
    for player in [0...this.players]
      if player not of this.timestepIndex[this.timestep]
        return
    this.timer.setMaxTicks(this.timestep + 1)

  sendCommand: (command) ->
    this.myCommands.push command

  _step: ->
    for player in [0...this.players]
      this.trigger('playerCommands', player, this.timestepIndex[this.timestep][player])
    this.trigger('advanceTimestep', this.timestep)
    delete this.timestepIndex[this.timestep]
    this._sendCommands()
    this.timestep += 1
    this.checkMaxTimestep()

  _sendCommands: ->
    this.trigger('sendCommands', this.playerId, this.timestep + this.scheduleDelay, this.myCommands)
    this.receiveCommands(this.playerId, this.timestep + this.scheduleDelay, this.myCommands)
    this.myCommands = []
MicroEvent.mixin(Engine)

window.ludos = window.ludos or {}
window.ludos.Engine = Engine
window.ludos.Timer = Timer