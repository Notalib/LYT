'use strict';

describe( 'Service: BookNetwork', function( ) {
  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var BookNetwork;
  beforeEach( inject( function( _BookService_ ) {
    BookNetwork = _BookService_;
  } ) );

  xit( 'should do something', function( ) {
    expect( !!BookNetwork ).toBe( true );
  } );
} );
