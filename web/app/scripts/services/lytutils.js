/*global jQuery: false */
'use strict';

angular.module( 'lyt3App' )
  .factory( 'LYTUtils', function( ) {
    var utils = {
      formatTime: function( seconds ) {
        seconds = parseInt( seconds, 10 );
        if ( !seconds || seconds < 0 ) {
          seconds = 0;
        }

        /*jshint bitwise: false*/
        var hours = ( seconds / 3600 ) >>> 0;
        var minutes = '0' + ( ( ( seconds % 3600 ) / 60 ) >>> 0 );
        /*jslint bitwise: true*/

        seconds = '0' + ( seconds % 60 );

        return '' + hours + ':' + ( minutes.slice( -2 ) ) + ':' + (
          seconds.slice( -2 ) );
      },
      parseTime: function( string ) {
        var components = String( string ).match(
          /^(\d*):?(\d{2}):(\d{2})$/ );
        if ( !components ) {
          return 0;
        }
        components.shift( );
        components = ( function( ) {
          return components.map( function( component ) {
            return parseInt( component, 10 ) || 0;
          } );
        } )( );
        return components[ 0 ] * 3600 + components[ 1 ] * 60 + components[
          2 ];
      },
      toSentence: function( array ) {
        if ( !( array instanceof Array ) || array.length === 0 ) {
          return '';
        }
        if ( array.length === 1 ) {
          return String( array[ 0 ] );
        }
        return '' + ( array.slice( 0, -1 ).join( ', ' ) ) + ' & ' + (
          array.slice( -1 ) );
      },
      toXML: ( function( ) {
        var toXML = function( hash ) {
          var xml = '';
          var append = function( nodeName, data ) {
            var nsid = 'ns1:';
            if ( jQuery.inArray( ':', nodeName ) > -1 ) {
              nsid = '';
            }

            xml += '<' + nsid + nodeName + '>' + ( toXML(
              data ) ) + '</' + nsid + nodeName + '>';
          };

          switch ( typeof hash ) {
            case 'string':
            case 'number':
            case 'boolean': {
              return jQuery( '<div>' ).text( String( hash ) ).html( );
            }
            case 'object': {
              Object.keys( hash ).forEach( function( key ) {
                var value = hash[ key ];
                if ( value instanceof Array ) {
                  value.forEach( function( item ) {
                    append( key, item );
                  } );
                } else {
                  append( key, value );
                }
              } );
            }
          }
          return xml;
        };

        return toXML;
      } )( )
    };

    return utils;
  } );
