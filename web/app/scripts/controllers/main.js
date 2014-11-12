'use strict';

/**
 * @ngdoc function
 * @name lyt3App.controller:MainCtrl
 * @description
 * # MainCtrl
 * Controller of the lyt3App
 */
angular.module( 'lyt3App' )
  .controller( 'MainCtrl', [ '$scope', 'BookService', 'Book', function ( $scope, BookService, Book ) {
    $scope.awesomeThings = [
      'HTML5 Boilerplate',
      'AngularJS',
      'Karma'
    ];

    BookService.logOn( 'guest', 'guest' ).then(
      function( ) {
        console.log( 'logOn: then', arguments );
          Book.load(37027).then(function(book) {
            book.getStructure().then(function(bookStructure) {
              console.log(bookStructure);
            } );
          }, function( ) {
            console.log( 'Load book FAILED', arguments );
          });
      },
      function( ) {
        console.log( 'logOn: rejected', arguments );
      }
    );
  } ] );
