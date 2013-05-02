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
    this.setMaxTicks(this.maxTicks + ticks)

  setMaxTicks: (maxTicks) ->
    this.maxTicks = maxTicks
    if this.ready
      this.ready = false
      this._tryTick()

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

sent = []

class Engine
  constructor: (playerId, players, stepTime, networkStepTime, scheduleDelay) ->
    this.players = players
    this.playerId = playerId
    this.stepTime = stepTime
    this.networkStepTime = networkStepTime
    this.scheduleDelay = Math.max(0, scheduleDelay)
    this.timestep = 0
    this.maxTimestep = 0
    this.networkStepModulo = parseInt(networkStepTime / stepTime)
    this.timestepIndex = {}
    this.myCommands = []
    this.timer = new Timer(stepTime)
    this.timer.bind 'tick', =>
      this._step()
    for timestep in [0...(1+Math.ceil(this.scheduleDelay/this.networkStepTime))*this.networkStepModulo]
      if timestep % this.networkStepModulo == 0
        for player of this.players
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
    if this.timestep % this.networkStepModulo == 0
      if this.timestep not of this.timestepIndex then return
      for player of this.players
        if player not of this.timestepIndex[this.timestep]
          return
    this.timer.setMaxTicks(this.timestep + 1)

  sendCommand: (command) ->
    sent.push new Date()
    this.myCommands.push command

  _step: ->
    if this.timestep % this.networkStepModulo == 0
      for player of this.players
        for command in this.timestepIndex[this.timestep][player]
          console.log (new Date() - sent.shift())
        this.trigger('playerCommands', player, this.timestepIndex[this.timestep][player])
    this.trigger('advanceTimestep', this.timestep)
    delete this.timestepIndex[this.timestep]
    if this.timestep % this.networkStepModulo == 0
      timestep = this.timestep
      setTimeout (this.networkStepTime - (this.scheduleDelay % this.networkStepTime)), =>
        this._sendCommands(timestep)
    this.timestep += 1
    this.checkMaxTimestep()

  _sendCommands: (timestep) ->
    timestep = timestep + (1 + Math.floor(this.scheduleDelay/this.networkStepTime)) * this.networkStepModulo
    this.trigger('sendCommands', this.playerId, timestep, this.myCommands)
    this.receiveCommands(this.playerId, timestep, this.myCommands)
    this.myCommands = []
MicroEvent.mixin(Engine)

window.ludos = window.ludos or {}
window.ludos.Engine = Engine
window.ludos.Timer = Timer