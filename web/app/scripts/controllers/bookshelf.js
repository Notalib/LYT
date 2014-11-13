'use strict';

angular.module( 'lyt3App' )
  .controller( 'BookshelfCtrl', [ '$scope', 'BookService', function( $scope,
    BookService ) {
    $scope.books = [ ];

    var loadBookShelf = function( ) {
      var from = $scope.books.length;
      var to = from + 2;
      BookService.getBookshelf( from, to ).then( function( list ) {
        var unique = {};
        $scope.books = $scope.books.concat( list.items ).filter(
          function( item ) {
            if ( item && !unique[ item.id ] ) {
              unique[ item.id ] = true;
              return true;
            }
            return false;
          } );
      } );
    };

    BookService.logOn( 'guest', 'guest' ).then(
      function( ) {
        loadBookShelf( );
      },
      function( ) {
        console.log( 'logOn: rejected', arguments );
      }
    );

    $scope.nextPage = function( ) {
      loadBookShelf( );
    };

  } ] );
