'use strict';

describe( 'Service: LYTUtils', function( ) {

  // load the service's module
  beforeEach( module( 'lyt3App' ) );

  // instantiate service
  var LYTUtils;
  beforeEach( inject( function( _LYTUtils_ ) {
    LYTUtils = _LYTUtils_;
  } ) );

  var timeData = {
    0: '0:00:00',
    10: '0:00:10',
    6661: '1:51:01'
  };

  it( 'formatTime', function( ) {
    Object.keys( timeData ).forEach( function( input ) {
      var res = timeData[ input ];

      expect(LYTUtils.formatTime(input)).toBe(res);
    });
  } );

  it( 'parseTime:', function( ) {
    Object.keys( timeData ).forEach( function( res ) {
      var input = timeData[ res ];

      expect(LYTUtils.parseTime(input)).toBe(Number(res));
    });
  } );

  it( 'toSentence:', function( ) {
    var str = 'Hugo';
    expect(LYTUtils.toSentence([str])).toBe(str);
    expect(LYTUtils.toSentence([str,str])).toBe(str + ' & ' + str);
    expect(LYTUtils.toSentence([str,str,str])).toBe(str + ', ' + str + ' & ' + str);
  } );

  it( 'toXML:', function( ) {
    expect( LYTUtils.toXML( {
      hej: {
        hugo: 1
      }
    } ) ).toBe( '<ns1:hej><ns1:hugo>1</ns1:hugo></ns1:hej>' );
  } );
} );
