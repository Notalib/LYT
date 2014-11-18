'use strict';

describe( 'Service: Section', function( ) {

  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var Section;
  beforeEach( inject( function( _Section_ ) {
    Section = _Section_;
  } ) );

  xit( 'should do something', function( ) {
    expect( !!Section ).toBe( true );
  } );

} );
