/*global jQuery: false */
'use strict';

angular.module( 'lyt3App' )
  .factory( 'Section', [ '$q', '$log', function( $q, $log ) {
    function Section( heading, book ) {
      var anchor, _ref;
      this.book = book;
      this._deferred = $q.defer( );
      this.promise = this._deferred.promise;

      // Wrap the heading in a jQuery object
      heading = jQuery( heading );

      // Get the basic attributes
      this.ref = heading.attr( 'id' );
      this[ 'class' ] = heading.attr( 'class' );

      // Get the anchor element of the heading, and its attributes
      anchor = heading.find( 'a:first' );
      this.title = jQuery.trim( anchor.text( ) );

      // The [NCC](http://www.daisy.org/z3986/specifications/daisy20.php#5.0%20NAVIGATION%20CONTROL%20CENTER%20%28NCC%29)
      // standard dictates that all references should point to a specific par or
      // seq id in the SMIL file. Since the section class represents the entire
      // SMIL file, we remove the id reference from the url.
      _ref = ( anchor.attr( 'href' ) ).split( '#' );
      this.url = _ref[ 0 ];
      this.fragment = _ref[ 1 ];

      // We get some weird uris from IE8 due to missing documentElement substituted with iframe contentDocument.
      // Here we trim away everything before the filename.
      if ( this.url.lastIndexOf( '/' ) !== -1 ) {
        this.url = this.url.substr( this.url.lastIndexOf( '/' ) + 1 );
      }

      // Create an array to collect any sub-headings
      this.children = [ ];
      this.document = null;

      // If this is a "meta-content" section (listed in src/config/config.coffee)
      // this property will be set to true
      this.metaContent = false;
    }

    Section.prototype.load = function( ) {
      if ( this.loading || this.loaded ) {
        return this;
      }

      this.loading = true;
      this.promise.finally( function( ) {
        this.loading = false;
      }.bind(this) );

      $log.log('Section: loading(\'' + this.url + '\')');
      // trim away everything after the filename.
      var file = ( this.url.replace( /#.*$/, '' ) ).toLowerCase( );
      if ( !this.book.resources[ file ] ) {
        $log.error('Section: load: url not found in resources: ' + file);
      }

      this.book.getSMIL( file )
        .then( function( document ) {
          this.loaded = true;
          this.document = document;

          this._deferred.resolve( this );
        }.bind(this))
        .catch( function( ) {
          $log.error( 'Section: Failed to load SMIL-file ' + ( this.url.replace( /#.*$/, '' ) ) ) ;
          return this._deferred.reject( );
        }.bind(this) );

      return this;
    };

    Section.prototype.segments = function( ) {
      return this.document.segments;
    };

    Section.prototype.getOffset = function( ) {
      if ( !this.document /* || this.document.promise.state() !== 'resolved' */ ) {
        return null;
      }
      return this.document.absoluteOffset;
    };

    Section.prototype.getAudioUrls = function( ) {
      if ( !this.document /* || this.document.promise.state() !== 'resolved' */ ) {
        return [ ];
      }
      var resources = this.resources;
      return this.document.getAudioReferences( ).reduce( function( urls,
        file ) {
        file = file.toLowerCase( );
        if ( resources[ file ] && resources[ file ].url ) {
          urls.push( resources[ file ].url );
        }

        return urls;
      }, [ ], this );
    };

    Section.prototype.hasNext = function( ) {
      return !!this.next;
    };

    Section.prototype.hasPrevious = function( ) {
      return !!this.previous;
    };

    Section.prototype.hasParent = function( ) {
      return !!this.parent;
    };


    // Since segments are sub-components of this class, we ensure that loading
    // is complete before returning them.

    // Helper function for segment getters
    // Return a promise that ensures that resources for both this object
    // and the segment are loaded.
    Section.prototype._getSegment = function( getter ) {
      var deferred = $q.defer( );
      this.promise.catch( function( error ) {
        return deferred.reject( error );
      } );
      this.promise.then( function( section ) {
        if ( !section || !section.document || !section.document.segments ) {
          throw 'Section: _getSegment: Invalid section loaded';
        }

        var segment = getter( section.document.segments );
        if ( segment ) {
          segment.load( );
          segment.promise.then( function( ) {
            return deferred.resolve( segment );
          } );
          return segment.promise.catch( function( error ) {
            return deferred.reject( error );
          } );
        } else {
          // TODO: We should change the call convention to just resolve with null
          //       if no segment is found.
          return deferred.reject( 'Segment not found' );
        }
      } );
      return deferred.promise;
    };

    Section.prototype.firstSegment = function( ) {
      return this._getSegment( function( segments ) {
        return segments[ 0 ];
      } );
    };

    Section.prototype.lastSegment = function( ) {
      return this._getSegment( function( segments ) {
        return segments[ segments.length - 1 ];
      } );
    };

    Section.prototype.getSegmentById = function( id ) {
      return this._getSegment( function( segments ) {
        var segment, _i, _len;
        for ( _i = 0, _len = segments.length; _i < _len; _i++ ) {
          segment = segments[ _i ];
          if ( segment.id === id ) {
            return segment;
          }
        }
      } );
    };

    Section.prototype.getUnloadedSegmentsByAudio = function( audio ) {
      if ( !!this.document /*this.state() !== 'resolved'*/ ) {
        throw 'Section: getSegmentsByAudio only works on resolved sections';
      }
      return jQuery.grep( this.document.segments, function( segment ) {
        if ( segment.audio === audio ) {
          return true;
        }
      } );
    };

    Section.prototype.getSegmentsByAudioOffset = function( audio, offset ) {
      var segment, _i, _len, _ref;
      _ref = this.getUnloadedSegmentsByAudio( audio );
      for ( _i = 0, _len = _ref.length; _i < _len; _i++ ) {
        segment = _ref[ _i ];
        if ( segment.containsOffset( offset ) ) {
          return segment;
        }
      }
    };

    Section.prototype.getSegmentBySmilOffset = function( offset ) {
      if ( !offset ) {
        offset = 0;
      }
      return this._getSegment( function( segments ) {
        var currentOffset, segment, _i, _len;
        currentOffset = 0;
        for ( _i = 0, _len = segments.length; _i < _len; _i++ ) {
          segment = segments[ _i ];
          if ( ( currentOffset <= offset && offset <= currentOffset +
              segment.duration ) ) {
            return segment;
          }
          currentOffset += segment.duration;
        }
      } );
    };

    Section.prototype.getSegmentByOffset = function( offset ) {
      if ( !offset ) {
        offset = 0;
      }
      return this._getSegment( function( segments ) {
        var segment, _i, _len;
        for ( _i = 0, _len = segments.length; _i < _len; _i++ ) {
          segment = segments[ _i ];
          if ( ( segment.start <= offset && offset < segment.end ) ) {
            return segment;
          }
        }
      } );
    };

    // Flattens the structure from this section and "downwards"
    Section.prototype.flatten = function( ) {
      return this.children.reduce( function( flat, child ) {
        return flat.concat( child.flatten( ) );
      }, [ this ] );
    };

    return Section;
  } ] );
