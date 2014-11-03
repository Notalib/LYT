'use strict';

describe( 'Service: DODPStatus', function ( ) {

  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var DODPStatus;
  beforeEach( inject( function ( _DODPStatus_ ) {
    DODPStatus = _DODPStatus_;
  } ) );

  it( 'should do something', function ( ) {
    expect( !!DODPStatus ).toBe( true );
  } );

} );
