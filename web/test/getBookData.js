#!/usr/bin/env node

'use strict';

var jsdom = require( 'jsdom' );

function callback( window ) {
  var angular = window.angular;

  var $injector = angular.injector( [ 'lyt3App' ] );
  var DODP = $injector.get( 'DODP' );
  DODP.logOn( 'guest', 'guest' ).then( function( ) {
    console.log( arguments, window.document.cookie );
    DODP.getServiceAttributes( )
      .then( function( ) {
        console.log( arguments );
        DODP.setReadingSystemAttributes( )
          .then( function( ) {
            DODP.getContentResources( ).then( function( resources ) {
              console.log( resources );
            } ).catch( function( ) {
              console.log( arguments );
            } );
          } ).catch( function( ) {
            console.log( arguments );
          } );
      } ).catch( function( ) {
        console.log( arguments );
      } );
  } ).catch( function( ) {
    console.log( arguments );
  } );
}

jsdom.env(
  '', [
    '../bower_components/jquery/dist/jquery.js',
    '../bower_components/angular/angular.js',
    '../bower_components/angular-resource/angular-resource.js',
    '../bower_components/angular-cookies/angular-cookies.js',
    '../bower_components/angular-resource/angular-resource.js',
    '../bower_components/angular-route/angular-route.js',
    '../bower_components/angular-sanitize/angular-sanitize.js',
    '../bower_components/angular-touch/angular-touch.js',
    '../bower_components/angular-xml/angular-xml.js',
    '../bower_components/angular-animate/angular-animate.js',
    '../bower_components/angular-local-storage/dist/angular-local-storage.js',
    '../app/scripts/app.js',
    '../app/scripts/services/dodp.js'
  ],
  function( errors, window ) {
    window.DOMParser = require( 'xmldom' ).DOMParser;
    window.console = console;

    callback( window );
  } );

console.log( jsdom );
