'use strict';

describe( 'Service: TextContentDocument', function( ) {

  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var TextContentDocument;
  beforeEach( inject( function( _TextContentDocument_ ) {
    TextContentDocument = _TextContentDocument_;
  } ) );

  xit( 'should do something', function( ) {
    expect( !!TextContentDocument ).toBe( true );
  } );

} );
