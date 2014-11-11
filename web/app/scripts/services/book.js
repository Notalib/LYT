'use strict';

/**
 * @ngdoc service
 * @name lyt3App.Book
 * @description
 * # Book
 * Factory in the lyt3App.
 */
angular.module( 'lyt3App' )
  .factory( 'Book', [ '$q', 'LYTUtils', 'BookService', 'BookErrorCodes', 'NCCDocument', 'SMILDocument',
    function( $q, LYTUtils, BookService, BookErrorCodes, NCCDocument, SMILDocument ) {
      var __indexOf = [].indexOf || function( item ) {
        for ( var i = 0, l = this.length; i < l; i++ ) {
          if ( i in this && this[ i ] === item ) {
            return i;
          }
        }
        return -1;
      };

      /*
       * The constructor takes one argument; the ID of the book.
       * The instantiated object acts as a Deferred object, as the instantiation of a book
       * requires several RPCs and file downloads, all of which are performed asynchronously.
       *
       * Here's an example of how to load a book for playback:
       *
       *     # Instantiate the book
       *     book = new LYT.Book 123
       *
       *     # Set up a callback for when the book's done loading
       *     # The callback receives the book object as its argument
       *     book.then (book) ->
       *       # Do something with the book
       *
       *     # Set up a callback to handle any failure to load the book
       *     book.fail () ->
       *       # Do something about the failure
       */
      function Book( id ) {
        var getBookmarks, getNCC, getResources, issue, pending, resolve;
        this.id = id;
        var deferred = $q.defer();
        this.promise = deferred.promise;

        this.resources = {};
        this.nccDocument = null;
        pending = 2;
        resolve = ( function( _this ) {
          return function() {
            return --pending || deferred.resolve( _this );
          };
        } )( this );

        // First step: Request that the book be issued
        issue = ( function( _this ) {
          return function() {
            // Perform the RPC
            var issued = BookService.issue( _this.id );
            // When the book has been issued, proceed to download
            // its resources list, ...
            issued.then( getResources );

            // ... or fail
            return issued.catch( function() {
              return deferred.reject( BookErrorCodes.BOOK_ISSUE_CONTENT_ERROR );
            } );
          };
        } )( this );

        getResources = ( function( _this ) {
          return function() {
            var got;
            got = BookService.getResources( _this.id );
            got.catch( function() {
              return deferred.reject( BookErrorCodes.BOOK_CONTENT_RESOURCES_ERROR );
            } );

            return got.then( function( resources ) {
              var localUri, ncc, origin, path, uri;
              ncc = null;
              for ( localUri in resources ) {
                if ( !resources[ localUri ] ) {
                  continue;
                }
                uri = resources[ localUri ];

                // We lowercase all resource lookups to avoid general case-issues
                localUri = localUri.toLowerCase();

                // Each resource is identified by its relative path,
                // and contains the properties `url` and `document`
                // (the latter initialized to `null`)
                // Urls are rewritten to use the origin server just
                // in case we are behind a proxy.
                origin = document.location.href.match( /(https?:\/\/[^\/]+)/ )[ 1 ];
                path = uri.match( /https?:\/\/[^\/]+(.+)/ )[ 1 ];
                _this.resources[ localUri ] = {
                  url: origin + path,
                  document: null
                };
                if ( localUri.match( /^ncc\.x?html?$/i ) ) {
                  ncc = _this.resources[ localUri ];
                }
              }

              // If the url of the resource is the NCC document,
              // save the resource for later
              if ( ncc ) {
                getNCC( ncc );
                return getBookmarks();
              } else {
                return deferred.reject( BookErrorCodes.BOOK_NCC_NOT_FOUND_ERROR );
              }
            } );
          };
        } )( this );

        // Third step: Get the NCC document
        getNCC = ( function( _this ) {
          return function( obj ) {
            // Instantiate an NCC document
            var ncc = new NCCDocument( obj.url, _this );
            var nccPromise = ncc.promise;

            // Propagate a failure
            nccPromise.catch( function() {
              return deferred.reject( BookErrorCodes.BOOK_NCC_NOT_LOADED_ERROR );
            } );
            return nccPromise.then( function( document ) {
              obj.document = _this.nccDocument = document;
              var metadata = _this.nccDocument.getMetadata();
              var authors = (metadata.creator || []).forEach(function(creator){
                return creator.content;
              });

              // Get the author(s)
              _this.author = LYTUtils.toSentence( authors );

              // Get the title
              _this.title = metadata.title ? metadata.title.content : '';

              // Get the total time
              _this.totalTime = metadata.totalTime ? metadata.totalTime.content : '';
              ncc.book = _this;
              return resolve();
            } );
          };
        } )( this );
        getBookmarks = ( function( _this ) {
          return function() {
            var process;
            _this.lastmark = null;
            _this.bookmarks = [];
            // log.message("Book: Getting bookmarks");
            process = BookService.getBookmarks( _this.id );

            // TODO: perhaps bookmarks should be loaded lazily, when required?
            process.catch( function() {
              return deferred.reject( BookErrorCodes.BOOK_BOOKMARKS_NOT_LOADED_ERROR );
            } );
            return process.then( function( data ) {
              if ( data ) {
                _this.lastmark = data.lastmark;
                _this.bookmarks = data.bookmarks;
                _this._normalizeBookmarks();
              }
              return resolve();
            } );
          };
        } )( this );

        // Kick the whole process off
        issue( this.id );
      }

      // Returns all .smil files in the @resources array
      Book.prototype.getSMILFiles = function() {
        var res, _results;
        _results = [];
        for ( res in this.resources ) {
          if ( this.resources[ res ].url.match( /\.smil$/i ) ) {
            _results.push( res );
          }
        }
        return _results;
      };

      // Returns all SMIL files which is referred to by the NCC document in order
      Book.prototype.getSMILFilesInNCC = function() {
        var ordered, section, _i, _len, _ref, _ref1;
        ordered = [];
        _ref = this.nccDocument.sections;
        for ( _i = 0, _len = _ref.length; _i < _len; _i++ ) {
          section = _ref[ _i ];
          if ( !( _ref1 = section.url, __indexOf.call( ordered, _ref1 ) >= 0 ) ) {
            ordered.push( section.url );
          }
        }
        return ordered;
      };

      Book.prototype.loadAllSMIL = function( ) {
        var promises = [];

        var defer = $q.defer();

        this.getSMILFiles().forEach(function( url ) {
          promises.push(this.getSMIL(url));
        }, this);

        $q.all(promises)
          .then(function(smildocuments) {
            defer.resolve(smildocuments);
          });

        return defer.promise;
      };

      Book.prototype.getSMIL = function( url ) {
        url = url.toLowerCase();
        var deferred = $q.defer();
        if ( !( url in this.resources ) ) {
          return deferred.reject();
        }
        var smil = this.resources[ url ];
        if ( !smil.document ) {
          smil.document = new SMILDocument( smil.url, this );
          smil.document.promise
            .then( function( smilDocument ) {
              return deferred.resolve( smilDocument );
            } )
            .catch( function( error ) {
              smil.document = null;
              return deferred.reject( error );
            } );
        } else {
          deferred.resolve(smil.document);
        }
        return deferred.promise;
      };

      Book.prototype.firstSegment = function() {
        return this.nccDocument.promise.then( function( document ) {
            return document.firstSection();
          } )
          .then( function( section ) {
            return section.firstSegment();
          } );
      };

      Book.prototype.getSectionBySegment = function( segment ) {
        var current, id, item, iterator, refs, section, _ref;
        refs = ( function() {
          var _i, _len, _ref, _results;
          _ref = this.nccDocument.sections;
          _results = [];
          for ( _i = 0, _len = _ref.length; _i < _len; _i++ ) {
            section = _ref[ _i ];
            _results.push( section.fragment );
          }
          return _results;
        } )
          .call( this );
        current = segment;

        // Inclusive backwards search
        iterator = function() {
          var result;
          result = current;
          current = !current ? current.previous : void 0;
          return result;
        };

        var itemEach = function() {
          var childID;
          childID = this.getAttribute( 'id' );
          if ( __indexOf.call( refs, childID ) >= 0 ) {
            id = childID;
            return false; // Break out early
          }
        };
        while ( !id && ( item = iterator() ) ) {
          if ( _ref = item.id, __indexOf.call( refs, _ref ) >= 0 ) {
            id = item.id;
          } else {
            item.el.find( '[id]' )
              .each( itemEach );
          }
        }
        section = this.nccDocument.sections[ refs.indexOf( id ) ];
        return section;
      };

      // Gets the book's metadata (as stated in the NCC document)
      Book.prototype.getMetadata = function() {
        if ( this.nccDocument ) {
          return this.nccDocument.getMetadata();
        }
        return null;
      };

      Book.prototype.saveBookmarks = function() {
        return BookService.setBookmarks( this );
      };

      Book.prototype._sortBookmarks = function() {
        var smils, tmpBookmarks;
        // log.message("Book: _sortBookmarks");
        smils = this.getSMILFilesInNCC();
        tmpBookmarks = ( this.bookmarks || [] )
          .slice( 0 );
        tmpBookmarks.sort( function( aMark, bMark ) {
          var aMarkID, aMarkIndex, aMarkSmil, bMarkID, bMarkIndex, bMarkSmil, _ref, _ref1;
          _ref = aMark.URI.split( '#' );
          aMarkSmil = _ref[ 0 ];
          aMarkID = _ref[ 1 ];
          aMarkIndex = smils.indexOf( aMarkSmil );
          _ref1 = bMark.URI.split( '#' );
          bMarkSmil = _ref1[ 0 ];
          bMarkID = _ref1[ 1 ];
          bMarkIndex = smils.indexOf( bMarkSmil );
          if ( aMarkIndex < bMarkIndex ) {
            return -1;
          } else if ( aMarkIndex === bMarkIndex ) {
            return aMark.timeOffset - bMark.timeOffset;
          } else if ( aMarkIndex > bMarkIndex ) {
            return 1;
          }
        } );
        this.bookmarks = tmpBookmarks;
        return this.bookmarks;
      };

      // Delete all bookmarks that are very close to each other
      Book.prototype._normalizeBookmarks = function() {
        var bookmark, bookmarks, i, saved, temp, uri, _i, _len, _name, _ref, _ref1, _results;
        temp = {};
        _ref = this.bookmarks;
        for ( _i = 0, _len = _ref.length; _i < _len; _i++ ) {
          bookmark = _ref[ _i ];
          if ( !temp[ _name = bookmark.URI ] ) {
            temp[ _name ] = [];
          }
          i = 0;
          while ( i < temp[ bookmark.URI ].length ) {
            saved = temp[ bookmark.URI ][ i ];
            if ( ( -2 < ( _ref1 = saved.timeOffset - bookmark.timeOffset ) && _ref1 < 2 ) ) {
              break;
            }
            i++;
          }
          temp[ bookmark.URI ][ i ] = bookmark;
        }
        this.bookmarks = [];
        _results = [];
        for ( uri in temp ) {
          bookmarks = temp[ uri ];
          _results.push( this.bookmarks = this.bookmarks.concat( bookmarks ) );
        }
        return _results;
      };

      // TODO: Add remove bookmark method
      Book.prototype.addBookmark = function( segment, offset ) {
        var bookmark, section;
        if ( offset === undefined ) {
          offset = 0;
        }
        // log.message("Book: addBookmark");
        bookmark = segment.bookmark( offset );
        section = this.getSectionBySegment( segment );

        // Add closest section's title as bookmark title
        bookmark.note = {
          text: section.title
        };

        // Add to bookmarks and save
        if ( !this.bookmarks ) {
          this.bookmarks = [];
        }
        this.bookmarks.push( bookmark );
        this._normalizeBookmarks();
        this._sortBookmarks();
        return this.saveBookmarks();
      };

      Book.prototype.setLastmark = function( segment, offset ) {
        if ( offset === undefined ) {
          offset = 0;
        }
        this.lastmark = segment.bookmark( offset );
        return this.saveBookmarks();
      };

      Book.prototype.segmentByURL = function( url ) {
        var fragment;
        var deferred = $q.defer();
        var _ref = url.split( '#' );
        var smil = _ref[ 0 ].split( '/' )
          .pop();
        fragment = _ref[ 1 ];
        this.getSMIL( smil )
          .then( function( document ) {
            var segment;
            if ( fragment ) {
              segment = document.getContainingSegment( fragment );
            } else {
              segment = document.segments[ 0 ];
            }
            if ( segment ) {
              return segment.load()
                .then( function( segment ) {
                  return deferred.resolve( segment );
                } );
            } else {
              return deferred.reject();
            }
          } )
          .catch( function() {
            return deferred.reject();
          } );
        return deferred.promise;
      };

      // Get the following segment if we are very close to the end of the current
      // segment and the following segment starts within the fudge limit.
      Book.prototype._fudgeFix = function( offset, segment, fudge ) {
        if ( fudge === undefined ) {
          fudge = 0.1;
        }
        if ( segment.end - offset < fudge && segment.next && offset - segment.next.start < fudge ) {
          segment = segment.next;
        }
        return segment;
      };

      Book.prototype.segmentByAudioOffset = function( start, audio, offset, fudge ) {
        if ( offset === undefined ) {
          offset = 0;
        }
        if ( fudge === undefined ) {
          fudge = 0.1;
        }
        if ( !audio ) {
          // log.error('Book: segmentByAudioOffset: audio not provided');
          return $q.defer()
            .reject( 'audio not provided' );
        }

        // Using 0.01s to cover rounding errors (yes, they do occur)
        return this.searchSections( start, ( function( _this ) {
          return function( section ) {
            var segment, _i, _len, _ref;
            _ref = section.document.segments;
            for ( _i = 0, _len = _ref.length; _i < _len; _i++ ) {
              segment = _ref[ _i ];
              // FIXME: loading segments is the responsibility of the section each
              // each segment belongs to.
              if ( segment.audio === audio && ( segment.start - 0.01 <= offset && offset < segment.end + 0.01 ) ) {
                segment = _this._fudgeFix( offset, segment );
                // log.message("Book: segmentByAudioOffset: load segment " + (segment.url()));
                segment.load();
                return segment;
              }
            }
          };
        } )( this ) );
      };

      /*
       * Search for sections using a callback handler
       * Returns a jQuery promise.
       * handler: callback that will be called with one section at a time.
       *          If handler returns anything trueish, the search will stop
       *          and the promise will resolve with the returned trueish.
       *          If the handler returns anything falseish, the search will
       *          continue by calling handler once again with a new section.
       *
       *          If the handler exhausts all sections, the promise will reject
       *          with no return value.
       *
       * start:   the section to start searching from (default: current section).
       */
      Book.prototype.searchSections = function( start, handler ) {
        var i, iterator, iterators, makeIterator, searchNext;
        /*
      * The use of iterators below can easily be adapted to the Strategy
      * design pattern, accommodating other search orders.

      * Generate an iterator with start value start and nextOp to generate
      * the next value.
      * Will stop calling nextOp as soon as nextOp returns null or undefined
      */
        makeIterator = function( start, nextOp ) {
          var current;
          current = start;
          return function() {
            var result;
            result = current;
            if ( current !== undefined ) {
              current = nextOp( current );
            }
            return result;
          };
        };
        /*
         * This iterator configuration will make the iterator return this:
         * this
         * this.next
         * this.previous
         * this.next.next
         * this.previous.previous
         * ...
         */
        iterators = [
          makeIterator( start, function( section ) {
            return section.previous;
          } ), makeIterator( start, function( section ) {
            return section.next;
          } )
        ];

        // This iterator will query the iterators in the iterators array one at a
        // time and remove them from the array if they stop returning anything.
        i = 0;
        iterator = function() {
          var result;
          result = null;
          while ( ( result === undefined ) && i < iterators.length ) {
            result = iterators[ i ].apply();
            if ( result === undefined ) {
              iterators.splice( i );
            }
            i++;
            i %= iterators.length;
            if ( result ) {
              return result;
            }
          }
        };
        searchNext = function() {
          var section = iterator();
          if ( section ) {
            section.load();
            return section.then( function( section ) {
              var result = handler( section );
              if ( result ) {
                return result;
              } else {
                return searchNext();
              }
            } );
          } else {
            return $q.defer()
              .reject();
          }
        };
        return searchNext();
      };

      // Factory-method
      // Note: Instances are cached in memory
      Book.load = ( function() {
        var loaded = {};
        return function( id ) {
          if ( !loaded[ id ] ) {
            loaded[ id ] = new Book( id );
          }
          return loaded[ id ].promise;
        };
      } )();

      /*
       * "Class"/"static" method for retrieving a
       * book's metadata
       * Note: Results are cached in memory
       *
       * DEPRECATED: Use `catalog.getDetails()` instead
       */
      Book.getDetails = ( function() {
        var loaded = {};
        return function( id ) {
          var deferred = $q.defer();
          // log.warn("Book.getDetails is deprecated. Use catalog.getDetails() instead");
          if ( loaded[ id ] ) {
            deferred.resolve( loaded[ id ] );
            return deferred;
          }
          BookService.getMetadata( id )
            .then( function( metadata ) {
              loaded[ id ] = metadata;
              return deferred.resolve( metadata );
            } )
            .catch( function() {
              var args;
              args = 1 <= arguments.length ? Array.prototype.slice.call( arguments, 0 ) : [];
              return deferred.reject.apply( deferred, args );
            } );
          return deferred.promise;
        };
      } )();

      // Public API here
      return Book;
    }
  ] );
