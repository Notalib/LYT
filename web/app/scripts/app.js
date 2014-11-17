'use strict';

/**
 * @ngdoc overview
 * @name lyt3App
 * @description
 * # lyt3App
 *
 * Main module of the application.
 */
angular
  .module( 'lyt3App', [
    'ngAnimate',
    'ngCookies',
    'ngResource',
    'ngRoute',
    'ngSanitize',
    'ngTouch',
    'xml',
    'LocalStorageModule',
  ] )
  .config( function( $routeProvider ) {
    $routeProvider
      .when( '/bookshelf', {
        templateUrl: 'views/bookshelf.html',
        controller: 'BookshelfCtrl'
      } )
      .when( '/book-player', {
        templateUrl: 'views/book-player.html',
        controller: 'BookPlayerCtrl'
      } )
      .otherwise( {
        redirectTo: '/bookshelf'
      } );
  } );
