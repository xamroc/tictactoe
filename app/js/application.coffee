"use strict"

@ticTacToe = angular.module 'TicTacToe', ["firebase"]

ticTacToe.constant 'WIN_PATTERNS',
  [
    [0,1,2]
    [3,4,5]
    [6,7,8]
    [0,3,6]
    [1,4,7]
    [2,5,8]
    [0,4,8]
    [2,4,6]
  ]

class BoardCtrl
  uniqueId: (length = 8) ->
    id = ""
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

  constructor: ($scope, @WIN_PATTERNS, $firebase) ->
    @scope = $scope
    @firebase = $firebase
    @scope.startGame = @startGame
    @scope.makeMove = @makeMove
    @scope.gameOn = false
    @scope.myMove = false
    @resetBoard()
    @pendingGameRef = new Firebase "https://tictactoe-lau.firebaseio.com/tictactoe/pendingGame"

  setUpGame: (pendingGame) =>
    if pendingGame
      @gameId = pendingGame
      @player = 1
      @scope.myMove = true
      null
    else
      @gameId = @uniqueId()
      @player = 0
      @gameId

  numberOfMoves: =>
    Object.keys(@scope.cells).filter( (k) -> k.length == 1 ).length

  runGame: (error, committed, snapshot) =>
    @boardRef = new Firebase "https://tictactoe-lau.firebaseio.com/tictactoe/games/#{@gameId}/board"
    @board = @firebase @boardRef
    @board.$bind( @scope, 'cells' ).then (unbind) =>
      @unbindCells = unbind
      @scope.gameOn = true
    @board.$on "change", =>
      @scope.myMove = (@numberOfMoves() + 1) % 2 == @player
      @parseBoard()

  resetBoard: =>
    @scope.theWinnerIs = false
    @gameId = null
    @unbindCells() if @unbindCells
    @scope.cells = {}
    @scope.winningCells = {}

  startGame: =>
    @resetBoard()
    @pendingGameRef.transaction @setUpGame, @runGame, true

  getPatterns: =>
    @patternsToTest = @WIN_PATTERNS.filter -> true

  getRow: (pattern) =>
    c = @scope.cells
    c0 = c[pattern[0]] || pattern[0]
    c1 = c[pattern[1]] || pattern[1]
    c2 = c[pattern[2]] || pattern[2]
    "#{c0}#{c1}#{c2}"

  someoneWon: (row) -> 'xxx' == row || 'ooo' == row

  isMixedRow: (row) -> row.match( /o+\d?x+|x+\d?o+/i   )?
  hasOneX:    (row) -> row.match( /x\d\d|\dx\d|\d\dx/i )?
  hasTwoXs:   (row) -> row.match( /xx\d|x\dx|\dxx/i    )?
  hasOneO:    (row) -> row.match( /o\d\d|\do\d|\d\do/i )?
  hasTwoOs:   (row) -> row.match( /oo\d|o\do|\doo/i    )?
  isEmptyRow: (row) -> row.match( /\d\d\d/i            )?

  movesRemaining: (player) =>
    totalMoves = 9 - @numberOfMoves()

    if player == 1
      Math.ceil(totalMoves / 2)
    else if player == 0
      Math.floor(totalMoves / 2)
    else
      totalMoves

  rowStillWinnable: (row) =>
    not (@isMixedRow(row) or
    (@hasOneX(row) and @movesRemaining(1) < 2) or
    (@hasTwoXs(row) and @movesRemaining(1) < 1) or
    (@hasOneO(row) and @movesRemaining(0) < 2) or
    (@hasTwoOs(row) and @movesRemaining(0) < 1) or
    (@isEmptyRow(row) and @movesRemaining() < 5))

  gameUnwinnable: =>
    @patternsToTest.length < 1

  announceWinner: (winningPattern) =>
    winner = @scope.cells[winningPattern[0]]
    for k, v of @scope.cells
      @scope.winningCells[k] = if k.length == 1 && parseInt(k) in winningPattern then 'win' else 'unwin'
    @scope.theWinnerIs = winner
    @scope.gameOn = false

  announceTie: =>
    @scope.cats = true
    @scope.gameOn = false

  parseBoard: =>
    winningPattern = false

    @patternsToTest = @WIN_PATTERNS.filter (pattern) =>
      row = @getRow(pattern)
      winningPattern ||= pattern if @someoneWon(row)
      @rowStillWinnable(row)

    if winningPattern
      @announceWinner(winningPattern)
    else if @gameUnwinnable()
      @announceTie()

  makeMove: (@$event) =>
    cell = @$event.target.dataset.index
    if @scope.gameOn && !@scope.cells[cell] && @scope.myMove
      @scope.cells[cell] = if @player == 1 then 'x' else 'o'
      @scope.myMove = false


BoardCtrl.$inject = ["$scope", "WIN_PATTERNS", "$firebase"]
ticTacToe.controller "BoardCtrl", BoardCtrl