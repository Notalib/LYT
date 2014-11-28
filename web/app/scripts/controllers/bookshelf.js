'use strict';

angular.module( 'lyt3App' )
  .controller( 'BookshelfCtrl', [ '$log', '$timeout', '$scope', 'BookNetwork', 'BookService',
  function( $log, $timeout, $scope, BookNetwork, BookService ) {
    var uniqueItems = function( items ) {
      // Angular doesn't like duplicates
      var unique = {};
      return items.filter( function( item ) {
        if ( !item ) {
          $log.warn( 'loadBookShelf: unique item: got undefined value'  );
          return false;
        }

        if ( !unique[ item.id ] ) {
          unique[ item.id ] = true;
          return true;
        }

        $log.warn( 'loadBookShelf: unique item: ' + item.id + ' is a duplicate', item );
        return false;
      } );
    };

    $scope.cacheBook = function( $event, bookid ) {
      $event.stopPropagation( );
      $event.preventDefault( );

      BookService.cacheBook( bookid );
      $scope.books.some( function( book ) {
        if ( book.id === bookid ) {
          delete book.downloaded;
          book.downloading = 0.1;
        }
      } );
    };

    $scope.clearBookCache = function( $event, bookid ) {
      $event.stopPropagation( );
      $event.preventDefault( );

      BookService.clearBookCache( bookid );
      $scope.books.some( function( book ) {
        if ( book.id === bookid ) {
          delete book.downloading;
          delete book.downloaded;
        }
      } );
    };

    $scope.cancelBookCaching = function( $event, bookid ) {
      $event.stopPropagation( );
      $event.preventDefault( );

      BookService.cancelBookCaching( bookid );
      $scope.books.some( function( book ) {
        if ( book.id === bookid ) {
          delete book.downloading;
          delete book.downloaded;
        }
      } );
    };

    $scope.books = uniqueItems( BookNetwork.getCachedBookShelf( ) );

    var loadBookShelf = function( from, count ) {
      if ( from === undefined ) {
        from = $scope.books.length;
      }

      from = Math.max( 0, from );

      count = Math.max( count || 0, 5 );

      var to = from + count - 1;

      return BookNetwork.getBookshelf( from, to )
        .then( function( items ) {
          $scope.books = uniqueItems( items );
        } );
    };

    loadBookShelf( 0, $scope.books.length || 5 ).catch( function( ) {
      BookNetwork.logOn( 'guest', 'guest' ).then( function( ) {
        loadBookShelf( 0, $scope.books.length || 5 );
      }, function( ) {
        $log.error( 'logOn: rejected', arguments );
      } );
    } );

    $scope.nextPage = function( ) {
      loadBookShelf( );
    };

    $scope.$on( 'download-progress', function( $currentScope, bookid, procent ) {
      $scope.books.some( function( book ) {
        if ( book.id === bookid ) {
          book.downloading = procent;
          return true;
        }
      } );
    } );

    $scope.$on( 'download-cancelled', function( $currentScope, bookid ) {
      $scope.books.some( function( book ) {
        if ( book.id === bookid ) {
          delete book.downloading;
          return true;
        }
      } );
    } );

    $scope.$on( 'download-completed', function( $currentScope, bookid ) {
      $scope.books.some( function( book ) {
        if ( book.id === bookid ) {
          $timeout( function( ) {
            book.downloaded = true;
          }, 250 );
          return true;
        }
      } );
    } );
  } ] );
