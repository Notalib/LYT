'use strict';

describe( 'Service: NCCDocument', function( ) {

  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var NCCDocument;
  beforeEach( inject( function( _NCCDocument_ ) {
    NCCDocument = _NCCDocument_;
  } ) );

  xit( 'should do something', function( ) {
    expect( !!NCCDocument ).toBe( true );
  } );

} );
