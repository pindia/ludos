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
      this.trigger('createGame', [{players: parseInt(this.view.$('#player-count').val())}])
      this.destroy()
    'click #join-game': ->
      this.trigger('joinGame', [this.view.$('#game-id').val()])
      this.destroy()

waitingDialog = $$
  model:
    gameId: ''
    players: 0
    targetPlayers: 0
  view:
    format: '''
      <div class="ui-dialog">
        <div class="ui-dialog-titlebar">Waiting for players</div>
        <div class="ui-dialog-content">
          <div class="progress progress-striped active">
            <div class="bar"></div>
          </div>
          <p>
            <span data-bind="players" /> / <span data-bind="targetPlayers" /> players joined.
          </p>
          <p>
            Game ID: <strong data-bind="gameId"/>
          </p>
          <div class="center">
            <button class="btn btn-danger" id="quit-button">Quit</button>
          </div>
        </div>
      </div>
    '''
  controller:
    'click #quit-button': ->
      this.destroy()
      this.trigger('quit')
    'show, change:players': ->
      this.view.$('.bar').css
        width: "#{100*this.m.players/this.m.targetPlayers}%"

class GameKitController
  constructor: (options) ->
    this.options = options
    this.initializeGame()

  initializeGame: ->
    this.game = new ludos.Game(this.options)
    $$.document.append $$ mainDialog,
      controller:
        'createGame': (evt, options) =>
          $.extend(this.game.options, options)
          this.game.createGame()
        'joinGame': (evt, gameId) =>
          this.game.joinGame(gameId)
    this.game.bind 'connected', =>
      this.showWaitingDialog()
    this.game.bind 'gameStarted', =>
      this.trigger('gameStarted', this.game)

  showWaitingDialog: ->
    dialog = $$ waitingDialog,
      model:
        players: this.game.numPlayers()
        targetPlayers: this.game.options.players
        gameId: this.game.gameId
      controller:
        'quit': =>
          this.game.quit()
          this.initializeGame()
    this.game.bind 'gameStarted', ->
      dialog.destroy()
    $$.document.append dialog

MicroEvent.mixin(GameKitController)


window.ludos.GameKitController = GameKitController