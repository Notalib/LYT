'use strict';

angular.module( 'lyt3App' )
  .factory( 'Book', [ '$q', '$log', 'LYTUtils', 'BookService', 'BookErrorCodes',
    'NCCDocument', 'SMILDocument',
    function( $q, $log, LYTUtils, BookService, BookErrorCodes, NCCDocument,
      SMILDocument ) {
      /*
       * The constructor takes one argument; the ID of the book.
       * The instantiated object acts as a Deferred object, as the instantiation of a book
       * requires several RPCs and file downloads, all of which are performed asynchronously.
       *
       * Here's an example of how to load a book for playback:
       *
       *     # Instantiate the book
       *     book = new Book( 123 )
       *
       *     # Set up a callback for when the book's done loading
       *     # The callback receives the book object as its argument
       *     book.promise.then (book) ->
       *       # Do something with the book
       *
       *     # Set up a callback to handle any failure to load the book
       *     book.promise.catch () ->
       *       # Do something about the failure
       */
      function Book( id ) {
        this.id = id;
        var deferred = $q.defer( );
        this.promise = deferred.promise;

        this.resources = {};
        this.nccDocument = null;

        var pending = 2;
        var resolve = function( ) {
          return --pending || deferred.resolve( this );
        }.bind( this );

        // First step: Request that the book be issued
        var issue = function( ) {
          // Perform the RPC
          var issued = BookService.issue( this.id );
          // When the book has been issued, proceed to download
          // its resources list, ...
          issued.then( getResources );

          // ... or fail
          return issued.catch( function( ) {
            return deferred.reject( BookErrorCodes.BOOK_ISSUE_CONTENT_ERROR );
          } );
        }.bind( this );

        var getResources = function( ) {
          var got = BookService.getResources( this.id );
          got.catch( function( ) {
            return deferred.reject( BookErrorCodes.BOOK_CONTENT_RESOURCES_ERROR );
          } );

          return got.then( function( resources ) {
            var ncc = null;
            Object.keys( resources ).forEach( function( localUri ) {
              var uri = resources[ localUri ];

              // We lowercase all resource lookups to avoid general case-issues
              localUri = localUri.toLowerCase( );

              // Each resource is identified by its relative path,
              // and contains the properties `url` and `document`
              // (the latter initialized to `null`)
              // Urls are rewritten to use the origin server just
              // in case we are behind a proxy.
              var origin = document.location.href.match(
                /(https?:\/\/[^\/]+)/ )[ 1 ];
              var path = uri.match( /https?:\/\/[^\/]+(.+)/ )[ 1 ];

              this.resources[ localUri ] = {
                url: origin + path,
                document: null
              };

              if ( localUri.match( /^ncc\.x?html?$/i ) ) {
                ncc = this.resources[ localUri ];
              }
            }, this );

            // If the url of the resource is the NCC document,
            // save the resource for later
            if ( ncc ) {
              getNCC( ncc );
              return getBookmarks( );
            } else {
              return deferred.reject( BookErrorCodes.BOOK_NCC_NOT_FOUND_ERROR );
            }
          }.bind( this ) );
        }.bind( this );

        // Third step: Get the NCC document
        var getNCC = function( obj ) {
          // Instantiate an NCC document
          var ncc = new NCCDocument( obj.url, this );
          var nccPromise = ncc.promise;

          // Propagate a failure
          nccPromise.catch( function( ) {
            return deferred.reject( BookErrorCodes.BOOK_NCC_NOT_LOADED_ERROR );
          } );

          nccPromise.then( function( document ) {
            obj.document = this.nccDocument = document;
            var metadata = this.nccDocument.getMetadata( );
            var authors = ( metadata.creator || [ ] ).map(
              function( creator ) {
                return creator.content;
              } );

            // Get the author(s)
            this.author = LYTUtils.toSentence( authors );

            // Get the title
            this.title = metadata.title ? metadata.title.content :
              '';

            // Get the total time
            this.totalTime = metadata.totalTime ? LYTUtils.parseTime( metadata.totalTime.content ) : null;
            ncc.book = this;
            resolve( );
          }.bind( this ) );
        }.bind( this );

        var getBookmarks = function( ) {
          this.lastmark = null;
          this.bookmarks = [ ];
          $log.log( 'Book: Getting bookmarks' );
          var process = BookService.getBookmarks( this.id );

          // TODO: perhaps bookmarks should be loaded lazily, when required?
          process.catch( function( ) {
            return deferred.reject( BookErrorCodes.BOOK_BOOKMARKS_NOT_LOADED_ERROR );
          } );

          return process.then( function( data ) {
            if ( data ) {
              this.lastmark = data.lastmark;
              this.bookmarks = data.bookmarks;
              normalizeBookmarks( this );
            }
            resolve( );
          }.bind( this ) );
        }.bind( this );

        // Kick the whole process off
        issue( this.id );
      }

      // Returns all .smil files in the @resources array
      Book.prototype.getSMILFiles = function( ) {
        return Object.keys( this.resources ).filter( function( key ) {
          return this.resources[ key ].url.match( /\.smil$/i );
        }, this );
      };

      // Returns all SMIL files which is referred to by the NCC document in order
      Book.prototype.getSMILFilesInNCC = function( ) {
        var ordered = [ ];
        this.nccDocument.sections.forEach( function( section ) {
          if ( ordered.indexOf( section.url ) === -1 ) {
            ordered.push( section.url );
          }
        } );
        return ordered;
      };

      Book.prototype.loadAllSMIL = function( ) {
        var promises = [ ];

        var defer = $q.defer( );

        this.getSMILFiles( ).forEach( function( url ) {
          promises.push( this.getSMIL( url ) );
        }, this );

        $q.all( promises )
          .then( function( smildocuments ) {
            defer.resolve( smildocuments );
          } );

        return defer.promise;
      };

      Book.prototype.getSMIL = function( url ) {
        url = url.toLowerCase( );
        var deferred = $q.defer( );
        if ( !( url in this.resources ) ) {
          return deferred.reject( );
        }

        var smil = this.resources[ url ];
        if ( !smil.document ) {
          smil.document = new SMILDocument( smil.url, this );
        }

        smil.document.promise
          .then( function( smilDocument ) {
            return deferred.resolve( smilDocument );
          } )
          .catch( function( error ) {
            smil.document = null;
            return deferred.reject( error );
          } );
        return deferred.promise;
      };

      Book.prototype.firstSegment = function( ) {
        return this.nccDocument.promise.then( function( document ) {
            return document.firstSection( );
          } )
          .then( function( section ) {
            return section.firstSegment( );
          } );
      };

      Book.prototype.getSectionBySegment = function( segment ) {
        var id, item;

        var sections = this.nccDocument.sections.map( function( section ) {
          return section.fragment;
        } );
        var current = segment;

        // Inclusive backwards search
        var iterator = function( ) {
          var result = current;
          current = !current ? current.previous : void 0;
          return result;
        };

        var itemEach = function( ) {
          var childID = this.getAttribute( 'id' );
          if ( sections.indexOf( childID ) > -1 ) {
            id = childID;
            return false; // Break out early
          }
        };

        while ( !id && ( item = iterator( ) ) ) {
          if ( item.id && sections.indexOf( item.id ) > -1 ) {
            id = item.id;
          } else {
            item.el.find( '[id]' )
              .each( itemEach );
          }
        }

        return this.nccDocument.sections[ sections.indexOf( id ) ];
      };

      // Gets the book's metadata (as stated in the NCC document)
      Book.prototype.getMetadata = function( ) {
        if ( this.nccDocument ) {
          return this.nccDocument.getMetadata( );
        }
        return null;
      };

      Book.prototype.saveBookmarks = function( ) {
        return BookService.setBookmarks( this );
      };

      var sortBookmarks = function( book ) {
        $log.log( 'Book: sortBookmarks' );

        var smils = book.getSMILFilesInNCC( );
        var tmpBookmarks = ( book.bookmarks || [ ] )
          .slice( 0 );

        tmpBookmarks.sort( function( aMark, bMark ) {
          var aMarkID, aMarkIndex, aMarkSmil, bMarkID, bMarkIndex,
            bMarkSmil, _ref, _ref1;
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
        book.bookmarks = tmpBookmarks;
      };

      // Delete all bookmarks that are very close to each other
      var normalizeBookmarks = function( book ) {
        var temp = {};
        book.bookmarks.forEach( function( bookmark ) {
          var name = bookmark.URI;
          if ( !temp[ name ] ) {
            temp[ name ] = [ ];
          }

          var tmpIdx = 0;
          temp[ name ].some( function( saved, idx ) {
            var tempOffset = saved.timeOffset - bookmark.timeOffset;
            if ( -2 < tempOffset && tempOffset < 2 ) {
              tmpIdx = idx;
              return true;
            }
          } );

          temp[ bookmark.URI ][ tmpIdx ] = bookmark;
        } );

        book.bookmarks = [];

        Object.keys( temp )
          .forEach( function( uri ) {
            book.bookmarks = book.bookmarks.concat( temp[ uri ] );
          } );
      };

      // TODO: Add remove bookmark method
      Book.prototype.addBookmark = function( segment, offset ) {
        var bookmark, section;
        if ( offset === undefined ) {
          offset = 0;
        }
        $log.log( 'Book: addBookmark' );
        bookmark = segment.bookmark( offset );
        section = this.getSectionBySegment( segment );

        // Add closest section's title as bookmark title
        bookmark.note = {
          text: section.title
        };

        // Add to bookmarks and save
        if ( !this.bookmarks ) {
          this.bookmarks = [ ];
        }
        this.bookmarks.push( bookmark );
        normalizeBookmarks( this );
        sortBookmarks( this );
        return this.saveBookmarks( );
      };

      Book.prototype.setLastmark = function( segment, offset ) {
        if ( offset === undefined ) {
          offset = 0;
        }
        this.lastmark = segment.bookmark( offset );
        return this.saveBookmarks( );
      };

      Book.prototype.segmentByURL = function( url ) {
        var deferred = $q.defer( );
        var _ref = url.split( '#' );
        var smil = _ref[ 0 ].split( '/' )
          .pop( );
        var fragment = _ref[ 1 ];
        this.getSMIL( smil )
          .then( function( document ) {
            var segment;
            if ( fragment ) {
              segment = document.getContainingSegment( fragment );
            } else {
              segment = document.segments[ 0 ];
            }
            if ( segment ) {
              return segment.load( )
                .then( function( segment ) {
                  return deferred.resolve( segment );
                } );
            } else {
              return deferred.reject( );
            }
          } )
          .catch( function( ) {
            return deferred.reject( );
          } );
        return deferred.promise;
      };

      // Get the following segment if we are very close to the end of the current
      // segment and the following segment starts within the fudge limit.
      var fudgeFix = function( offset, segment, fudge ) {
        if ( fudge === undefined ) {
          fudge = 0.1;
        }

        if ( segment.end - offset < fudge && segment.next && offset -
          segment.next.start < fudge ) {
          segment = segment.next;
        }

        return segment;
      };

      Book.prototype.segmentByAudioOffset = function( start, audio, offset,
        fudge ) {
        if ( offset === undefined ) {
          offset = 0;
        }

        if ( fudge === undefined ) {
          fudge = 0.1;
        }

        if ( !audio ) {
          $log.error( 'Book: segmentByAudioOffset: audio not provided' );
          return $q.defer( )
            .reject( 'audio not provided' );
        }

        // Using 0.01s to cover rounding errors (yes, they do occur)
        return this.searchSections( start, function( section ) {
          var res;

          section.document.segments.some( function( segment ) {
            if ( segment.audio === audio && ( segment.start - 0.01 <=
                offset && offset < segment.end + 0.01 ) ) {
              segment = fudgeFix( offset, segment );
              $log.log( 'Book: segmentByAudioOffset: load segment ' + ( segment.url( ) ) );
              segment.load( );
              res = segment;

              return true;
            }
          } );

          return res;
        } );
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
        /*
         * The use of iterators below can easily be adapted to the Strategy
         * design pattern, accommodating other search orders.

         * Generate an iterator with start value start and nextOp to generate
         * the next value.
         * Will stop calling nextOp as soon as nextOp returns null or undefined
         */
        var makeIterator = function( start, nextOp ) {
          var current = start;

          return function( ) {
            var result = current;
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
        var iterators = [
          makeIterator( start, function( section ) {
            return section.previous;
          } ), makeIterator( start, function( section ) {
            return section.next;
          } )
        ];

        // This iterator will query the iterators in the iterators array one at a
        // time and remove them from the array if they stop returning anything.
        var i = 0;
        var iterator = function( ) {
          var result;
          while ( result === undefined && i < iterators.length ) {
            result = iterators[ i ].apply( );
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

        var searchNext = function( ) {
          var section = iterator( );
          if ( section ) {
            section.load( );
            return section.promise.then( function( section ) {
              var result = handler( section );
              if ( result ) {
                return result;
              } else {
                return searchNext( );
              }
            } );
          } else {
            return $q.defer( )
              .reject( );
          }
        };

        return searchNext( );
      };

      /**
       * getStructure extractes the book information in plain object form,
       * return a promise-object that resolves with this structure:
       * {
       *  title: <BOOK_TITLE>,
       *  author: <BOOK_AUTHOR>,
       *  playlist: [
       *    {
       *      url: <SEGMENT_URL>,
       *      start: <START_OFFSET_IN_FILE>,
       *      end: <END_OFFSET_IN_FILE>
       *    }
       *  ],
       *  navigation: [
       *    {
       *      title: <CHAPTER_TITLE>,
       *      offset: <CHAPTER_OFFSET>
       *    }
       *  }
       * }
       */
      Book.prototype.getStructure = ( function( ) {
        var loaded = {};

        return function( ) {
          var defer = $q.defer( );
          if ( loaded[ this.id ] ) {
            defer.resolve( loaded[ this.id ] );
            return defer.promise;
          }

          // Make sure the book is loaded
          this.promise.then( function( ) {
            var bookStructure = {
              id: this.id,
              author: this.author,
              title: this.title,
              playlist: [ ],
              navigation: [ ]
            };

            var promises = this.nccDocument.structure.reduce(
              function( flat, section ) {
                return flat.concat( section.flatten( ) );
              }, [ ] ).map( function( section ) {
              var loadSegment = $q.defer( );
              this.segmentByURL( section.url + '#' + section.ref )
                .then( function( segment ) {
                  loadSegment.resolve( {
                    title: section.title,
                    offset: segment.getBookOffset( )
                  } );
                } );

              return loadSegment.promise;
            }, this );

            var loadNavigation = $q.all( promises )
              .then( function( segments ) {
                bookStructure.navigation = segments;
              } );

            var loadPlaylist = this.loadAllSMIL( )
              .then( function( smildocuments ) {
                smildocuments.forEach( function( smildocument ) {
                  smildocument.segments.forEach( function( segment ) {
                    bookStructure.playlist.push( {
                      url: segment.audio.url,
                      start: segment.start,
                      end: segment.end
                    } );
                  } );
                } );
              } );

            $q.all( [ loadNavigation, loadPlaylist ] )
              .then( function( ) {
                loaded[ bookStructure.id ] = bookStructure;
                defer.resolve( bookStructure );
              } );
          }.bind( this ) );

          return defer.promise;
        };
      } )( );

      Book.prototype.findSectionFromOffset = function( offset ) {
        var defer = $q.defer();

        this.loadAllSMIL( )
          .then( function( smildocuments ) {
            var matched;
            smildocuments.some( function( smildocument ) {
              var startOffset = smildocument.absoluteOffset;
              var endOffset = startOffset + smildocument.duration;
              if ( startOffset <= offset && offset <= endOffset ) {
                smildocument.segments.some( function( segment ) {
                  var segmentStart = startOffset + segment.documentOffset;
                  var segmentEnd = segmentStart + segment.duration;
                  if ( segmentStart <= offset && offset <= segmentEnd ) {
                    defer.resolve( segment );
                    matched = true;
                    return true;
                  }
                } );

                return true;
              }
            } );

            if ( !matched ) {
              $log.error( 'Couldn\'t find segment for offset ', offset );
              defer.reject( );
            }
          } )
          .catch( function( ) {
            defer.reject( );
          } );

        return defer.promise;
      };

      // Factory-method
      // Note: Instances are cached in memory
      Book.load = ( function( ) {
        var loaded = {};
        return function( id ) {
          if ( !loaded[ id ] ) {
            loaded[ id ] = new Book( id );
          }
          return loaded[ id ].promise;
        };
      } )( );

      // Public API here
      return {
        load: Book.load
      };
    }
  ] );
