'use strict';

describe( 'Service: DODPErrorCodes', function( ) {

  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var DODPErrorCodes;
  beforeEach( inject( function( _DODPErrorCodes_ ) {
    DODPErrorCodes = _DODPErrorCodes_;
  } ) );

  describe( 'identifyDODPError:', function( ) {
    it( 'internalServerError', function( ) {
      var res = DODPErrorCodes.identifyDODPError( 'internalServerError' );

      expect(res).toBe(DODPErrorCodes.DODP_INTERNAL_ERROR);
    } );

    it( 'unknown', function( ) {
      var res = DODPErrorCodes.identifyDODPError( 'some weird error code' );

      expect(res).toBe(DODPErrorCodes.DODP_UNKNOWN_ERROR);
    } );
  } );
} );
