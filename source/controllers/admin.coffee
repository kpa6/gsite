_        = require "underscore"
async    = require 'async'
mongoose = require 'mongoose'
games    = mongoose.model('games')
sites    = mongoose.model('sites')
DIR      = 'partials/admin/'

admin_controller =

  # Rendering main page of admin panel
  sites: (req, res) =>
    {ctx}     = req
    ctx.admin = true
    ctx.title = "Admin : Sites"
    
    sites.getAll (err, allsites) ->
      allsites = _.map allsites, (site) ->
        site.toJSON()
      
      async.each allsites, (it, cb)->
        games.countGames it._id, ctx, (err, number) ->
          it.games_number = number
          cb err
      , (err)->
        unless err
          ctx.sites = allsites
        
        else
          ctx.err = err
        
        res.render "#{DIR}sites", ctx

  # Rendering site settings
  site_settings: (req, res) =>
    {ctx}     = req
    {site}    = req.params
    ctx.games = []
    ctx.admin = true
       
    sites.getByDomain site, (err, site) ->
      ctx.title = "Admin : " + site.domain
      ctx.site  = site

      games.getAllGamesBySite ctx, (err, data) ->
        async.each data, (game, cb)->
          ctx.games.push game
        , (err)-> console.log 'ERROR!!!'

        res.render "#{DIR}site-settings", ctx



  ads_settings: (req, res) ->
    {ctx}     = req
    ctx.admin = true
    ctx.title = "Admin : Ads Settings"
    ctx.ads   = {}
    
    res.render "#{DIR}ads", ctx

  status: (req, res) ->
    {ctx}      = req
    ctx.admin  = true
    ctx.title  = "Admin : Status"
    ctx.status = {}
    
    res.render "#{DIR}status", ctx

  login: (req, res) =>
    {ctx}     = req
    ctx.admin = true
    ctx.title = "Admin : Login"
    
    res.render "#{DIR}login", ctx

  logout: (req, res) ->
    req.logout()
    res.redirect '/admin/login'

module.exports = admin_controller