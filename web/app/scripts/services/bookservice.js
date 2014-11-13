'use strict';

angular.module( 'lyt3App' )
  .factory( 'BookService', [ '$q', 'LYTSession', 'DODPErrorCodes', 'DODP',
    function( $q, LYTSession, DODPErrorCodes, DODP ) {
      /*
       *
       * Higher-level functions for interacting with the server
       *
       * This module is a facade or abstraction layer between the
       * controller/model code and the `rpc`/`protocol` functions.
       * As such, it's **not** a 1-to-1 mapping of the DODP web
       * service (that's `protocol`'s job).
       *
       * The `service` object may emit the following events:
       *
       * - `logon:rejected` (data: none) - The username/password was rejected, or
       *    not supplied. User must log in
       * - `error:rpc` (data: `{code: [RPC_* error constants]}`) - A communication error,
       *    e.g. timeout, occurred (see [rpc.coffee](rpc.html) for error codes)
       * - `error:service` (data: `{code: [DODP_* error constant]}`) - The server barfed
       *    (see [rpc.coffee](rpc.html) for error constants)
       *
       * Events are emitted and can be observed via jQuery. Example:
       *
       *     jQuery(LYT.service).bind 'logon:rejected', ->
       *       # go to the log-in page
       *
       */
      var __slice = [ ].slice;

      var currentLogOnProcess, currentRefreshSessionProcess, emit, emitError,
        lastBookmark, logOn, onCurrentLogOn, operations, withLogOn;

      // # Privileged API
      lastBookmark = null;

      // optional service operations
      operations = {
        DYNAMIC_MENUS: false,
        SET_BOOKMARKS: false,
        GET_BOOKMARKS: false,
        SERVICE_ANNOUNCEMENTS: false,
        PDTB2_KEY_PROVISION: false
      };

      // The current logon process(es)
      currentLogOnProcess = null;
      currentRefreshSessionProcess = null;

      var gotServiceAttrs = function( services ) {
        Object.keys( operations ).forEach( function( op ) {
          operations[ op ] = false;
        } );

        if ( services.supportedOptionalOperations && services.supportedOptionalOperations
          .operation ) {
          services.supportedOptionalOperations.operation.forEach( function(
            op ) {
            operations[ op ] = true;
          } );
        }
      };

      // Initilize serviceAttributes with values when we are logged in but user reloads scripts.....
      DODP.getServiceAttributes( )
        .then( function( ops ) {
          var op, _i, _len, _results;
          for ( op in operations ) {
            operations[ op ] = false;
          }
          _results = [ ];
          for ( _i = 0, _len = ops.length; _i < _len; _i++ ) {
            op = ops[ _i ];
            _results.push( operations[ op ] = true );
          }
          return _results;
        } );

      // Emit an event
      emit = function( event, data ) {
        console.log( event, data );
        /*
      var obj;
      if (!data) {
        data = {};
      }
      obj = jQuery.Event(event);
      if (data.hasOwnProperty('type')) {
        delete data.type;
      }
      jQuery.extend(obj, data);
      // log.message('Service: Emitting ' + event + ' event');
      return jQuery(LYT.service).trigger(obj);
      */
      };

      // Emit an error event
      emitError = function( code ) {
        switch ( code ) {
          case DODPErrorCodes.RPC_GENERAL_ERROR:
          case DODPErrorCodes.RPC_TIMEOUT_ERROR:
          case DODPErrorCodes.RPC_ABORT_ERROR:
          case DODPErrorCodes.RPC_HTTP_ERROR: {
            return emit( 'error:rpc', {
              code: code
            } );
          }
          default: {
            return emit( 'error:service', {
              code: code
            } );
          }
        }
      };
      /*
       * Wraps a call in a couple of checks: If the call the fails,
       * check if the reason is due to the user not being logged in.
       * If that's the case, attempt logon, and attempt the call again
       */
      withLogOn = function( callback ) {
        var deferred, failure, result, success;
        deferred = $q.defer( );

        // If the call goes through
        success = function( ) {
          var args;
          args = 1 <= arguments.length ? __slice.call( arguments, 0 ) : [ ];
          return deferred.resolve.apply( deferred, args );
        };

        // If the call fails
        failure = function( code, message ) {
          emitError( code );
          return deferred.reject( code, message );
        };
        result = callback( );

        // If everything works, then just pass on the resolve args
        result.then( success );

        // If the call fails
        result.catch( function( code, message ) {
          // Is it because the user's not logged in?
          if ( code === DODPErrorCodes.DODP_NO_SESSION_ERROR ) {
            // If so , the attempt log-on
            return logOn( )
              .then( function( ) {
                // Logon worked, so re-attempt the call
                return callback( )
                  // If it works, this time around, then great
                  .then( success )
                  // If it doesn't, then give up
                  .catch( failure );
              } )
              .catch( function( code, message ) {
                // Logon failed, so propagate the error
                return deferred.reject( code, message );
              } );
          } else {
            return failure( code, message );
          }
        } );
        return deferred.promise;
      };

      onCurrentLogOn = function( handlers ) {
        var handlerName, promise, _results;
        promise = currentLogOnProcess;
        if ( !promise ) {
          promise = $q.defer( )
            .resolve( );
        }
        _results = [ ];
        for ( handlerName in handlers ) {
          _results.push( promise[ handlerName ]( handlers[ handlerName ] ) );
        }
        return _results;
      };

      // Perform the logOn handshake:
      // `logOn` then `getServiceAttributes` then `setReadingSystemAttributes`
      logOn = function( username, password ) {
        var attemptLogOn, attempts, deferred, failed,
          gotServiceAnnouncements, loggedOn, readingSystemAttrsSet;
        // Check for and return any pending logon processes
        if ( currentLogOnProcess && currentLogOnProcess.state === 'pending' ) {
          return currentLogOnProcess;
        }
        if ( currentRefreshSessionProcess && currentRefreshSessionProcess.state ===
          'pending' ) {
          currentRefreshSessionProcess.reject( );
        }
        deferred = currentLogOnProcess = $q.defer( );
        currentLogOnProcess.state = 'pending';
        currentLogOnProcess.promise.then( function( ) {
          currentLogOnProcess.state = 'resolved';
        }, function( ) {
          currentLogOnProcess.state = 'rejected';
        } );
        if ( !( username && password ) ) {
          var credentials = LYTSession.getCredentials( );
          if ( credentials ) {
            username = credentials.username;
            password = credentials.password;
          }
        }
        if ( !( username && password ) ) {
          emit( 'logon:rejected' );
          deferred.reject( );
          return deferred.promise;
        }
        // attempts = ((_ref = LYT.config.service) != null ? _ref.logOnAttempts : void 0) || 3;

        // The maximum number of attempts to make
        attempts = 3;
        // (For readability, the handlers are separated out here)

        // TODO: Flesh out error handling
        failed = function( code, message ) {
          if ( code === DODPErrorCodes.RPC_UNEXPECTED_RESPONSE_ERROR ) {
            emit( 'logon:rejected' );
            return deferred.reject( );
          } else {
            if ( attempts > 0 ) {
              return attemptLogOn( );
            } else {
              emitError( code );
              return deferred.reject( code, message );
            }
          }
        };

        loggedOn = function( data ) {
          emit( 'logon:resolved' );

          LYTSession.setCredentials( username, password );
          LYTSession.setInfo( data );

          return DODP.getServiceAttributes( )
            .then( gotServiceAttrs )
            .then( function( ) {
              DODP.setReadingSystemAttributes( )
                .then( readingSystemAttrsSet )
                .catch( failed );
            } )
            .catch( failed );
        };
        readingSystemAttrsSet = function( ) {
          deferred.resolve( ); // returning that logon is Ok.
          if ( BookService.announcementsSupported( ) ) {
            return DODP.getServiceAnnouncements( )
              .then( gotServiceAnnouncements );
          }
        };

        gotServiceAnnouncements = function( /*announcements*/ ) {
          // Calling GUI to show announcements
          // TODO: return LYT.render.showAnnouncements(announcements);
        };

        attemptLogOn = function( ) {
          --attempts;
          // log.message('Service: Attempting log-on (' + attempts + ' attempt(s) left)');
          return DODP.logOn( username, password )
            .then( loggedOn )
            .catch( failed );
        };

        // Kick it off
        attemptLogOn( );
        return deferred.promise;
      };

      /* -------
       * # Public API
       * ## Basic operations
       */
      var BookService = {
        logOn: logOn,
        onCurrentLogOn: onCurrentLogOn,
        /* Silently attempt to refresh a session. I.e. if this fails, no logOn errors are
         * emitted directly. This is intended for use with e.g. DTBDocument.
         * However, if there's an explicit logon process running, it'll use that
         */
        refreshSession: function( ) {
          var deferred, fail, gotServiceAttrs, loggedOn, password,
            readingSystemAttrsSet, username;
          if ( currentLogOnProcess && currentLogOnProcess.state ===
            'pending' ) {
            return currentLogOnProcess;
          }
          if ( currentRefreshSessionProcess &&
            currentRefreshSessionProcess.state === 'pending' ) {
            return currentRefreshSessionProcess;
          }
          deferred = currentRefreshSessionProcess = $q.defer( );
          currentRefreshSessionProcess.state = 'pending';
          currentRefreshSessionProcess.promise.then( function( ) {
            currentRefreshSessionProcess.state = 'resolved';
          }, function( ) {
            currentRefreshSessionProcess.state = 'rejected';
          } );
          fail = function( ) {
            return deferred.reject( );
          };
          var credentials = LYTSession.getCredentials( );
          if ( credentials ) {
            username = credentials.username;
            password = credentials.password;
          }
          if ( !( username && password ) ) {
            fail( );
            return deferred.promise;
          }
          loggedOn = function( ) {
            return DODP.getServiceAttributes( )
              .then( gotServiceAttrs, fail );
          };
          gotServiceAttrs = function( ) {
            return DODP.setReadingSystemAttributes( )
              .then( readingSystemAttrsSet, fail );
          };
          readingSystemAttrsSet = function( ) {
            return deferred.resolve( );
          };
          DODP.logOn( username, password )
            .then( loggedOn, fail );
          return deferred.promise;
        },
        /*
         * TODO: Can logOff fail? If so, what to do? Very zen!
         * Also, there should probably be some global "cancel all
         * outstanding ajax calls!" when log off is called
         * ----: No, Nota's service implementation always returns true when calling
         *       logOff(). Other service implementations may behave differently.
         */
        logOff: function( ) {
          return DODP.logOff( )
            .finally( function( ) {
              LYTSession.clear( );

              return emit( 'logoff' );
            } );
        },
        issue: function( bookId ) {
          return withLogOn( function( ) {
            return DODP.issueContent( bookId );
          } );
        },
        'return': function( bookId ) {
          return withLogOn( function( ) {
            return DODP.returnContent( bookId );
          } );
        },
        getMetadata: function( bookId ) {
          return withLogOn( function( ) {
            return DODP.getContentMetadata( bookId );
          } );
        },
        getResources: function( bookId ) {
          return withLogOn( function( ) {
            return DODP.getContentResources( bookId );
          } );
        },
        /*
         * The the list of issued content (i.e. the bookshelf)
         * Note: The `getContentList` API gets items by range
         * I.e. from 1 item index to (and including) another
         * index. So getting item 0 to 5, will get you 6 items.
         * Specifying `-1` as the `to` argument will get all
         * items from the `from` index to the end of the list
         */
        getBookshelf: function( from, to ) {
          var deferred, response;
          if ( !from ) {
            from = 0;
          }
          if ( to === undefined ) {
            to = -1;
          }

          deferred = $q.defer( );
          response = withLogOn( function( ) {
            return DODP.getContentList( 'issued', from, to );
          } );
          response.then( function( list ) {
            return deferred.resolve( list );
          } );
          response.catch( function( err, message ) {
            return deferred.reject( err, message );
          } );
          return deferred.promise;
        },

        /* -------
         * ## Optional operations
         */
        bookmarksSupported: function( ) {
          return operations.GET_BOOKMARKS && operations.SET_BOOKMARKS;
        },
        getBookmarks: function( bookId ) {
          return withLogOn( function( ) {
            return DODP.getBookmarks( bookId );
          } );
        },
        setBookmarks: function( bookmarks ) {
          var _ref, _ref1, _ref2, _ref3;
          if ( lastBookmark && lastBookmark.bookId === bookmarks.id &&
            lastBookmark.URI === ( ( _ref = bookmarks.lastmark ) ? _ref.URI :
              void 0 ) && lastBookmark.timeOffset === ( ( _ref1 =
              bookmarks.lastmark ) ? _ref1.timeOffse : void 0 ) ) {
            // log.message('setBookmarks: same as last time');
            return;
          }
          lastBookmark = {
            bookId: bookmarks.id,
            URI: ( _ref2 = bookmarks.lastmark ) ? _ref2.URI : void 0,
            timeOffset: ( _ref3 = bookmarks.lastmark ) ? _ref3.timeOffset : void 0
          };
          return withLogOn( function( ) {
            return DODP.setBookmarks( bookmarks );
          } );
        },
        announcementsSupported: function( ) {
          return operations.SERVICE_ANNOUNCEMENTS;
        },
        markAnnouncementsAsRead: function( AnnouncementsIDS ) {
          return withLogOn( function( ) {
            return DODP.markAnnouncementsAsRead( AnnouncementsIDS );
          } );
        },
        getAnnouncements: function( ) {
          var deferred = $q.defer( );
          if ( BookService.announcementsSupported( ) ) {
            withLogOn( function( ) {
              return DODP.getServiceAnnouncements( );
            } )
              .then( function( /*announcements*/ ) {
                // LYT.render.showAnnouncements(announcements);
                return deferred.resolve( );
              } )
              .catch( function( err, message ) {
                return deferred.reject( err, message );
              } );
          } else {
            deferred.reject( );
          }
          return deferred.promise;
        }
      };

      return BookService;
    }
  ] );
