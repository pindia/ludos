keyboardEvent =
  DOWN: 0
  UP: 1


class KeyboardEventHelper
  constructor: (game, element, keys=[]) ->
    this.keysDown = {}
    element.keydown (evt) =>
      if evt.which in keys
        if evt.which not of this.keysDown # Prevent repeat when held down
          game.sendAction([keyboardEvent.DOWN, evt.which])
          this.keysDown[evt.which] = null
    element.keyup (evt) =>
      if evt.which in keys
        game.sendAction([keyboardEvent.UP, evt.which])
        delete this.keysDown[evt.which]
    game.bind 'playerActions', (playerId, actions) =>
      for action in actions
        if action[0] == keyboardEvent.DOWN
          this.trigger('keydown', playerId, action[1])
        if action[0] == keyboardEvent.UP
          this.trigger('keyup', playerId, action[1])


MicroEvent.mixin(KeyboardEventHelper)

do ($=jQuery) ->
  $.fn.ludosEventSync = (options) ->
    helper = new KeyboardEventHelper(options.game, this, options.keys)
    if options.keyDown
      helper.bind('keydown', options.keydown)
    if options.keyUp
      helper.bind('keyup', options.keyup)