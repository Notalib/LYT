'use strict';

describe( 'Service: Book', function( ) {
  // load the service's module
  beforeEach( module( 'lyt3App' ) );
  beforeEach( module( 'lytTest' ) );

  // instantiate service
  var Book;
  var testData;
  var rootScope;
  beforeEach( inject( function( _$rootScope_, _Book_, _testData_ ) {
    rootScope = _$rootScope_;
    Book = _Book_;
    testData = _testData_.book;
  } ) );

  xit( 'should do something', function( ) {
    Book.load( testData.bookId ).then( function( book ) {
      console.log( book );
    } );

    rootScope.$digest( );
  } );
} );
