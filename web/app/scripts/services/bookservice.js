'use strict';

angular.module('lyt3App')
  .factory('BookService', [ '$q', '$rootScope', '$location', '$interval', 'LYTConfig', 'Book', 'BookNetwork', 'NativeGlue',
  function( $q, $rootScope, $location, $interval, LYTConfig, Book, BookNetwork, NativeGlue ) {
    var currentBook;

    $interval( function( ) {
      if ( currentBook ) {
        currentBook.setLastmark( );
      }
    }, LYTConfig.player.lastmarkUpdateInterval || 10000 );

    // Public API here
    var BookService = {
      get currentBook( ) {
        return currentBook;
      },

      set currentBook( book ) {
        currentBook = book;

        NativeGlue.setBook( book.structure );
      },

      play: function( bookId, offset ) {
        if ( !bookId ) {
          if ( !currentBook ) {
            return;
          }

          if ( offset !== undefined ) {
            currentBook.currentPosition = offset;
          }

          NativeGlue.play( currentBook.id, currentBook.currentPosition );
        } else if ( currentBook && currentBook.id === bookId ) {
          if ( offset !== undefined ) {
            currentBook.currentPosition = offset;
          }

          NativeGlue.play( bookId, currentBook.currentPosition );
        } else {
          BookService.loadBook( bookId )
            .then( function( book ) {
              BookService.currentBook( book );

              if ( offset !== undefined ) {
                currentBook.currentPosition = offset;
              }

              NativeGlue.play( bookId, offset );
            } );
        }
      },

      skip: function( diff ) {
        if ( currentBook ) {
          BookService.play( currentBook.id, currentBook.currentPosition + diff );
        }
      },

      stop: function( ) {
        NativeGlue.stop( );
      },

      pause: function( ) {
        NativeGlue.pause( );
      },

      loadBook: function( bookId ) {
        var deferred = $q.defer();

        if ( currentBook && currentBook.id === bookId ) {
          deferred.resolve( currentBook );
          return deferred.promise;
        }

        BookNetwork
          .withLogOn( function( ) {
            return Book.load( bookId );
          } )
            .then( function( book ) {
              deferred.resolve( book );
              BookService.currentBook = book;

              NativeGlue.setBook( book.structure );

              NativeGlue.getBooks( )
                .some( function( bookData ) {
                  if ( bookData.id === book.id ) {
                    book.currentPosition = Math.max( bookData.offset || 0, book.currentPosition || 0, 0 );
                    return true;
                  }
                } );
            } )
            .catch( function( ) {
              deferred.reject( );
            } );

        return deferred.promise;
      },
    };

    $rootScope.$on( 'play-time-update', function( $currentScope, bookId, offset ) {
      if ( !currentBook || currentBook.id !== bookId ) {
        if ( $location.path( ).indexOf( 'book-player' ) > -1 ) {
          var bookPath = '/book-player/' + bookId;
          $location.path( bookPath );
        } else {
          BookService.loadBook( bookId )
            .then( function( book ) {
              book.currentPosition = offset;
            } );
        }
      } else {
        currentBook.currentPosition = offset;
      }
    } );

    return BookService;
  }] );
