mongoose = require 'mongoose'

class Rest extends mongoose.Schema
  constructor: (args)->
    super args
    
    @statics.get    = (req, res, next) ->
      {id} = req.params
      
      @findOne {_id:id}, (err, item) ->
        unless err?
          res.json item
        
        else
          res.json err:err
    
    @statics.put    = (req, res, next) ->
      console.log "PUT"
      res.send 'PUT'
    
    @statics.delete = (req, res, next) ->
      console.log "DELETE"
      res.send 'DELETE'
    
    @statics.post   = (req, res, next) ->
      console.log "POST"
      res.send 'POST'
    
    @statics.patch  = (req, res, next) ->
      console.log "PATCH"
      res.send 'PATCH'

module.exports = Rest