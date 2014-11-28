/*global $ */
( function( ) {
  'use strict';

  if ( window.lytBridge ) {
    // Has already been created by the native layer
    return;
  }

  if ( /(iPhone|iPod|iPad).*AppleWebKit(?!.*Safari)/i.test( navigator.userAgent ) ) {
    ( function( ) {
      // Create iframe for signaling iOS-nativeglue
      var iframe;
      $( function( ) {
        iframe = $( '<iframe src="about:blank;"></iframe>' )
          .appendTo( document.body ).css( {
            position: 'absolute',
            top: -10000,
            left: -10000
          } );
      } );

      window.lytBridge = {
        _queue: [],
        _books: [], // should be updated by native app

        _sendCommand: function(commandName, payloadArray) {
          console.log(commandName, payloadArray);
          this._queue.push([commandName, payloadArray]);
          if ( iframe ) {
            iframe.attr( 'src', 'nota://signal?r=' + Math.random( ) );
          } else {
            window.open('nota://signal');
          }
        },

        _consumeCommands: function() {
          var result = JSON.stringify(this._queue);
          this._queue = [];
          return result;
        },

        setBook: function(bookData) {
          this._sendCommand('setBook', [bookData]);
        },

        clearBook: function(bookId) {
          this._sendCommand('clearBook', [bookId]);
        },
        getBooks: function() {
          return this._books;
        },

        play: function(bookId, offset) {
          var position = offset;
          if ( position === undefined ) {
            position = -1;
          }
          this._sendCommand('play', [bookId, position]);
        },

        stop: function() {
          this._sendCommand('stop', []);
        },

        cacheBook: function( bookId ) {
          this._sendCommand('cacheBook', [bookId]);
        },

        cancelBookCaching: function( bookId ) {
          this._sendCommand('cancelBookCaching', [bookId]);
        },

        clearBookCache: function( bookId ) {
          this._sendCommand('clearBookCache', [bookId]);
        }
      };
    })( );
  } else {
    ( function( ) {
      /**
       * Dummy implementation of the lytBrigde object
       * API defined at https://github.com/Notalib/LYT/wiki/LYT3---POC
       **/

      var getStoredVar = function( key ) {
        var res = window.localStorage.getItem( 'lydbridge:' + key );
        if ( res ) {
          return JSON.parse( res ) || {};
        }

        return {};
      };

      var storeVar = function( key, obj ) {
        window.localStorage.setItem( 'lydbridge:' + key, JSON.stringify( obj ) );
      };

      // Hash reference of the known books
      // id => {
      //   id: <ID>,
      //   title: <TITLE>,
      //   playlist: [ {
      //      URL: <MP3-url>,
      //      start: <start-offset-in-file>,
      //      end: <end-offset-in-file>
      //   } ],
      //   navigation: [ {
      //     offset: <absolute-offset-in-book>,
      //     title: <title>
      //   } ]
      // }
      var books = getStoredVar( 'books' );

      // List of cached books
      // id => true
      var cachedBooks = getStoredVar( 'cachedBooks' );

      // Book offset
      var booksOffset = getStoredVar( 'booksOffset' );

      // used for faking playback progress
      var playInterval;

      window.lytBridge = {
        // Add the bookdata
        setBook: function( bookData ) {
          if ( !bookData ) {
            return;
          }

          bookData = JSON.parse( bookData );
          if ( bookData && bookData.id ) {
            bookData.duration = bookData.playlist
              .reduce( function( res, item ) {
                res += ( item.end - item.start );
                return res;
              }, 0 );

            books[ bookData.id ] = bookData;
          }

          storeVar( 'books', books );
        },
        // Remove book from book list
        clearBook: function( bookId ) {
          delete books[ bookId ];
          delete cachedBooks[ bookId ];
          delete booksOffset[ bookId ];

          storeVar( 'books', books );
          storeVar( 'cachedBooks', cachedBooks );
          storeVar( 'booksOffset', booksOffset );
        },
        // Return a list of all known books:
        // [
        //  {
        //    id: <ID>,
        //    offset: <current-absolute-offset-in-book>,
        //    downloaded: <cachedBooks[<ID>]>
        //  }
        // ]
        getBooks: function( ) {
          return Object.keys(books)
            .map( function( bookId ) {
              return {
                id: bookId,
                offset: Math.max( booksOffset[ bookId ] || 0, 0 ),
                downloaded: !!cachedBooks[ bookId ]
              };
            } );
        },
        // Start playback, take bookId and offset.
        // If offset is undefined use the book's last known offset
        play: function( bookId, offset ) {
          if ( !books[ bookId ] ) {
            return;
          }

          clearInterval( playInterval );

          if ( offset === undefined ) {
            offset = booksOffset[ bookId ] || 0;
          }

          var lastTime = (new Date()) / 1000.0;
          playInterval = setInterval( function( ) {
            if ( !books[ bookId ] ) {
              window.lytBridge.stop( );
              return;
            }

            if ( !booksOffset[ bookId ] ) {
              booksOffset[ bookId ] = 0;
            }

            var curTime = (new Date()) / 1000.0;
            var timeDiff = curTime - lastTime;
            lastTime = curTime;

            offset += timeDiff;
            booksOffset[ bookId ] = Math.min( offset, books[ bookId ].duration );
            window.lytHandleEvent( 'play-time-update', bookId, offset );
            if ( booksOffset[ bookId ] >= books[ bookId ].duration ) {
              window.lytHandleEvent( 'play-end', bookId );
              clearInterval( playInterval );
            }

            storeVar( 'booksOffset', booksOffset );
          }, 250 );
        },
        stop: function() {
          clearInterval( playInterval );
          window.lytHandleEvent( 'play-stop' );
        },
        cacheBook: function( bookId ) {
          if ( !cachedBooks[ bookId ] ) {
            cachedBooks[ bookId ] = 0;
          }

          storeVar( 'cachedBooks', cachedBooks );
          var delay = 100;
          var wantedDuration = 30000;
          var numIteration = wantedDuration / delay;
          var increasePerIteration = numIteration / 100;
          var downloadInterval = setInterval( function( ) {
            if ( cachedBooks[ bookId ] === undefined ) {
              clearInterval( downloadInterval );
              return;
            }

            cachedBooks[ bookId ] += increasePerIteration;
            if ( cachedBooks[ bookId ] >= 100 ) {
              setTimeout( function( ) {
                window.lytHandleEvent( 'download-completed', bookId, ( new Date( ) ) / 1000 );
              }, delay );
              clearInterval( downloadInterval );

              cachedBooks[ bookId ] = 100;
            }
            window.lytHandleEvent( 'download-progress', bookId, cachedBooks[ bookId ] );

            storeVar( 'cachedBooks', cachedBooks );
          }, 100 );
        },
        cancelBookCaching: function( bookId ) {
          window.lytBridge.clearBookCache( bookId );

          window.lytHandleEvent( 'download-cancelled', bookId );
        },
        clearBookCache: function( bookId ) {
          delete cachedBooks[ bookId ];

          storeVar( 'cachedBooks', cachedBooks );
        }
      };

      setTimeout( function( ) {
        Object.keys(cachedBooks).forEach( function( bookid ) {
          window.lytBridge.cacheBook( bookid );
        } );
      }, 1000 );
    })();
  }
} )();
