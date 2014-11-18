'use strict';

describe( 'Service: Book', function( ) {
  // load the service's module
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
      $provide.value( 'BookService', BookService );
    } );

    inject( function( _$rootScope_, _testData_, _Book_, _$httpBackend_ ) {
      rootScope = _$rootScope_;
      testData = _testData_.book;
      Book = _Book_;
      mockBackend = _$httpBackend_;
    } );
  } );

  xit( 'load book', function( ) {
    testData.resources
      .forEach( function( fileData ) {
        mockBackend.whenGET(fileData.URL).respond( fileData.content );
      } );

    var book;
    Book.load( testData.bookId )
      .then( function( _book_ ) {
        console.log( 'book loaded', _book_, testData.bookId );
        book = _book_;
      } ).catch( function( ) {
        console.log( 'Error', arguments );
      } );

    rootScope.$digest( );
    mockBackend.flush( );

    expect(book).not.toBeUndefined();
  } );
} );
