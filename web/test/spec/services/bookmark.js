'use strict';

describe( 'Service: Bookmark', function( ) {

  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var Bookmark;
  beforeEach( inject( function( _Bookmark_ ) {
    Bookmark = _Bookmark_;
  } ) );

  it( 'Create bookmark', function( ) {
    var data = {
      note: {
        'text': 'Om denne udgave'
      },
      URI: 'dcbw0002.smil#sfe_par_0002_0003',
      timeOffset: 0,
      hugo: 'boerge'
    };

    var bookmark = new Bookmark( data );
    expect(bookmark.URI).toEqual(data.URI);
    expect(bookmark.timeOffset).toEqual(data.timeOffset);
    expect(bookmark.note.text).toEqual(data.note.text);
    expect(bookmark.hugo).toBeUndefined( );
  } );

} );
