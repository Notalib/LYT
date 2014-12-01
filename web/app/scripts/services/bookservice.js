'use strict';

angular.module('lyt3App')
  .factory('BookService', [ '$q', '$rootScope', '$location', '$interval', '$log', 'LYTConfig', 'Book', 'BookNetwork', 'NativeGlue',
  function( $q, $rootScope, $location, $interval, $log,  LYTConfig, Book, BookNetwork, NativeGlue ) {
    var currentBook;

    var getCurrentPOsition = function( ) {
      if ( !currentBook ) {
        return;
      }

      var bookData = NativeGlue.getBooks( ).filter( function( bookData ) {
        return bookData.id === currentBook.id;
      } ).pop();

      if ( bookData ) {
        currentBook.currentPosition = bookData.offset;
      }

      return currentBook.currentPosition;
    };

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
        if ( !currentBook || currentBook.id !== book.id ) {
          $log.info( 'BookService: set currentBook:', book.id );
          currentBook = book;

          NativeGlue.setBook( book.structure );
        }
      },

      play: function( bookId, offset ) {
        $log.info( 'BookService: play:', bookId, offset );
        if ( !bookId ) {
          if ( !currentBook ) {
            return;
          }

          if ( offset === undefined ) {
            offset = getCurrentPOsition( );
          }

          NativeGlue.play( currentBook.id, offset );
        } else if ( currentBook && currentBook.id === bookId ) {
          if ( offset === undefined ) {
            offset = getCurrentPOsition( );
          }

          NativeGlue.play( bookId, offset );
        } else {
          $log.info( 'BookService: play: loadBook', bookId, offset );

          BookService.loadBook( bookId )
            .then( function( book ) {
              BookService.currentBook = book;

              if ( offset === undefined ) {
                offset = getCurrentPOsition( );
              }

              NativeGlue.play( bookId, offset );
            } );
        }
      },

      skip: function( diff ) {
        if ( currentBook ) {
          $log.info( 'BookService: ship:', currentBook.id, diff, currentBook.currentPosition + diff );
          BookService.play( currentBook.id, currentBook.currentPosition + diff );
        }
      },

      restart: function( ) {
        if ( currentBook ) {
          $log.info( 'BookService: restart', currentBook.id );
          currentBook.currentPosition = 0;
          BookService.play( currentBook.id, 0 );
        }
      },

      stop: function( ) {
        $log.info( 'BookService: stop' );
        NativeGlue.stop( );
      },

      cacheBook: function( bookId ) {
        $log.info( 'BookService: cacheBook', bookId );

        var cachedBook = NativeGlue.getBooks( )
          .filter( function( bookData ) {
            return bookData.id === bookId;
          } ).pop();

        if ( cachedBook ) {
          NativeGlue.cacheBook( '' + bookId );
        } else {
          $log.info( 'BookService: cacheBook: not set yet', bookId );

          BookService.loadBook( bookId )
            .then( function( ) {
              NativeGlue.cacheBook( '' + bookId );
            } );
        }
      },

      cancelBookCaching: function( bookId ) {
        var cachedBook = NativeGlue.getBooks( )
          .filter( function( bookData ) {
            return bookData.id === bookId;
          } ).pop();

        if ( cachedBook ) {
          NativeGlue.cancelBookCaching( '' + bookId );
        }
      },

      clearBookCache: function( bookId ) {
        var cachedBook = NativeGlue.getBooks( )
          .filter( function( bookData ) {
            return bookData.id === bookId;
          } ).pop();

        if ( cachedBook ) {
          NativeGlue.clearBookCache( '' + bookId );
        }
      },

      loadBook: function( bookId ) {
        var deferred = $q.defer();

        if ( currentBook && currentBook.id === bookId ) {
          $log.info( 'BookService: loadBook, already loaded', bookId );
          deferred.resolve( currentBook );
          return deferred.promise;
        }

        $log.info( 'BookService: loadBook', bookId );

        BookNetwork
          .withLogOn( function( ) {
            return Book.load( bookId );
          } )
            .then( function( book ) {
              deferred.resolve( book );
              BookService.currentBook = book;

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

      playing: false
    };

    $rootScope.$on( 'play-time-update', function( $currentScope, bookId, offset ) {
      if ( !currentBook || currentBook.id !== bookId ) {
        if ( $location.path( ).indexOf( 'book-player' ) > -1 ) {
          var bookPath = '/book-player/' + bookId;
          $location.path( bookPath );
          BookService.playing = true;
          $log.info( 'BookService: play-time-update: location is book-player but different', bookId, offset );
        } else {
          $log.info( 'BookService: play-time-update: location different from book-player', bookId, offset );
          BookService.loadBook( bookId )
            .then( function( book ) {
              book.currentPosition = offset;
              BookService.playing = true;
            } );
        }
      } else {
        currentBook.currentPosition = offset;
        BookService.playing = true;
      }
    } );

    $rootScope.$on( 'play-stop', function( $currentScope, bookId ) {
      if ( currentBook && currentBook.id === bookId ) {
        BookService.playing = false;
      }
    } );

    $rootScope.$on( 'play-end', function( $currentScope, bookId ) {
      if ( currentBook && currentBook.id === bookId ) {
        BookService.playing = false;
        currentBook.currentPosition = currentBook.duration;
      }
    } );

    return BookService;
  }] );
