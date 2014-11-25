( function( ) {
  'use strict';

  /**
   * Dummy implementation of the lytBrigde object
   * API defined at https://github.com/Notalib/LYT/wiki/LYT3---POC
   **/

  if ( window.lytBridge ) {
    // Has already been created by the native layer
    return;
  }

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
  var books = {};

  // List of cached books
  // id => true
  var cachedBooks = {};

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
    },
    // Remove book from book list
    clearBook: function( bookId ) {
      delete books[ bookId ];
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
            offset: Math.max( books[ bookId ].offset || 0, 0 ),
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
        offset = books[ bookId ].offset || 0;
      }

      var lastTime = (new Date()) / 1000.0;
      playInterval = setInterval( function( ) {
        if ( !books[ bookId ] ) {
          window.lytBridge.stop( );
          return;
        }

        var curTime = (new Date()) / 1000.0;
        var timeDiff = curTime - lastTime;
        lastTime = curTime;

        offset += timeDiff;
        books[ bookId ].offset = Math.min( offset, books[ bookId ].duration );
        window.lytHandleEvent( 'play-time-update', bookId, offset );
        if ( books[ bookId ].offset >= books[ bookId ].duration ) {
          window.lytHandleEvent( 'play-end', bookId );
          clearInterval( playInterval );
        }
      }, 250 );
    },
    stop: function() {
      clearInterval( playInterval );
      window.lytHandleEvent( 'play-stop' );
    },
    pause: function( ) {
      clearInterval( playInterval );
      window.lytHandleEvent( 'play-stop' );
    },
    cacheBook: function( bookId ) {
      cachedBooks[ bookId ] = true;
    },
    clearBookCache: function( bookId ) {
      delete cachedBooks[ bookId ];
    }
  };
} )();
