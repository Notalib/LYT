'use strict';

angular.module('lyt3App')
  .factory('BookService', [ '$q', '$rootScope', '$location', 'Book', 'BookNetwork', 'NativeGlue',
  function( $q, $rootScope, $location, Book, BookNetwork, NativeGlue ) {
    var currentBook;

    // Public API here
    var BookService = {
      get currentBook( ) {
        return currentBook;
      },

      set currentBook( book ) {
        currentBook = book;

        try {
          NativeGlue.setBook( book.structure );
        } catch ( exp ) {
        }
      },

      play: function( bookId, offset ) {
        if ( !bookId ) {
          if ( !currentBook ) {
            return;
          }

          if ( offset !== undefined ) {
            currentBook.currentPosition = offset;
          }

          NativeGlue.play( bookId, currentBook.currentPosition );
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

      ship: function( diff ) {
        if ( currentBook ) {
          BookService.play( currentBook.id, currentBook.currentPosition + diff );
        }
      },

      stop: function( ) {
        NativeGlue.stop( );
      },

      loadBook: function( bookId ) {
        var defered = $q.defer();

        if ( currentBook && currentBook.id === bookId ) {
          defered.resolve( currentBook );
          return defered.promise;
        }

        BookNetwork
          .withLogOn( function( ) {
            return Book.load( bookId );
          } )
            .then( function( book ) {
              defered.resolve( book );
              currentBook = book;

              try {
                NativeGlue.setBook( book.structure );
              } catch ( e ) {
              }
            } )
            .catch( function( ) {
              defered.reject( );
            } );

        return defered.promise;
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
