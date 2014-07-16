#!/usr/bin/env coffee

express = require 'express'
watchr = require 'watchr'
exec = require('child_process').exec
proxy = require('http-proxy').createProxyServer()
argv = require 'optimist'
  .usage 'Starts a local dev server that proxies DODP calls'
  .demand 'r'
  .alias 'r', 'remote-host'
  .describe 'r', 'Proxy /DodpMobile, /DodpFiles and /CatalogSearch to this url'
  .default 'r', 'http://m.e17.dk/'

  .alias 'q', 'quiet'
  .describe 'q', 'Be quieter please'

  .alias 's', 'silence'
  .describe 's', 'Silence please'

  .alias 'p', 'port'
  .describe 'p', 'Start the server at this port'
  .default 'p', 8080
  .argv

app = express()
app.use require('morgan')() if not (argv.quiet or argv.silence)
app
  .use express.static( process.cwd() + '/build' )
  .use (req, res, next) ->
    if req.url.match( /^\/(Dodp(Mobile|Files)|CatalogSearch)/ )
      proxy.proxyRequest req, res, target: argv['remote-host']
    else
      next()



server = app.listen argv.port, ->
  if not argv.silence
    console.log 'Listening on port %d', server.address().port

changedTimeout = null

fileChanged = (filePath) ->
  clearTimeout( changedTimeout ) if changedTimeout
  if not argv.silence
    console.log 'Rebuild after change to ' + filePath
  changedTimeout = setTimeout(
    =>
      exec 'cake -dnt app', ->
        if not argv.silence
          console.log 'Fininshed rebuild'
    , 100
  )

watchr.watch
  paths: [ 'html', 'src', 'scss' ],
  listeners:
    change: ( changeType, filePath, fileCurrentStat, filePreviousStat ) ->
      fileChanged filePath
