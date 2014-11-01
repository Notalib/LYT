'use strict';

describe( 'Service: DODP', function ( ) {

  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var DODP;
  beforeEach( inject( function ( _DODP_ ) {
    DODP = _DODP_;
  } ) );

  it( 'should do something', function ( ) {
    expect( !!DODP ).toBe( true );
  } );

} );