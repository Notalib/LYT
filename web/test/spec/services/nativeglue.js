'use strict';

describe( 'Service: Nativeglue', function( ) {

  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var Nativeglue;
  beforeEach( inject( function( _Nativeglue_ ) {
    Nativeglue = _Nativeglue_;
  } ) );

  it( 'should do something', function( ) {
    expect( !!Nativeglue ).toBe( true );
  } );

} );
