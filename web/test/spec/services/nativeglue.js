'use strict';

describe( 'Service: NativeGlue', function( ) {

  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var NativeGlue;
  beforeEach( inject( function( _NativeGlue_ ) {
    NativeGlue = _NativeGlue_;
  } ) );

  xit( 'should do something', function( ) {
    expect( !!NativeGlue ).toBe( true );
  } );

} );
