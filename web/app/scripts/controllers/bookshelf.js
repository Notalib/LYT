'use strict';

angular.module( 'lyt3App' )
  .controller( 'BookshelfCtrl', [ '$scope', 'BookService', function( $scope,
    BookService ) {
    $scope.books = BookService.getCachedBookShelf( );

    var loadBookShelf = function( from, count ) {
      if ( from === undefined ) {
        from = $scope.books.length;
      }

      from = Math.max( 0, from );

      var to = from + ( count || 5 ) - 1;

      return BookService.getBookshelf( from, to ).then( function( items ) {
        var unique = {};
        $scope.books = items.filter(
          function( item ) {
            if ( item && !unique[ item.id ] ) {
              unique[ item.id ] = true;
              return true;
            }
            return false;
          } );
      } );
    };

    loadBookShelf( 0, $scope.books.length - 1 ).catch( function( ) {
      BookService.logOn( 'guest', 'guest' ).then( function( ) {
        loadBookShelf( 0, $scope.books.length - 1 );
      }, function( ) {
        console.log( 'logOn: rejected', arguments );
      } );
    } );

    $scope.nextPage = function( ) {
      loadBookShelf( );
    };
  } ] );
