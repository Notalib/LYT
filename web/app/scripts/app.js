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
      .when( '/', {
        templateUrl: 'views/main.html',
        controller: 'MainCtrl'
      } )
      .when( '/about', {
        templateUrl: 'views/about.html',
        controller: 'AboutCtrl'
      } )
      .when( '/bookshelf', {
        templateUrl: 'views/bookshelf.html',
        reloadOnSearch: false,
        controller: 'BookshelfCtrl'
      } )
      .otherwise( {
        redirectTo: '/'
      } );
  } );
