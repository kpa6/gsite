# for development
process.env.LOGENTRIES_KEY          = process.env.LOGENTRIES_KEY          || "703440f5-1d7b-4523-885c-76516d11102c"
process.env.NODETIME_ACCOUNT_KEY    = process.env.NODETIME_ACCOUNT_KEY    || "43389b1b19e9d19f93e815650663c4aeb1279b7e"
process.env.MEMCACHIER_SERVERS      = process.env.MEMCACHIER_SERVERS      || "mc2.dev.ec2.memcachier.com:11211"
process.env.MEMCACHIER_USERNAME     = process.env.MEMCACHIER_USERNAME     || "bb3435"
process.env.MEMCACHIER_PASSWORD     = process.env.MEMCACHIER_PASSWORD     || "00b4bfbba300aa89e4bc"
process.env.MONGOLAB_URI            = process.env.MONGOLAB_URI            || "mongodb://gsite_app:temp_passw0rd@ds041327.mongolab.com:41327/heroku_app14575890"
process.env.BLITLINE_APPLICATION_ID = process.env.BLITLINE_APPLICATION_ID || "3wYloUPnQrqOKNOep1I1LJQ"
process.env.BLITLINE_URL            = process.env.BLITLINE_URL            || "http://api.blitline.com/job/3wYloUPnQrqOKNOep1I1LJQ"
process.env.FILEPICKER_API_KEY      = process.env.FILEPICKER_API_KEY      || 'AHM0McfCNSO6RKHvEADdqz'
process.env.FILEPICKER_API_SECRET   = process.env.FILEPICKER_API_SECRET   || '7HDSNPSHV5GBHJU6EDPBMVNT3A'
process.env.AWS_ACCESS_KEY_ID       = process.env.AWS_ACCESS_KEY_ID       || 'AKIAITI4VR6ZZFFCJ5FA'
process.env.AWS_SECRET_ACCESS_KEY   = process.env.AWS_SECRET_ACCESS_KEY   || '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'
process.env.AWS_CLOUDFRONT_IMG      = process.env.AWS_CLOUDFRONT_IMG      || 'd1zjm5k21y5rcp.cloudfront.net'
process.env.AWS_CLOUDFRONT_STATIC   = process.env.AWS_CLOUDFRONT_STATIC   || 'dsogyhci03djz.cloudfront.net'
process.env.AWS_STORAGE_BUCKET_NAME = process.env.AWS_STORAGE_BUCKET_NAME || 'gsites-static'
process.env.AWS_STORAGE_BUCKET_NAME_IMG = process.env.AWS_STORAGE_BUCKET_NAME_IMG || 'gsites-img'
process.env.AWS_STORAGE_BUCKET_NAME_STATIC = process.env.AWS_STORAGE_BUCKET_NAME_STATIC || 'gsites-static'



if process.env.NODE_ENV is "dev"
  process.env.UPLOAD_STATIC_TO_S3 = false
  process.env.USE_MEMCACHE = false
else
  process.env.UPLOAD_STATIC_TO_S3 = true
  process.env.USE_MEMCACHE = true

# for USE_MEMCACHE 
process.env.USE_MEMCACHE = true
useMemCache = process.env.USE_MEMCACHE

# profiler
if process.env.NODETIME_ACCOUNT_KEY
  require('nodetime').profile
    accountKey: process.env.NODETIME_ACCOUNT_KEY
    appName: 'g-sites'

# global settings
process.env.GLOBAL_MEMCACHE_EXPIRES = 3600

# requires
root          = __dirname
express       = require 'express'
i18n          = require 'i18n'
mongoose      = require 'mongoose'
dot           = require 'express-dot'
async         = require 'async'
_             = require 'underscore'
passport      = require 'passport'
crypto        = require 'crypto'
logentries    = require 'node-logentries'
localStrategy = require('passport-local').Strategy
#blitline      = require 'simple_blitline_node'

app          = express()

# register models
sites        = require './models/sites'
games        = require './models/games'

# controllers
admin        = require './controllers/admin'
index        = require './controllers/index'
source       = require './controllers/source'

# logger
app.log      = logentries.logger token: process.env.LOGENTRIES_KEY
app.log.info "====================================="
app.log.info "====================================="
app.log.info "Start server!"

startServer = () ->
  app.configure () ->

    # dot
    app.set 'views', './source/views'
    app.set 'view engine', 'dot'
    app.engine 'dot', dot.__express

    # stack
    app.use express.compress()
    app.use express.global_settings = 3600
    app.use "/public", express.static './source/public', { maxAge: 86400000 }
    app.use "/static", express.static './source/public', { maxAge: 86400000 }
    app.use express.cookieParser()
    app.use express.bodyParser()
    app.use express.methodOverride()
    app.use express.errorHandler
      dumpExceptions: true,
      showStack:      true
    app.use express.session secret:'super-puper-secret-key'
    app.use passport.initialize()
    app.use passport.session()
    app.use i18n.init

    app.use (req, res, next) ->
      req.ctx            = {}
      req.ctx.__         = i18n.__
      req.ctx.getCatalog = i18n.getCatalog
      req.ctx.locales    = app.locales
      req.ctx.api        = '/api/v1.alpha'
      req.ctx.env        = process.env
      req.ctx.file       = app.file

      next()

    app.use (req, res, next) ->
      domainName = req.headers.host.replace(/^www\./, "").replace "localhost:5000", "g-sites.herokuapp.com"

      ## #domainName = req.headers.host.replace(/^www\./, "")
      ## domainName = req.headers.host.replace(/^www\./, "").replace "localhost:5000", "g-sites.herokuapp.com"

      mongooseModel = (req, res, next, useMemCache) =>
        mongoose.model('sites').getByDomain domainName, (err, domain) ->
          if !err? and domain?
            domain      = domain.toJSON()
            domain.hash = crypto.createHash('md5').update(JSON.stringify domain ).digest "hex"
            _.extend req.ctx, domain
            
            if useMemCache.localeCompare 'true' is 0
              app.mem.set domainName, JSON.stringify domain
            
            next()
          
          else
            app.log.warning "domain #{req.headers.host} not found in sites db"
            res.send 404

      # Comparison of the value process.env.USE_MEMCACHE with the value 'true'
      # if not using MemCache
      unless useMemCache.localeCompare 'true' is 0
        mongooseModel req, res, next, useMemCache

      # if using MemCache
      else
        app.mem.get domainName, (err, val) ->
          if !err and val
            _.extend req.ctx, JSON.parse val
            next()
          
          else
            mongooseModel req, res, next, useMemCache

    app.use (req, res, next) ->
      req.ctx.locale = req.ctx.language
      
      if req.ctx.enable or (req.url.match "^\/admin")? or (req.user is 'admin' and (req.url.match "^\/api")?)
        next()
      
      else
        # if site suspended
        res.send 404

    async.auto
      api        : (cb) -> require('./onstart').createApi app, cb
      locales    : (cb) -> require('./onstart').createLocales app, cb
      mongo      : (cb) -> require('./onstart').connectToMongo app, cb
      memcache   : (cb) -> require('./onstart').connectToMemcache app, cb
      grunt      : (cb) -> require('./onstart').runGrunt app, cb
      uploadToS3 : ['grunt', (cb) -> require('./onstart').uploadStaticToS3(app,cb) ]
    , () ->
      port = process.env.PORT || 5000
      app.listen port, () ->
        console.log "Listening on " + port

  app.post '/admin/login', passport.authenticate('local'), (req, res) -> res.redirect '/admin/'
  app.get  '/admin/', ensureAuthenticated, admin.sites
  app.get  '/admin', (req, res) -> res.redirect '/admin/'
  app.get  '/admin/site/', (req, res) -> res.redirect '/admin/'
  app.get  '/admin/site/:site', ensureAuthenticated, admin.site_settings
  app.get  '/admin/ads/', ensureAuthenticated, admin.ads_settings
  app.get  '/admin/status/', ensureAuthenticated, admin.status
  app.get  '/admin/login', redirectIfAuthenticated, admin.login
  app.get  '/admin/logout', admin.logout

  app.get  '/', isInCache, index.homepage, addToCache
  app.get  '/public/css/site-settings.css', isInCache, index.site_css, addToCache
  app.get  '/games/:slug', isInCache, index.gamepage, addToCache

# Auth
passport.use new localStrategy (username, password, done) ->
  if username is 'admin'
    if password is 'admin'
      return done null, username
    
    else
      return done null, false, message: 'Incorrect password.'
  
  else
    return done null, false, message: 'Incorrect username.'

passport.serializeUser   (user, done) -> done null, user
passport.deserializeUser (id, done)   -> done null, id

ensureAuthenticated = (req, res, next) ->
  if req.isAuthenticated()
    return next()
  
  res.redirect '/admin/login'

redirectIfAuthenticated = (req, res, next) ->
  unless req.isAuthenticated()
    return next()
  
  res.redirect '/admin/'

# Cache middleware
generateKey = (req, res) ->
  return "#{req.ctx.locale}/#{req.ctx.hash}#{req.url}"

isInCache = (req, res, next) ->
  if useMemCache.localeCompare 'true' is 0
    app.mem.get generateKey(req, res), (err, val) ->
      if !err and val
        extension = req.url.split '.'
        
        if extension?[extension.length-1] is 'css'
          res.set 'Content-Type', 'text/css'
        
        else
          res.set 'Content-Type', 'text/html'
        res.send val
      
      else
        next()

  else
    next()

addToCache = (req, res) ->
  if useMemCache.localeCompare 'true' is 0
    if res.saveToCache? or req.isAuthenticated()
      app.mem.set generateKey(req, res), res.saveToCache

startServer()
