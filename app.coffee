###
Module dependencies.
###
express = require "express"
http = require "http"
git = require "simple-git-child"
wintersmith = require "wintersmith"

baseDir = "/home/fleet/cloudloader/repos"
ignorePushesFrom = [ "pinion-deploy" ]

app = express()
app.configure ->
  app.set "port", process.env.PORT or 3000
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router

app.configure "development", ->
  app.use express.errorHandler()

app.post "/newCommit/:name", (req,res) ->
  data = JSON.parse req.body.payload
  for pusher in ignorePushesFrom
    return if data.pusher.name == pusher
  buildBlog req.params.name

buildBlog = (name) ->
  dir = "#{baseDir}/#{name}"
  git.pull "#{dir}", (res) ->
    console.log "done"
    throw res.err if res.err?
    wintersmith {
      output: "#{dir}/build/"
      contents: "#{dir}/contents"
      templates: "#{dir}/templates"
    }, (error) ->
      throw error if error?

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

