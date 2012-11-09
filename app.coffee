###
Module dependencies.
###
express = require "express"
http = require "http"
url = require "url"
fs = require "fs"
path = require "path"
git = require "simple-git-child"
exec = require('child_process').exec
wintersmith = require "wintersmith"

ignorePushesFrom = [ "pinion-deploy" ]
branches = [ "deploy", "staging" ]

app = express()
app.configure ->
  app.set "port", process.env.PORT or 3002
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use(express.static(__dirname + '/repos'))

app.configure "development", ->
  app.use express.errorHandler()

app.post "/newCommit", (req,res) ->
  data = JSON.parse req.body.payload
  for pusher in ignorePushesFrom
    return if data.pusher.name == pusher
  buildBlog data.repository

buildBlog = (repository) ->
  console.log "buildBlog called"
  dir = "#{__dirname}/repos/#{repository.name}"
  repoLoc = "git@github.com:#{url.parse(repository.url).path}.git"
  git.exec './', "clone #{repoLoc} #{dir}", (res) ->
    app.use(express.static("#{dir}/build"))
    git.pull dir, (res) ->
      branch = branches.pop()
      git.exec dir, "checkout #{branch}", (res) ->
        throw res.err if res.err?
        conf = JSON.parse fs.readFileSync("#{dir}/config.json", "utf8")
        exec "npm install #{conf.plugins.join(' ')}", (error, stdout, stderr) ->
          throw error if error?
          wintersmith {
            output: "#{dir}/build/"
            contents: "#{dir}/contents"
            templates: "#{dir}/templates"
            locals: conf.locals
            plugins: conf.plugins
          }, (error) ->
            throw error if error?
            git.addAll dir, (res) ->
              throw res.err if res.err?
              git.exec dir, "commit -am 'buildBot'", (res) ->
                throw res.err if res.err?
                if branches.length > 0
                  buildBlog(repository)
                else
                  git.push dir, (res) ->
                    throw res.err if res.err?
                    console.log "Pushed", res

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

