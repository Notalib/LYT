'use strict';

describe( 'Service: Book', function( ) {
  // load the service's module
  beforeEach( module( 'lyt3App' ) );
  beforeEach( module( 'lytTest' ) );

  // instantiate service
  var testData;
  var rootScope;
  var BookService;
  var Book;
  var mockBackend;

  beforeEach( function( ) {
    BookService = angular
      .injector( [ 'lytTest', 'ng' ] )
      .get( 'mockBookService' );

    module( 'lyt3App', function( $provide ) {
      $provide.value( '$log', console );
      $provide.value( 'BookService', BookService );
    } );

    inject( function( _$rootScope_, _testData_, _Book_, _$httpBackend_ ) {
      rootScope = _$rootScope_;
      testData = _testData_.book;
      Book = _Book_;
      mockBackend = _$httpBackend_;
    } );
  } );

  var createBook = function( ) {
    return new Book( testData.bookId );
  };

  it( 'Create book', function( ) {
    var book = createBook( );
    expect(book).not.toBeUndefined();
  } );

  var issueBook = function( callback ) {
    var book = createBook( );

    book.issue( )
      .then( function( ) {
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
      rootScope.$digest( );
      return issued === true;
    }, 'Book to be issued', 10000 );
  } );

  var loadResources = function( callback ) {
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
      book.loadNCC()
        .then( function( nccDocument ) {
          callback( !!nccDocument );
        } )
        .catch( function( ) {
          console.log( arguments );
          callback( false );
        } );
    } );
  };

  it( 'loadNCC', function( ) {
    var gotNCC;
    var fileData = testData.resources[ 'ncc.html' ];
    mockBackend
      .whenGET( fileData.URL )
      .respond( fileData.content );

    runs( function( ) {
      loadNCC( function( status ) {
        gotNCC = status;
      } );
    } );

    waitsFor( function( ) {
      rootScope.$digest( );
      try {
        mockBackend.flush( );
      } catch ( exp ) {
        // flush throws an error is the request hasn't been started yet
      }
      return gotNCC === true;
    }, 'load NCC', 1000 );
  } );
} );
