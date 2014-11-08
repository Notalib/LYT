'use strict';

try {
  angular.module( 'lytTest' );
} catch ( err ) {
  angular.module( 'lytTest', [ ] );
}

angular.module( 'lytTest', [ 'lytTestUser' ] )
  .factory( 'testData', [ 'testDataLocal',
    function ( testDataLocal ) {
      var DODPVERSION = 'Dummy=1.0.0';
      var testUser = testDataLocal.user;

      var logOn = {
        valid: {
          params: {
            username: testUser.username,
            password: testUser.password,
          },
          respond: '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Header><MemberId xmlns="http://www.daisy.org/ns/daisy-online/">' +
            testUser.memberId +
            '</MemberId><Username xmlns="http://www.daisy.org/ns/daisy-online/">' +
            testUser.username +
            '</Username><Realname xmlns="http://www.daisy.org/ns/daisy-online/">' +
            testUser.realname +
            '</Realname><Email xmlns="http://www.daisy.org/ns/daisy-online/">user@user.nu</Email><Address xmlns="http://www.daisy.org/ns/daisy-online/" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/><Age xmlns="http://www.daisy.org/ns/daisy-online/">90</Age><Gender xmlns="http://www.daisy.org/ns/daisy-online/">FEMALE</Gender><Teacher xmlns="http://www.daisy.org/ns/daisy-online/">0</Teacher><Usergroup xmlns="http://www.daisy.org/ns/daisy-online/">Blind</Usergroup><VersionInfo xmlns="http://www.daisy.org/ns/daisy-online/">' +
            DODPVERSION +
            '</VersionInfo><EnvironmentInfo xmlns="http://www.daisy.org/ns/daisy-online/">TEST</EnvironmentInfo></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><logOnResponse xmlns="http://www.daisy.org/ns/daisy-online/"><logOnResult>true</logOnResult></logOnResponse></s:Body></s:Envelope>'
        }
      };

      var logOff = {
        params: {},
        respond: '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Header><Username xmlns="http://www.e17.dk" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><Realname xmlns="http://schemas.datacontract.org/2004/07/NotaSecureInterface">none</Realname><TypeOfMember xmlns="http://schemas.datacontract.org/2004/07/NotaSecureInterface">PHYSICAL</TypeOfMember><Username xmlns="http://schemas.datacontract.org/2004/07/NotaSecureInterface">' +
          testUser.username +
          '</Username><Value xmlns="http://schemas.datacontract.org/2004/07/NotaSecureInterface">' +
          testUser.password +
          '</Value></Username><VersionInfo xmlns="http://www.daisy.org/ns/daisy-online/">' +
          DODPVERSION +
          '</VersionInfo><EnvironmentInfo xmlns="http://www.daisy.org/ns/daisy-online/">TEST</EnvironmentInfo></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><logOffResponse xmlns="http://www.daisy.org/ns/daisy-online/"><logOffResult>true</logOffResult></logOffResponse></s:Body></s:Envelope>'
      };

      var getServiceAttributes = {
        params: {},
        respond: '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Header><MemberId xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.username +
          '</MemberId><Username xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.username +
          '</Username><Realname xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.realname +
          '</Realname><Email xmlns="http://www.daisy.org/ns/daisy-online/">user@user.nu</Email><Address xmlns="http://www.daisy.org/ns/daisy-online/" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/><Age xmlns="http://www.daisy.org/ns/daisy-online/">64</Age><Gender xmlns="http://www.daisy.org/ns/daisy-online/">MALE</Gender><Teacher xmlns="http://www.daisy.org/ns/daisy-online/">0</Teacher><Usergroup xmlns="http://www.daisy.org/ns/daisy-online/">Ordblind</Usergroup><VersionInfo xmlns="http://www.daisy.org/ns/daisy-online/">' +
          DODPVERSION +
          '</VersionInfo><EnvironmentInfo xmlns="http://www.daisy.org/ns/daisy-online/">TEST</EnvironmentInfo></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><getServiceAttributesResponse xmlns="http://www.daisy.org/ns/daisy-online/"><serviceAttributes><serviceProvider id="Nota"><label xml:lang="en" dir=""><text>National library for persons with print disabilities</text></label></serviceProvider><service id="DodpMobile.nota.nu"><label xml:lang="en" dir=""><text>DodpMobile</text></label></service><supportedContentSelectionMethods><method>OUT_OF_BAND</method></supportedContentSelectionMethods><supportsServerSideBack>false</supportsServerSideBack><supportsSearch>false</supportsSearch><supportedUplinkAudioCodecs/><supportsAudioLabels>false</supportsAudioLabels><supportedOptionalOperations><operation>GET_BOOKMARKS</operation><operation>SET_BOOKMARKS</operation><operation>SERVICE_ANNOUNCEMENTS</operation></supportedOptionalOperations></serviceAttributes></getServiceAttributesResponse></s:Body></s:Envelope>'
      };

      return {
        get logOnData( ) {
          return angular.copy( logOn );
        },
        get logOffData( ) {
          return angular.copy( logOff );
        },
        get getServiceAttributesData( ) {
          return angular.copy( getServiceAttributes );
        }
      };
    }
  ] );
