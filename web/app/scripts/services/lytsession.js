/*global getNotaAuthToken: false */
'use strict';

angular.module( 'lyt3App' )
  .factory( 'LYTSession', [ '$log', 'localStorageService', function(
    $log, localStorageService ) {
    var LYTSession = {
      init: function( ) {
        if ( typeof getNotaAuthToken !== 'undefined' &&
          getNotaAuthToken !== null ) {
          var credentials = getNotaAuthToken( );
          if ( credentials.status === 'ok' ) {
            $log.log( 'Session: init: reading credentials from getNotaAuthToken()' );
            LYTSession.setCredentials( credentials.username, credentials.token );
          }
        } else {
          $log.warn( 'Session: init: getNotaAuthToken is undefined' );
        }
      },
      getCredentials: function( ) {
        return localStorageService.get( 'session|credentials' );
      },
      setCredentials: function( username, password ) {
        var credentials = {
          username: username,
          password: password
        };

        localStorageService.set( 'session|credentials', credentials );
      },
      getInfo: function( ) {
        return localStorageService.get( 'session|memberinfo' ) || {};
      },
      setInfo: function( info ) {
        var memberInfo = angular.extend( this.getInfo(), info );
        localStorageService.set( 'session|memberinfo', memberInfo );
      },
      getMemberId: function( ) {
        return LYTSession.getInfo( ).memberId;
      },
      setBookShelf: function( bookShelf ) {
        localStorageService.set( 'session|bookShelf', bookShelf );
      },
      getBookShelf: function( ) {
        return localStorageService.get( 'session|bookShelf' ) || [ ];
      },
      clear: function( ) {
        localStorageService.remove( 'session|credentials' );
        localStorageService.remove( 'session|memberinfo' );
      }
    };

    return LYTSession;
  } ] );
