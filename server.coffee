express = require 'express'

proxy = require( 'http-proxy' ).createProxyServer()

apiProxy = ( target  ) ->
  return ( req, res, next ) ->
    if req.url.match( /^\/(Dodp(Mobile|Files)|CatalogSearch)/ )
      proxy.proxyRequest(req, res,
        target: target
      )
    else
      next()

    return

stdio = require('stdio')
ops = stdio.getopt(
  remotehost :
    key: 'r'
    mandatory: true
    description: 'Proxy /DodpMobile, /DodpFiles and /CatalogSearch to this url'
  port:
    description: 'The port the test server will listen to'
)

app = express()
logger = require( 'morgan' )
watchr = require( 'watchr' )
exec = require('child_process').exec

app.use logger()

app.use express.static( process.cwd( ) + '/build' )

app.use apiProxy( ops.remotehost )

server = app.listen ops.port or 8080, () ->
  console.log 'Listening on port %d', server.address().port

watchr.watch(
  paths: [
    'html', 'src', 'sass'
  ],
  listeners:
    change : ( changeType, filePath, fileCurrentStat, filePreviousStat ) ->
      exec( 'cake -dnt app', ( ) ->
        console.log 'Rebuild after change to ' + filePath
        return
      )
      return
)
