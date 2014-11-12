'use strict';

/**
 * @ngdoc function
 * @name lyt3App.controller:MainCtrl
 * @description
 * # MainCtrl
 * Controller of the lyt3App
 */
angular.module( 'lyt3App' )
  .controller( 'MainCtrl', [ '$scope', 'BookService', 'Book', function( $scope,
    BookService, Book ) {
    $scope.awesomeThings = [
      'HTML5 Boilerplate',
      'AngularJS',
      'Karma'
    ];

    BookService.logOn( 'guest', 'guest' ).then(
      function( ) {
        console.log( 'logOn: then', arguments );
        Book.load( 37027 ).then( function( book ) {
          console.log( 'Load book', book );
          book.loadAllSMIL( ).then( function( smildocuments ) {
            var output = [ ];

            smildocuments.forEach( function( smildocument ) {
              smildocument.segments.forEach( function(
                segment ) {
                output.push( {
                  url: segment.audio.url,
                  start: segment.start,
                  end: segment.end
                } );
              } );
            } );
            console.log( output );
            console.log( JSON.stringify( output ) );

            book.getBookStructure( ).then( function( structure ) {
              console.log( structure );
            } );
          } );
        }, function( ) {
          console.log( 'Load book FAILED', arguments );
        } );
      },
      function( ) {
        console.log( 'logOn: rejected', arguments );
      }
    );
  } ] );
