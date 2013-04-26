keyboardEvent =
  DOWN: 0
  UP: 1

eventList = []

class KeyboardEventHelper
  constructor: (game, element, keys=[]) ->
    this.keysDown = {}
    element.keydown (evt) =>
      if evt.which in keys
        if evt.which not of this.keysDown # Prevent repeat when held down
          eventList.push(new Date())
          game.sendAction([keyboardEvent.DOWN, evt.which])
          this.keysDown[evt.which] = null
    element.keyup (evt) =>
      if evt.which in keys
        game.sendAction([keyboardEvent.UP, evt.which])
        eventList.push(new Date())
        delete this.keysDown[evt.which]
    game.bind 'playerActions', (playerId, actions) =>
      for action in actions
        if action[0] == keyboardEvent.DOWN
          this.trigger('keyDown', playerId, action[1])
          console.log new Date() - eventList.shift()
        if action[0] == keyboardEvent.UP
          this.trigger('keyUp', playerId, action[1])
          console.log new Date() - eventList.shift()


MicroEvent.mixin(KeyboardEventHelper)

window.ludos.KeyboardEventHelper = KeyboardEventHelper