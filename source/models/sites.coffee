mongoose = require 'mongoose'
Schema   = require '../rest'

Sites    = new Schema
  enable:
    type:        Boolean
    default:     false
  domain:
    type:        String
    required:    true
    unique:      true
    lowercase:   true
    trim:        true
  title:         String
  description:   String
  keywords:      String
  language:
    type:        String
    default:     'en'
  sources:       []
  logo_url:      String
  toolbar:
    start_color: String
    stop_color:  String
  background:
    url:         String
    color:       String

Sites.statics.getByDomain = (domain, cb) ->
  @findOne {domain}, cb

Sites.statics.getAll = (cb)->
  @find {}, null, { sort:  { domain: 1 } }, cb

Sites.statics.post = (req, res)->
  if req.isAuthenticated()
    {domain}    = req.body
    site        = new (mongoose.model 'sites', Sites)
    site.domain = domain
    
    site.save (err)->
      unless err?
        #res.redirect "/admin/site/#{domain}"
        res.redirect "/admin/"
      else
        console.log err
        res.json {err}
  else
    res.json err:'Not authenticated'

Sites.statics.put = (req, res) ->
  if req.isAuthenticated()
    {id} = req.params
    oid  = null
    
    if id? and id.match "^[0-9A-Fa-f]+$"
      oid = new ObjectId id
    
    @update { $or: [ { domain: id }, { _id: oid } ] }, { $set: req.body }, { multi: false }, (err, numAffected) =>
      unless err? or !numAffected
        req.app.mem.delete id, console.log "clear memcache for " + id
        res.json null
      
      else
        res.json {err}
  
  else
    res.json err:'Not authenticated'


exports.model   = mongoose.model 'sites', Sites
exports.methods = ["post", "put"]