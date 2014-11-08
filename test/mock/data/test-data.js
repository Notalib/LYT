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
            '</Realname><Email xmlns="http://www.daisy.org/ns/daisy-online/">' +
            testUser.email +
            '</Email><Address xmlns="http://www.daisy.org/ns/daisy-online/" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/><Age xmlns="http://www.daisy.org/ns/daisy-online/">90</Age><Gender xmlns="http://www.daisy.org/ns/daisy-online/">FEMALE</Gender><Teacher xmlns="http://www.daisy.org/ns/daisy-online/">0</Teacher><Usergroup xmlns="http://www.daisy.org/ns/daisy-online/">Blind</Usergroup><VersionInfo xmlns="http://www.daisy.org/ns/daisy-online/">' +
            DODPVERSION +
            '</VersionInfo><EnvironmentInfo xmlns="http://www.daisy.org/ns/daisy-online/">TEST</EnvironmentInfo></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><logOnResponse xmlns="http://www.daisy.org/ns/daisy-online/"><logOnResult>true</logOnResult></logOnResponse></s:Body></s:Envelope>',
          resolved: {
            'MemberId': 'undefined',
            'Username': 'USERNAME',
            'Realname': 'undefined',
            'Email': 'undefined',
            'Address': '',
            'Age': 90,
            'Gender': 'FEMALE',
            'Teacher': 0,
            'Usergroup': 'Blind',
            'VersionInfo': 'Dummy=1.0.0',
            'EnvironmentInfo': 'TEST'
          }
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
          '</VersionInfo><EnvironmentInfo xmlns="http://www.daisy.org/ns/daisy-online/">TEST</EnvironmentInfo></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><logOffResponse xmlns="http://www.daisy.org/ns/daisy-online/"><logOffResult>true</logOffResult></logOffResponse></s:Body></s:Envelope>',
        resolved: {
          'Username': {
            'Realname': 'none',
            'TypeOfMember': 'PHYSICAL',
            'Username': testUser.username,
            'Value': testUser.password
          },
          'VersionInfo': 'Dummy=1.0.0',
          'EnvironmentInfo': 'TEST'
        },
      };

      var getServiceAttributes = {
        params: {},
        respond: '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Header><MemberId xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.username +
          '</MemberId><Username xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.username +
          '</Username><Realname xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.realname +
          '</Realname><Email xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.email +
          '</Email><Address xmlns="http://www.daisy.org/ns/daisy-online/" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/><Age xmlns="http://www.daisy.org/ns/daisy-online/">64</Age><Gender xmlns="http://www.daisy.org/ns/daisy-online/">MALE</Gender><Teacher xmlns="http://www.daisy.org/ns/daisy-online/">0</Teacher><Usergroup xmlns="http://www.daisy.org/ns/daisy-online/">Ordblind</Usergroup><VersionInfo xmlns="http://www.daisy.org/ns/daisy-online/">' +
          DODPVERSION +
          '</VersionInfo><EnvironmentInfo xmlns="http://www.daisy.org/ns/daisy-online/">TEST</EnvironmentInfo></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><getServiceAttributesResponse xmlns="http://www.daisy.org/ns/daisy-online/"><serviceAttributes><serviceProvider id="Nota"><label xml:lang="en" dir=""><text>National library for persons with print disabilities</text></label></serviceProvider><service id="DodpMobile.nota.nu"><label xml:lang="en" dir=""><text>DodpMobile</text></label></service><supportedContentSelectionMethods><method>OUT_OF_BAND</method></supportedContentSelectionMethods><supportsServerSideBack>false</supportsServerSideBack><supportsSearch>false</supportsSearch><supportedUplinkAudioCodecs/><supportsAudioLabels>false</supportsAudioLabels><supportedOptionalOperations><operation>GET_BOOKMARKS</operation><operation>SET_BOOKMARKS</operation><operation>SERVICE_ANNOUNCEMENTS</operation></supportedOptionalOperations></serviceAttributes></getServiceAttributesResponse></s:Body></s:Envelope>',
        resolved: {
          'serviceProvider': {
            'attrs': {
              'id': 'Nota'
            },
            'label': {
              'text': 'National library for persons with print disabilities'
            }
          },
          'service': {
            'attrs': {
              'id': 'DodpMobile.nota.nu'
            },
            'label': {
              'text': 'DodpMobile'
            }
          },
          'supportedContentSelectionMethods': {
            'method': 'OUT_OF_BAND'
          },
          'supportsServerSideBack': false,
          'supportsSearch': false,
          'supportedUplinkAudioCodecs': '',
          'supportsAudioLabels': false,
          'supportedOptionalOperations': {
            'operation': [ 'GET_BOOKMARKS', 'SET_BOOKMARKS',
              'SERVICE_ANNOUNCEMENTS'
            ]
          }
        }
      };

      var setReadingSystemAttributes = {
        params: {
          readingSystemAttributes: {
            manufacturer: 'NOTA',
            model: 'LYT',
            serialNumber: 1,
            version: 1,
            config: ''
          }
        },
        respond: '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Header><MemberId xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.username +
          '</MemberId><Username xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.username +
          '</Username><Realname xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.realname +
          '</Realname><Email xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.email +
          '</Email><Address xmlns="http://www.daisy.org/ns/daisy-online/" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/><Age xmlns="http://www.daisy.org/ns/daisy-online/">64</Age><Gender xmlns="http://www.daisy.org/ns/daisy-online/">MALE</Gender><Teacher xmlns="http://www.daisy.org/ns/daisy-online/">0</Teacher><Usergroup xmlns="http://www.daisy.org/ns/daisy-online/">Ordblind</Usergroup><VersionInfo xmlns="http://www.daisy.org/ns/daisy-online/">' +
          DODPVERSION +
          '</VersionInfo><EnvironmentInfo xmlns="http://www.daisy.org/ns/daisy-online/">TEST</EnvironmentInfo></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><setReadingSystemAttributesResponse xmlns="http://www.daisy.org/ns/daisy-online/"><setReadingSystemAttributesResult>true</setReadingSystemAttributesResult></setReadingSystemAttributesResponse></s:Body></s:Envelope>'
      };

      var getContentList = {
        params: {
          listIdentifier: 'issued',
          firstItem: 0,
          lastItem: 5
        },
        respond: '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Header><MemberId xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.memberId +
          '</MemberId><Username xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.username +
          '</Username><Realname xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.realname +
          '</Realname><Email xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.email +
          '</Email><Address xmlns="http://www.daisy.org/ns/daisy-online/" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/><Age xmlns="http://www.daisy.org/ns/daisy-online/">64</Age><Gender xmlns="http://www.daisy.org/ns/daisy-online/">MALE</Gender><Teacher xmlns="http://www.daisy.org/ns/daisy-online/">0</Teacher><Usergroup xmlns="http://www.daisy.org/ns/daisy-online/">Ordblind</Usergroup><VersionInfo xmlns="http://www.daisy.org/ns/daisy-online/">' +
          DODPVERSION +
          '</VersionInfo><EnvironmentInfo xmlns="http://www.daisy.org/ns/daisy-online/">TEST</EnvironmentInfo></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><getContentListResponse xmlns="http://www.daisy.org/ns/daisy-online/"><contentList totalItems="6" firstItem="0" lastItem="5" id="issued"><label xml:lang="en" dir=""><text>issued</text></label><contentItem id="37379"><label xml:lang="en" dir=""><text>Douglas Adams$So long, and thanks for all the fish</text></label></contentItem><contentItem id="17214"><label xml:lang="en" dir=""><text>Joanne K. Rowling$Harry Potter og dødsregalierne</text></label></contentItem><contentItem id="39314"><label xml:lang="en" dir=""><text>Ole Frøslev$Haltefanden</text></label></contentItem><contentItem id="13984"><label xml:lang="en" dir=""><text>Joanne K. Rowling$Harry Potter og fangen fra Azkaban</text></label></contentItem><contentItem id="36736"><label xml:lang="en" dir=""><text>Jan Kjær$Taynikma - Toron-sagaen</text></label></contentItem><contentItem id="39424"><label xml:lang="en" dir=""><text>Hergé$Den mystiske stjerne</text></label></contentItem></contentList></getContentListResponse></s:Body></s:Envelope>',
        resolved: {
          'attrs': {
            'totalItems': 6,
            'firstItem': 0,
            'lastItem': 5,
            'id': 'issued'
          },
          'label': {
            'text': 'issued'
          },
          'contentItem': [ {
            'attrs': {
              'id': 37379
            },
            'label': {
              'text': 'Douglas Adams$So long, and thanks for all the fish'
            }
          }, {
            'attrs': {
              'id': 17214
            },
            'label': {
              'text': 'Joanne K. Rowling$Harry Potter og dødsregalierne'
            }
          }, {
            'attrs': {
              'id': 39314
            },
            'label': {
              'text': 'Ole Frøslev$Haltefanden'
            }
          }, {
            'attrs': {
              'id': 13984
            },
            'label': {
              'text': 'Joanne K. Rowling$Harry Potter og fangen fra Azkaban'
            }
          }, {
            'attrs': {
              'id': 36736
            },
            'label': {
              'text': 'Jan Kjær$Taynikma - Toron-sagaen'
            }
          }, {
            'attrs': {
              'id': 39424
            },
            'label': {
              'text': 'Hergé$Den mystiske stjerne'
            }
          } ]
        }
      };

      return {
        dodp: {
          get logOnData( ) {
            return angular.copy( logOn );
          },
          get logOffData( ) {
            return angular.copy( logOff );
          },
          get getServiceAttributesData( ) {
            return angular.copy( getServiceAttributes );
          },
          get setReadingSystemAttributesData( ) {
            return angular.copy( setReadingSystemAttributes );
          },
          get getContentListData( ) {
            return angular.copy( getContentList );
          }
        }
      };
    }
  ] );
