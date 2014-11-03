'use strict';

describe( 'Service: DODP', function ( ) {
  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var DODP;
  beforeEach( inject( function ( _DODP_ ) {
    DODP = _DODP_;
  } ) );

  it( 'logOn:', function ( ) {
    DODP.logOn( );
  } );

  it( 'logOff:', function ( ) {
    DODP.logOff( );
  } );

  xit( 'getServiceAttributes:', function ( ) {
    DODP.getServiceAttributes( );
  } );

  xit( 'setReadingSystemAttributes:', function ( ) {
    DODP.setReadingSystemAttributes( );
  } );

  xit( 'getServiceAnnouncements:', function ( ) {
    DODP.getServiceAnnouncements( );
  } );

  xit( 'markAnnouncementsAsRead:', function ( ) {
    DODP.markAnnouncementsAsRead( );
  } );
  xit( 'getContentList:', function ( ) {
    DODP.getContentList( );
  } );
  xit( 'issueContent:', function ( ) {
    DODP.issueContent( );
  } );
  xit( 'returnContent:', function ( ) {
    DODP.returnContent( );
  } );
  xit( 'getContentMetadata:', function ( ) {
    DODP.getContentMetadata( );
  } );
  xit( 'getContentResources:', function ( ) {
    DODP.getContentResources( );
  } );
  xit( 'getBookmarks:', function ( ) {
    DODP.getBookmarks( );
  } );
  xit( 'setBookmarks:', function ( ) {
    DODP.setBookmarks( );
  } );

} );
