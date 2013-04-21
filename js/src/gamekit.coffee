mainDialog = $$
  view:
    format: '''
      <div class="ui-dialog">
        <div class="ui-dialog-titlebar">Find Game</div>
        <div class="ui-dialog-content">

          <form class="form-horizontal">
            Players:
            <select id="player-count" class="input-mini">
              <option value="1">1</option>
              <option value="2">2</option>
              <option value="3">3</option>
              <option value="4">4</option>
              <option value="5">5</option>
            </select>
            <button id="create-game" class="btn btn-primary">Create game</button>
          </form>
          <form class="form-horizontal">
            <input type="text" placeholder="Game ID" id="game-id">
            <button id="join-game" class="btn btn-primary">Join game</button>
          </form>
        </div>
      </div>
    '''
  controller:
    'click #create-game': ->
      this.trigger('createGame')
      this.destroy()
    'click #join-game': ->
      this.trigger('joinGame', [this.view.$('#game-id').val()])
      this.destroy()


class GameKitController
  constructor: (options) ->
    this.options = options
    this.initializeGame()

  initializeGame: ->
    this.game = new ludos.Game(this.options)
    $$.document.append $$ mainDialog,
      controller:
        'createGame': =>
          this.game.createGame()
        'joinGame': (evt, gameId) =>
          this.game.joinGame(gameId)
    this.game.bind 'gameStarted', =>
      this.trigger('gameStarted', this.game)

MicroEvent.mixin(GameKitController)


window.ludos.GameKitController = GameKitController