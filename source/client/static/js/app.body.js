var Game, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Game = (function(_super) {
  __extends(Game, _super);

  function Game() {
    _ref = Game.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  Game.prototype.url = function() {
    var base;
    base = "/api/v1.alpha/games/";
    if (this.has("_id")) {
      return base + this.get("_id");
    } else if (this.has("slug")) {
      return base + this.get("slug");
    } else {
      return base;
    }
  };

  Game.prototype.idAttribute = "_id";

  Game.prototype.fetchPopularAndSimilar = function(cb) {
    var _this = this;
    return $.ajax({
      url: this.url() + "?popular=5",
      type: 'GET',
      success: function(data) {
        _this.set("popular", data);
        return $.ajax({
          url: _this.url() + "?similar=5",
          type: 'GET',
          success: function(data) {
            _this.set("similar", data);
            return cb.success();
          },
          error: function() {
            return cb.error();
          }
        });
      },
      error: function() {
        return cb.error();
      }
    });
  };

  Game.prototype.thumbsUp = function(isInc) {
    return $.ajax({
      url: this.url() + ("?thumbsUp=" + isInc),
      type: 'PUT'
    });
  };

  Game.prototype.thumbsDown = function(isDec) {
    return $.ajax({
      url: this.url() + ("?thumbsDown=" + isDec),
      type: 'PUT'
    });
  };

  return Game;

})(Backbone.Model);


/*=========================================================*/
/*=========================================================*/
var GamesCollection, _ref,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

GamesCollection = (function(_super) {
  __extends(GamesCollection, _super);

  function GamesCollection() {
    this.search = __bind(this.search, this);
    _ref = GamesCollection.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  GamesCollection.prototype.url = "/api/v1.alpha/games/";

  GamesCollection.prototype.model = Game;

  GamesCollection.prototype.initialize = function() {
    return this.search = _.debounce(this.search, 200);
  };

  GamesCollection.prototype.search = function(query, cb) {
    console.log("" + this.url + "?query=" + query);
    return $.ajax({
      url: "" + this.url + "?query=" + query,
      type: 'GET',
      success: function(games) {
        return cb(_.map(games, function(game) {
          var item;
          item = new Game(game);
          item.toString = function() {
            return JSON.stringify(item.toJSON());
          };
          item.toLowerCase = function() {
            return item.title.toLowerCase();
          };
          item.indexOf = function(string) {
            return String.prototype.indexOf.apply(item.title, arguments);
          };
          item.replace = function(string) {
            return String.prototype.replace.apply(item.title, arguments);
          };
          return item;
        }));
      }
    });
  };

  return GamesCollection;

})(Backbone.Collection);


/*=========================================================*/
/*=========================================================*/
var GamePageView, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

GamePageView = (function(_super) {
  __extends(GamePageView, _super);

  function GamePageView() {
    _ref = GamePageView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  GamePageView.prototype.id = "GamePage";

  GamePageView.prototype.templateStr = '<div class="game-page-body">\
        <div class="games-list popular">\
          <div class="top">{{=locale["Popular games"] || "Popular games"}}</div>\
          <div class="panel-content">\
            {{~it.popular :game}}\
            <div class="game">\
              <a href="/games/{{=game.slug}}">\
                <img class="thumb" src="{{=game.image_url}}">\
                <div class="name">{{=game.title}}</div>\
              </a>\
            </div>\
            {{~}}\
           </div>\
        </div>\
        <div class="game-window">\
          <div class="top">\
            <a href="/" class="typicn previous"></a>\
            <span class="game-name">{{=it.title}}</span>\
            <a href="#" class="typicn thumbsUp"></a>\
            <a href="#" class="typicn thumbsDown"></a>\
            <a href="#" class="typicn heart"></a>\
          </div>\
          <div class="panel-content">\
            <div id="swf-game-wrapper">\
              <p>\
                <a href="http://www.adobe.com/go/getflashplayer">\
                  <img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Get Adobe Flash player" />\
                </a>\
              </p>\
            </div>\
          </div>\
        </div>\
        <div class="games-list similar">\
          <div class="top">{{=locale["Similar games"] || "Similar games"}}</div>\
          <div class="panel-content">\
            {{~it.similar :game}}\
            <div class="game">\
              <a href="/games/{{=game.slug}}">\
                <img class="thumb" src="{{=game.image_url}}">\
                <div class="name">{{=game.title}}</div>\
              </a>\
            </div>\
            {{~}}\
          </div>\
        </div>\
        <div class="ad">\
          <div class="top">{{=locale["Advertisement"] || "Advertisement"}}</div>\
          <div class="panel-content"></div>\
        </div>\
      </div>\
      <div class="fb-comments" data-href="http://{{=window.location.hostname}}/games/{{=it.slug}}" data-num-posts="10"></div>';

  GamePageView.prototype.template = doT.template(GamePageView.prototype.templateStr, void 0, {});

  GamePageView.prototype.swfObject = null;

  GamePageView.prototype.events = {
    'click .heart': 'like',
    'click .thumbsUp': 'thumbsUp',
    'click .thumbsDown': 'thumbsDown'
  };

  GamePageView.prototype.initialize = function() {
    var slug;
    slug = location.pathname.split("/");
    slug = slug[slug.length - 1];
    if (slug !== "") {
      this.model = new Game({
        slug: slug
      });
      return swfobject.registerObject("swf-game-wrapper", "9.0.0");
    }
  };

  GamePageView.prototype.render = function() {
    var context;
    context = this.model.toJSON();
    this.$el.html(this.template(context));
    return this.$el;
  };

  GamePageView.prototype.setupSwfObject = function() {
    return swfobject.embedSWF(this.model.get("swf_url"), "swf-game-wrapper", "100%", "100%", "9.0.0");
  };

  GamePageView.prototype.deleteSwfObject = function() {
    return swfobject.removeSWF("swf-game-wrapper");
  };

  GamePageView.prototype.like = function() {
    return console.log('@model.like()');
  };

  GamePageView.prototype.thumbsUp = function() {
    return this.model.thumbsUp(true);
  };

  GamePageView.prototype.thumbsDown = function() {
    return this.model.thumbsDown(true);
  };

  return GamePageView;

})(Backbone.View);


/*=========================================================*/
/*=========================================================*/
var GameView, _ref,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

GameView = (function(_super) {
  __extends(GameView, _super);

  function GameView() {
    this.render = __bind(this.render, this);
    _ref = GameView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  GameView.prototype.tagName = "div";

  GameView.prototype.className = "game";

  GameView.prototype.templateStr = '<a href="/games/{{=it.slug}}">\
      <img class="thumb" src="{{=it.image_url}}">\
      <div class="name">{{=it.title}}</div>\
    </a>';

  GameView.prototype.template = doT.template(GameView.prototype.templateStr, void 0, {});

  GameView.prototype.render = function() {
    this.$el.append(this.template(this.model.toJSON()));
    return this.$el;
  };

  return GameView;

})(Backbone.View);


/*=========================================================*/
/*=========================================================*/
var GamesView, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

GamesView = (function(_super) {
  __extends(GamesView, _super);

  function GamesView() {
    _ref = GamesView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  GamesView.prototype.el = "div#games";

  GamesView.prototype.initialize = function() {
    this.listenTo(this.collection, 'add', this.appendGame);
    return this.infiniScroll = new Backbone.InfiniScroll(this.collection, {
      strict: true,
      includePage: true,
      scrollOffset: 600
    });
  };

  GamesView.prototype.render = function() {
    this.collection.forEach(function(game) {
      return this.appendGame(game);
    });
    return this.$el;
  };

  GamesView.prototype.appendGame = function(game, games, options) {
    var gameview;
    gameview = new GameView({
      model: game
    });
    this.$el.append(gameview.render());
    return this.$el;
  };

  GamesView.prototype.remove = function() {
    this.infiniScroll.destroy();
    return Backbone.View.prototype.remove.call(this);
  };

  return GamesView;

})(Backbone.View);


/*=========================================================*/
/*=========================================================*/
var App, _ref,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App = (function(_super) {
  __extends(App, _super);

  function App() {
    this.initFullScreen = __bind(this.initFullScreen, this);
    this.center_games = __bind(this.center_games, this);
    _ref = App.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  App.prototype.initialize = function() {
    this.bind('route', this._trackPageview);
    this.games = new GamesCollection();
    _.each($('.game'), function(game_el) {
      var game, gameEl, gameView, slug;
      game = new Game;
      gameEl = $(game_el);
      slug = gameEl.find('a').attr('href');
      game.set({
        title: gameEl.find('div.name').html(),
        image_url: gameEl.find('img.thumb').attr('src'),
        slug: slug.substr(slug.lastIndexOf('/') + 1)
      });
      gameView = new GameView({
        model: game,
        el: game_el
      });
      return this.add(game);
    }, this.games);
    this.gamesView = new GamesView({
      collection: this.games
    });
    this.gamePageView = new GamePageView({
      el: $('#GamePage')
    });
    return this.initFullScreen();
  };

  App.prototype.center_games = function() {
    var margin;
    if ($('body').height() < $(window).height()) {
      this.initFullScreen();
    }
    margin = ($(window).width() - $("#games").width() - 10) / 2;
    if (margin > 40) {
      margin = 0;
    }
    return $(".content").css("margin-left", margin);
  };

  App.prototype.initFullScreen = function() {
    $(window).scroll();
    if ($('body').height() > $(window).height()) {
      return;
    }
    return setTimeout(this.initFullScreen, 100);
  };

  App.prototype._trackPageview = function() {
    var url;
    url = Backbone.history.getFragment();
    if (!/^\//.test(url) && url !== "") {
      url = "/" + url;
    }
    return ga('send', 'pageview', url);
  };

  App.prototype.routes = {
    "!/games/:game_link": "gamepage",
    "/": "index"
  };

  App.prototype.init = function() {};

  App.prototype.index = function() {
    console.log("INDEX");
    $('body').removeClass("no-scroll");
    $('#GamePage').hide();
    $('#GamePageBackdrop').hide();
    this.gamePageView.deleteSwfObject();
    return $(window).resize();
  };

  App.prototype.gamepage = function(game_link) {
    var slug,
      _this = this;
    $('#GamePageBackdrop').show();
    slug = game_link.substr(game_link.lastIndexOf('/') + 1);
    this.gamePageView.model = new Game({
      slug: slug
    });
    return this.gamePageView.model.fetch({
      success: function() {
        return _this.gamePageView.model.fetchPopularAndSimilar({
          success: function() {
            $('#GamePage').replaceWith(_this.gamePageView.render());
            _this.gamePageView.setupSwfObject();
            $('#GamePage').show();
            return $('body').addClass("no-scroll");
          },
          error: function() {
            return $('#GamePageBackdrop').hide();
          }
        });
      },
      error: function() {
        return $('#GamePageBackdrop').hide();
      }
    });
  };

  return App;

})(Backbone.Router);

$(function() {
  var _this = this;
  window.app = new App();
  $(window).resize(app.center_games);
  setTimeout(app.center_games, 200);
  Backbone.history.start({
    silent: true
  });
  $(document).on("a", "click", function(e) {
    var attribute,
      _this = this;
    attribute = function(attr) {
      return e.currentTarget.getAttribute(attr);
    };
    if (attribute('nobackbone')) {
      return;
    }
    if (!attribute('href')) {
      return true;
    }
    /*if href[0] is '/'
      uri = if Backbone.history._hasPushState then e.currentTarget.getAttribute('href').slice(1) else "!/"+e.currentTarget.getAttribute('href').slice(1)
      app.navigate uri, {trigger:true}
      return false
    */

  });
  $(document).on("*[data-tracking-action]", "click", function(e) {
    return ga('send', 'event', $(this).attr("data-tracking-category"), $(this).attr("data-tracking-action"), $(this).attr("data-tracking-label"), $(this).attr("data-tracking-value"));
  });
  return $('.search-bar .search-query').typeahead({
    source: app.games.search,
    matcher: function() {
      return true;
    },
    sorter: function(items) {
      return items;
    },
    highlighter: function(game) {
      var gv;
      gv = new GameView({
        model: game
      });
      return gv.render();
    },
    updater: function(itemString) {
      var item;
      item = JSON.parse(itemString);
      app.navigate('/games/' + item.slug, {
        trigger: true
      });
    },
    items: 8
  });
});
