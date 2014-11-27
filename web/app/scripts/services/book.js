'use strict';

angular.module( 'lyt3App' )
  .factory( 'Book', [ '$q', '$log', 'LYTUtils', 'BookNetwork', 'BookErrorCodes',
    'NCCDocument', 'SMILDocument',
    function( $q, $log, LYTUtils, BookNetwork, BookErrorCodes, NCCDocument, SMILDocument ) {
      /*
       * The constructor takes one argument; the ID of the book.
       * The instantiated object acts as a Deferred object, as the instantiation of a book
       * requires several RPCs and file downloads, all of which are performed asynchronously.
       *
       * The create a book use the Book.load( 123 ) factory method.
       * This returns a promise object that resolves with the finished book object.
       *
       * The constructor method shouldn't be used directly except for tests.
       */
      function Book( id ) {
        this.id = id;

        this.resources = {};
        this.currentPosition = 0;
        this.nccDocument = null;
        this.structure = null;
      }

      // Request the book to be issued from the DODP service,
      // this is required to stream the files.
      Book.prototype.issue = function( ) {
        if ( this.issuedPromise ) {
          return this.issuedPromise;
        }

        var deferred = $q.defer();
        this.issuedPromise = deferred.promise;
        var bookId = this.id;

        BookNetwork.issue( bookId )
          .then( function( ) {
            $log.log( 'Book ' + bookId + ' has been issued' );

            deferred.resolve( bookId );
          } )
          .catch( function( ) {
            deferred.reject( BookErrorCodes.BOOK_ISSUE_CONTENT_ERROR );
          } )
          .finally( function( ) {
            delete this.issuedPromise;
          }.bind( this ) );

        return this.issuedPromise;
      };

      // Load the list of resources from DODP, this is required to load any content files.
      Book.prototype.loadResources = function( ) {
        if ( this.resourcePromise ) {
          return this.resourcePromise;
        }

        var deferred = $q.defer();
        this.resourcePromise = deferred.promise;

        BookNetwork.getResources( this.id )
          .then( function( resources ) {
            var ncc = null;
            Object.keys( resources )
              .forEach( function( localUri ) {
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
              this.nccData = ncc;
              deferred.resolve( );
            } else {
              deferred.reject( BookErrorCodes.BOOK_NCC_NOT_FOUND_ERROR );
            }
          }.bind( this ) )
          .catch( function( ) {
            deferred.reject( BookErrorCodes.BOOK_CONTENT_RESOURCES_ERROR );
          } );

        return this.resourcePromise;
      };

      // Load bookmarks from the DODP service.
      Book.prototype.loadBookmarks = function( ) {
        if ( this.bookmarkPromise ) {
          return this.bookmarkPromise;
        }

        var deferred = $q.defer();
        this.bookmarkPromise = deferred.promise;

        this.lastmark = null;
        this.bookmarks = null;
        $log.log( 'Book: Getting bookmarks' );

        BookNetwork.getBookmarks( this.id )
          .then( function( data ) {
            this.bookmarks = [];
            if ( data ) {
              this.lastmark = data.lastmark;
              // TODO: Update book.currentPosition from lastmark;
              $log.warn( 'Book: loadBookmarks: lastmark updated. currentPosition should be updated' );

              this.bookmarks = data.bookmarks || [];
              normalizeBookmarks( this );
            }

            deferred.resolve( );
          }.bind( this ) )
          .catch( function( ) {
            // TODO: perhaps bookmarks should be loaded lazily, when required?
            deferred.reject( BookErrorCodes.BOOK_BOOKMARKS_NOT_LOADED_ERROR );
          } );

        return this.bookmarkPromise;
      };

      // Load and parse the NCCDocument for this book. This is required to know which order to play for book
      // and to have the navigation-index.
      Book.prototype.loadNCC = function( ) {
        if ( this.nccPromise ) {
          return this.nccPromise;
        }

        var deferred = $q.defer();
        this.nccPromise = deferred.promise;

        // Instantiate an NCC document
        var ncc = new NCCDocument( this.nccData.url, this );
        ncc.promise
          .then( function( document ) {
            this.nccData.document = this.nccDocument = document;
            var metadata = this.nccDocument.getMetadata( );
            var authors = ( metadata.creator || [ ] ).map(
              function( creator ) {
                return creator.content;
              } );

            // Get the author(s)
            this.author = LYTUtils.toSentence( authors );

            // Get the title
            this.title = metadata.title ? metadata.title.content : '';

            // Get the total time
            this.totalTime = metadata.totalTime ? LYTUtils.parseTime( metadata.totalTime.content ) : null;
            ncc.book = this;

            deferred.resolve( document );
          }.bind( this ) )
          .catch( function( ) {
            // Propagate a failure
            deferred.reject( BookErrorCodes.BOOK_NCC_NOT_LOADED_ERROR );
          } );

        return this.nccPromise;
      };

      var isSMIL = /\.smil$/i;

      // Returns all .smil files in the @resources array
      Book.prototype.getSMILFiles = function( ) {
        var res = Object.keys( this.resources )
          .filter( function( key ) {
            return this.resources[ key ].url.match( isSMIL );
          }, this );

        return res;
      };

      // Returns all SMIL files which is referred to by the NCC document in order
      Book.prototype.getSMILFilesInNCC = function( ) {
        var temp = {};
        return this.nccDocument.sections.map( function( section ) {
          return section.url;
        } ).filter( function( url ) {
          if ( url.match( isSMIL ) && !temp[ url ] ) {
            temp[ url ] = true;
            return true;
          }

          return false;
        } );
      };

      Book.prototype.loadAllSMIL = function( ) {
        if ( this.loadAllSMILPromise ) {
          return this.loadAllSMILPromise;
        }

        var promises = [ ];

        var deferred = $q.defer( );

        this.getSMILFiles( )
          .forEach( function( url ) {
            promises.push( this.getSMIL( url ) );
          }, this );

        $q.all( promises )
          .then( function( smildocuments ) {
            deferred.resolve( smildocuments );
          } )
          .catch( function( ) {
            deferred.reject();
          } );

        this.loadAllSMILPromise = deferred.promise;

        return this.loadAllSMILPromise;
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
            deferred.resolve( smilDocument );
          } )
          .catch( function( error ) {
            smil.document = null;
            deferred.reject( error );
          } );
        return deferred.promise;
      };

      Book.prototype.firstSegment = function( ) {
        if ( !this.nccDocument ) {
          var errorMsg = 'Book: ' + this.id + ', nccDocument required for firstSegment';
          $log.error( errorMsg );
          throw Error( errorMsg );
        }

        return this.nccDocument.promise.then( function( document ) {
            return document.firstSection( );
          } )
          .then( function( section ) {
            return section.firstSegment( );
          } );
      };

      Book.prototype.getSectionBySegment = function( segment ) {
        if ( !this.nccDocument ) {
          var errorMsg = 'Book: ' + this.id + ', nccDocument required for getSectionBySegment';
          $log.error( errorMsg );
          throw Error( errorMsg );
        }

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
        return BookNetwork.setBookmarks( this );
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
        offset = Math.max( offset || 0, 0 );

        $log.log( 'Book: addBookmark' );

        var bookmark = segment.bookmark( offset );
        var section = this.getSectionBySegment( segment );

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
        this.saveBookmarks( );
      };

      Book.prototype.setLastmark = function( ) {
        var currentPosition = this.currentPosition;
        var defer = $q.defer( );

        this.findSegmentFromOffset( currentPosition )
          .then( function( segment ) {
            this.lastmark = segment.bookmark( currentPosition );
            this.saveBookmarks( )
              .then( function( stored ) {
                defer.resolve( stored );
              } )
              .catch( function( ) {
                defer.reject( );
              } );
          }.bind( this ) )
          .catch( function( ) {
            defer.reject( );
          } );

        return defer.promise;
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
            section.load( )
              .then( function( section ) {
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
      Book.prototype.getStructure = function( ) {
        var defer = $q.defer( );
        if ( this.structure ) {
          defer.resolve( this.structure );
          return defer.promise;
        }

        // Make sure the book is loaded
        this.loadNCC().then( function( ) {
          var bookStructure = {
            id: this.id,
            author: this.author,
            title: this.title,
            playlist: [ ],
            navigation: [ ]
          };

          // Create the navigation-list, by walking through the nccDocument.structure
          var promises = this.nccDocument.structure.reduce(
            function( flat, section ) {
              // We want all levels of the navigation hieraki
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

          // Once all the navigation items have been loaded, add them to bookStructure
          var loadNavigation = $q.all( promises )
            .then( function( segments ) {
              bookStructure.navigation = segments;
            } );

          var duration = 0;

          var playlist = [];

          // Generate the playlist, e.g. list of all audio-files and their start/end-offsets
          var loadPlaylist = this.loadAllSMIL( )
            .then( function( smildocuments ) {
              smildocuments.forEach( function( smildocument ) {
                smildocument.segments.forEach( function( segment ) {
                  duration += segment.duration;

                  playlist.push( {
                    url: segment.audio.url,
                    start: segment.start,
                    end: segment.end
                  } );
                } );
              } );
            } );

          loadPlaylist.then( function( ) {
            // Clean up the playlist, before returning in
            // A mp3-file is usually used in more than one segment, with the last end-offset
            // equals the start-offset in the next segment.
            bookStructure.playlist = playlist.reduce( function( output, item ) {
              item = angular.copy( item );

              if ( output.length ) {
                var lastItem = output.pop();
                // Get the last item in the out
                if ( lastItem.url === item.url &&
                    lastItem.end.toFixed(3) === item.start.toFixed(3) ) {
                  // Since the two items have the same url and their end- and start-offset
                  // match to precition of 3 decimals. We can assume they're in sequence.
                  item.start = lastItem.start;
                } else {
                  output.push( lastItem );
                }
              }

              output.push( item );
              return output;
            }, [] );
          } );

          $q.all( [ loadNavigation, loadPlaylist ] )
            .then( function( ) {
              this.structure = bookStructure;
              this.duration = duration;
              defer.resolve( bookStructure );
            }.bind( this ) );
        }.bind( this ) );

        return defer.promise;
      };

      // Find the segment from an absolute offset in the book.
      // Returns a promise object.
      Book.prototype.findSegmentFromOffset = function( offset ) {
        var defer = $q.defer();

        this.loadAllSMIL( )
          .then( function( smildocuments ) {
            var res;
            smildocuments.some( function( smildocument ) {
              res = smildocument.getSegmentAtAbsoluteOffset( offset );

              return !!res;
            } );

            if ( res ) {
              defer.resolve( res );
            } else {
              $log.error( 'Couldn\'t find segment for offset ', offset, smildocuments );
              defer.reject( );
            }
          } )
          .catch( function( ) {
            defer.reject( );
          } );

        return defer.promise;
      };

      // Factory-method, for generating a Book-object.
      // A book object is created and the required data is loaded.
      // Note: Instances are cached in memory
      Book.load = ( function( ) {
        var loaded = {};

        return function( id ) {
          var book = loaded[ id ];
          if ( !book ) {
            book = new Book( id );
            loaded[ id ] = book;
          }

          var deferred = $q.defer();

          var reject = function( rejected ) {
            deferred.reject( rejected );
          };

          book.issue( )
            .then( function( ) {
              book.loadResources( )
                .then( function( ) {
                  book.loadBookmarks( )
                    .then( function( ) {
                      book.loadNCC( )
                        .then( function( ) {
                          book.getStructure( )
                            .then( function( ) {
                              deferred.resolve( book );
                            } )
                            .catch( reject );
                        } )
                        .catch( reject );
                    } )
                    .catch( reject );
                } )
                .catch( reject );
            } )
            .catch( reject );

          return deferred.promise;
        };
      } )( );

      // Public API here
      return Book;
    }
  ] );
