'use strict';

// Requires lytTestUser:
// Use test/mock/data/test-data-local.js-tmpl to create test/mock/data/test-data-local.js
//
// Requires lytTestBook
// Run the script tools/createBookTestData.js to generate test/mock/data/bookData.js

angular.module( 'lytTest' )
  .factory( 'testData', [ 'testDataLocal', 'bookDataLocal',
    function( testDataLocal, bookDataLocal ) {
      var DODPVERSION = 'Dummy=1.0.0';
      var testUser = testDataLocal.user;
      var baseUrl = document.location.href.match( /(https?:\/\/[^\/]+)/ )[ 1 ];
      var bookId = 37027;

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
        resolved: {
          'firstItem': 0,
          'id': 'issued',
          'lastItem': 5,
          'totalItems': 6,
          'items': [ {
            'id': 37379,
            'author': 'Douglas Adams',
            'title': 'So long, and thanks for all the fish'
          }, {
            'id': 17214,
            'author': 'Joanne K. Rowling',
            'title': 'Harry Potter og dødsregalierne'
          }, {
            'id': 39314,
            'author': 'Ole Frøslev',
            'title': 'Haltefanden'
          }, {
            'id': 13984,
            'author': 'Joanne K. Rowling',
            'title': 'Harry Potter og fangen fra Azkaban'
          }, {
            'id': 36736,
            'author': 'Jan Kjær',
            'title': 'Taynikma - Toron-sagaen'
          }, {
            'id': 39424,
            'author': 'Hergé',
            'title': 'Den mystiske stjerne'
          } ]
        }
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

      var makeResourceURI = function( fileName ) {
        return baseUrl + '/DodpFiles/20155/' + bookId + '/' + fileName + '?forceclose=true';
      };

      var getContentResources = {
        params: {
          contentID: bookId
        },
        respond: '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Header><MemberId xmlns="http://www.daisy.org/ns/daisy-online/">0</MemberId><Username xmlns="http://www.daisy.org/ns/daisy-online/">0</Username><Realname xmlns="http://www.daisy.org/ns/daisy-online/"/><Email xmlns="http://www.daisy.org/ns/daisy-online/"/><Address xmlns="http://www.daisy.org/ns/daisy-online/" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/><Age xmlns="http://www.daisy.org/ns/daisy-online/">0</Age><Gender xmlns="http://www.daisy.org/ns/daisy-online/">NONE</Gender><Teacher xmlns="http://www.daisy.org/ns/daisy-online/">0</Teacher><Usergroup xmlns="http://www.daisy.org/ns/daisy-online/">Intet handicap</Usergroup><VersionInfo xmlns="http://www.daisy.org/ns/daisy-online/">' +
          DODPVERSION +
          '</VersionInfo><EnvironmentInfo xmlns="http://www.daisy.org/ns/daisy-online/">TEST</EnvironmentInfo></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><getContentResourcesResponse xmlns="http://www.daisy.org/ns/daisy-online/"><resources returnBy="9999-12-31T23:59:59.9999999" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00">' + ( function( ) {
            var str = '<resource uri="_URI_" mimeType="application/octet-stream" size="0" localURI="_LOCALURI_" lastModifiedDate="2014-11-09T01:41:27.9662215+01:00"/>';

            return Object.keys(bookDataLocal)
                .reduce( function( output, fileName ) {
                  return output + str.replace( '_URI_', makeResourceURI( fileName ) ).replace( '_LOCALURI_', fileName );
                }, '' );
          } )() + '</resources></getContentResourcesResponse></s:Body></s:Envelope>',
        resolved: (function( ) {
          return Object.keys(bookDataLocal)
            .reduce( function( output, fileName ) {
              output[ fileName ] = makeResourceURI( fileName );
              return output;
            }, {} );
        })()
      };

      var getBookmarks = {
        params: {
          contentID: bookId
        },
        respond: '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Header><MemberId xmlns="http://www.daisy.org/ns/daisy-online/">0</MemberId><Username xmlns="http://www.daisy.org/ns/daisy-online/">0</Username><Realname xmlns="http://www.daisy.org/ns/daisy-online/"/><Email xmlns="http://www.daisy.org/ns/daisy-online/"/><Address xmlns="http://www.daisy.org/ns/daisy-online/" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/><Age xmlns="http://www.daisy.org/ns/daisy-online/">0</Age><Gender xmlns="http://www.daisy.org/ns/daisy-online/">NONE</Gender><Teacher xmlns="http://www.daisy.org/ns/daisy-online/">0</Teacher><Usergroup xmlns="http://www.daisy.org/ns/daisy-online/">Intet handicap</Usergroup><VersionInfo xmlns="http://www.daisy.org/ns/daisy-online/">' +
          DODPVERSION +
          '</VersionInfo><EnvironmentInfo xmlns="http://www.daisy.org/ns/daisy-online/">TEST</EnvironmentInfo></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><getBookmarksResponse xmlns="http://www.daisy.org/ns/daisy-online/"><bookmarkSet><title xmlns="http://www.daisy.org/z3986/2005/bookmark/"><text>Bunker 137</text><audio src=""/></title><uid xmlns="http://www.daisy.org/z3986/2005/bookmark/">' + bookId +  '</uid><lastmark xmlns="http://www.daisy.org/z3986/2005/bookmark/"><ncxRef/><URI>dcbw0002.smil#sfe_par_0002_0003</URI><timeOffset>00:00:05.00</timeOffset><charOffset>0</charOffset></lastmark><bookmark label="" xml:lang="en" xmlns="http://www.daisy.org/z3986/2005/bookmark/"><ncxRef/><URI>dcbw0002.smil#sfe_par_0002_0003</URI><timeOffset>00:00:00.00</timeOffset><charOffset>0</charOffset><note><text>Om denne udgave</text><audio src=""/></note></bookmark></bookmarkSet></getBookmarksResponse></s:Body></s:Envelope>',
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
            'uid': bookId,
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
          contentID: bookId
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
        },
        book: {
          bookId: bookId,
          resources: (function( ) {
            return Object.keys(bookDataLocal)
              .reduce( function( output, fileName ) {
                var fileData = bookDataLocal[ fileName ];
                output[ fileName ] = {
                  URL: makeResourceURI( fileName ),
                  content: fileData.content
                };

                return output;
              }, {} );
          } )()
        }
      };
    }
  ] );
