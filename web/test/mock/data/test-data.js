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
          testUser.memberId +
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
          testUser.memberId +
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
        resolved: {'firstItem':0,'id':'issued','lastItem':5,'totalItems':6,'items':[{'id':37379,'author':'Douglas Adams','title':'So long, and thanks for all the fish'},{'id':17214,'author':'Joanne K. Rowling','title':'Harry Potter og dødsregalierne'},{'id':39314,'author':'Ole Frøslev','title':'Haltefanden'},{'id':13984,'author':'Joanne K. Rowling','title':'Harry Potter og fangen fra Azkaban'},{'id':36736,'author':'Jan Kjær','title':'Taynikma - Toron-sagaen'},{'id':39424,'author':'Hergé','title':'Den mystiske stjerne'}]}
      };

      var getServiceAnnouncements = {
        params: {},
        respond: '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Header><MemberId xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.memberId +
          '</MemberId><Username xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.memberId +
          ' </Username><Realname xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.realname +
          '</Realname><Email xmlns="http://www.daisy.org/ns/daisy-online/">' +
          testUser.email +
          '</Email><Address xmlns="http://www.daisy.org/ns/daisy-online/" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/><Age xmlns="http://www.daisy.org/ns/daisy-online/">64</Age><Gender xmlns="http://www.daisy.org/ns/daisy-online/">MALE</Gender><Teacher xmlns="http://www.daisy.org/ns/daisy-online/">0</Teacher><Usergroup xmlns="http://www.daisy.org/ns/daisy-online/">Ordblind</Usergroup><VersionInfo xmlns="http://www.daisy.org/ns/daisy-online/">' +
          DODPVERSION +
          '</VersionInfo><EnvironmentInfo xmlns="http://www.daisy.org/ns/daisy-online/">TEST</EnvironmentInfo></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><getServiceAnnouncementsResponse xmlns="http://www.daisy.org/ns/daisy-online/"><announcements><announcement id="1" type="INFORMATION" priority="1"><label xml:lang="en" dir=""><text>Besked nummer 1 fra Nota</text></label></announcement><announcement id="2" type="INFORMATION" priority="1"><label xml:lang="en" dir=""><text>Besked nummer 2 fra Nota</text></label></announcement><announcement id="3" type="INFORMATION" priority="1"><label xml:lang="en" dir=""><text>Besked nummer 3 fra Nota</text></label></announcement></announcements></getServiceAnnouncementsResponse></s:Body></s:Envelope>',
        resolved: [ {
          'attrs': {
            'id': 1,
            'type': 'INFORMATION',
            'priority': 1
          },
          'label': {
            'text': 'Besked nummer 1 fra Nota'
          }
        }, {
          'attrs': {
            'id': 2,
            'type': 'INFORMATION',
            'priority': 1
          },
          'label': {
            'text': 'Besked nummer 2 fra Nota'
          }
        }, {
          'attrs': {
            'id': 3,
            'type': 'INFORMATION',
            'priority': 1
          },
          'label': {
            'text': 'Besked nummer 3 fra Nota'
          }
        } ]
      };

      var getContentResources = {
        params: {
          contentID: 37027
        },
        respond: '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Header><MemberId xmlns="http://www.daisy.org/ns/daisy-online/">0</MemberId><Username xmlns="http://www.daisy.org/ns/daisy-online/">0</Username><Realname xmlns="http://www.daisy.org/ns/daisy-online/"/><Email xmlns="http://www.daisy.org/ns/daisy-online/"/><Address xmlns="http://www.daisy.org/ns/daisy-online/" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/><Age xmlns="http://www.daisy.org/ns/daisy-online/">0</Age><Gender xmlns="http://www.daisy.org/ns/daisy-online/">NONE</Gender><Teacher xmlns="http://www.daisy.org/ns/daisy-online/">0</Teacher><Usergroup xmlns="http://www.daisy.org/ns/daisy-online/">Intet handicap</Usergroup><VersionInfo xmlns="http://www.daisy.org/ns/daisy-online/">' +
          DODPVERSION +
          '</VersionInfo><EnvironmentInfo xmlns="http://www.daisy.org/ns/daisy-online/">TEST</EnvironmentInfo></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><getContentResourcesResponse xmlns="http://www.daisy.org/ns/daisy-online/"><resources returnBy="9999-12-31T23:59:59.9999999" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/01_Michael_Kamp_Bunker_.mp3" mimeType="application/octet-stream" size="0" localURI="01_Michael_Kamp_Bunker_.mp3" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/02_Om_denne_udgave.mp3" mimeType="application/octet-stream" size="0" localURI="02_Om_denne_udgave.mp3" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/03_Kolofon_og_bibliogra.mp3" mimeType="application/octet-stream" size="0" localURI="03_Kolofon_og_bibliogra.mp3" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/04_Citat.mp3" mimeType="application/octet-stream" size="0" localURI="04_Citat.mp3" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/05_Kapitel_1.mp3" mimeType="application/octet-stream" size="0" localURI="05_Kapitel_1.mp3" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/06_Kapitel_2.mp3" mimeType="application/octet-stream" size="0" localURI="06_Kapitel_2.mp3" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/07_Kapitel_3.mp3" mimeType="application/octet-stream" size="0" localURI="07_Kapitel_3.mp3" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/08_Kapitel_4.mp3" mimeType="application/octet-stream" size="0" localURI="08_Kapitel_4.mp3" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/09_Kapitel_5.mp3" mimeType="application/octet-stream" size="0" localURI="09_Kapitel_5.mp3" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/10_Kapitel_6.mp3" mimeType="application/octet-stream" size="0" localURI="10_Kapitel_6.mp3" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/11_Kapitel_7.mp3" mimeType="application/octet-stream" size="0" localURI="11_Kapitel_7.mp3" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/12_Kapitel_8.mp3" mimeType="application/octet-stream" size="0" localURI="12_Kapitel_8.mp3" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/13_Kapitel_9.mp3" mimeType="application/octet-stream" size="0" localURI="13_Kapitel_9.mp3" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/37027.htm" mimeType="application/octet-stream" size="0" localURI="37027.htm" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0001.smil" mimeType="application/octet-stream" size="0" localURI="dcbw0001.smil" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0002.smil" mimeType="application/octet-stream" size="0" localURI="dcbw0002.smil" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0003.smil" mimeType="application/octet-stream" size="0" localURI="dcbw0003.smil" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0004.smil" mimeType="application/octet-stream" size="0" localURI="dcbw0004.smil" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0005.smil" mimeType="application/octet-stream" size="0" localURI="dcbw0005.smil" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0006.smil" mimeType="application/octet-stream" size="0" localURI="dcbw0006.smil" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0007.smil" mimeType="application/octet-stream" size="0" localURI="dcbw0007.smil" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0008.smil" mimeType="application/octet-stream" size="0" localURI="dcbw0008.smil" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0009.smil" mimeType="application/octet-stream" size="0" localURI="dcbw0009.smil" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw000A.smil" mimeType="application/octet-stream" size="0" localURI="dcbw000A.smil" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw000B.smil" mimeType="application/octet-stream" size="0" localURI="dcbw000B.smil" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw000C.smil" mimeType="application/octet-stream" size="0" localURI="dcbw000C.smil" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw000D.smil" mimeType="application/octet-stream" size="0" localURI="dcbw000D.smil" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/master.smil" mimeType="application/octet-stream" size="0" localURI="master.smil" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/><resource uri="http://test.m.e17.dk:80/DodpFiles/20155/37027/ncc.html" mimeType="application/octet-stream" size="0" localURI="ncc.html" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/></resources></getContentResourcesResponse></s:Body></s:Envelope>',
        resolved: {
          '01_Michael_Kamp_Bunker_.mp3': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/01_Michael_Kamp_Bunker_.mp3',
          '02_Om_denne_udgave.mp3': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/02_Om_denne_udgave.mp3',
          '03_Kolofon_og_bibliogra.mp3': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/03_Kolofon_og_bibliogra.mp3',
          '04_Citat.mp3': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/04_Citat.mp3',
          '05_Kapitel_1.mp3': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/05_Kapitel_1.mp3',
          '06_Kapitel_2.mp3': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/06_Kapitel_2.mp3',
          '07_Kapitel_3.mp3': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/07_Kapitel_3.mp3',
          '08_Kapitel_4.mp3': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/08_Kapitel_4.mp3',
          '09_Kapitel_5.mp3': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/09_Kapitel_5.mp3',
          '10_Kapitel_6.mp3': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/10_Kapitel_6.mp3',
          '11_Kapitel_7.mp3': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/11_Kapitel_7.mp3',
          '12_Kapitel_8.mp3': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/12_Kapitel_8.mp3',
          '13_Kapitel_9.mp3': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/13_Kapitel_9.mp3',
          '37027.htm': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/37027.htm',
          'dcbw0001.smil': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0001.smil',
          'dcbw0002.smil': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0002.smil',
          'dcbw0003.smil': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0003.smil',
          'dcbw0004.smil': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0004.smil',
          'dcbw0005.smil': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0005.smil',
          'dcbw0006.smil': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0006.smil',
          'dcbw0007.smil': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0007.smil',
          'dcbw0008.smil': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0008.smil',
          'dcbw0009.smil': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw0009.smil',
          'dcbw000A.smil': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw000A.smil',
          'dcbw000B.smil': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw000B.smil',
          'dcbw000C.smil': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw000C.smil',
          'dcbw000D.smil': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/dcbw000D.smil',
          'master.smil': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/master.smil',
          'ncc.html': 'http://test.m.e17.dk:80/DodpFiles/20155/37027/ncc.html'
        }
      };

      var getBookmarks = {
        params: {
          contentID: 37027
        },
        respond: '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Header><MemberId xmlns="http://www.daisy.org/ns/daisy-online/">0</MemberId><Username xmlns="http://www.daisy.org/ns/daisy-online/">0</Username><Realname xmlns="http://www.daisy.org/ns/daisy-online/"/><Email xmlns="http://www.daisy.org/ns/daisy-online/"/><Address xmlns="http://www.daisy.org/ns/daisy-online/" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/><Age xmlns="http://www.daisy.org/ns/daisy-online/">0</Age><Gender xmlns="http://www.daisy.org/ns/daisy-online/">NONE</Gender><Teacher xmlns="http://www.daisy.org/ns/daisy-online/">0</Teacher><Usergroup xmlns="http://www.daisy.org/ns/daisy-online/">Intet handicap</Usergroup><VersionInfo xmlns="http://www.daisy.org/ns/daisy-online/">' +
          DODPVERSION +
          '</VersionInfo><EnvironmentInfo xmlns="http://www.daisy.org/ns/daisy-online/">TEST</EnvironmentInfo></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><getBookmarksResponse xmlns="http://www.daisy.org/ns/daisy-online/"><bookmarkSet><title xmlns="http://www.daisy.org/z3986/2005/bookmark/"><text>Bunker 137</text><audio src=""/></title><uid xmlns="http://www.daisy.org/z3986/2005/bookmark/">37027</uid><lastmark xmlns="http://www.daisy.org/z3986/2005/bookmark/"><ncxRef/><URI>dcbw0002.smil#sfe_par_0002_0003</URI><timeOffset>00:00:05.00</timeOffset><charOffset>0</charOffset></lastmark><bookmark label="" xml:lang="en" xmlns="http://www.daisy.org/z3986/2005/bookmark/"><ncxRef/><URI>dcbw0002.smil#sfe_par_0002_0003</URI><timeOffset>00:00:00.00</timeOffset><charOffset>0</charOffset><note><text>Om denne udgave</text><audio src=""/></note></bookmark></bookmarkSet></getBookmarksResponse></s:Body></s:Envelope>',
        resolved: {
          'bookmarks': [ {
            'ncxRef': null,
            'URI': 'dcbw0002.smil#sfe_par_0002_0003',
            'timeOffset': 0,
            'note': {
              'text': 'Om denne udgave'
            }
          } ],
          'book': {
            'uid': 37027,
            'title': {
              'text': 'Bunker 137',
              'audio': {
                'attrs': {
                  'src': ''
                },
                'value': ''
              }
            }
          },
          'lastmark': {
            'ncxRef': null,
            'URI': 'dcbw0002.smil#sfe_par_0002_0003',
            'timeOffset': 5,
            'note': {
              'text': '-'
            }
          }
        }
      };

      var issueContent = {
        params: {
          contentID: 37027
        },
        respond: '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Header><MemberId xmlns="http://www.daisy.org/ns/daisy-online/">0</MemberId><Username xmlns="http://www.daisy.org/ns/daisy-online/">0</Username><Realname xmlns="http://www.daisy.org/ns/daisy-online/"/><Email xmlns="http://www.daisy.org/ns/daisy-online/"/><Address xmlns="http://www.daisy.org/ns/daisy-online/" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/><Age xmlns="http://www.daisy.org/ns/daisy-online/">0</Age><Gender xmlns="http://www.daisy.org/ns/daisy-online/">NONE</Gender><Teacher xmlns="http://www.daisy.org/ns/daisy-online/">0</Teacher><Usergroup xmlns="http://www.daisy.org/ns/daisy-online/">Intet handicap</Usergroup><VersionInfo xmlns="http://www.daisy.org/ns/daisy-online/">DodpCore=1.1.1.19462;DodpBase=3.1.23.24696;MemberCatalog=2.0.32.23097;NotaSecure=1.1.22.17564;DodpMobile=3.1.16.24698</VersionInfo><EnvironmentInfo xmlns="http://www.daisy.org/ns/daisy-online/">TEST</EnvironmentInfo></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><issueContentResponse xmlns="http://www.daisy.org/ns/daisy-online/"><issueContentResult>true</issueContentResult></issueContentResponse></s:Body></s:Envelope>'
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
          },
          get getServiceAnnouncementsData( ) {
            return angular.copy( getServiceAnnouncements );
          },
          get getContentResourcesData( ) {
            return angular.copy( getContentResources );
          },
          get getBookmarksData( ) {
            return angular.copy( getBookmarks );
          },
          get issueContentData( ) {
            return angular.copy( issueContent );
          }
        }
      };
    }
  ] );
