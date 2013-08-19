_ = require "underscore"

api = (app) ->
  modelNames = Object.keys app.models
  api_version = "v1.alpha"
  
  modelNames.forEach (modelName) =>
    {methods, model} = app.models[modelName]
    
    methods.forEach (method) ->
      app[method] "/api/#{api_version}/#{modelName}/:id?", _.bind(model[method], model)

module.exports = api