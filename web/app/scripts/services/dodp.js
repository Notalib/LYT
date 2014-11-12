'use strict';

/**
 * @ngdoc service
 * @name lyt3App.DODP
 * @description
 * # DODP
 * Factory in the lyt3App.
 */
angular.module( 'lyt3App' )
  .factory( 'DODP', [ '$sanitize', '$http', '$q', 'xmlParser', function(
    $sanitize, $http, $q, xmlParser ) {
    /*jshint quotmark: false */
    var soapTemplate = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
      "<SOAP-ENV:Envelope\n" +
      " xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"\n" +
      " xmlns:ns1=\"http://www.daisy.org/ns/daisy-online/\"\n" +
      " xmlns:ns2=\"http://www.daisy.org/z3986/2005/bookmark/\">\n" +
      "<SOAP-ENV:Body>SOAPBODY</SOAP-ENV:Body>\n" +
      "</SOAP-ENV:Envelope>";
    /*jshint quotmark: single */


    var appendToXML = function( xml, nodeName, data ) {
      var nsid = 'ns1:';
      if ( nodeName.indexOf( ':' ) > -1 ) {
        nsid = '';
      }

      xml += '<' + nsid + nodeName + '>' + toXML( data ) + '</' + nsid +
        nodeName + '>';

      return xml;
    };

    var toXML = function( hash ) {
      var xml = '';
      // Handling of namespaces could be done here by initializing a string
      // containing the necessary declarations that can be inserted in append()

      // Append XML-strings by recursively calling `toXML`
      // on the data

      var type = typeof hash;
      if ( [ 'string', 'number', 'boolean' ].indexOf( type ) > -1 ) {
        // If the argument is a string, number or boolean,
        // then coerce it to a string and use a pseudo element
        // to handle the escaping of special chars
        xml = $sanitize( hash );
      } else if ( type === 'object' && type !== null ) {
        // If the argument is an object, go through its members
        Object.keys( hash ).forEach( function( key ) {
          var value = hash[ key ];
          if ( value instanceof Array ) {
            value.forEach( function( item ) {
              xml = appendToXML( xml, key, item );
            } );
          } else {
            xml = appendToXML( xml, key, value );
          }
        } );
      }

      return xml;
    };

    var createRequest = function( action, data ) {
      var requestData = {};
      requestData[ action ] = data || {};

      var xmlBody = soapTemplate.replace( /SOAPBODY/, toXML( requestData ) );

      return $http( {
        url: '/DodpMobile/Service.svc',
        method: 'POST',
        headers: {
          soapaction: '/' + action,
          'Content-Type': 'text/xml; charset=UTF-8'
        },
        data: xmlBody,
        transformResponse: function( data ) {
          return xmlStr2Json( data );
        }
      } );
    };

    var xml2Json = function( xmlDom, json ) {
      var tagName = xmlDom.tagName.replace( /^s:/, '' );
      var attrs;
      var item;
      if ( xmlDom.attributes ) {
        attrs = Array.prototype.reduce.call( xmlDom.attributes, function(
          attrs, attr ) {
          var name = attr.name;
          var idx = name.indexOf( ':' );
          var ignore = false;
          if ( idx > -1 ) {
            var ns = name.substr( 0, idx );
            if ( [ 'xml', 'xmlns', 'ns1', 'ns2' ].indexOf( ns ) > -1 ) {
              ignore = true;
            }
          }

          if ( [ 'xmlns', 'dir' ].indexOf( name ) > -1 ) {
            ignore = true;
          }

          var value;
          try {
            value = JSON.parse( attr.value );
          } catch ( exp ) {
            value = attr.value;
          }

          if ( !ignore ) {
            attrs[ name ] = value;
          }

          return attrs;
        }, {} );

        if ( Object.keys( attrs ).length === 0 ) {
          attrs = undefined;
        }
      }

      if ( xmlDom.children.length > 0 ) {
        item = {};

        if ( attrs ) {
          item.attrs = attrs;
        }

        Array.prototype.forEach.call( xmlDom.children, function( el ) {
          xml2Json( el, item );
        } );
      } else {
        var textContent = xmlDom.textContent;
        var value;
        try {
          value = JSON.parse( textContent );
        } catch ( exp ) {
          value = textContent;
        }

        item = value;

        if ( attrs ) {
          item = {
            attrs: attrs,
            value: value
          };
        }
      }

      if ( json[ tagName ] ) {
        if ( json[ tagName ] instanceof Array ) {
          json[ tagName ].push( item );
        } else {
          json[ tagName ] = [ json[ tagName ], item ];
        }
      } else {
        json[ tagName ] = item;
      }
    };

    var xmlStr2Json = function( xmlStr ) {
      var xmlDOM = xmlParser.parse( xmlStr );
      var json = {};

      Array.prototype.forEach.call( xmlDOM.children[ 0 ].children,
        function( domEl ) {
          xml2Json( domEl, json );
        } );

      return angular.extend( {
        Body: {},
        Header: {}
      }, json );
    };

    // Public API here
    return {
      logOn: function( username, password ) {
        var defer = $q.defer( );

        createRequest( 'logOn', {
          username: username,
          password: password
        } ).then( function( response ) {
          var data = response.data;
          if ( data.Body.logOnResponse && data.Body.logOnResponse.logOnResult ) {
            defer.resolve( data.Header );
          } else {
            defer.reject( data );
          }
        }, function( ) {
          defer.reject( arguments );
        } );

        return defer.promise;
      },
      logOff: function( ) {
        var defer = $q.defer( );
        createRequest( 'logOff' )
          .then( function( response ) {
            var data = response.data;
            if ( data.Body.logOffResponse && data.Body.logOffResponse.logOffResult ) {
              defer.resolve( data.Header );
            } else {
              defer.reject( 'logOffFailed' );
            }
          }, function( ) {
            defer.reject( 'logOffFailed' );
          } );

        return defer.promise;
      },
      getServiceAttributes: function( ) {
        var defer = $q.defer( );
        createRequest( 'getServiceAttributes' )
          .then( function( response ) {
            var getServiceAttributesResponse = response.data.Body.getServiceAttributesResponse || {};
            var services = getServiceAttributesResponse.serviceAttributes || {};

            if ( Object.keys( services ).length ) {
              defer.resolve( services );
            } else {
              defer.reject(
                'getServiceAttributes failed, missing response.data.Body.getServiceAttributesResponse.serviceAttributes'
              );
            }
          }, function( ) {
            defer.reject( 'getServiceAttributes failed' );
          } );

        return defer.promise;
      },
      setReadingSystemAttributes: function( readingSystemAttributes ) {
        var defer = $q.defer( );
        /* NOTE: input should be:
         */
        readingSystemAttributes = angular.extend( {
          manufacturer: 'NOTA',
          model: 'LYT',
          serialNumber: 1,
          version: 1,
          config: ''
        }, readingSystemAttributes );

        createRequest( 'setReadingSystemAttributes', {
            readingSystemAttributes: readingSystemAttributes
          } )
          .then( function( response ) {
            if ( response.data.Body.setReadingSystemAttributesResponse.setReadingSystemAttributesResult ) {
              defer.resolve( );
            } else {
              defer.reject( 'setReadingSystemAttributes failed' );
            }
          }, function( ) {
            defer.reject( 'setReadingSystemAttributes failed' );
          } );

        return defer.promise;
      },
      getServiceAnnouncements: function( ) {
        var defer = $q.defer( );
        createRequest( 'getServiceAnnouncements' )
          .then( function( response ) {
            var data = response.data.Body;
            var announcements = ( ( data.getServiceAnnouncementsResponse || {} )
              .announcements || {} ).announcement || [ ];
            defer.resolve( announcements );
          }, function( ) {
            defer.reject( 'getServiceAnnouncements failed' );
          } );

        return defer.promise;
      },
      markAnnouncementsAsRead: function( ) {
        var defer = $q.defer( );
        defer.reject( );

        return defer.promise;
      },
      getContentList: function( listIdentifier, firstItem, lastItem ) {
        var defer = $q.defer( );
        createRequest( 'getContentList', {
            id: listIdentifier,
            firstItem: firstItem,
            lastItem: lastItem
          } )
          .then( function( response ) {
            var data = response.data;
            if ( data.Body.getContentListResponse && data.Body.getContentListResponse
              .contentList ) {
              defer.resolve( data.Body.getContentListResponse.contentList );
            } else {
              defer.reject( 'setReadingSystemAttributes failed' );
            }
          }, function( ) {
            defer.reject( 'setReadingSystemAttributes failed' );
          } );

        return defer.promise;
      },
      issueContent: function( contentID ) {
        var defer = $q.defer( );

        createRequest( 'issueContent', {
            contentID: contentID
          } )
          .then( function( response ) {
            var data = response.data;
            var Body = data.Body;
            if ( Body.issueContentResponse.issueContentResult ) {
              defer.resolve( );
            } else {
              defer.reject( 'issueContent failed' );
            }
          }, function( ) {
            defer.reject( 'issueContent failed' );
          } );

        return defer.promise;
      },
      returnContent: function( ) {
        var defer = $q.defer( );
        defer.reject( );

        return defer.promise;
      },
      getContentMetadata: function( ) {
        var defer = $q.defer( );
        defer.reject( );

        return defer.promise;
      },
      getContentResources: function( contentID ) {
        var defer = $q.defer( );

        createRequest( 'getContentResources', {
            contentID: contentID
          } )
          .then( function( response ) {
            var data = response.data;
            var Body = data.Body;
            var resources = Body.getContentResourcesResponse.resources.resource
              .reduce( function( resources, item ) {
                resources[ item.attrs.localURI ] = item.attrs.uri;
                return resources;
              }, {} );

            defer.resolve( resources );
          }, function( ) {
            defer.reject( 'getContentResources failed' );
          } );

        return defer.promise;
      },
      getBookmarks: ( function( ) {
        /**
         * Convert from Dodp offset to floating point in seconds
         * TODO: Implement correct parsing of all time formats provided in
         *       http://www.daisy.org/z3986/2005/Z3986-2005.html#Clock
         * Parse offset strings ("HH:MM:SS.ss") to seconds, e. g.
         *     parseOffset("1:02:03.05") #=> 3723.05
         * We keep this function as well as parseTime in LYTUtils because they
         * are used to parse formats that are not completely identical.
         */

        var parseOffset = function( timeOffset ) {
          var values = timeOffset.match( /\d+/g );
          if ( values && values.length === 4 ) {
            values[ 3 ] = values[ 3 ] || '0';
            values = values.map( function( val ) {
              return parseFloat( val, 10 );
            } );

            return values[ 0 ] * 3600 + values[ 1 ] * 60 + values[ 2 ] +
              values[ 3 ];
          }
        };

        var deserialize = function( data ) {
          if ( !data ) {
            return;
          }

          var uri = data.URI;

          var timeOffset = parseOffset( data.timeOffset );
          var note = ( data.note || {} ).text || '-';
          if ( uri && timeOffset !== undefined ) {
            return {
              ncxRef: null,
              URI: uri,
              timeOffset: timeOffset,
              note: {
                text: note
              }
            };
          }
        };

        return function( contentID ) {
          var defer = $q.defer( );

          createRequest( 'getBookmarks', {
              contentID: contentID
            } )
            .then( function( response ) {
              var data = response.data;
              var Body = data.Body;
              var getBookmarksResponse = Body.getBookmarksResponse || {};
              var bookmarkSet = getBookmarksResponse.bookmarkSet || {};
              var title = bookmarkSet.title;
              var bookmarks = bookmarkSet.bookmark || [ ];
              if ( bookmarks ) {
                if ( !( bookmarks instanceof Array ) ) {
                  bookmarks = [ bookmarks ];
                }
              }

              var res = {
                bookmarks: bookmarks.map( deserialize ).filter(
                  function( bookmark ) {
                    return !!bookmark;
                  } ),
                book: {
                  uid: bookmarkSet.uid,
                  title: {
                    text: title.text,
                    audio: title.audio
                  }
                },
                lastmark: deserialize( bookmarkSet.lastmark )
              };

              defer.resolve( res );
            }, function( ) {
              defer.reject( 'getBookmarks failed' );
            } );

          return defer.promise;
        };
      } )( ),
      setBookmarks: function( ) {
        var defer = $q.defer( );
        defer.reject( );

        return defer.promise;
      },
    };
  } ] );
