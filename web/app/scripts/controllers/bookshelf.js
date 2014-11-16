'use strict';

angular.module( 'lyt3App' )
  .controller( 'BookshelfCtrl', [ '$scope', 'BookService', 'Book', function( $scope,
    BookService, Book ) {
    var uniqueItems = function( items ) {
      var unique = {};
      return items.filter( function( item ) {
        if ( item && !unique[ item.id ] ) {
          unique[ item.id ] = true;
          return true;
        }

        console.warn( 'loadBookShelf: unique item: ' + item.id + ' is a duplicate', item );
        return false;
      } );
    };

    $scope.books = uniqueItems( BookService.getCachedBookShelf( ) );

    var loadBookShelf = function( from, count ) {
      if ( from === undefined ) {
        from = $scope.books.length;
      }

      from = Math.max( 0, from );

      count = Math.max( count, 5 );

      var to = from + count - 1;
      console.log( from, to, count );

      return BookService.getBookshelf( from, to ).then( function( items ) {
        $scope.books = uniqueItems( items );
      } );
    };

    loadBookShelf( 0, $scope.books.length || 5 ).catch( function( ) {
      BookService.logOn( 'guest', 'guest' ).then( function( ) {
        loadBookShelf( 0, $scope.books.length || 5 );
      }, function( ) {
        console.log( 'logOn: rejected', arguments );
      } );
    } );

    Book.load( 37027 ).then( function( book ) {
      console.log( book );
      book.getStructure( ).then( function( resolved ) {
        console.log( resolved );
      } );
    } );

    $scope.nextPage = function( ) {
      loadBookShelf( );
    };
  } ] );
