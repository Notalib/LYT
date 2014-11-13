'use strict';

describe( 'Service: Bookmark', function( ) {

  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var Bookmark;
  beforeEach( inject( function( _Bookmark_ ) {
    Bookmark = _Bookmark_;
  } ) );

  it( 'should do something', function( ) {
    expect( !!Bookmark ).toBe( true );
  } );

} );
