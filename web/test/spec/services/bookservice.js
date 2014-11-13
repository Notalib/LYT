'use strict';

describe( 'Service: BookService', function( ) {
  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var BookService;
  beforeEach( inject( function( _BookService_ ) {
    BookService = _BookService_;
  } ) );

  it( 'should do something', function( ) {
    expect( !!BookService ).toBe( true );
  } );
} );
