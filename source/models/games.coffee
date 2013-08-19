url          = require 'url'
mongoose     = require 'mongoose'
_            = require 'underscore'
Schema       = require '../rest'
async        = require 'async'
memjs        = require 'memjs'
useMemCache  = process.env.USE_MEMCACHE

# if running MemCache
if useMemCache.localeCompare 'true' is 0
  express    = require 'express'
  logentries = require 'node-logentries'
  app        = express()
  app.log    = logentries.logger token: process.env.LOGENTRIES_KEY

  # connect to MemCache
  async.auto
    memcache: (cb) -> require('../onstart').connectToMemcache app, cb
  , ()->
    app.log.info 'MemCache launched in model Games'

{ObjectId} = Schema.Types

Games = new Schema
  title:
    type:      String
    required:  true
  description: String
  slug:
    type:      String
    required:  true
    trim:      true
  image_url:
    type:      String
    required:  true
  swf_url:
    type:      String
    required:  true
  created_on:
    type:      Date
    default:   Date.now
  updated_on:
    type:      Date
    default:   Date.now
  thumbs_up:
    type:      Number
    default:   0
  thumbs_down:
    type:      Number
    default:   0
  pageviews:
    type:      Number
    default:   0
  avg_time:
    type:      Number
    default:   0
  bounce_rate:
    type:      Number
    default:   0
  score: 
    type:      Number
    default:   0
  site: 
    type:      ObjectId
    ref:      'sites'

Games.statics.getAllGamesBySite = (ctx, cb)->
  @find { site: ctx._id }, null, { sort: { score: -1 } }, cb

Games.statics.getBySlugOrId = (id, ctx, cb)->
  oid = if id?.match "^[0-9A-Fa-f]+$" then new ObjectId id else null
  @findOne { $or: [ { slug: id }, {_id: oid } ], site: ctx._id}, cb

Games.statics.getSimilar = (id, count, ctx, cb) ->
  @find { site: ctx._id }, null, { limit: count }, cb

Games.statics.getPopular = (count, ctx, cb) ->
  @find { site: ctx._id }, null, { sort: { thumbs_up: -1 }, limit: count}, cb

Games.statics.search = (query, ctx, cb)->
  @find { site: ctx._id, title: new RegExp(query, "i") }, null, { limit: 20 }, cb

Games.statics.pagination = (page, page_size, ctx, cb)->
  page       = page || 0
  limit      = page_size || 40
  skip       = (page-1)*limit
  end        = skip + limit*1

  # if running MemCache
  if useMemCache.localeCompare 'true' is 0

    # reed MemCache
    app.mem.get "AllGames_#{ctx._id}", (err, val)=>
      
      # data sample is necessary Games
      pickGames = (allGames, i, n) ->
        result = []
        while i < n
          oneGame = allGames[i++]
          if oneGame
            # create a selection of games
            result.push oneGame

        return result

      # if the cache is full
      if !err and val?
        
        # data sample is necessary Games
        result = pickGames JSON.parse(val), skip, end
        cb null, result
      
      # if the cache is empty
      else
        # reed db
        @find { site: ctx._id }, null, { sort: { score: -1 } }, (err, data)->
          return cb(err) if err?

          # fill the cache
          app.mem.set "AllGames_#{ctx._id}", JSON.stringify(data)

          # data sample is necessary Games
          result = pickGames data, skip, end
          cb null, result

  # if not running MemCache
  else
    # reed db
    @find { site: ctx._id }, null, { sort: { score: -1 }, skip: skip, limit: limit }, cb

Games.statics.countGames = (site_id, ctx, cb)->
  @count { site:site_id }, cb

Games.statics.get = (req, res)->
  {ctx} = req
  {id}  = req.params
  {query, page, page_size, popular, similar} = req.query
  key   = "#{ctx.locale}/#{ctx.hash}/"
  
  if id?
    key += id
  
  key += JSON.stringify req.query

  req.app.mem.get key, (err, val)=>
    if !err and val
      res.json JSON.parse val
    
    else
      cb = (err, data)->
        unless err
          req.app.mem.set key, JSON.stringify data
          res.json data
        
        else
          res.json {err}

      if popular?
        #get popular games
        @getPopular popular, ctx, cb
      
      else if id?
        if similar?
          #get similar games to id
          @getSimilar id, similar, ctx, cb
        
        else
          #get by id or slug
          @getBySlugOrId id, ctx, cb
      
      else if query?
        #search by name
        @search query, ctx, cb
      
      else
        @pagination page, page_size, ctx, cb

Games.statics.put = (req, res)->
  {ctx}         = req
  {id}          = req.params
  dbSearchParam = {}
    
  if id? and id.match "^[0-9A-Fa-f]+$"
    oid = new ObjectId id
  
  thumbsUp   = req.query.thumbsUp
  thumbsDown = req.query.thumbsDown
  changes    = {}

  # write changes to thumbsUp
  if thumbsUp?
    changes.thumbs_up   = if thumbsUp.localeCompare('true') is 0 then 1 else -1
  
  # write changes to thumbsDown
  else if thumbsDown?
    changes.thumbs_down = if thumbsDown.localeCompare('true') is 0 then 1 else -1
  
  # return error
  else
    return res.json err:"unknown action"

  dbSearchParam.site   = ctx._id
  
  #choose which of the options will be used in a query to the database
  unless oid?
    console.log 'dbSearchParam.slug = id'
    dbSearchParam.slug = id
  
  else
    console.log 'dbSearchParam._id  = oid.path'
    dbSearchParam._id  = oid.path

  #@update {$or:[{slug:id}, {_id: oid.path}], site:ctx._id}, {$inc: changes}, {multi:false}, (err)->
  @update dbSearchParam, { $inc: changes }, { multi: false }, (err)->
    unless err?
      console.log '== not error =='
      res.send success:true
    
    else
      console.log '==   error   =='
      return res.send err:err



###
i = 0
while i<123
  game_rnd = Math.floor(Math.random() * 100000000)
  picnum = Math.floor(Math.random() * 3) + 1
  g = new gm
  g.title = "Game " + game_rnd
  g.description = "description for game "+game_rnd
  g.slug = "game_slug_" + game_rnd
  g.image_url = '/static/img/thumb150_' + picnum + '.jpg'
  g.swf_url = 'http://www.mousebreaker.com/games/parking/INSKIN__parking-v1.1_Secure.swf'
  g.site = "518f72b56e98bc0200000001"
  console.log g
  g.save (err, it)->
    console.log err
  i++
###

exports.model   = mongoose.model 'games', Games
exports.methods = ["get","put"]