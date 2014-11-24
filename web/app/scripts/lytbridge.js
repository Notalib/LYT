( function( ) {
  'use strict';

  if ( window.lytBridge ) {
    return;
  }


  var books = {};

  var cachedBooks = {};

  var playInterval;

  window.lytBridge = {
    setBook: function( bookData ) {
      if ( !bookData ) {
        return;
      }

      bookData = JSON.parse( bookData );
      if ( bookData && bookData.id ) {
        books[ bookData.id ] = bookData;
      }
    },
    clearBook: function( bookId ) {
      delete books[ bookId ];
    },
    getBooks: function( ) {
      return Object.keys(books)
        .map( function( bookId ) {
          return {
            id: bookId,
            offset: Math.max( books[ bookId ].offset || 0, 0 ),
            downloaded: !!cachedBooks[ bookId ]
          };
        } );
    },
    play: function( bookId, offset ) {
      clearInterval( playInterval );

      var start = (new Date()) / 1000.0;
      playInterval = setInterval( function( ) {
        if ( !books[ bookId ] ) {
          window.lytBridge.stop( );
          return;
        }

        var timeDiff = (new Date()) / 1000.0 - start;
        offset += timeDiff;
        books[ bookId ].offset = offset;
        window.lytHandleEvent( 'play-time-update', bookId, offset );
      }, 250 );
    },
    stop: function() {
      clearInterval( playInterval );
    },
    pause: function( ) {
      window.lytBridge.stop( );
    },
    cacheBook: function( bookId ) {
      cachedBooks[ bookId ] = true;
    },
    clearBookCache: function( bookId ) {
      delete cachedBooks[ bookId ];
    }
  };
} )();
