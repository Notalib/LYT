(function( ) {
  'use strict';

  var express = require('express'),
    proxy = require('http-proxy').createProxyServer(),
    apiProxy = function( host, port ) {
      return function( req, res, next ) {
        if ( req.url.match( /^\/Dodp(Mobile|Files)/ ) ) {
          proxy.proxyRequest(req, res, {
            target: 'http://' + host + ':' + port
          });
        } else {
          next();
        }
      };
    },
    app = express(),
    logger = require( 'morgan' ),
    watchr = require( 'watchr' ),
    exec = require('child_process').exec;

  app
    .use( logger() );

  app
    .use( express.static( process.cwd( ) + '/build' ) );

  app
    .use( apiProxy( 'test.m.e17.dk', 80 ) );

  app
    .listen( 8080 );


  watchr.watch( {
    paths: [
      'html', 'src', 'sass'
    ],
    listeners: {
      change : function( changeType, filePath /*, fileCurrentStat, filePreviousStat*/ ) {
        exec( 'cake -dnt app', function( ) {
          console.log( 'Rebuild after change to ' + filePath );
        });
      }
    }
  } );
} )();
