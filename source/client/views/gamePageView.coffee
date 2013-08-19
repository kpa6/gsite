class GamePageView extends Backbone.View
  id: "GamePage"
  templateStr:'<div class="game-page-body">
        <div class="games-list popular">
          <div class="top">{{=locale["Popular games"] || "Popular games"}}</div>
          <div class="panel-content">
            {{~it.popular :game}}
            <div class="game">
              <a href="/games/{{=game.slug}}">
                <img class="thumb" src="{{=game.image_url}}">
                <div class="name">{{=game.title}}</div>
              </a>
            </div>
            {{~}}
           </div>
        </div>
        <div class="game-window">
          <div class="top">
            <a href="/" class="typicn previous"></a>
            <span class="game-name">{{=it.title}}</span>
            <a href="#" class="typicn thumbsUp"></a>
            <a href="#" class="typicn thumbsDown"></a>
            <a href="#" class="typicn heart"></a>
          </div>
          <div class="panel-content">
            <div id="swf-game-wrapper">
              <p>
                <a href="http://www.adobe.com/go/getflashplayer">
                  <img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Get Adobe Flash player" />
                </a>
              </p>
            </div>
          </div>
        </div>
        <div class="games-list similar">
          <div class="top">{{=locale["Similar games"] || "Similar games"}}</div>
          <div class="panel-content">
            {{~it.similar :game}}
            <div class="game">
              <a href="/games/{{=game.slug}}">
                <img class="thumb" src="{{=game.image_url}}">
                <div class="name">{{=game.title}}</div>
              </a>
            </div>
            {{~}}
          </div>
        </div>
        <div class="ad">
          <div class="top">{{=locale["Advertisement"] || "Advertisement"}}</div>
          <div class="panel-content"></div>
        </div>
      </div>
      <div class="fb-comments" data-href="http://{{=window.location.hostname}}/games/{{=it.slug}}" data-num-posts="10"></div>'
  template: doT.template(@::templateStr, undefined, {})
  swfObject: null
  events:
    'click .heart': 'like'
    'click .thumbsUp': 'thumbsUp'
    'click .thumbsDown': 'thumbsDown'

  initialize: ()->
    slug =  location.pathname.split "/"
    slug = slug[slug.length-1]
    if slug isnt ""
      @model = new Game {slug:slug}
      swfobject.registerObject "swf-game-wrapper", "9.0.0"


  render: ()->
    context = @model.toJSON()
    @$el.html @template context
    return @$el

  setupSwfObject: ()->
    swfobject.embedSWF @model.get("swf_url"), "swf-game-wrapper", "100%", "100%", "9.0.0"#, null, null, {bgcolor:"#11729f"}
  deleteSwfObject: ()->
    swfobject.removeSWF "swf-game-wrapper"

  like: ()->
    console.log '@model.like()'
    #@model.like()

  thumbsUp: ()->
    @model.thumbsUp(true)

  thumbsDown: ()->
    @model.thumbsDown(true)

