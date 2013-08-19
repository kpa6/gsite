###
  Env variables
###

process.env.GA_SERVICE_ACCOUNT      = process.env.GA_SERVICE_ACCOUNT      || "901556670104.apps.googleusercontent.com"
process.env.GA_SERVICE_EMAIL        = process.env.GA_SERVICE_EMAIL        || "901556670104@developer.gserviceaccount.com"
process.env.GA_KEY_PATH             = process.env.GA_KEY_PATH             || "source/gsites-analytics-privatekey.pem"
process.env.MONGOLAB_URI            = process.env.MONGOLAB_URI            || "mongodb://gsite_app:temp_passw0rd@ds041327.mongolab.com:41327/heroku_app14575890"

###
  Modules
###

_ = require 'underscore'
fs = require 'fs'
path = require 'path'
crypto = require 'crypto'
request = require 'request'
qs = require 'querystring'
googleapis = require 'googleapis'
mongoose = require 'mongoose'
async = require 'async'

###
  Models we use
###
gamesM    = require("../models/games").model
sitesM    = require("../models/sites").model

authorize = (callback)->
  now = parseInt Date.now() / 1000, 10

  authHeader =
    alg: 'RS256'
    typ: 'JWT'

  authClaimSet =
    iss  : process.env.GA_SERVICE_EMAIL
    scope: 'https://www.googleapis.com/auth/analytics.readonly'
    aud  : 'https://accounts.google.com/o/oauth2/token'
    iat  : now
    exp  : now + 60

  #Setup JWT source
  signatureInput = base64Encode(authHeader) + '.' + base64Encode authClaimSet

  #Generate JWT
  cipher = crypto.createSign 'RSA-SHA256'
  cipher.update signatureInput
  signature = cipher.sign readPrivateKey(), 'base64'
  jwt = signatureInput + '.' + urlEscape signature

  #Send request to authorize this application
  request
    method: 'POST'
    headers:
      'Content-Type': 'application/x-www-form-urlencoded'
    uri: 'https://accounts.google.com/o/oauth2/token'
    body: 'grant_type=' + escape('urn:ietf:params:oauth:grant-type:jwt-bearer') +
    '&assertion=' + jwt
  , (err, res, body)=>
    return callback err if err?

    # parsing JSON
    try
      gaResult = JSON.parse body
      throw gaResult.error if gaResult.error?
    catch error
      return callback error

    callback null, gaResult

urlEscape = (source)->
  source.replace(/\+/g, '-').replace(/\//g, '_').replace /\=+$/, ''

base64Encode = (obj)->
  encoded = new Buffer(JSON.stringify(obj), 'utf8').toString 'base64'
  urlEscape encoded

readPrivateKey = ->
  fs.readFileSync process.env.GA_KEY_PATH, 'utf8'

process_analytics_data = (data, callback)->
  sitesM.find {}, (err, sites)->
    return callback err if err?
    sitesByDomain = {}
    sites.forEach (site)-> sitesByDomain[site.domain] = site
    
    max_data = _.max data, (row)-> return row[3]
    max_avg_time = max_data[3]

    async.forEach data, (details, done)->
      [gameSpecificDomain, gameSpecificSlug, timeOnPage, avgTimeOnPage] = details

      # return unless its a game
      return done null unless /^\/games\/[a-z0-9_-]+$/i.test(gameSpecificSlug)

      domainName = gameSpecificDomain.replace "www.",""
      siteId = sitesByDomain[domainName]._id

      extractedSlug = gameSpecificSlug.replace "/games/", ""
      
      if not avgTimeOnPage
        score = 0
      else
        score = (avgTimeOnPage/max_avg_time) + Math.random()

      gamesM.update {site: siteId, slug: "#{extractedSlug}"},{max_avg_time, score}, (err)->
        done err
    , callback




update_game_analytics = (callback) ->
  authorize (err, data) ->
    return callback err if err?

    addZero = (val) ->
      if val < 10
        return "0#{val}"
      return val

    formatTime = (date) ->
      YY = date.getFullYear()
      MM = addZero date.getMonth()+1
      DD = addZero date.getDate()

      return "#{YY}" + "-" + "#{MM}" + "-" + "#{DD}"

    endDate = formatTime new Date
    startDate = formatTime new Date((new Date - 12096e5))

    #Query the number of total visits for a month
    requestConfig =
      'ids': 'ga:73030585'
      'start-date': "#{startDate}"
      'end-date': "#{endDate}"
      'metrics': 'ga:timeOnPage,ga:avgTimeOnPage'
      'dimensions': 'ga:hostname,ga:pagePath'

    request
      method: 'GET'
      headers:
        'Authorization': 'Bearer ' + data.access_token
      uri: 'https://www.googleapis.com/analytics/v3/data/ga?' + qs.stringify requestConfig
    ,(err, res, body)->
      return callback err if err?
      try
        data = JSON.parse body
        throw data.error if data.error?
      catch error
        return callback error

      # get unique domains
      process_analytics_data data.rows, callback

exports.run = ->
  db = mongoose.connect process.env.MONGOLAB_URI, (err)->
    throw err if err?
    update_game_analytics (err, data)->
      throw err if err?
      console.info "successfuly updated information about the games"
      # closing mongoose connection
      mongoose.connection.close()