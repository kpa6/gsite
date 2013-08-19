class GamesView extends Backbone.View
  el: "div#games"

  initialize: () ->
    @listenTo @collection, 'add', @appendGame
    @infiniScroll = new Backbone.InfiniScroll @collection,
      strict: true
      includePage: true
      scrollOffset: 600

  render: ()->
    @collection.forEach (game) ->
      @appendGame(game)
    
    return @$el

  appendGame: (game, games, options) ->
    gameview = new GameView { model: game }
    @$el.append gameview.render()
    
    return @$el

  remove: () ->
    @infiniScroll.destroy()
    
    return Backbone.View.prototype.remove.call @



