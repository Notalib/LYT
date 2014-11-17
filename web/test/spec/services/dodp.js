'use strict';

describe( 'Service: DODP', function( ) {
  // load the service's module
  beforeEach( module( 'lyt3App' ) );
  beforeEach( module( 'lytTest' ) );

  // instantiate service
  var DODP;
  var $rootScope;
  var mockBackend;
  var expectPOST;
  var testData;
  beforeEach( inject( function( _$rootScope_, _DODP_, _$httpBackend_,
    _testData_ ) {
    $rootScope = _$rootScope_;
    DODP = _DODP_;
    mockBackend = _$httpBackend_;
    expectPOST = mockBackend.expectPOST( '/DodpMobile/Service.svc' );
    testData = _testData_.dodp;
  } ) );

  var createExpectXML = function( respond ) {
    expectPOST.respond( respond, {
      'Content-Type': 'text/xml'
    } );
  };

  describe( 'logOn:', function( ) {
    var logOnData;
    beforeEach( function( ) {
      logOnData = testData.logOnData;
    } );

    it( 'valid logOn:', function( ) {
      var status;
      var data = logOnData.valid;
      var params = data.params;
      createExpectXML( data.respond );

      DODP.logOn( params.username, params.password )
        .then( function( resolved ) {
          expect( resolved ).toEqual( data.resolved );
          status = 'success';
        }, function( ) {
          status = 'failed';
        } );

      mockBackend.flush( );
      $rootScope.$digest( );

      expect( status )
        .toEqual( 'success' );
    } );
  } );

  it( 'logOff:', function( ) {
    var status;
    var data = testData.logOffData;
    createExpectXML( data.respond );
    DODP.logOff( )
      .then( function( resolved ) {
        expect( resolved ).toEqual( data.resolved );
        status = 'success';
      }, function( ) {
        status = 'failed';
      } );


    mockBackend.flush( );
    $rootScope.$digest( );
    expect( status )
      .toEqual( 'success' );
  } );

  it( 'getServiceAttributes:', function( ) {
    var status;
    var data = testData.getServiceAttributesData;
    createExpectXML( data.respond );
    DODP.getServiceAttributes( )
      .then( function( resolved ) {
        expect( resolved ).toEqual( data.resolved );
        status = 'success';
      }, function( ) {
        status = 'failed';
      } );
    mockBackend.flush( );
    $rootScope.$digest( );
    expect( status )
      .toEqual( 'success' );
  } );

  it( 'setReadingSystemAttributes:', function( ) {
    var status;
    var data = testData.setReadingSystemAttributesData;
    var params = data.params;
    createExpectXML( data.respond );

    DODP.setReadingSystemAttributes( params.readingSystemAttributes )
      .then( function( ) {
        status = 'success';
      }, function( ) {
        status = 'failed';
      } );
    mockBackend.flush( );
    $rootScope.$digest( );
    expect( status )
      .toEqual( 'success' );
  } );

  it( 'getServiceAnnouncements:', function( ) {
    var status;
    var data = testData.getServiceAnnouncementsData;
    createExpectXML( data.respond );

    DODP.getServiceAnnouncements( )
      .then( function( resolved ) {
        expect( resolved ).toEqual( data.resolved );
        status = 'success';
      }, function( ) {
        status = 'failed';
      } );
    mockBackend.flush( );
    $rootScope.$digest( );
    expect( status )
      .toEqual( 'success' );
  } );

  xit( 'markAnnouncementsAsRead:', function( ) {
    var status;
    DODP.markAnnouncementsAsRead( )
      .then( function( ) {
        status = 'success';
      }, function( ) {
        status = 'failed';
      } );
    mockBackend.flush( );
    $rootScope.$digest( );
    expect( status )
      .toEqual( 'success' );
  } );

  it( 'getContentList:', function( ) {
    var status;
    var data = testData.getContentListData;
    var params = data.params;
    createExpectXML( data.respond );

    DODP.getContentList( params.listIdentifier, params.firstTime, params.lastItem )
      .then( function( resolved ) {
        expect( resolved ).toEqual( data.resolved );
        status = 'success';
      }, function( ) {
        status = 'failed';
      } );
    mockBackend.flush( );
    $rootScope.$digest( );
    expect( status )
      .toEqual( 'success' );
  } );

  it( 'issueContent:', function( ) {
    var status;
    var data = testData.issueContentData;
    var params = data.params;
    createExpectXML( data.respond );

    DODP.issueContent( params.contentId )
      .then( function( ) {
        status = 'success';
      }, function( ) {
        status = 'failed';
      } );
    mockBackend.flush( );
    $rootScope.$digest( );
    expect( status )
      .toEqual( 'success' );
  } );

  xit( 'returnContent:', function( ) {
    var status;
    DODP.returnContent( )
      .then( function( ) {
        status = 'success';
      }, function( ) {
        status = 'failed';
      } );
    mockBackend.flush( );
    $rootScope.$digest( );
    expect( status )
      .toEqual( 'success' );
  } );

  xit( 'getContentMetadata:', function( ) {
    var status;
    DODP.getContentMetadata( )
      .then( function( ) {
        status = 'success';
      }, function( ) {
        status = 'failed';
      } );
    mockBackend.flush( );
    $rootScope.$digest( );
    expect( status )
      .toEqual( 'success' );
  } );

  it( 'getContentResources:', function( ) {
    var status;
    var data = testData.getContentResourcesData;
    var params = data.params;
    createExpectXML( data.respond );

    DODP.getContentResources( params.contentId )
      .then( function( resolved ) {
        expect( resolved ).toEqual( data.resolved );
        status = 'success';
      }, function( ) {
        status = 'failed';
      } );
    mockBackend.flush( );
    $rootScope.$digest( );
    expect( status )
      .toEqual( 'success' );
  } );

  it( 'getBookmarks:', function( ) {
    var status;
    var data = testData.getBookmarksData;
    var params = data.params;
    createExpectXML( data.respond );
    DODP.getBookmarks( params.contentId )
      .then( function( resolved ) {
        expect( resolved ).toEqual( data.resolved );
        status = 'success';
      }, function( ) {
        status = 'failed';
      } );
    mockBackend.flush( );
    $rootScope.$digest( );
    expect( status )
      .toEqual( 'success' );
  } );

  xit( 'setBookmarks:', function( ) {
    var status;
    DODP.setBookmarks( )
      .then( function( ) {
        status = 'success';
      }, function( ) {
        status = 'failed';
      } );
    mockBackend.flush( );
    $rootScope.$digest( );
    expect( status )
      .toEqual( 'success' );
  } );

} );
