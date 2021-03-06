globalOptions = {}

gameItem = $$
  model:
    id: ''
  view:
    format: '''<tr><td data-bind="id" /><td><span data-bind="players"/> / <span data-bind="target_players"/></td><td><a href="#">Join</a></tr>'''
  controller:
    'click a': (evt) ->
      evt.preventDefault()
      this.trigger('joinGame', [this.model.get('id')])

mainDialog = $$
  view:
    format: '''
      <div class="ui-dialog">
        <div class="ui-dialog-titlebar">Find Game</div>
        <div class="ui-dialog-content">

          <table class="table table-bordered table-condensed game-list">
            <thead>
              <tr><th>Game ID</th><th>Players</th><th>Join</th></tr>
            </thead>
            <tbody>

            </tbody>
          </table>

          <form class="form-horizontal">
            Players:
            <select id="player-count" class="input-mini">
              <option value="1">1</option>
              <option value="2">2</option>
              <option value="3">3</option>
              <option value="4">4</option>
              <option value="5">5</option>
            </select>
            <button type="button" id="create-game" class="btn btn-primary">Create game</button>
          </form>
          <!--<form class="form-horizontal">
            <input type="text" placeholder="Game ID" id="game-id">
            <button type="button" id="join-game" class="btn btn-primary">Join game</button>
          </form>-->
          <div class="server-stats">
            <strong data-bind="games" /> games ongoing,
            <strong data-bind="players" /> players connected
          </div>
        </div>
      </div>
    '''
  controller:
    show: ->
      this.connection = new ludos.protocol.LudosConnection(globalOptions.server, globalOptions.protocol)
      this.connection.listGames()
      this.connection.bind 'gameList', (serverData, gameList) =>
        this.model.set serverData
        this.empty()
        for game in gameList
          this.append $$(gameItem, game), '.game-list tbody'
        if not gameList.length
          console.log 'aaa'
          this.append $$({view: format: '<tr class="game-list-empty"><td colspan="3">No open games</td></tr>'}), '.game-list tbody'
      this.connection.bind 'disconnected', =>
        setTimeout 5000, =>
          this.connection.listGames()
    destroy: ->
      this.connection.close()
    'child:joinGame': (evt, id) ->
      this.trigger('joinGame', [id])
      this.destroy()
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
            <button type="button" class="btn btn-danger" id="quit-button">Quit</button>
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
        width: "#{100*this.model.get('players')/this.model.get('targetPlayers')}%"

gameOverDialog = $$
  view:
    format: '''
      <div class="ui-dialog">
        <div class="ui-dialog-titlebar" data-bind="title"></div>
        <div class="ui-dialog-content">
          <div class="center">
            <button type="button" class="btn btn-danger" id="quit-button">Quit</button>
          </div>
        </div>
      </div>
    '''
  controller:
    'click #quit-button': ->
      this.destroy()
      this.trigger('quit')

playerItem = $$
  view:
    format: '''
      <tr>
        <td class="name" data-bind="name">
        <td class="latency"></td>
      </tr>
    '''
  controller:
    'show, change:latency': ->
      ms = this.model.get('latency')
      if ms?
        this.view.$('.latency').text("#{ms} ms")
      else
        this.view.$('.latency').text('-')
      this.view.$('.latency').toggleClass('low', ms < 100).toggleClass('medium', ms >= 100 and ms < 200).toggleClass('high', ms >= 200)

playersPanel = $$
  view:
    format: '''
      <div id="ludos-player-panel">
        <table class="table">
          <thead>
            <tr><th>Name</th><th>Latency</th></tr>
          </thead>
          <tbody>

          </tbody>
        </table>
      </div>
    '''
  controller:
    create: ->
      this.playerIndex = {}
  addPlayer: (id, data) ->
    data.name = data.name or id.toString()
    e = $$(playerItem, data)
    this.append e, 'tbody'
    this.playerIndex[id] = e
  updatePlayer: (id, data) ->
    this.playerIndex[id].model.set data

class GameKitController
  constructor: (options) ->
    this.options = options
    globalOptions = options
    this.initializeGame()

  initializeGame: ->
    this.game = new ludos.Game(this.options)
    this.playersPanel = $$ playersPanel
    $$.document.append this.playersPanel
    $$.document.append $$ mainDialog,
      controller:
        'createGame': (evt, options) =>
          $.extend(this.game.options, options)
          this.game.createGame()
        'joinGame': (evt, gameId) =>
          this.game.joinGame(gameId)
    this.game.bind 'connected', =>
      this.showWaitingDialog()
    this.game.bind 'playerJoined', (playerId, playerData) =>
      this.playersPanel.addPlayer(playerId, playerData)
    this.game.bind 'playerUpdated', (playerId, data) =>
      this.playersPanel.updatePlayer(playerId, data)
    this.game.bind 'gameStarted', =>
      this.trigger('gameStarted', this.game)
    this.game.bind 'disconnected', =>
      this.playersPanel.destroy()
      $$.document.append $$ gameOverDialog,
        model:
          title: 'Disconnected from server'
        controller:
          quit: => this.initializeGame()

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
    this.game.bind 'playersChanged', =>
      dialog.m.players = this.game.numPlayers()
    this.game.bind 'gameStarted', ->
      dialog.destroy()
    this.game.bind 'disconnected', ->
      dialog.destroy()
    $$.document.append dialog




MicroEvent.mixin(GameKitController)


window.ludos.GameKitController = GameKitController