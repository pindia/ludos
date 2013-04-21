class Timer
  constructor: (interval) ->
    this.ticksAllowed = 0
    this.ready = false
    this.interval = interval
    this.events = $({})

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
    this.events.trigger('tick')
    this._setTimeout()