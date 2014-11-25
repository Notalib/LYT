'use strict';

describe( 'Service: Book', function( ) {
  // load the service's module
  beforeEach( module( 'lyt3App' ) );
  beforeEach( module( 'lytTest' ) );

  // instantiate service
  var testData;
  var rootScope;
  var BookNetwork;
  var Book;
  var mockBackend;

  beforeEach( function( ) {
    // Mock the BookNetwork, so we don't have to mock every single DODP-request
    BookNetwork = angular
      .injector( [ 'lytTest', 'ng' ] )
      .get( 'mockBookService' );

    module( 'lyt3App', function( $provide ) {
      // $provide.value( '$log', console ); // Uncomment this to get $log in angular to log to karma+jasmine tests, for debugging
      $provide.value( 'BookNetwork', BookNetwork );
    } );

    inject( function( _$rootScope_, _testData_, _Book_, _$httpBackend_ ) {
      rootScope = _$rootScope_;
      testData = _testData_.book;
      Book = _Book_;
      mockBackend = _$httpBackend_;
    } );
  } );

  // To test create and load a book, the test are written accumalative.
  //
  // So the first test's helper-function simply creates the book object,
  // the second test's helper-function calls the first to be the book object.
  //
  // All these test-helper functions must return the book object and should
  // take a callback function, except the first one.

  // Create the book object.
  var createBook = function( ) {
    return new Book( testData.bookId );
  };

  it( 'Create book', function( ) {
    var book = createBook( );
    expect(book).not.toBeUndefined();
  } );

  // Ask the server to issue the book, the callback-function
  // is called with the boolena status
  //
  // Book object is returned for the net function
  var issueBook = function( callback ) {
    var book = createBook( );

    book.issue( )
      .then( function( ) {
        // Book issue resolved, tell the callback function.
        callback( true );
      } )
      .catch( function( ) {
        callback( false );
      } );

    return book;
  };

  it( 'Issue book', function( ) {
    var issued;
    runs( function() {
      issueBook( function( status ) {
        issued = status;
      } );
    } );

    waitsFor( function( ) {
      // deferred are resolved in the digest loop,
      // so without this deferred are never resolved.
      rootScope.$digest( );

      return issued === true;
    }, 'Book to be issued', 1000 );
  } );

  // Get contentResources via DODP, without this book content
  // can't be loaded.
  var loadResources = function( callback ) {
    // Depends on issueBook to have been performed.
    var book = issueBook( function( ) {
      book.loadResources()
        .then( function( ) {
          callback( true );
        } )
        .catch( function( ) {
          callback( false );
        } );
    } );

    return book;
  };

  it( 'load resources', function( ) {
    var loadedResources;

    runs( function() {
      loadResources( function( status ) {
        loadedResources = status;
      } );
    } );

    waitsFor( function( ) {
      rootScope.$digest( );
      return loadedResources === true;
    }, 'Book to be ', 1000 );
  } );

  // Load bookmarks via DODP
  var loadBookmarks = function( callback ) {
    var book = loadResources( function( ) {
      book.loadBookmarks()
        .then( function( ) {
          callback( true );
        } )
        .catch( function( ) {
          callback( false );
        } );
    } );

    return book;
  };

  it( 'load bookmarks', function( ) {
    var gotBookmarks;
    runs( function( ) {
      loadBookmarks( function( status ) {
        gotBookmarks = status;
      } );
    } );

    waitsFor( function( ) {
      rootScope.$digest( );
      return gotBookmarks === true;
    }, 'load bookmarks', 1000 );
  } );

  var loadNCC = function( callback ) {
    var book = loadResources( function( ) {
      // Mock the ajax request for ncc.html
      var fileData = testData.resources[ 'ncc.html' ];
      mockBackend
        .whenGET( fileData.URL )
        .respond( fileData.content );
      book.loadNCC()
        .then( function( nccDocument ) {
          callback( !!nccDocument );
        } )
        .catch( function( ) {
          callback( false );
        } );
    } );

    return book;
  };

  it( 'loadNCC', function( ) {
    var gotNCC;

    runs( function( ) {
      loadNCC( function( status ) {
        gotNCC = status;
      } );
    } );

    waitsFor( function( ) {
      rootScope.$digest( );
      try {
        // Flush the ajax request.
        mockBackend.flush( );
      } catch ( exp ) {
        // flush throws an error is the request hasn't been started yet.
      }
      return gotNCC === true;
    }, 'load NCC', 1000 );
  } );

  // Download the full book structure
  var getStructure = function( callback ) {
    // This depends on loadNCC or the book won't have the navigation structure
    var book = loadNCC( function( ) {
      // Mock all the ajax requests for loading the full book structure
      Object.keys( testData.resources )
        .filter( function( fileName ) {
          return !/\.mp3$/.test(fileName) && fileName !== 'ncc.html';
        } )
        .forEach( function( fileName ) {
          var fileData = testData.resources[ fileName ];
          mockBackend
            .whenGET( fileData.URL )
            .respond( fileData.content );
        } );

      book.getStructure( )
        .then( function( resolved ) {
          callback( resolved );
        } )
        .catch( function( ) {
          callback( false );
        } );
    } );

    return book;
  };

  it( 'get full structure', function( ) {
    var structure;
    var book;
    runs( function( ) {
      book = getStructure( function( loadedStructure ) {
        structure = loadedStructure;
      } );
    } );

    waitsFor( function( ) {
      rootScope.$digest( );
      try {
        mockBackend.flush( );
      } catch ( exp ) {
        // flush throws an error is the request hasn't been started yet
      }

      return structure && structure.playlist.length && structure.navigation.length && structure.id === book.id;
    }, 'Structure loaded', 1000 );
  } );

  var findSegmentFromOffset = function( offset, callback ) {
    var book = getStructure( function( ) {
      book.findSegmentFromOffset( offset )
        .then( function( segment ) {
          callback( segment );
        } )
        .catch( function( ) {
          callback( false );
        } );
    } );

    return book;
  };

  var setLastmark = function( offset, callback ) {
    var book = getStructure( function( ) {
      book.currentPosition = offset;
      book.setLastmark( )
        .then( function( status ) {
          callback( status );
        } )
        .catch( function( ) {
          callback( );
        } );
    } );

    return book;
  };

  [ 0, 101, 3500, 5811.1 ].forEach( function( offset ) {
    it( 'find segment from offset: ' + offset, function( ) {
      var resolved;
      runs( function( ) {
        findSegmentFromOffset( offset, function( segment ) {
          resolved = segment;
        } );
      } );

      waitsFor( function( ) {
        try {
          rootScope.$digest( );
        } catch ( exp ) {
          // flush throws an error is the request hasn't been started yet
        }

        try {
          mockBackend.flush( );
        } catch ( exp ) {
          // flush throws an error is the request hasn't been started yet
        }

        return resolved && ( resolved.documentOffset + resolved.document.absoluteOffset ) <= offset && ( resolved.documentOffset + resolved.document.absoluteOffset + resolved.duration ) >= offset;
      }, '', 1000 );
    } );

    it( 'setLastmark', function( ) {
      var resolved;
      runs( function( )  {
        setLastmark( offset, function( segment ) {
          resolved = segment;
        } );
      } );

      waitsFor( function( ) {
        try {
          rootScope.$digest( );
        } catch ( exp ) {
          // flush throws an error is the request hasn't been started yet
        }

        try {
          mockBackend.flush( );
        } catch ( exp ) {
          // flush throws an error is the request hasn't been started yet
        }

        return resolved !== undefined;
      }, '', 1000 );
    } );
  } );
} );
