class GameView extends Backbone.View
  tagName: "div"
  className : "game"

  templateStr:'<a href="/games/{{=it.slug}}">
      <img class="thumb" src="{{=it.image_url}}">
      <div class="name">{{=it.title}}</div>
    </a>'
  template: doT.template @::templateStr, undefined, {}

  render: ()=>
    @$el.append @template @model.toJSON()
    return @$el


