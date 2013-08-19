class GamesCollection extends Backbone.Collection
  url: "/api/v1.alpha/games/"
  model : Game

  initialize: ()->
    @search = _.debounce(@search, 200);

  search: (query, cb)=>
    console.log "#{@url}?query=#{query}"
    
    $.ajax
      url: "#{@url}?query=#{query}"
      type: 'GET'
      
      success:(games)->
        cb _.map games, (game)->
          item = new Game game
          
          item.toString = ()->
            JSON.stringify item.toJSON()
          
          item.toLowerCase = ()->
            item.title.toLowerCase()
          
          item.indexOf = (string) ->
            String::indexOf.apply item.title, arguments
          
          item.replace = (string) ->
            String::replace.apply item.title, arguments
          
          return item