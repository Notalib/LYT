'use strict';

describe( 'Service: Segment', function( ) {

  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var Segment;
  beforeEach( inject( function( _Segment_ ) {
    Segment = _Segment_;
  } ) );

  xit( 'should do something', function( ) {
    expect( !!Segment ).toBe( true );
  } );

} );
