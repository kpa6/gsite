root      = __dirname
i18n      = require 'i18n'
mongoose  = require 'mongoose'
walk      = require 'walk'
memjs     = require 'memjs'
crypto    = require 'crypto'
cp        = require 'child_process'
fs        = require 'fs'
knox      = require 'knox'
async     = require 'async'
path      = require 'path'

# generate route for RESTful api
exports.createApi = (app, cb) ->
  app.models = {}
  walker     = walk.walk root + "/models", followLinks:false
  
  walker.on "names", (root, modelNames) ->
    modelNames.forEach (modelName) ->
      modelName             = modelName.replace /\.[^/.]+$/, ""
      app.models[modelName] = require './models/'+ modelName
  
  walker.on "end", () ->
    require('./api') app
    app.log.info "generate api routes    - Ok!"
    cb()

# generate locales for i18n
exports.createLocales = (app, cb) ->
  dirLocales  = './source/public/locales'
  appLocales  = ['en','en-us','en-gb','ru','de','es','es-es','es-mx','es-co','es-ar','es-pe','es-ve','zh','fr','ja','ar','pt','pt-br','pl','it','tr','nl','fa','cs','sv','id','el','ro','vi','hu','th','da','ko','sk','fi','bg','no','he','lt','hr','sr','sl','uk']
  app.locales = appLocales.sort()
  
  i18n.configure
    locales:   appLocales
    directory: dirLocales
  
  app.log.info "setup locales          - Ok!"
  cb()

# mongo connection
exports.connectToMongo = (app, cb) ->
  mongoose.connect process.env.MONGOLAB_URI
  db = mongoose.connection
  
  db.on 'error', console.error.bind console, 'connection error:'
  
  db.once 'open', () ->
    app.log.info "connection to mongo    - Ok!"
    cb()

# memcache
exports.connectToMemcache = (app, cb) ->
  MemCacheExpires = process.env.GLOBAL_MEMCACHE_EXPIRES
  app.mem         = memjs.Client.create(undefined, expires: MemCacheExpires)
  
  app.mem.flush (err, info) ->
    unless err
      app.log.info  "flush memcache         - Ok!"
    else
      app.log.err  "flush memcache         - ERROR!"
      app.log.err err, info
  
  app.log.info  "connection to memcache - Ok!"
  cb()

# run grunt to compile new js and css files
exports.runGrunt = (app, cb) ->
  grunt = cp.exec "node node_modules/grunt-cli/bin/grunt dev --no-color", (err, stdout, stderr) ->
    app.log.info stdout

    if err?
      app.log.err "grunt                  - FAILED!"
      app.log.err stderr
      app.log.err err
    
    else
      app.log.info "grunt                  - Ok!"
    
    cb()

# upload to S3
exports.uploadStaticToS3 = (app, cb) ->
  app.file = {}

  client   = knox.createClient
    key:    process.env.AWS_ACCESS_KEY_ID
    secret: process.env.AWS_SECRET_ACCESS_KEY
    bucket: process.env.AWS_STORAGE_BUCKET_NAME_STATIC

  options  =
    followLinks: false
    filters:     ["locales"]

  walker   = walk.walk "#{root}/public/", options

  walker.on "file", (root, fileStats, next) ->
    fs.readFile path.normalize("#{root}/#{fileStats.name}"), (err, buf) ->
      folder   = path.normalize(root.replace(__dirname, "")).replace(/\\/g, "/").replace "/", ""
      name     = fileStats.name.replace /^([0-9a-f]{32}\.)/, ""
      dotIndex = name.lastIndexOf '.'
      
      ext = if dotIndex > 0 then name.substr 1 + dotIndex else null
      
      if ext is 'css'
        contentType ='text/css'
      
      else if ext is 'js'
        contentType = 'application/javascript'
      
      else if ext in ['png', 'jpeg', 'gif', 'bmp']
        contentType = "image/#{ext}"
      
      else
        contentType = 'text/plain'

      if process.env.UPLOAD_STATIC_TO_S3.localeCompare 'true' is 0
        req = client.put "#{folder}/#{fileStats.name}",
          'Content-Length': buf.length
          'Content-Type': contentType
          'x-amz-acl': 'public-read'
        
        req.on 'response', (res) ->
          if res.statusCode is 200
            app.file[name] = "http://#{process.env.AWS_CLOUDFRONT_STATIC}/#{folder}/#{fileStats.name}"
          
          else
            app.log.err "Loading #{folder}/#{fileStats.name} - ERROR!"
            app.log.err "#{folder}/#{fileStats.name} will be served from heroku"
            app.file[name] = "/#{folder}/#{fileStats.name}"
          next()
        
        req.end buf
      
      else
        app.file[name] = "/#{folder}/#{fileStats.name}"
        next()

  walker.on "end", ->
    app.log.info "Load static files to S3 - Ok!"
    app.log.info app.file
    console.log app.file
    cb()